/// Cached service for managing movies in the Movie Star application.
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

import 'package:moviestar/database/movie_cache_repository.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/movie_service.dart';

/// A cached service that wraps MovieService with local caching capabilities.

class CachedMovieService {
  /// The underlying movie service for API calls.

  final MovieService _movieService;

  /// Repository for managing cached movie data.

  final MovieCacheRepository _cacheRepository;

  /// Whether caching is enabled.

  bool _cachingEnabled;

  /// Whether to use offline mode (no network calls).

  bool _cacheOnlyMode;

  /// Creates a new CachedMovieService instance.

  CachedMovieService(
    this._movieService,
    this._cacheRepository, {
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
    developer.log(
      'Getting movies for ${category.value} - cachingEnabled: $_cachingEnabled, cacheOnlyMode: $_cacheOnlyMode',
      name: 'CachedMovieService',
    );

    if (!_cachingEnabled) {
      // Caching disabled, go straight to network.

      developer.log(
        'Caching disabled for ${category.value}, going to network',
        name: 'CachedMovieService',
      );

      if (_cacheOnlyMode) {
        // This shouldn't happen with the new UI logic, but handle it gracefully.

        developer.log(
          'Invalid state: Offline mode enabled but caching is disabled for ${category.value}',
          name: 'CachedMovieService',
          level: 1000,
        );
        throw Exception(
          'Cannot use offline mode when caching is disabled. Please enable caching first or disable offline mode.',
        );
      }

      try {
        final movies = await networkCall();
        developer.log(
          'Network call successful for ${category.value}: ${movies.length} movies',
          name: 'CachedMovieService',
        );
        return CacheResult(data: movies, fromCache: false);
      } catch (e) {
        developer.log(
          'Network call failed for ${category.value} with caching disabled: $e',
          name: 'CachedMovieService',
          level: 1000,
        );

        rethrow;
      }
    }

    // Try cache first.

    final cacheResult = await _cacheRepository.getMoviesWithCacheInfo(category);
    if (cacheResult != null) {
      developer.log(
        'Cache hit for ${category.value} (${cacheResult.data.length} movies, '
        'age: ${cacheResult.cacheAge?.inMinutes ?? 0}min)',
        name: 'CachedMovieService',
      );
      return cacheResult;
    }

    // Cache miss or invalid - check if we're in offline mode.

    if (_cacheOnlyMode) {
      developer.log(
        'Cache miss for ${category.value} in offline mode, checking for stale cache',
        name: 'CachedMovieService',
      );

      // Try to return stale cache if available.

      final staleMovies = await _cacheRepository.getStaleMovies(category);
      if (staleMovies != null && staleMovies.isNotEmpty) {
        developer.log(
          'Returning stale cache for ${category.value} in offline mode (${staleMovies.length} movies)',
          name: 'CachedMovieService',
        );
        return CacheResult(data: staleMovies, fromCache: true);
      }

      // No cache data available at all.

      developer.log(
        'No cache data available for ${category.value} in offline mode',
        name: 'CachedMovieService',
        level: 1000,
      );
      throw Exception(
        'No cached ${_getCategoryDisplayName(category)} available. Try refreshing data or disable offline mode to fetch from network.',
      );
    }

    // Fallback to network.

    try {
      developer.log(
        'Cache miss for ${category.value}, fetching from network',
        name: 'CachedMovieService',
      );

      final movies = await networkCall();

      // Cache the results.

      await _cacheRepository.cacheMovies(category, movies);

      developer.log(
        'Cached ${movies.length} movies for ${category.value}',
        name: 'CachedMovieService',
      );

      return CacheResult(data: movies, fromCache: false);
    } catch (e) {
      developer.log(
        'Network call failed for ${category.value}: $e',
        name: 'CachedMovieService',
        level: 1000,
      );

      // Try to return stale cache as fallback (ignoring TTL).

      final staleMovies = await _cacheRepository.getStaleMovies(category);

      if (staleMovies != null && staleMovies.isNotEmpty) {
        developer.log(
          'Returning stale cache for ${category.value} (${staleMovies.length} movies)',
          name: 'CachedMovieService',
        );
        return CacheResult(data: staleMovies, fromCache: true);
      }

      // No cache available, rethrow the error.

      rethrow;
    }
  }

  /// Gets a list of popular movies (with caching).

  Future<List<Movie>> getPopularMovies() async {
    final result = await _getMoviesWithCache(
      CacheCategory.popular,
      () => _movieService.getPopularMovies(),
    );
    return result.data;
  }

  /// Gets a list of movies currently playing in theaters (with caching).

  Future<List<Movie>> getNowPlayingMovies() async {
    final result = await _getMoviesWithCache(
      CacheCategory.nowPlaying,
      () => _movieService.getNowPlayingMovies(),
    );
    return result.data;
  }

  /// Gets a list of top rated movies (with caching).

  Future<List<Movie>> getTopRatedMovies() async {
    final result = await _getMoviesWithCache(
      CacheCategory.topRated,
      () => _movieService.getTopRatedMovies(),
    );
    return result.data;
  }

  /// Gets a list of upcoming movies (with caching).

  Future<List<Movie>> getUpcomingMovies() async {
    final result = await _getMoviesWithCache(
      CacheCategory.upcoming,
      () => _movieService.getUpcomingMovies(),
    );
    return result.data;
  }

  /// Gets popular movies with cache information.

  Future<CacheResult<List<Movie>>> getPopularMoviesWithCacheInfo() async {
    return await _getMoviesWithCache(
      CacheCategory.popular,
      () => _movieService.getPopularMovies(),
    );
  }

  /// Gets now playing movies with cache information.

  Future<CacheResult<List<Movie>>> getNowPlayingMoviesWithCacheInfo() async {
    return await _getMoviesWithCache(
      CacheCategory.nowPlaying,
      () => _movieService.getNowPlayingMovies(),
    );
  }

  /// Gets top rated movies with cache information.

  Future<CacheResult<List<Movie>>> getTopRatedMoviesWithCacheInfo() async {
    return await _getMoviesWithCache(
      CacheCategory.topRated,
      () => _movieService.getTopRatedMovies(),
    );
  }

  /// Gets upcoming movies with cache information.

  Future<CacheResult<List<Movie>>> getUpcomingMoviesWithCacheInfo() async {
    return await _getMoviesWithCache(
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

    // Invalidate existing cache.

    await _cacheRepository.invalidateCache(category);

    // Fetch fresh data.

    final List<Movie> movies;
    switch (category) {
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

    await _cacheRepository.cacheMovies(category, movies);

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

  /// Gets cache statistics for all categories.

  Future<Map<CacheCategory, CacheStats>> getCacheStats() async {
    return await _cacheRepository.getAllCacheStats();
  }

  /// Gets cache statistics for a specific category.

  Future<CacheStats?> getCacheStatsForCategory(CacheCategory category) async {
    return await _cacheRepository.getCacheStats(category);
  }

  /// Clears cache for a specific category.

  Future<void> clearCache(CacheCategory category) async {
    developer.log(
      'Clearing cache for ${category.value}',
      name: 'CachedMovieService',
    );
    await _cacheRepository.invalidateCache(category);
  }

  /// Clears all cached data.

  Future<void> clearAllCache() async {
    developer.log('Clearing all cached data', name: 'CachedMovieService');
    await _cacheRepository.invalidateAllCache();
  }

  /// Updates cache configuration.

  void updateCacheConfig(Map<CacheCategory, Duration> ttls) {
    _cacheRepository.updateCacheConfig(ttls);
    developer.log('Cache configuration updated', name: 'CachedMovieService');
  }

  /// Resets cache configuration to defaults.

  void resetCacheConfig() {
    _cacheRepository.resetCacheConfig();
    developer.log(
      'Cache configuration reset to defaults',
      name: 'CachedMovieService',
    );
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
