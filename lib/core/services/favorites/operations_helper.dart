/// Helper class for MovieListService CRUD operations.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/core/services/favorites/movie_list_file_helper.dart';
import 'package:moviestar/core/services/pod/file_operations_service.dart';
import 'package:moviestar/core/services/pod/operations_mixin.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/user_profile_service.dart';
import 'package:moviestar/utils/serializer.dart';

/// Helper for MovieList CRUD operations.

class MovieListOperationsHelper with PodOperationsMixin {
  final BuildContext _context;
  final Widget _child;
  final UserProfileService _userProfileService;
  final MovieListFileHelper _fileHelper;
  final Map<String, Map<String, dynamic>> _cache;

  MovieListOperationsHelper(
    this._context,
    this._child,
    this._userProfileService,
    this._fileHelper,
    this._cache,
  );

  /// Adds a movie to a MovieList.

  Future<bool> addMovieToList(
    String movieListId,
    Movie movie, {
    String contentType = 'movie',
  }) async {
    try {
      final movieList = await _getMovieList(movieListId);
      if (movieList == null) {
        return false;
      }

      final currentMovies = List<Movie>.from(movieList['movies'] ?? []);

      if (currentMovies.any((m) => m.id == movie.id)) {
        return true; // Already in list
      }

      await _fileHelper.createMovieFile(movie, contentType: contentType);
      currentMovies.add(movie);

      return await _updateMovieListContent(
        movieListId,
        movieList,
        currentMovies,
      );
    } catch (e) {
      return false;
    }
  }

  /// Removes a movie from a MovieList.

  Future<bool> removeMovieFromList(String movieListId, int movieId) async {
    try {
      final movieList = await _getMovieList(movieListId);
      if (movieList == null) return false;

      final currentMovies = List<Movie>.from(movieList['movies'] ?? []);
      currentMovies.removeWhere((m) => m.id == movieId);

      return await _updateMovieListContent(
        movieListId,
        movieList,
        currentMovies,
      );
    } catch (e) {
      return false;
    }
  }

  /// Deletes a MovieList.

  Future<bool> deleteMovieList(String movieListId) async {
    if (!await validateContextAndLogin(_context)) {
      return false;
    }

    try {
      final filePath = 'moviestar/data/${getMovieListFilePath(movieListId)}';

      if (!_context.mounted) return false;

      final result = await PodFileOperationsService.deleteFile(
        filePath,
        _context,
        _child,
      );

      if (!_context.mounted) {
        return false;
      }

      if (result.success) {
        _cache.remove(movieListId);

        final profileUpdateSuccess =
            await _userProfileService.removeMovieListFromProfile(movieListId);

        if (profileUpdateSuccess) {
          return true;
        } else {
          return false;
        }
      } else {}
    } catch (e) {
      // Failed to remove movie from list.
    }
    return false;
  }

  /// Updates the name of a MovieList.

  Future<bool> updateMovieListName(String movieListId, String newName) async {
    try {
      final movieList = await _getMovieList(movieListId);
      if (movieList == null) return false;

      final currentMovies = List<Movie>.from(movieList['movies'] ?? []);

      final updatedTtl = TurtleSerializer.createMovieList(
        movieListId,
        newName,
        movies: currentMovies,
      );

      return await _writeMovieListFile(movieListId, updatedTtl);
    } catch (e) {
      return false;
    }
  }

  /// Batch adds multiple movies to a MovieList.

  Future<bool> batchAddMoviesToList(
    String movieListId,
    List<Movie> movies,
  ) async {
    try {
      final movieList = await _getMovieList(movieListId);
      if (movieList == null) return false;

      final currentMovies = List<Movie>.from(movieList['movies'] ?? []);
      final currentIds = currentMovies.map((m) => m.id).toSet();

      for (final movie in movies) {
        if (!currentIds.contains(movie.id)) {
          await _fileHelper.createMovieFile(movie);
          currentMovies.add(movie);
        }
      }

      return await _updateMovieListContent(
        movieListId,
        movieList,
        currentMovies,
      );
    } catch (e) {
      return false;
    }
  }

  /// Gets all MovieLists for the current user.

  Future<List<Map<String, dynamic>>> getAllMovieLists() async {
    if (!await validateContextAndLogin(_context)) {
      return [];
    }

    try {
      final profile = await _userProfileService.getUserProfile();

      final movieListIds = profile?['movieListIds'] as List<String>? ?? [];

      final movieLists = <Map<String, dynamic>>[];

      for (final id in movieListIds) {
        final movieList = await _getMovieList(id);
        if (movieList != null) {
          movieLists.add(movieList);
        } else {}
      }

      return movieLists;
    } catch (e) {
      return [];
    }
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

  Future<Map<String, dynamic>?> _getMovieList(String movieListId) async {
    if (_cache.containsKey(movieListId)) {
      return _cache[movieListId];
    }

    // Load from POD if not in cache.

    final fileName = getMovieListFilePath(movieListId);

    final result = await PodFileOperationsService.readFile(
      'moviestar/data/$fileName',
      _context,
      _child,
    );

    if (result.success && (result.data?.isNotEmpty ?? false)) {
      final movieListData = TurtleSerializer.movieListFromTurtle(result.data!);
      if (movieListData != null) {
        movieListData['id'] = movieListId;
        _cache[movieListId] = movieListData;
        return movieListData;
      }
    }
    return null;
  }

  Future<bool> _updateMovieListContent(
    String movieListId,
    Map<String, dynamic> movieList,
    List<Movie> movies,
  ) async {
    final updatedTtl = TurtleSerializer.createMovieList(
      movieListId,
      movieList['name'],
      movies: movies,
    );

    if (await _writeMovieListFile(movieListId, updatedTtl)) {
      _cache.remove(movieListId);
      return true;
    }
    return false;
  }

  /// Gets the file path for a MovieList file.

  @override
  String getMovieListFilePath(String movieListId) {
    return 'user_lists/MovieList-$movieListId.ttl';
  }

  Future<bool> _writeMovieListFile(String movieListId, String content) async {
    if (!validateContext(_context)) return false;

    final result = await PodFileOperationsService.writeFile(
      getMovieListFilePath(movieListId),
      content,
      _context,
      _child,
      encrypted: false,
    );

    return result.success;
  }
}
