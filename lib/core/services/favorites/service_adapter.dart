/// Adapter to make FavoritesServiceManager compatible with existing screens.
/// Includes caching functionality for better performance.
///
// Time-stamp: <Thursday 2025-04-10 11:47:48 +1000 Graham Williams>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
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
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
/// Authors: Ashley Tang.

library;

import 'package:moviestar/constants/timing_constants.dart';
import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/core/services/favorites/favorites_service_manager.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';

/// Adapter that makes FavoritesServiceManager look like FavoritesService.
/// This allows us to integrate POD storage without changing all existing screens.
/// Includes caching functionality for better performance.

class FavoritesServiceAdapter extends FavoritesService {
  final FavoritesServiceManager _manager;

  /// Cache for to-watch movies.

  List<Movie>? _cachedToWatch;
  DateTime? _toWatchCacheTime;

  /// Cache for watched movies.

  List<Movie>? _cachedWatched;
  DateTime? _watchedCacheTime;

  /// TTL (time to live) for user data cache (5 minutes for frequent updates).

  static const Duration _userDataTtl = NetworkTimingConstants.userDataTtl;

  FavoritesServiceAdapter(this._manager) : super(_manager.prefs);

  @override
  Stream<List<Movie>> get toWatchMovies => _manager.toWatchMovies;

  @override
  Stream<List<Movie>> get watchedMovies => _manager.watchedMovies;

  @override
  Stream<List<CustomList>> get customLists => _manager.customLists;

  @override
  Future<List<Movie>> getToWatch() async {
    // Check if cache is valid.

    if (_cachedToWatch != null &&
        _toWatchCacheTime != null &&
        DateTime.now().difference(_toWatchCacheTime!) < _userDataTtl) {
      return List.from(_cachedToWatch!);
    }

    // Cache miss or expired - fetch from manager.

    final movies = await _manager.getToWatch();

    // Update cache.

    _cachedToWatch = List.from(movies);
    _toWatchCacheTime = DateTime.now();

    return movies;
  }

  @override
  Future<List<Movie>> getWatched() async {
    // Check if cache is valid.

    if (_cachedWatched != null &&
        _watchedCacheTime != null &&
        DateTime.now().difference(_watchedCacheTime!) < _userDataTtl) {
      return List.from(_cachedWatched!);
    }

    // Cache miss or expired - fetch from manager.

    final movies = await _manager.getWatched();

    // Update cache.

    _cachedWatched = List.from(movies);
    _watchedCacheTime = DateTime.now();

    return movies;
  }

  @override
  Future<void> addToWatch(Movie movie, {String contentType = 'movie'}) async {
    await _manager.addToWatch(movie, contentType: contentType);
    _invalidateToWatchCache();
  }

  @override
  Future<void> addToWatched(Movie movie, {String contentType = 'movie'}) async {
    await _manager.addToWatched(movie, contentType: contentType);
    _invalidateWatchedCache();
  }

  @override
  Future<void> removeFromToWatch(Movie movie) async {
    await _manager.removeFromToWatch(movie);
    _invalidateToWatchCache();
  }

  @override
  Future<void> removeFromWatched(Movie movie) async {
    await _manager.removeFromWatched(movie);
    _invalidateWatchedCache();
  }

  /// Invalidate to-watch cache to force refresh.

  void _invalidateToWatchCache() {
    _cachedToWatch = null;
    _toWatchCacheTime = null;
  }

  /// Invalidate watched cache to force refresh.

  void _invalidateWatchedCache() {
    _cachedWatched = null;
    _watchedCacheTime = null;
  }

  @override
  Future<bool> isInToWatch(Movie movie) => _manager.isInToWatch(movie);

  @override
  Future<bool> isInWatched(Movie movie) => _manager.isInWatched(movie);

  @override
  Future<double?> getPersonalRating(Movie movie) =>
      _manager.getPersonalRating(movie);

  @override
  Future<void> setPersonalRating(Movie movie, double rating) =>
      _manager.setPersonalRating(movie, rating);

  @override
  Future<void> removePersonalRating(Movie movie) =>
      _manager.removePersonalRating(movie);

  @override
  Future<String?> getMovieComments(Movie movie) =>
      _manager.getMovieComments(movie);

  @override
  Future<void> setMovieComments(Movie movie, String comments) =>
      _manager.setMovieComments(movie, comments);

  @override
  Future<void> removeMovieComments(Movie movie) =>
      _manager.removeMovieComments(movie);

  @override
  Future<bool> hasMovieFile(Movie movie) => _manager.hasMovieFile(movie);

  @override
  String? getMovieFilePath(Movie movie) => _manager.getMovieFilePath(movie);

  /// Get cache statistics for debugging.

  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    return {
      'toWatch': {
        'cached': _cachedToWatch != null,
        'count': _cachedToWatch?.length ?? 0,
        'age': _toWatchCacheTime != null
            ? now.difference(_toWatchCacheTime!).inMinutes
            : null,
        'valid': _cachedToWatch != null &&
            _toWatchCacheTime != null &&
            now.difference(_toWatchCacheTime!) < _userDataTtl,
      },
      'watched': {
        'cached': _cachedWatched != null,
        'count': _cachedWatched?.length ?? 0,
        'age': _watchedCacheTime != null
            ? now.difference(_watchedCacheTime!).inMinutes
            : null,
        'valid': _cachedWatched != null &&
            _watchedCacheTime != null &&
            now.difference(_watchedCacheTime!) < _userDataTtl,
      },
    };
  }

  /// Force refresh to-watch cache.

  Future<List<Movie>> forceRefreshToWatch() async {
    _invalidateToWatchCache();
    return getToWatch();
  }

  /// Force refresh watched cache.

  Future<List<Movie>> forceRefreshWatched() async {
    _invalidateWatchedCache();
    return getWatched();
  }

  /// Clear all caches.

  void clearAllCaches() {
    _invalidateToWatchCache();
    _invalidateWatchedCache();
  }

  /// Clear all caches (no stream controllers to dispose).

  void disposeCache() {
    clearAllCaches();
  }

  /// Checks if POD storage is currently enabled.

  bool get isPodStorageEnabled => _manager.isPodStorageEnabled;

  /// Custom Lists Methods - Delegate to manager.

  @override
  Future<List<CustomList>> getCustomLists() async {
    return _manager.getCustomLists();
  }

  @override
  Future<CustomList> createCustomList(
    String name, {
    String? description,
  }) async {
    return _manager.createCustomList(name, description: description);
  }

  @override
  Future<void> updateCustomList(CustomList updatedList) async {
    await _manager.updateCustomList(updatedList);
  }

  @override
  Future<void> deleteCustomList(String listId) async {
    await _manager.deleteCustomList(listId);
  }

  @override
  Future<void> addMovieToCustomList(
    String listId,
    Movie movie, {
    String contentType = 'movie',
  }) async {
    await _manager.addMovieToCustomList(
      listId,
      movie,
      contentType: contentType,
    );
  }

  @override
  Future<void> removeMovieFromCustomList(String listId, int movieId) async {
    await _manager.removeMovieFromCustomList(listId, movieId);
  }

  @override
  Future<bool> isMovieInCustomList(String listId, int movieId) async {
    return _manager.isMovieInCustomList(listId, movieId);
  }

  @override
  Future<List<CustomList>> getCustomListsContainingMovie(int movieId) async {
    return _manager.getCustomListsContainingMovie(movieId);
  }

  @override
  Future<List<Movie>> getMoviesInCustomList(String listId) async {
    return _manager.getMoviesInCustomList(listId);
  }

  @override
  Future<List<int>> getMovieIdsInCustomList(String listId) async {
    return _manager.getMovieIdsInCustomList(listId);
  }

  @override
  void dispose() {
    // Don't dispose the manager as other components may still be using it.

    super.dispose();
  }
}
