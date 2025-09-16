/// Hive-based cached service for managing movies.
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
import 'package:moviestar/core/services/cache/hive_movie_cache_service.dart';
import 'package:moviestar/core/services/api/movie_service.dart';

/// A cached service that wraps MovieService with Hive caching capabilities.

class CachedMovieService {
  /// The underlying movie service for API calls.
  final MovieService _movieService;

  /// Service for managing cached movie data.

  final HiveMovieCacheService _cacheService;

  /// Whether caching is enabled.
  bool _cachingEnabled;

  /// Whether to use offline mode (no network calls).

  bool _cacheOnlyMode;

  /// Creates a new CachedMovieService instance.

  CachedMovieService(
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
      name: 'CachedMovieService',
    );
  }

  /// Enables or disables offline mode.

  void setCacheOnlyMode(bool cacheOnly) {
    _cacheOnlyMode = cacheOnly;
    developer.log(
      'Offline mode ${cacheOnly ? 'enabled' : 'disabled'}',
      name: 'CachedMovieService',
    );
  }

  /// Gets movies with caching strategy.

  Future<CacheResult<List<Movie>>> _getMoviesWithCache(
    CacheCategory category,
    Future<List<Movie>> Function() networkCall,
  ) async {
    // Prevent user data categories from being cached here.

    if (category == CacheCategory.toWatch ||
        category == CacheCategory.watched) {
      throw UnsupportedError(
        '${category.value} movies are user data and should not be cached via CachedMovieService. '
        'Use FavoritesService instead.',
      );
    }

    developer.log(
      'Getting movies for ${category.value} - cachingEnabled: $_cachingEnabled, cacheOnlyMode: $_cacheOnlyMode',
      name: 'CachedMovieService',
    );

    // If offline mode is enabled, try cache first.

    if (_cacheOnlyMode) {
      final staleMovies = await _cacheService.getStaleMovies(category);
      if (staleMovies != null && staleMovies.isNotEmpty) {
        developer.log(
          'Offline mode: Using stale cache for ${category.value} (${staleMovies.length} movies)',
          name: 'CachedMovieService',
        );
        return CacheResult(data: staleMovies, fromCache: true);
      } else {
        developer.log(
          'Offline mode: No cached data available for ${category.value}',
          name: 'CachedMovieService',
          level: 1000,
        );
        throw Exception(
          'No cached ${_getCategoryDisplayName(category)} available. Try refreshing data or disable offline mode to fetch from network.',
        );
      }
    }

    // If caching is disabled, make network call only.

    if (!_cachingEnabled) {
      developer.log(
        'Caching disabled: Making network call for ${category.value}',
        name: 'CachedMovieService',
      );
      try {
        final movies = await networkCall();
        return CacheResult(data: movies, fromCache: false);
      } catch (e) {
        developer.log(
          'Network call failed for ${category.value}: $e',
          name: 'CachedMovieService',
          level: 1000,
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
          name: 'CachedMovieService',
        );
        return cacheResult;
      }
    }

    // Try network call with cache fallback.

    try {
      developer.log(
        'Making network call for ${category.value}',
        name: 'CachedMovieService',
      );
      final movies = await networkCall();

      // Cache the fresh data.

      await _cacheService.cacheMoviesForCategory(category, movies);

      developer.log(
        'Network success: Cached ${movies.length} movies for ${category.value}',
        name: 'CachedMovieService',
      );

      return CacheResult(data: movies, fromCache: false);
    } catch (e) {
      developer.log(
        'Network call failed for ${category.value}: $e',
        name: 'CachedMovieService',
        level: 1000,
      );

      // Fallback to stale cache if available.

      final staleMovies = await _cacheService.getStaleMovies(category);
      if (staleMovies != null && staleMovies.isNotEmpty) {
        developer.log(
          'Network failed: Using stale cache for ${category.value} (${staleMovies.length} movies)',
          name: 'CachedMovieService',
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

  /// Searches for movies (no caching for search results).

  Future<List<Movie>> searchMovies(String query) async {
    developer.log(
      'Searching movies for: $query (no caching)',
      name: 'CachedMovieService',
    );
    return await _movieService.searchMovies(query);
  }

  /// Gets detailed information about a specific movie (no caching for details).

  Future<Movie> getMovieDetails(int movieId) async {
    developer.log(
      'Getting movie details for ID: $movieId (no caching)',
      name: 'CachedMovieService',
    );
    return await _movieService.getMovieDetails(movieId);
  }

  /// Forces refresh of cached data for a specific category.

  Future<List<Movie>> forceRefresh(CacheCategory category) async {
    developer.log(
      'Force refreshing cache for ${category.value}',
      name: 'CachedMovieService',
    );

    // Clear existing cache.

    await _cacheService.clearCacheForCategory(category);

    // Fetch fresh data.

    final List<Movie> movies;
    switch (category) {
      case CacheCategory.toWatch:
        throw UnsupportedError(
          'To Watch movies are user data and should not be cached via CachedMovieService. '
          'Use FavoritesService instead.',
        );
      case CacheCategory.watched:
        throw UnsupportedError(
          'Watched movies are user data and should not be cached via CachedMovieService. '
          'Use FavoritesService instead.',
        );
      case CacheCategory.popular:
        movies = await _movieService.getPopularMovies();
      case CacheCategory.nowPlaying:
        movies = await _movieService.getNowPlayingMovies();
      case CacheCategory.topRated:
        movies = await _movieService.getTopRatedMovies();
      case CacheCategory.upcoming:
        movies = await _movieService.getUpcomingMovies();
    }

    // Cache the fresh data.

    await _cacheService.cacheMoviesForCategory(category, movies);

    developer.log(
      'Force refreshed ${movies.length} movies for ${category.value}',
      name: 'CachedMovieService',
    );

    return movies;
  }

  /// Forces refresh for all movie categories.

  Future<Map<CacheCategory, List<Movie>>> forceRefreshAll() async {
    developer.log(
      'Force refreshing all movie categories',
      name: 'CachedMovieService',
    );

    final results = <CacheCategory, List<Movie>>{};

    for (final category in CacheCategory.values) {
      // Skip user data categories.

      if (category == CacheCategory.toWatch ||
          category == CacheCategory.watched) {
        continue;
      }

      try {
        results[category] = await forceRefresh(category);
      } catch (e) {
        developer.log(
          'Failed to refresh ${category.value}: $e',
          name: 'CachedMovieService',
          level: 1000,
        );
      }
    }

    return results;
  }

  /// Gets cache metadata for all categories.

  Future<Map<CacheCategory, Map<String, dynamic>>> getCacheStats() async {
    final stats = <CacheCategory, Map<String, dynamic>>{};

    for (final category in CacheCategory.values) {
      final metadata = await _cacheService.getCacheMetadata(category);
      if (metadata != null) {
        stats[category] = metadata;
      }
    }

    return stats;
  }

  /// Gets cache metadata for a specific category.

  Future<Map<String, dynamic>?> getCacheStatsForCategory(
    CacheCategory category,
  ) async {
    return await _cacheService.getCacheMetadata(category);
  }

  /// Clears cache for a specific category.

  Future<void> clearCache(CacheCategory category) async {
    developer.log(
      'Clearing cache for ${category.value}',
      name: 'CachedMovieService',
    );
    await _cacheService.clearCacheForCategory(category);
  }

  /// Clears all cached data.

  Future<void> clearAllCache() async {
    developer.log('Clearing all cached data', name: 'CachedMovieService');
    await _cacheService.clearAllCache();
  }

  /// Updates the API key in the underlying service.
  Future<void> updateApiKey() async {
    await _movieService.updateApiKey();
    developer.log(
      'API key updated in underlying service',
      name: 'CachedMovieService',
    );
  }

  /// Gets human-readable display name for cache category.

  String _getCategoryDisplayName(CacheCategory category) {
    switch (category) {
      case CacheCategory.toWatch:
        return 'To Watch';
      case CacheCategory.watched:
        return 'Watched';
      case CacheCategory.popular:
        return 'popular movies';
      case CacheCategory.nowPlaying:
        return 'now playing movies';
      case CacheCategory.topRated:
        return 'top rated movies';
      case CacheCategory.upcoming:
        return 'upcoming movies';
    }
  }

  /// Disposes the service and its resources.

  void dispose() {
    _movieService.dispose();
    developer.log('CachedMovieService disposed', name: 'CachedMovieService');
  }
}
