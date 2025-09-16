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
import 'package:moviestar/models/list_operation_models.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/movie_list_service.dart';
import 'package:moviestar/services/pod_file_operations_service.dart';
import 'package:moviestar/services/pod_list_cache_manager.dart';
import 'package:moviestar/services/pod_list_data_converter.dart';
import 'package:moviestar/services/pod_list_file_validator.dart';
import 'package:moviestar/utils/is_logged_in.dart';

/// Service for managing custom movie lists in POD storage.
class PodListManagementService {
  final BuildContext _context;
  final Widget _child;
  final MovieListService _movieListService;
  final PodListCacheManager _cacheManager = PodListCacheManager();

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

      // Check cache
      if (!_cacheManager.shouldRefresh(forceRefresh: forceRefresh)) {
        final cachedLists = _cacheManager.getCachedLists();
        if (cachedLists != null) {
          return ListOperationResult.success(lists: cachedLists);
        }
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
    _cacheManager.clearForRebuild();

    // Track processed list IDs and names to avoid duplicates
    final processedListIds = <String>{};
    final processedListNames = <String>{};

    try {
      // Scan the user_lists directory for MovieList files
      final dirUrl = await getDirUrl('moviestar/data/user_lists');
      final resources = await getResourcesInContainer(dirUrl);

      for (final fileName in resources.files) {
        if (!PodListFileValidator.isValidMovieListFile(fileName)) {
          continue;
        }

        // Extract the MovieList ID from the filename
        final movieListId = PodListFileValidator.extractMovieListId(fileName);
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
        final customList = PodListDataConverter.movieListToCustomList(
          movieListId,
          movieListData,
        );

        // Skip standard lists and duplicates by name
        if (PodListFileValidator.isStandardList(customList.name) ||
            processedListNames.contains(customList.name)) {
          continue;
        }

        processedListNames.add(customList.name);
        customLists.add(customList);
        _cacheManager.cacheList(movieListId, customList);
      }

      _cacheManager.markDirectoryScanned();
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
      _cacheManager.cacheList(movieListId, newList);

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
      final movieListTtl = PodListDataConverter.createMovieListTtl(
        updatedList.id,
        updatedList.name,
        movies,
        description: updatedList.description,
      );

      // Write updated content back to POD
      final fileName = PodListDataConverter.generateFileName(updatedList.id);

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
      _cacheManager.updateCachedList(updatedList.id, updatedList);

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
      _cacheManager.removeCachedList(listId);

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
      if (_cacheManager.containsList(listId)) {
        final currentList = _cacheManager.getCachedList(listId)!;
        if (!currentList.movieIds.contains(movie.id)) {
          final updatedMovieIds = [...currentList.movieIds, movie.id];
          _cacheManager.updateCachedList(
            listId,
            currentList.copyWith(movieIds: updatedMovieIds),
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
      final movie = PodListDataConverter.createMinimalMovie(movieId);

      // Remove movie from the MovieList in PODs
      final success =
          await _movieListService.removeMovieFromList(listId, movie.id);

      if (!success) {
        return ListOperationResult.failure(
          'Failed to remove movie from MovieList in POD',
        );
      }

      // Update cache
      if (_cacheManager.containsList(listId)) {
        final currentList = _cacheManager.getCachedList(listId)!;
        final updatedMovieIds =
            currentList.movieIds.where((id) => id != movieId).toList();
        _cacheManager.updateCachedList(
          listId,
          currentList.copyWith(movieIds: updatedMovieIds),
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

        // Filter out placeholder movies and TV shows
        final validMovies = PodListDataConverter.filterValidMovies(movies);

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
      if (_cacheManager.containsList(listId)) {
        return _cacheManager.getCachedList(listId)!.movieIds.contains(movieId);
      }

      // Otherwise, fetch the list
      final result = await getCustomLists();
      if (result.success && result.lists != null) {
        final list = result.lists!.firstWhere(
          (list) => list.id == listId,
          orElse: PodListDataConverter.createEmptyCustomList,
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
    _cacheManager.clearCache();
  }
}
