/// Cache management for POD favorites service.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Ashley Tang, Kevin Wang

library;

import 'package:moviestar/core/services/pod/favorites_file_manager.dart';
import 'package:moviestar/core/services/pod/favorites_stream_manager.dart';
import 'package:moviestar/models/movie.dart';

/// Handles caching operations for POD favorites service.

class PodFavoritesCacheManager {
  final Map<int, Movie> _movieCache;
  final Set<int> _moviesWithFiles;
  final PodFavoritesStreamManager _streamManager;
  final PodFavoritesFileManager _fileManager;

  PodFavoritesCacheManager(
    this._movieCache,
    this._moviesWithFiles,
    this._streamManager,
    this._fileManager,
  );

  /// Clears all caches.

  void clearCache() {
    _movieCache.clear();
    _moviesWithFiles.clear();
    _streamManager.clearAll();
  }

  /// Gets a cached movie by ID.

  Movie? getCachedMovie(int movieId) {
    return _movieCache[movieId];
  }

  /// Caches a movie.

  void cacheMovie(Movie movie) {
    _movieCache[movie.id] = movie;
  }

  /// Removes a movie from cache.

  void removeCachedMovie(int movieId) {
    _movieCache.remove(movieId);
  }

  /// Checks if a movie is cached.

  bool isMovieCached(int movieId) {
    return _movieCache.containsKey(movieId);
  }

  /// Marks a movie as having a file.

  void markMovieWithFile(int movieId) {
    _moviesWithFiles.add(movieId);
  }

  /// Removes movie file tracking.

  void removeMovieFileTracking(int movieId) {
    _moviesWithFiles.remove(movieId);
  }

  /// Checks if a movie has a file tracked.

  bool isMovieFileTracked(int movieId) {
    return _moviesWithFiles.contains(movieId);
  }

  /// Checks if a movie file exists.

  Future<bool> hasMovieFile(Movie movie) async {
    return _fileManager.hasMovieFile(movie);
  }

  /// Gets the file path for a movie file.

  String? getMovieFilePath(Movie movie) {
    return _fileManager.getMovieFilePathByMovie(movie);
  }

  /// Gets cache statistics for debugging.

  Map<String, dynamic> getCacheStats() {
    return {
      'cachedMovies': _movieCache.length,
      'trackedFiles': _moviesWithFiles.length,
      'toWatchCount': _streamManager.toWatch.length,
      'watchedCount': _streamManager.watched.length,
      'customListsCount': _streamManager.customLists.length,
    };
  }

  /// Logs cache statistics.

  void logCacheStats() {
    getCacheStats();
  }
}
