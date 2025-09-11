/// Service for managing custom movie lists in POD storage.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/movie_list_service.dart';
import 'package:moviestar/services/pod_file_operations_service.dart';
import 'package:moviestar/utils/is_logged_in.dart';
import 'package:moviestar/utils/turtle_serializer.dart';

/// Result model for list operations.
class ListOperationResult {
  final bool success;
  final String? error;
  final CustomList? list;
  final List<CustomList>? lists;

  const ListOperationResult({
    required this.success,
    this.error,
    this.list,
    this.lists,
  });

  factory ListOperationResult.success({
    CustomList? list,
    List<CustomList>? lists,
  }) {
    return ListOperationResult(
      success: true,
      list: list,
      lists: lists,
    );
  }

  factory ListOperationResult.failure(String error) {
    return ListOperationResult(
      success: false,
      error: error,
    );
  }
}

/// Service for managing custom movie lists in POD storage.
class PodListManagementService {
  final BuildContext _context;
  final Widget _child;
  final MovieListService _movieListService;

  /// Cache for custom lists to avoid frequent POD reads.
  final Map<String, CustomList> _customListsCache = {};

  /// Track the last time we scanned the directory.
  DateTime? _lastDirectoryScan;

  /// Cache expiration duration.
  static const Duration _cacheExpiration = Duration(minutes: 5);

  PodListManagementService(
    this._context,
    this._child,
    this._movieListService,
  );

  /// Retrieves all custom lists from PODs with caching.
  Future<ListOperationResult> getCustomLists({
    bool forceRefresh = false,
  }) async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        return ListOperationResult.success(lists: []);
      }

      // Check cache expiration
      final shouldRefresh = forceRefresh ||
          _lastDirectoryScan == null ||
          DateTime.now().difference(_lastDirectoryScan!) > _cacheExpiration;

      if (!shouldRefresh && _customListsCache.isNotEmpty) {
        return ListOperationResult.success(
          lists: _customListsCache.values.toList(),
        );
      }

      return await _scanAndLoadCustomLists();
    } catch (e) {
      debugPrint('❌ Failed to get custom lists from POD: $e');
      return ListOperationResult.failure('Failed to load custom lists: $e');
    }
  }

  /// Scans the POD directory and loads all custom lists.
  Future<ListOperationResult> _scanAndLoadCustomLists() async {
    final customLists = <CustomList>[];

    // Clear cache to rebuild it
    _customListsCache.clear();

    // Track processed list IDs and names to avoid duplicates
    final processedListIds = <String>{};
    final processedListNames = <String>{};

    try {
      // Scan the user_lists directory for MovieList files
      final dirUrl = await getDirUrl('moviestar/data/user_lists');
      final resources = await getResourcesInContainer(dirUrl);

      debugPrint(
        '📂 [PodListManagement] Found ${resources.files.length} files in user_lists directory',
      );

      for (final fileName in resources.files) {
        if (!_isValidMovieListFile(fileName)) {
          continue;
        }

        // Extract the MovieList ID from the filename
        final movieListId = _extractMovieListId(fileName);
        if (movieListId == null) continue;

        // Skip if we've already processed this list ID
        if (processedListIds.contains(movieListId)) {
          debugPrint(
            '⚠️ [PodListManagement] Skipping duplicate MovieList ID: $movieListId',
          );
          continue;
        }
        processedListIds.add(movieListId);

        // Get the MovieList data
        final movieListData = await _movieListService.getMovieList(movieListId);
        if (movieListData == null) {
          debugPrint(
            '❌ [PodListManagement] Failed to load MovieList: $movieListId',
          );
          continue;
        }

        // Convert MovieList data to CustomList format
        final customList = _movieListToCustomList(movieListId, movieListData);

        // Skip standard lists and duplicates by name
        if (_isStandardList(customList.name) ||
            processedListNames.contains(customList.name)) {
          continue;
        }

        processedListNames.add(customList.name);
        customLists.add(customList);
        _customListsCache[movieListId] = customList;
      }

      _lastDirectoryScan = DateTime.now();
      return ListOperationResult.success(lists: customLists);
    } catch (e) {
      if (!e.toString().contains('does not exist') &&
          !e.toString().contains('Failed to get resource list')) {
        debugPrint('❌ Error scanning user_lists directory: $e');
        return ListOperationResult.failure('Failed to scan directory: $e');
      }
      return ListOperationResult.success(lists: []);
    }
  }

  /// Checks if a filename is a valid MovieList file.
  bool _isValidMovieListFile(String fileName) {
    if (!fileName.startsWith('MovieList-') || !fileName.endsWith('.ttl')) {
      return false;
    }

    // Skip ACL, backup, or other metadata files that might be created during sharing
    if (fileName.contains('.acl.') ||
        fileName.contains('_backup') ||
        fileName.contains('_shared') ||
        fileName.contains('.meta.') ||
        fileName.contains('~') ||
        fileName.startsWith('.')) {
      debugPrint('⚠️ [PodListManagement] Skipping metadata file: $fileName');
      return false;
    }

    return true;
  }

  /// Extracts MovieList ID from filename.
  String? _extractMovieListId(String fileName) {
    try {
      return fileName.replaceAll('MovieList-', '').replaceAll('.ttl', '');
    } catch (e) {
      return null;
    }
  }

  /// Checks if a list name is a standard system list.
  bool _isStandardList(String name) {
    return name == 'To Watch' || name == 'Watched';
  }

  /// Converts MovieList data to CustomList format.
  CustomList _movieListToCustomList(
    String movieListId,
    Map<String, dynamic> movieListData,
  ) {
    final movies = List<Movie>.from(movieListData['movies'] ?? []);
    final movieIds = movies.map((m) => m.id).toList();

    return CustomList(
      id: movieListId,
      name: movieListData['name'] ?? 'Unnamed List',
      description: movieListData['description'],
      movieIds: movieIds,
      createdAt: DateTime.now(), // MovieList doesn't track creation time yet
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a new custom list in PODs.
  Future<ListOperationResult> createCustomList(
    String name, {
    String? description,
  }) async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        return ListOperationResult.failure(
          'Please log in to create custom lists',
        );
      }

      // Create the MovieList in PODs
      final movieListId = await _movieListService.createMovieList(
        name,
        movies: [],
        description: description ?? '',
      );

      if (movieListId == null) {
        return ListOperationResult.failure('Failed to create MovieList in POD');
      }

      final newList = CustomList(
        id: movieListId,
        name: name,
        description: description,
        movieIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Update cache
      _customListsCache[movieListId] = newList;

      return ListOperationResult.success(list: newList);
    } catch (e) {
      debugPrint('❌ Failed to create custom list in POD: $e');
      return ListOperationResult.failure('Failed to create list: $e');
    }
  }

  /// Updates an existing custom list in PODs.
  Future<ListOperationResult> updateCustomList(CustomList updatedList) async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        return ListOperationResult.failure(
          'Please log in to update custom lists',
        );
      }

      // Get the current MovieList data to preserve movies
      final movieListData =
          await _movieListService.getMovieList(updatedList.id);
      if (movieListData == null) {
        return ListOperationResult.failure(
          'MovieList not found for ID: ${updatedList.id}',
        );
      }

      // Get the movies from the existing list
      final movies = movieListData['movies'] as List<Movie>? ?? [];

      // Create updated TTL content with new name/description but same movies
      final movieListTtl = TurtleSerializer.createMovieList(
        updatedList.id,
        updatedList.name,
        movies: movies,
        description: updatedList.description,
      );

      // Write updated content back to POD
      final fileName = 'user_lists/MovieList-${updatedList.id}.ttl';

      if (!_context.mounted) {
        return ListOperationResult.failure('Context not available');
      }

      final result = await PodFileOperationsService.writeFile(
        fileName,
        movieListTtl,
        _context,
        _child,
        encrypted: false,
      );

      if (!result.success) {
        return ListOperationResult.failure(
          result.error ?? 'Failed to write updated list to POD storage',
        );
      }

      // Update cache
      _customListsCache[updatedList.id] = updatedList;

      return ListOperationResult.success(list: updatedList);
    } catch (e) {
      debugPrint('❌ Failed to update custom list in POD: $e');
      return ListOperationResult.failure('Failed to update list: $e');
    }
  }

  /// Deletes a custom list from PODs.
  Future<ListOperationResult> deleteCustomList(String listId) async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        return ListOperationResult.failure(
          'Please log in to delete custom lists',
        );
      }

      // Delete the MovieList from PODs
      final success = await _movieListService.deleteMovieList(listId);
      if (!success) {
        return ListOperationResult.failure(
          'Failed to delete MovieList from POD',
        );
      }

      // Remove from cache
      _customListsCache.remove(listId);

      return ListOperationResult.success();
    } catch (e) {
      debugPrint('❌ Failed to delete custom list from POD: $e');
      return ListOperationResult.failure('Failed to delete list: $e');
    }
  }

  /// Adds a movie to a custom list in PODs.
  Future<ListOperationResult> addMovieToCustomList(
    String listId,
    Movie movie, {
    String contentType = 'movie',
  }) async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        return ListOperationResult.failure(
          'Please log in to modify custom lists',
        );
      }

      // Add movie to the MovieList in PODs
      final success = await _movieListService.addMovieToList(
        listId,
        movie,
        contentType: contentType,
      );

      if (!success) {
        return ListOperationResult.failure(
          'Failed to add movie to MovieList in POD',
        );
      }

      // Update cache
      if (_customListsCache.containsKey(listId)) {
        final currentList = _customListsCache[listId]!;
        if (!currentList.movieIds.contains(movie.id)) {
          final updatedMovieIds = [...currentList.movieIds, movie.id];
          _customListsCache[listId] = currentList.copyWith(
            movieIds: updatedMovieIds,
          );
        }
      }

      return ListOperationResult.success();
    } catch (e) {
      debugPrint('❌ Failed to add movie to custom list in POD: $e');
      return ListOperationResult.failure('Failed to add movie to list: $e');
    }
  }

  /// Removes a movie from a custom list in PODs.
  Future<ListOperationResult> removeMovieFromCustomList(
    String listId,
    int movieId,
  ) async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        return ListOperationResult.failure(
          'Please log in to modify custom lists',
        );
      }

      // Create a minimal Movie object for the removal operation
      final movie = Movie(
        id: movieId,
        title: '',
        overview: '',
        posterUrl: '',
        backdropUrl: '',
        voteAverage: 0,
        releaseDate: DateTime(1970),
        genreIds: [],
      );

      // Remove movie from the MovieList in PODs
      final success =
          await _movieListService.removeMovieFromList(listId, movie);

      if (!success) {
        return ListOperationResult.failure(
          'Failed to remove movie from MovieList in POD',
        );
      }

      // Update cache
      if (_customListsCache.containsKey(listId)) {
        final currentList = _customListsCache[listId]!;
        final updatedMovieIds =
            currentList.movieIds.where((id) => id != movieId).toList();
        _customListsCache[listId] = currentList.copyWith(
          movieIds: updatedMovieIds,
        );
      }

      return ListOperationResult.success();
    } catch (e) {
      debugPrint('❌ Failed to remove movie from custom list in POD: $e');
      return ListOperationResult.failure(
        'Failed to remove movie from list: $e',
      );
    }
  }

  /// Gets movies in a specific custom list.
  Future<List<Movie>> getMoviesInCustomList(String listId) async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        return [];
      }

      // Get the MovieList data which includes movie objects
      final movieListData = await _movieListService.getMovieList(listId);
      if (movieListData != null && movieListData['movies'] != null) {
        final movies = List<Movie>.from(movieListData['movies']);

        // Filter out placeholder movies (those with titles exactly matching "Movie 123456" pattern)
        final validMovies = movies.where((movie) {
          final isPlaceholder = RegExp(r'^Movie \d+$').hasMatch(movie.title);
          return !isPlaceholder;
        }).toList();

        return validMovies;
      }

      return [];
    } catch (e) {
      debugPrint('❌ Failed to get movies in custom list: $e');
      return [];
    }
  }

  /// Checks if a movie is in a specific custom list.
  Future<bool> isMovieInCustomList(String listId, int movieId) async {
    try {
      // First check cache
      if (_customListsCache.containsKey(listId)) {
        return _customListsCache[listId]!.movieIds.contains(movieId);
      }

      // Otherwise, fetch the list
      final result = await getCustomLists();
      if (result.success && result.lists != null) {
        final list = result.lists!.firstWhere(
          (list) => list.id == listId,
          orElse: () => CustomList(
            id: '',
            name: '',
            movieIds: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        return list.movieIds.contains(movieId);
      }

      return false;
    } catch (e) {
      debugPrint('❌ Failed to check if movie is in custom list: $e');
      return false;
    }
  }

  /// Gets all custom lists that contain a specific movie.
  Future<List<CustomList>> getCustomListsContainingMovie(int movieId) async {
    final result = await getCustomLists();
    if (result.success && result.lists != null) {
      return result.lists!
          .where((list) => list.movieIds.contains(movieId))
          .toList();
    }
    return [];
  }

  /// Clears the cache and forces a refresh on next access.
  void clearCache() {
    _customListsCache.clear();
    _lastDirectoryScan = null;
  }
}
