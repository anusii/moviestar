/// Hive-based cached service for managing movies in the Movie Star application.
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
/// Authors: Ashley Tang

library;

import 'dart:developer' as developer;

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/hive_movie_cache_service.dart';
import 'package:moviestar/services/movie_service.dart';

/// A cached service that wraps MovieService with Hive caching capabilities.

class HiveCachedMovieService {
  /// The underlying movie service for API calls.

  final MovieService _movieService;

  /// Service for managing cached movie data.

  final HiveMovieCacheService _cacheService;

  /// Whether caching is enabled.

  bool _cachingEnabled;

  /// Whether to use offline mode (no network calls).

  bool _cacheOnlyMode;

  /// Creates a new HiveCachedMovieService instance.

  HiveCachedMovieService(
    this._movieService,
    this._cacheService, {
    bool cachingEnabled = true,
    bool cacheOnlyMode = false,
  })  : _cachingEnabled = cachingEnabled,
        _cacheOnlyMode = cacheOnlyMode;

  /// Enables or disables caching.

  void setCachingEnabled(bool enabled) {
    _cachingEnabled = enabled;
    developer.log(
      'Caching ${enabled ? 'enabled' : 'disabled'}',
      name: 'HiveCachedMovieService',
    );
  }

  /// Enables or disables offline mode.

  void setCacheOnlyMode(bool cacheOnly) {
    _cacheOnlyMode = cacheOnly;
    developer.log(
      'Offline mode ${cacheOnly ? 'enabled' : 'disabled'}',
      name: 'HiveCachedMovieService',
    );
  }

  /// Gets movies with caching strategy.

  Future<CacheResult<List<Movie>>> _getMoviesWithCache(
    CacheCategory category,
    Future<List<Movie>> Function() networkCall,
  ) async {
    developer.log(
      'Getting movies for ${category.value} - cachingEnabled: $_cachingEnabled, cacheOnlyMode: $_cacheOnlyMode',
      name: 'HiveCachedMovieService',
    );

    // If offline mode is enabled, try cache first.

    if (_cacheOnlyMode) {
      final staleMovies = await _cacheService.getStaleMovies(category);
      if (staleMovies != null && staleMovies.isNotEmpty) {
        developer.log(
          'Offline mode: Using stale cache for ${category.value} (${staleMovies.length} movies)',
          name: 'HiveCachedMovieService',
        );
        return CacheResult(data: staleMovies, fromCache: true);
      } else {
        developer.log(
          'Offline mode: No cached data available for ${category.value}',
          name: 'HiveCachedMovieService',
        );
        return CacheResult(data: <Movie>[], fromCache: true);
      }
    }

    // If caching is disabled, make network call only.

    if (!_cachingEnabled) {
      developer.log(
        'Caching disabled: Making network call for ${category.value}',
        name: 'HiveCachedMovieService',
      );
      try {
        final movies = await networkCall();
        return CacheResult(data: movies, fromCache: false);
      } catch (e) {
        developer.log(
          'Network call failed for ${category.value}: $e',
          name: 'HiveCachedMovieService',
        );
        rethrow;
      }
    }

    // Check if we have valid cached data.

    final isValid = await _cacheService.isCacheValid(category);
    if (isValid) {
      final cacheResult = await _cacheService.getMoviesWithCacheInfo(category);
      if (cacheResult != null) {
        developer.log(
          'Cache hit for ${category.value} (${cacheResult.data.length} movies, '
          'age: ${cacheResult.cacheAge?.inMinutes ?? 0}min)',
          name: 'HiveCachedMovieService',
        );
        return cacheResult;
      }
    }

    // Try network call with cache fallback.

    try {
      developer.log(
        'Making network call for ${category.value}',
        name: 'HiveCachedMovieService',
      );
      final movies = await networkCall();

      // Cache the fresh data.

      await _cacheService.cacheMoviesForCategory(category, movies);

      developer.log(
        'Network success: Cached ${movies.length} movies for ${category.value}',
        name: 'HiveCachedMovieService',
      );

      return CacheResult(data: movies, fromCache: false);
    } catch (e) {
      developer.log(
        'Network call failed for ${category.value}: $e',
        name: 'HiveCachedMovieService',
      );

      // Fallback to stale cache if available.

      final staleMovies = await _cacheService.getStaleMovies(category);
      if (staleMovies != null && staleMovies.isNotEmpty) {
        developer.log(
          'Network failed: Using stale cache for ${category.value} (${staleMovies.length} movies)',
          name: 'HiveCachedMovieService',
        );
        return CacheResult(data: staleMovies, fromCache: true);
      }

      // No cache available, rethrow the network error.

      rethrow;
    }
  }

  /// Get popular movies with caching.

  Future<List<Movie>> getPopularMovies() async {
    final result = await _getMoviesWithCache(
      CacheCategory.popular,
      () => _movieService.getPopularMovies(),
    );
    return result.data;
  }

  /// Get now playing movies with caching.

  Future<List<Movie>> getNowPlayingMovies() async {
    final result = await _getMoviesWithCache(
      CacheCategory.nowPlaying,
      () => _movieService.getNowPlayingMovies(),
    );
    return result.data;
  }

  /// Get top rated movies with caching.

  Future<List<Movie>> getTopRatedMovies() async {
    final result = await _getMoviesWithCache(
      CacheCategory.topRated,
      () => _movieService.getTopRatedMovies(),
    );
    return result.data;
  }

  /// Get upcoming movies with caching.

  Future<List<Movie>> getUpcomingMovies() async {
    final result = await _getMoviesWithCache(
      CacheCategory.upcoming,
      () => _movieService.getUpcomingMovies(),
    );
    return result.data;
  }

  /// Get popular movies with cache information.

  Future<CacheResult<List<Movie>>> getPopularMoviesWithCacheInfo() async {
    return _getMoviesWithCache(
      CacheCategory.popular,
      () => _movieService.getPopularMovies(),
    );
  }

  /// Get now playing movies with cache information.

  Future<CacheResult<List<Movie>>> getNowPlayingMoviesWithCacheInfo() async {
    return _getMoviesWithCache(
      CacheCategory.nowPlaying,
      () => _movieService.getNowPlayingMovies(),
    );
  }

  /// Get top rated movies with cache information.

  Future<CacheResult<List<Movie>>> getTopRatedMoviesWithCacheInfo() async {
    return _getMoviesWithCache(
      CacheCategory.topRated,
      () => _movieService.getTopRatedMovies(),
    );
  }

  /// Get upcoming movies with cache information.

  Future<CacheResult<List<Movie>>> getUpcomingMoviesWithCacheInfo() async {
    return _getMoviesWithCache(
      CacheCategory.upcoming,
      () => _movieService.getUpcomingMovies(),
    );
  }

  /// Clear cache for all categories.

  Future<void> clearAllCache() async {
    await _cacheService.clearAllCache();
    developer.log('Cleared all cache', name: 'HiveCachedMovieService');
  }

  /// Clear cache for a specific category.

  Future<void> clearCacheForCategory(CacheCategory category) async {
    await _cacheService.clearCacheForCategory(category);
    developer.log(
      'Cleared cache for ${category.value}',
      name: 'HiveCachedMovieService',
    );
  }

  /// Get cache metadata for a category.

  Future<Map<String, dynamic>?> getCacheMetadata(CacheCategory category) async {
    return await _cacheService.getCacheMetadata(category);
  }
}
