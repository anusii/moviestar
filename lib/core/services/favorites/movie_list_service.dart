/// Compact MovieListService using composition with helper classes.
/// Reduced from 1,247 to ~220 lines by extracting operations to helpers.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/core/services/favorites/movie_list_file_helper.dart';
import 'package:moviestar/core/services/favorites/operations_helper.dart';
import 'package:moviestar/core/services/pod/base_pod_service.dart';
import 'package:moviestar/core/services/pod/operations_mixin.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/user_profile_service.dart';
import 'package:moviestar/utils/serializer.dart';

/// Compact MovieListService using helper composition pattern.
/// Functionality preserved while dramatically reducing file size.
class MovieListService extends BasePodService with PodOperationsMixin {
  final UserProfileService _userProfileService;
  final Map<String, Map<String, dynamic>> _cache = {};

  late final MovieListFileHelper _fileHelper;
  late final MovieListOperationsHelper _operationsHelper;

  MovieListService(super.context, super.child, this._userProfileService) {
    _fileHelper = MovieListFileHelper(context, child);
    _operationsHelper = MovieListOperationsHelper(
      context,
      child,
      _userProfileService,
      _fileHelper,
      _cache,
    );
  }

  /// Creates a new MovieList with the given name and movies.
  Future<String?> createMovieList(
    String listName, {
    List<Movie> movies = const [],
    String description = '',
  }) async {
    return await executePodOperation(
      operation: () async {
        // Check if a custom list with this name already exists
        debugPrint(
          '🎬 [MovieListService] Checking for existing list with name: $listName',
        );
        final existingListId = await _fileHelper.findExistingMovieList(
          'custom', // Use 'custom' as list type for user-created lists
          listName,
        );

        if (existingListId != null) {
          debugPrint(
            '⚠️ [MovieListService] List "$listName" already exists with ID: $existingListId - returning existing',
          );
          return existingListId;
        }

        final movieListId = TurtleSerializer.generateId();
        final movieListTtl = TurtleSerializer.createMovieList(
          movieListId,
          listName,
          movies: movies,
          description: description,
        );

        final success = await safeWriteFile(
          _fileHelper.getMovieListFilePath(movieListId),
          movieListTtl,
        );

        if (success) {
          _cache[movieListId] = {
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
        return null;
      },
      operationName: 'createMovieList',
    );
  }

  /// Gets a MovieList by ID, optionally forcing a refresh from POD.
  Future<Map<String, dynamic>?> getMovieList(
    String movieListId, {
    bool forceRefresh = false,
  }) async {
    debugPrint(
      '🎬 [MovieListService] getMovieList called for: $movieListId (forceRefresh: $forceRefresh)',
    );

    if (!forceRefresh && _cache.containsKey(movieListId)) {
      final cached = _cache[movieListId];
      final movies = cached?['movies'] as List<Movie>? ?? [];

      // Check if cached data contains placeholder movies
      final hasPlaceholders =
          movies.any((movie) => movie.title == 'Loading...');
      if (hasPlaceholders) {
        debugPrint(
          '🎬 [MovieListService] Cache contains placeholder movies - forcing refresh',
        );
        _cache.remove(movieListId);
      } else {
        debugPrint('🎬 [MovieListService] Returning cached data');
        debugPrint(
          '🎬 [MovieListService] Cached movies count: ${movies.length}',
        );
        return cached;
      }
    }

    debugPrint('🎬 [MovieListService] Loading from POD...');
    return await executePodOperation(
      operation: () async {
        final fileName = _fileHelper.getMovieListFilePath(movieListId);
        debugPrint(
          '🎬 [MovieListService] Reading file: moviestar/data/$fileName',
        );
        final content = await safeReadFile('moviestar/data/$fileName');

        if (content != null && content.isNotEmpty) {
          debugPrint(
            '🎬 [MovieListService] File content loaded (${content.length} chars)',
          );
          final movieListData = TurtleSerializer.movieListFromTurtle(content);

          if (movieListData != null) {
            debugPrint(
              '🎬 [MovieListService] Successfully parsed movie list data',
            );
            movieListData['id'] = movieListId;

            // Load full movie data
            final placeholderMovies =
                movieListData['movies'] as List<Movie>? ?? [];
            debugPrint(
              '🎬 [MovieListService] Found ${placeholderMovies.length} placeholder movies',
            );
            final fullMovies = <Movie>[];

            for (final placeholderMovie in placeholderMovies) {
              final contentType =
                  placeholderMovie.contentType == ContentType.tvShow
                      ? 'tv'
                      : 'movie';
              debugPrint(
                '🎬 [MovieListService] Loading movie ${placeholderMovie.id} with contentType: $contentType',
              );
              final fullMovieData = await _fileHelper.loadFullMovieData(
                placeholderMovie.id,
                contentType: contentType,
              );
              debugPrint(
                '🎬 [MovieListService] Loaded movie ${placeholderMovie.id}: ${fullMovieData?.title ?? 'NULL'}',
              );
              fullMovies.add(fullMovieData ?? placeholderMovie);
            }

            movieListData['movies'] = fullMovies;
            _cache[movieListId] = movieListData;
            debugPrint(
              '🎬 [MovieListService] Final result: ${fullMovies.length} movies with full details',
            );
            return movieListData;
          } else {
            debugPrint('🎬 [MovieListService] Failed to parse movie list data');
          }
        } else {
          debugPrint('🎬 [MovieListService] No content found in file');
        }
        return null;
      },
      operationName: 'getMovieList',
    );
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
    final success = await _operationsHelper.addMovieToList(
      movieListId,
      movie,
      contentType: contentType,
    );

    if (success) {
      _cache.remove(movieListId);
    }

    return success;
  }

  /// Removes a movie from a MovieList.
  Future<bool> removeMovieFromList(String movieListId, int movieId) async {
    final success =
        await _operationsHelper.removeMovieFromList(movieListId, movieId);

    if (success) {
      _cache.remove(movieListId);
    }

    return success;
  }

  /// Deletes a MovieList.
  Future<bool> deleteMovieList(String movieListId) async {
    return await _operationsHelper.deleteMovieList(movieListId);
  }

  /// Gets all MovieLists for the current user.
  Future<List<Map<String, dynamic>>> getAllMovieLists() async {
    return await _operationsHelper.getAllMovieLists();
  }

  /// Initializes a MovieList for a specific type (to_watch, watched, favorites).
  Future<String?> initializeMovieList(
    String listType,
    String displayName, {
    List<Movie> initialMovies = const [],
  }) async {
    return await retryOperation(
      operation: () async {
        String? existingId = await _fileHelper.findExistingMovieList(
          listType,
          displayName,
        );

        if (existingId != null) {
          debugPrint('✅ Found existing $listType MovieList: $existingId');
          return existingId;
        }

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

  /// Updates the name of a MovieList.
  Future<bool> updateMovieListName(String movieListId, String newName) async {
    final success =
        await _operationsHelper.updateMovieListName(movieListId, newName);

    if (success) {
      _cache.remove(movieListId);
    }

    return success;
  }

  /// Gets MovieLists containing a specific movie.
  Future<List<String>> getMovieListsContainingMovie(int movieId) async {
    return await _operationsHelper.getMovieListsContainingMovie(movieId);
  }

  /// Batch adds multiple movies to a MovieList.
  Future<bool> batchAddMoviesToList(
    String movieListId,
    List<Movie> movies,
  ) async {
    final success =
        await _operationsHelper.batchAddMoviesToList(movieListId, movies);

    if (success) {
      _cache.remove(movieListId);
    }

    return success;
  }

  /// Clears the cache for all MovieLists.
  void clearCache() {
    _cache.clear();
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
}
