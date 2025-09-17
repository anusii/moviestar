/// Cache management for POD favorites service.
/// Handles movie caching and file tracking operations.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'package:flutter/foundation.dart';

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/core/services/pod/pod_favorites_stream_manager.dart';
import 'package:moviestar/core/services/pod/pod_favorites_file_manager.dart';

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
    final stats = getCacheStats();
    debugPrint('🎬 [PodFavoritesCacheManager] Cache stats: $stats');
  }
}