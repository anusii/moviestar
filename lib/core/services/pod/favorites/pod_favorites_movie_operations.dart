/// Movie operations for POD favorites service.
/// Handles adding/removing movies from watch lists and movie-related queries.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'dart:async';

import 'package:moviestar/core/services/favorites/movie_list_service.dart';
import 'package:moviestar/core/services/pod/favorites_file_manager.dart';
import 'package:moviestar/core/services/pod/favorites_stream_manager.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/utils/serializer.dart';

/// Handles movie-specific operations for POD favorites service.

class PodFavoritesMovieOperations {
  final PodFavoritesStreamManager _streamManager;
  final PodFavoritesFileManager _fileManager;
  final MovieListService _movieListService;
  final Map<int, Movie> _movieCache;
  final Set<int> _moviesWithFiles;
  final Future<Object?> Function({
    bool checkContext,
    required Future<Object?> Function() operation,
    required String operationName,
    bool requiresLogin,
  }) executePodOperation;
  final Function(String fileName, String content) safeWriteFile;

  PodFavoritesMovieOperations(
    this._streamManager,
    this._fileManager,
    this._movieListService,
    this._movieCache,
    this._moviesWithFiles,
    this.executePodOperation,
    this.safeWriteFile,
  );

  /// Adds a movie to the to-watch list.

  Future<void> addToWatchList(Movie movie) async {
    await _addToList(
      movie,
      'to_watch',
      'Movies to Watch',
      _streamManager.updateToWatch,
    );
  }

  /// Removes a movie from the to-watch list.

  Future<void> removeFromWatchList(int movieId) async {
    await _removeFromList(
      movieId,
      'to_watch',
      'Movies to Watch',
      _streamManager.updateToWatch,
    );
  }

  /// Adds a movie to the watched list.

  Future<void> addToWatchedList(Movie movie) async {
    await _addToList(
      movie,
      'watched',
      'Movies Watched',
      _streamManager.updateWatched,
    );
  }

  /// Removes a movie from the watched list.

  Future<void> removeFromWatchedList(int movieId) async {
    await _removeFromList(
      movieId,
      'watched',
      'Movies Watched',
      _streamManager.updateWatched,
    );
  }

  /// Gets a movie by ID from cache or delegates to file manager.

  Future<Movie?> getMovie(int movieId) async {
    return _movieCache[movieId] ?? await _fileManager.loadMovieData(movieId);
  }

  /// Checks if a movie is in the to-watch list.

  bool isInToWatchList(int movieId) {
    return _streamManager.toWatch.any((movie) => movie.id == movieId);
  }

  /// Checks if a movie is in the watched list.

  bool isInWatchedList(int movieId) {
    return _streamManager.watched.any((movie) => movie.id == movieId);
  }

  /// Adds a movie to to-watch list with content type support.

  Future<void> addToWatch(Movie movie, {String contentType = 'movie'}) async {
    await addToWatchList(movie);
  }

  /// Adds a movie to watched list with content type support.

  Future<void> addToWatched(Movie movie, {String contentType = 'movie'}) async {
    await addToWatchedList(movie);
  }

  /// Removes a movie from to-watch list.

  Future<void> removeFromToWatch(Movie movie) async {
    await removeFromWatchList(movie.id);
  }

  /// Removes a movie from watched list.

  Future<void> removeFromWatched(Movie movie) async {
    await removeFromWatchedList(movie.id);
  }

  /// Checks if a movie is in to-watch list.

  Future<bool> isInToWatch(Movie movie) async {
    return isInToWatchList(movie.id);
  }

  /// Checks if a movie is in watched list.

  Future<bool> isInWatched(Movie movie) async {
    return isInWatchedList(movie.id);
  }

  /// Gets personal rating for a movie.

  Future<double?> getPersonalRating(Movie movie) async {
    final userData = await _fileManager.readMovieFile(movie);
    return userData?['rating'] as double?;
  }

  /// Sets personal rating for a movie.

  Future<void> setPersonalRating(Movie movie, double rating) async {
    final updatedMovie = Movie(
      id: movie.id,
      title: movie.title,
      overview: movie.overview,
      posterUrl: movie.posterUrl,
      backdropUrl: movie.backdropUrl,
      releaseDate: movie.releaseDate,
      voteAverage: movie.voteAverage,
      genreIds: movie.genreIds,
      contentType: movie.contentType,
    );
    await _fileManager.createOrUpdateMovieFile(updatedMovie, rating: rating);
  }

  /// Removes personal rating for a movie.

  Future<void> removePersonalRating(Movie movie) async {
    final updatedMovie = Movie(
      id: movie.id,
      title: movie.title,
      overview: movie.overview,
      posterUrl: movie.posterUrl,
      backdropUrl: movie.backdropUrl,
      releaseDate: movie.releaseDate,
      voteAverage: movie.voteAverage,
      genreIds: movie.genreIds,
      contentType: movie.contentType,
    );
    await _fileManager.createOrUpdateMovieFile(updatedMovie);
  }

  /// Gets personal comments for a movie.

  Future<String?> getMovieComments(Movie movie) async {
    final userData = await _fileManager.readMovieFile(movie);
    return userData?['comment'] as String?;
  }

  /// Sets personal comments for a movie.

  Future<void> setMovieComments(Movie movie, String comments) async {
    final updatedMovie = Movie(
      id: movie.id,
      title: movie.title,
      overview: movie.overview,
      posterUrl: movie.posterUrl,
      backdropUrl: movie.backdropUrl,
      releaseDate: movie.releaseDate,
      voteAverage: movie.voteAverage,
      genreIds: movie.genreIds,
      contentType: movie.contentType,
    );
    await _fileManager.createOrUpdateMovieFile(updatedMovie, comment: comments);
  }

  /// Removes personal comments for a movie.

  Future<void> removeMovieComments(Movie movie) async {
    final updatedMovie = Movie(
      id: movie.id,
      title: movie.title,
      overview: movie.overview,
      posterUrl: movie.posterUrl,
      backdropUrl: movie.backdropUrl,
      releaseDate: movie.releaseDate,
      voteAverage: movie.voteAverage,
      genreIds: movie.genreIds,
      contentType: movie.contentType,
    );
    await _fileManager.createOrUpdateMovieFile(updatedMovie);
  }

  /// Helper method for adding movies to lists.

  Future<void> _addToList(
    Movie movie,
    String listType,
    String displayName,
    Function(List<Movie>) updateStream,
  ) async {
    await executePodOperation(
      operation: () async {
        final listId =
            await _movieListService.initializeMovieList(listType, displayName);
        if (listId != null) {
          await _movieListService.addMovieToList(
            listId,
            movie,
            contentType:
                movie.contentType == ContentType.tvShow ? 'tvShow' : 'movie',
          );

          await _fileManager.createOrUpdateMovieFile(movie);

          _movieCache[movie.id] = movie;
          _moviesWithFiles.add(movie.id);

          final currentList = List<Movie>.from(
            listType == 'to_watch'
                ? _streamManager.toWatch
                : _streamManager.watched,
          );
          if (!currentList.any((m) => m.id == movie.id)) {
            currentList.add(movie);
            updateStream(currentList);
          } else {}

          // Update the TTL file to persist the change.

          await _writeTtlFile(listType, currentList);
        } else {}
        return null;
      },
      operationName: 'addToList($listType)',
    );
  }

  /// Helper method for removing movies from lists.

  Future<void> _removeFromList(
    int movieId,
    String listType,
    String displayName,
    Function(List<Movie>) updateStream,
  ) async {
    await executePodOperation(
      operation: () async {
        final listId =
            await _movieListService.initializeMovieList(listType, displayName);
        if (listId != null) {
          await _movieListService.removeMovieFromList(listId, movieId);

          final currentList = List<Movie>.from(
            listType == 'to_watch'
                ? _streamManager.toWatch
                : _streamManager.watched,
          );
          currentList.removeWhere((m) => m.id == movieId);
          updateStream(currentList);

          _movieCache.remove(movieId);
          _moviesWithFiles.remove(movieId);

          // Update the TTL file to persist the change.

          await _writeTtlFile(listType, currentList);
        }
        return null;
      },
      operationName: 'removeFromList($listType)',
    );
  }

  /// Writes a movie list to the appropriate TTL file.

  Future<void> _writeTtlFile(String listType, List<Movie> movies) async {
    try {
      final displayName =
          listType == 'to_watch' ? 'Movies to Watch' : 'Movies Watched';
      final fileName = 'moviestar/data/user_lists/$listType.ttl';

      // Generate TTL content using TurtleSerializer.

      final movieListId =
          await _movieListService.initializeMovieList(listType, displayName) ??
              'default';
      final ttlContent = TurtleSerializer.createMovieList(
        movieListId,
        displayName,
        description: 'User $displayName list',
        movies: movies,
      );

      // Write to POD.

      await safeWriteFile(fileName, ttlContent);
      // File operation completed.
    } catch (e) {
      // Error writing TTL file.
    }
  }
}
