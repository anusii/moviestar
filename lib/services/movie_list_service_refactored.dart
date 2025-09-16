/// Service for managing MovieList entities following the ontology structure.
/// Refactored version using PodOperationsMixin to reduce code duplication.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").

library;

import 'package:flutter/material.dart';

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/movie_list_file_helper.dart';
import 'package:moviestar/services/pod_file_operations_service.dart';
import 'package:moviestar/services/pod_operations_mixin.dart';
import 'package:moviestar/services/user_profile_service.dart';
import 'package:moviestar/utils/turtle_serializer.dart';

/// Service for managing MovieList entities in the POD following the ontology structure.
/// Refactored to use PodOperationsMixin for common patterns.
class MovieListService with PodOperationsMixin {
  final BuildContext _context;
  final Widget _child;
  final UserProfileService _userProfileService;

  // Cache for movie lists
  final Map<String, Map<String, dynamic>> _movieListCache = {};

  // Helper for file operations
  late final MovieListFileHelper _fileHelper;

  MovieListService(this._context, this._child, this._userProfileService) {
    _fileHelper = MovieListFileHelper(_context, _child);
  }

  /// Creates a new MovieList with the given name and movies.
  Future<String?> createMovieList(
    String listName, {
    List<Movie> movies = const [],
    String description = '',
  }) async {
    if (!await validateContextAndLogin(_context)) return null;

    try {
      final movieListId = TurtleSerializer.generateId();
      final fileName = getMovieListFilePath(movieListId);

      final movieListTtl = TurtleSerializer.createMovieList(
        movieListId,
        listName,
        movies: movies,
        description: description,
      );

      final result = await PodFileOperationsService.writeFile(
        fileName,
        movieListTtl,
        _context,
        _child,
        encrypted: false,
      );

      if (result.success) {
        _movieListCache[movieListId] = {
          'id': movieListId,
          'name': listName,
          'movies': movies,
          'description': description,
        };

        await _userProfileService.addMovieListToProfile(movieListId);

        for (final movie in movies) {
          await _fileHelper.createMovieFile(movie);
        }

        debugPrint('✅ Created MovieList: $listName (ID: $movieListId)');
        return movieListId;
      }
    } catch (e) {
      debugPrint('❌ Failed to create movie list: $e');
    }
    return null;
  }

  /// Gets a MovieList by ID, optionally forcing a refresh from POD.
  Future<Map<String, dynamic>?> getMovieList(
    String movieListId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _movieListCache.containsKey(movieListId)) {
      return _movieListCache[movieListId];
    }

    if (!await validateContextAndLogin(_context)) return null;

    try {
      final fileName = getMovieListFilePath(movieListId);

      final result = await PodFileOperationsService.readFile(
        'moviestar/data/$fileName',
        _context,
        _child,
      );

      if (result.success && (result.data?.isNotEmpty ?? false)) {
        final movieListData =
            TurtleSerializer.movieListFromTurtle(result.data!);

        if (movieListData != null) {
          movieListData['id'] = movieListId;

          // Load full movie data
          final placeholderMovies =
              movieListData['movies'] as List<Movie>? ?? [];
          final fullMovies = <Movie>[];

          for (final placeholderMovie in placeholderMovies) {
            final fullMovieData = await _fileHelper.loadFullMovieData(
              placeholderMovie.id,
              contentType: placeholderMovie.contentType == ContentType.tvShow
                  ? 'tvShow'
                  : 'movie',
            );
            fullMovies.add(fullMovieData ?? placeholderMovie);
          }

          movieListData['movies'] = fullMovies;
          _movieListCache[movieListId] = movieListData;
          return movieListData;
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to get movie list: $e');
    }
    return null;
  }

  /// Forces a refresh of a specific MovieList from POD.
  Future<Map<String, dynamic>?> refreshMovieList(String movieListId) async {
    return await getMovieList(movieListId, forceRefresh: true);
  }

  /// Adds a movie to a MovieList.
  Future<bool> addMovieToList(
    String movieListId,
    Movie movie, {
    String contentType = 'movie',
  }) async {
    try {
      final movieList = await getMovieList(movieListId);
      if (movieList == null) {
        debugPrint('❌ MovieList $movieListId not found');
        return false;
      }

      final currentMovies = List<Movie>.from(movieList['movies'] ?? []);

      if (currentMovies.any((m) => m.id == movie.id)) {
        return true; // Already in list
      }

      await _fileHelper.createMovieFile(movie, contentType: contentType);
      currentMovies.add(movie);

      final updatedTtl = TurtleSerializer.createMovieList(
        movieListId,
        movieList['name'],
        movies: currentMovies,
      );

      if (!validateContext(_context)) return false;

      final result = await PodFileOperationsService.writeFile(
        getMovieListFilePath(movieListId),
        updatedTtl,
        _context,
        _child,
        encrypted: false,
      );

      if (result.success) {
        _movieListCache.remove(movieListId);
        debugPrint('✅ Added ${movie.title} to MovieList $movieListId');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Failed to add movie to list: $e');
    }
    return false;
  }

  /// Removes a movie from a MovieList.
  Future<bool> removeMovieFromList(String movieListId, int movieId) async {
    try {
      final movieList = await getMovieList(movieListId);
      if (movieList == null) return false;

      final currentMovies = List<Movie>.from(movieList['movies'] ?? []);
      currentMovies.removeWhere((m) => m.id == movieId);

      final updatedTtl = TurtleSerializer.createMovieList(
        movieListId,
        movieList['name'],
        movies: currentMovies,
      );

      if (!validateContext(_context)) return false;

      final result = await PodFileOperationsService.writeFile(
        getMovieListFilePath(movieListId),
        updatedTtl,
        _context,
        _child,
        encrypted: false,
      );

      if (result.success) {
        _movieListCache.remove(movieListId);
        debugPrint('✅ Removed movie $movieId from MovieList $movieListId');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Failed to remove movie from list: $e');
    }
    return false;
  }

  /// Deletes a MovieList.
  Future<bool> deleteMovieList(String movieListId) async {
    if (!await validateContextAndLogin(_context)) return false;

    try {
      final result = await PodFileOperationsService.deleteFile(
        'moviestar/data/${getMovieListFilePath(movieListId)}',
        _context,
        _child,
      );

      if (result.success) {
        _movieListCache.remove(movieListId);
        await _userProfileService.removeMovieListFromProfile(movieListId);
        debugPrint('✅ Deleted MovieList $movieListId');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Failed to delete movie list: $e');
    }
    return false;
  }

  /// Gets all MovieLists for the current user.
  Future<List<Map<String, dynamic>>> getAllMovieLists() async {
    if (!await validateContextAndLogin(_context)) return [];

    try {
      final profile = await _userProfileService.getUserProfile();
      final movieListIds = profile?['movieListIds'] as List<String>? ?? [];
      final movieLists = <Map<String, dynamic>>[];

      for (final id in movieListIds) {
        final movieList = await getMovieList(id);
        if (movieList != null) {
          movieLists.add(movieList);
        }
      }

      return movieLists;
    } catch (e) {
      debugPrint('❌ Failed to get all movie lists: $e');
      return [];
    }
  }

  /// Initializes a MovieList for a specific type (to_watch, watched, favorites).
  Future<String?> initializeMovieList(
    String listType,
    String displayName, {
    List<Movie> initialMovies = const [],
  }) async {
    return await retryOperation(
      operation: () async {
        // Try to find existing list first
        String? existingId = await _fileHelper.findExistingMovieList(
          listType,
          displayName,
        );

        if (existingId != null) {
          debugPrint('✅ Found existing $listType MovieList: $existingId');
          return existingId;
        }

        // Create new list
        final description = _getListDescription(listType);
        return await createMovieList(
          displayName,
          movies: initialMovies,
          description: description,
        );
      },
      operationName: 'initializeMovieList($listType)',
      maxRetries: 3,
    );
  }

  /// Gets the file path for a MovieList file.
  @override
  String getMovieListFilePath(String movieListId) {
    return 'user_lists/MovieList-$movieListId.ttl';
  }

  String _getListDescription(String listType) {
    switch (listType) {
      case 'to_watch':
        return 'Movies you want to watch';
      case 'watched':
        return 'Movies you have watched';
      case 'favorites':
        return 'Your favorite movies';
      default:
        return '';
    }
  }

  /// Clears the cache for all MovieLists.
  void clearCache() {
    _movieListCache.clear();
  }

  /// Gets the count of movies in a MovieList without loading full data.
  Future<int> getMovieCount(String movieListId) async {
    final movieList = await getMovieList(movieListId);
    return (movieList?['movies'] as List?)?.length ?? 0;
  }

  /// Checks if a movie is in a MovieList.
  Future<bool> isMovieInList(String movieListId, int movieId) async {
    final movieList = await getMovieList(movieListId);
    final movies = movieList?['movies'] as List<Movie>? ?? [];
    return movies.any((m) => m.id == movieId);
  }

  /// Updates the name of a MovieList.
  Future<bool> updateMovieListName(String movieListId, String newName) async {
    try {
      final movieList = await getMovieList(movieListId);
      if (movieList == null) return false;

      final currentMovies = List<Movie>.from(movieList['movies'] ?? []);

      final updatedTtl = TurtleSerializer.createMovieList(
        movieListId,
        newName,
        movies: currentMovies,
      );

      if (!validateContext(_context)) return false;

      final result = await PodFileOperationsService.writeFile(
        getMovieListFilePath(movieListId),
        updatedTtl,
        _context,
        _child,
        encrypted: false,
      );

      if (result.success) {
        _movieListCache.remove(movieListId);
        debugPrint('✅ Updated MovieList name to: $newName');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Failed to update movie list name: $e');
    }
    return false;
  }

  /// Gets MovieLists containing a specific movie.
  Future<List<String>> getMovieListsContainingMovie(int movieId) async {
    final allLists = await getAllMovieLists();
    final listsWithMovie = <String>[];

    for (final list in allLists) {
      final movies = list['movies'] as List<Movie>? ?? [];
      if (movies.any((m) => m.id == movieId)) {
        listsWithMovie.add(list['id'] as String);
      }
    }

    return listsWithMovie;
  }

  /// Batch adds multiple movies to a MovieList.
  Future<bool> batchAddMoviesToList(
    String movieListId,
    List<Movie> movies,
  ) async {
    try {
      final movieList = await getMovieList(movieListId);
      if (movieList == null) return false;

      final currentMovies = List<Movie>.from(movieList['movies'] ?? []);
      final currentIds = currentMovies.map((m) => m.id).toSet();

      for (final movie in movies) {
        if (!currentIds.contains(movie.id)) {
          await _fileHelper.createMovieFile(movie);
          currentMovies.add(movie);
        }
      }

      final updatedTtl = TurtleSerializer.createMovieList(
        movieListId,
        movieList['name'],
        movies: currentMovies,
      );

      if (!validateContext(_context)) return false;

      final result = await PodFileOperationsService.writeFile(
        getMovieListFilePath(movieListId),
        updatedTtl,
        _context,
        _child,
        encrypted: false,
      );

      if (result.success) {
        _movieListCache.remove(movieListId);
        debugPrint('✅ Batch added ${movies.length} movies to MovieList');
        return true;
      }
    } catch (e) {
      debugPrint('❌ Failed to batch add movies: $e');
    }
    return false;
  }
}
