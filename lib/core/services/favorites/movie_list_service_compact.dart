/// Compact MovieListService using composition with helper classes.
/// Reduced from 1,247 to ~220 lines by extracting operations to helpers.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/core/services/favorites/movie_list_file_helper.dart';
import 'package:moviestar/core/services/favorites/movie_list_operations_helper.dart';
import 'package:moviestar/core/services/pod/base_pod_service.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/user_profile_service.dart';
import 'package:moviestar/utils/turtle_serializer.dart';

/// Compact MovieListService using helper composition pattern.
/// Functionality preserved while dramatically reducing file size.
class MovieListService extends BasePodService {
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
    if (!forceRefresh && _cache.containsKey(movieListId)) {
      return _cache[movieListId];
    }

    return await executePodOperation(
      operation: () async {
        final fileName = _fileHelper.getMovieListFilePath(movieListId);
        final content = await safeReadFile('moviestar/data/$fileName');

        if (content != null && content.isNotEmpty) {
          final movieListData = TurtleSerializer.movieListFromTurtle(content);

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
            _cache[movieListId] = movieListData;
            return movieListData;
          }
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
    return await _operationsHelper.addMovieToList(
      movieListId,
      movie,
      contentType: contentType,
    );
  }

  /// Removes a movie from a MovieList.
  Future<bool> removeMovieFromList(String movieListId, int movieId) async {
    return await _operationsHelper.removeMovieFromList(movieListId, movieId);
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

        debugPrint('✅ Found existing $listType MovieList: $existingId');
        return existingId;

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
    return await _operationsHelper.updateMovieListName(movieListId, newName);
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
    return await _operationsHelper.batchAddMoviesToList(movieListId, movies);
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
