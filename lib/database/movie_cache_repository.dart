/// Path constants for the movie star application.
///
// Time-stamp: <Friday 2025-02-21 17:02:01 +1100 Graham Williams>
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
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

import 'package:moviestar/database/app_database.dart';
import 'package:moviestar/models/movie.dart';

/// Categories available for movie caching.

enum CacheCategory {
  /// To watch movies.

  toWatch('to_watch'),

  /// Watched movies.

  watched('watched'),

  /// Popular movies from TMDB.

  popular('popular'),

  /// Movies currently playing in theaters.

  nowPlaying('now_playing'),

  /// Top rated movies.

  topRated('top_rated'),

  /// Upcoming movies.

  upcoming('upcoming');

  const CacheCategory(this.value);

  /// String value of the category.

  final String value;
}

/// Configuration for cache behavior.

class CacheConfig {
  /// Default time-to-live (TTL) for cached data (1 hour).

  static const Duration defaultTtl = Duration(hours: 1);

  /// Time-to-live (TTL) for popular movies (30 minutes).

  static const Duration popularTtl = Duration(minutes: 30);

  /// Time-to-live (TTL) for now playing movies (15 minutes).

  static const Duration nowPlayingTtl = Duration(minutes: 15);

  /// Time-to-live (TTL) for top rated movies (2 hours).

  static const Duration topRatedTtl = Duration(hours: 2);

  /// Time-to-live (TTL) for upcoming movies (6 hours).

  static const Duration upcomingTtl = Duration(hours: 6);

  /// Gets the time-to-live (TTL) for a specific category.

  static Duration getTtlForCategory(CacheCategory category) {
    switch (category) {
      case CacheCategory.toWatch:
        return popularTtl;
      case CacheCategory.watched:
        return popularTtl;
      case CacheCategory.popular:
        return popularTtl;
      case CacheCategory.nowPlaying:
        return nowPlayingTtl;
      case CacheCategory.topRated:
        return topRatedTtl;
      case CacheCategory.upcoming:
        return upcomingTtl;
    }
  }
}

/// Result of a cache operation.

class CacheResult<T> {
  /// The data retrieved from cache or API.

  final T data;

  /// Whether the data came from cache.

  final bool fromCache;

  /// Age of the cached data (null if from API).

  final Duration? cacheAge;

  /// Timestamp when the data was cached (null if from API).

  final DateTime? cachedAt;

  const CacheResult({
    required this.data,
    required this.fromCache,
    this.cacheAge,
    this.cachedAt,
  });
}

/// Repository for managing cached movie data.

class MovieCacheRepository {
  /// Database instance for accessing cached data.

  final AppDatabase _database;

  /// Cache configuration.

  final Map<CacheCategory, Duration> _customTtls = {};

  /// Creates a new MovieCacheRepository.

  MovieCacheRepository(this._database);

  /// Sets custom time-to-live (TTL) for a specific category.

  void setCustomTtl(CacheCategory category, Duration ttl) {
    _customTtls[category] = ttl;
  }

  /// Gets the time-to-live (TTL) for a category (custom or default).

  Duration _getTtl(CacheCategory category) {
    return _customTtls[category] ?? CacheConfig.getTtlForCategory(category);
  }

  /// Checks if cached data for a category is still valid.

  Future<bool> isCacheValid(CacheCategory category) async {
    final ttl = _getTtl(category);
    return await _database.isCacheValid(category.value, ttl);
  }

  /// Gets cached movies for a category.
  /// Returns null if cache is invalid or empty.

  Future<List<Movie>?> getCachedMovies(CacheCategory category) async {
    final isValid = await isCacheValid(category);
    if (!isValid) return null;

    final movies = await _database.getCachedMoviesForCategory(category.value);
    return movies.isEmpty ? null : movies;
  }

  /// Gets cached movies regardless of TTL (for stale cache fallback).
  /// Returns null if no movies are cached.

  Future<List<Movie>?> getStaleMovies(CacheCategory category) async {
    final movies = await _database.getCachedMoviesForCategory(category.value);
    return movies.isEmpty ? null : movies;
  }

  /// Caches movies for a specific category.

  Future<void> cacheMovies(CacheCategory category, List<Movie> movies) async {
    await _database.cacheMoviesForCategory(category.value, movies);
  }

  /// Gets movies with cache information.
  /// If cache is valid, returns cached data. Otherwise returns null.

  Future<CacheResult<List<Movie>>?> getMoviesWithCacheInfo(
    CacheCategory category,
  ) async {
    final metadata = await _database.getCacheMetadata(category.value);
    final isValid = await isCacheValid(category);

    if (!isValid || metadata == null) return null;

    final movies = await _database.getCachedMoviesForCategory(category.value);
    if (movies.isEmpty) return null;

    final cacheAge = DateTime.now().difference(metadata.lastUpdated);

    return CacheResult(
      data: movies,
      fromCache: true,
      cacheAge: cacheAge,
      cachedAt: metadata.lastUpdated,
    );
  }

  /// Invalidates cache for a specific category.

  Future<void> invalidateCache(CacheCategory category) async {
    await _database.clearCacheForCategory(category.value);
  }

  /// Invalidates all cached data.

  Future<void> invalidateAllCache() async {
    await _database.clearAllCache();
  }

  /// Gets cache statistics for a category.

  Future<CacheStats?> getCacheStats(CacheCategory category) async {
    final metadata = await _database.getCacheMetadata(category.value);
    if (metadata == null) return null;

    final age = DateTime.now().difference(metadata.lastUpdated);
    final ttl = _getTtl(category);
    final isValid = age <= ttl;

    return CacheStats(
      category: category,
      movieCount: metadata.movieCount,
      lastUpdated: metadata.lastUpdated,
      age: age,
      ttl: ttl,
      isValid: isValid,
    );
  }

  /// Gets cache statistics for all categories.

  Future<Map<CacheCategory, CacheStats>> getAllCacheStats() async {
    final stats = <CacheCategory, CacheStats>{};

    for (final category in CacheCategory.values) {
      final categoryStats = await getCacheStats(category);
      if (categoryStats != null) {
        stats[category] = categoryStats;
      }
    }

    return stats;
  }

  /// Preloads cache validity for multiple categories.
  /// Useful for optimizing multiple cache checks.

  Future<Map<CacheCategory, bool>> getCacheValidityMap(
    List<CacheCategory> categories,
  ) async {
    final validityMap = <CacheCategory, bool>{};

    for (final category in categories) {
      validityMap[category] = await isCacheValid(category);
    }

    return validityMap;
  }

  /// Updates cache configuration for multiple categories.

  void updateCacheConfig(Map<CacheCategory, Duration> ttls) {
    _customTtls.clear();
    _customTtls.addAll(ttls);
  }

  /// Resets cache configuration to defaults.

  void resetCacheConfig() {
    _customTtls.clear();
  }
}

/// Statistics about cached data for a category.

class CacheStats {
  /// The movie category.

  final CacheCategory category;

  /// Number of movies in cache.

  final int movieCount;

  /// When the cache was last updated.

  final DateTime lastUpdated;

  /// Age of the cached data.

  final Duration age;

  /// Time-to-live (TTL) for this category.

  final Duration ttl;

  /// Whether the cache is still valid.

  final bool isValid;

  const CacheStats({
    required this.category,
    required this.movieCount,
    required this.lastUpdated,
    required this.age,
    required this.ttl,
    required this.isValid,
  });

  /// Time remaining before cache expires (null if already expired).

  Duration? get timeRemaining {
    if (!isValid) return null;
    return ttl - age;
  }

  /// Cache hit ratio as a percentage (0-100).

  double get freshness {
    final ratio =
        (ttl.inMilliseconds - age.inMilliseconds) / ttl.inMilliseconds;
    return (ratio * 100).clamp(0.0, 100.0);
  }
}
