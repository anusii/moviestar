/// Hive-based movie cache service for the Movie Star application.
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

import 'package:flutter/material.dart';

import 'package:hive/hive.dart';

import 'package:moviestar/models/movie.dart';

/// Categories available for movie caching.

enum CacheCategory {
  /// Popular movies from TMDB.

  popular('popular'),

  /// Movies currently playing in theaters.

  nowPlaying('now_playing'),

  /// Top rated movies.

  topRated('top_rated'),

  /// Upcoming movies.

  upcoming('upcoming'),

  /// User's to-watch movies.

  toWatch('to_watch'),

  /// User's watched movies.

  watched('watched');

  const CacheCategory(this.value);

  /// String value of the category.

  final String value;
}

/// Cache configuration and TTL settings.

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
      case CacheCategory.popular:
        return popularTtl;
      case CacheCategory.nowPlaying:
        return nowPlayingTtl;
      case CacheCategory.topRated:
        return topRatedTtl;
      case CacheCategory.upcoming:
        return upcomingTtl;
      case CacheCategory.toWatch:
      case CacheCategory.watched:
        return defaultTtl;
    }
  }
}

/// Result of a cache operation with metadata.

class CacheResult<T> {
  /// The data retrieved from cache.

  final T data;

  /// Whether the data came from cache.

  final bool fromCache;

  /// Age of the cached data.

  final Duration? cacheAge;

  /// Timestamp when the data was cached.

  final DateTime? cachedAt;

  const CacheResult({
    required this.data,
    required this.fromCache,
    this.cacheAge,
    this.cachedAt,
  });
}

/// Hive-based movie cache service that replaces Drift database functionality.

class HiveMovieCacheService {
  /// Box for storing movie lists by category.

  Box<List<dynamic>>? _movieBox;

  /// Box for storing cache timestamps.

  Box<DateTime>? _timestampBox;

  /// Whether the service has been initialized.

  bool _isInitialized = false;

  /// Initialise the Hive service and open boxes.

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _movieBox = await Hive.openBox<List<dynamic>>('movies');
      _timestampBox = await Hive.openBox<DateTime>('cache_timestamps');
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing Hive cache service: $e');
      rethrow;
    }
  }

  /// Ensure the service is initialised before use.

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Cache movies for a specific category.

  Future<void> cacheMoviesForCategory(
    CacheCategory category,
    List<Movie> movies,
  ) async {
    await _ensureInitialized();
    try {
      // Store movies as a list.

      await _movieBox!.put(category.value, movies);

      // Store timestamp for cache expiration.

      await _timestampBox!.put(category.value, DateTime.now());
    } catch (e) {
      debugPrint('Error caching movies for ${category.value}: $e');
      rethrow;
    }
  }

  /// Get cached movies for a specific category.

  Future<List<Movie>?> getCachedMoviesForCategory(
    CacheCategory category,
  ) async {
    await _ensureInitialized();
    try {
      final cachedData = _movieBox!.get(category.value);
      if (cachedData == null) return null;

      // Convert dynamic list back to Movie list.

      return cachedData.cast<Movie>();
    } catch (e) {
      debugPrint('Error retrieving cached movies for ${category.value}: $e');
      return null;
    }
  }

  /// Check if cache for a category is valid (not expired).

  Future<bool> isCacheValid(CacheCategory category) async {
    await _ensureInitialized();
    try {
      final timestamp = _timestampBox!.get(category.value);
      if (timestamp == null) return false;

      final ttl = CacheConfig.getTtlForCategory(category);
      final age = DateTime.now().difference(timestamp);

      return age <= ttl;
    } catch (e) {
      debugPrint('Error checking cache validity for ${category.value}: $e');
      return false;
    }
  }

  /// Get cached movies regardless of TTL (for stale cache fallback).

  Future<List<Movie>?> getStaleMovies(CacheCategory category) async {
    return getCachedMoviesForCategory(category);
  }

  /// Get movies with cache information.

  Future<CacheResult<List<Movie>>?> getMoviesWithCacheInfo(
    CacheCategory category,
  ) async {
    await _ensureInitialized();
    try {
      final timestamp = _timestampBox!.get(category.value);
      final isValid = await isCacheValid(category);

      if (!isValid || timestamp == null) return null;

      final movies = await getCachedMoviesForCategory(category);
      if (movies == null || movies.isEmpty) return null;

      final cacheAge = DateTime.now().difference(timestamp);

      return CacheResult(
        data: movies,
        fromCache: true,
        cacheAge: cacheAge,
        cachedAt: timestamp,
      );
    } catch (e) {
      debugPrint(
        'Error getting movies with cache info for ${category.value}: $e',
      );
      return null;
    }
  }

  /// Invalidate cache for a specific category.

  Future<void> clearCacheForCategory(CacheCategory category) async {
    await _ensureInitialized();
    try {
      await _movieBox!.delete(category.value);
      await _timestampBox!.delete(category.value);
    } catch (e) {
      debugPrint('Error clearing cache for ${category.value}: $e');
      rethrow;
    }
  }

  /// Clear all cached data.

  Future<void> clearAllCache() async {
    await _ensureInitialized();
    try {
      await _movieBox!.clear();
      await _timestampBox!.clear();
    } catch (e) {
      debugPrint('Error clearing all cache: $e');
      rethrow;
    }
  }

  /// Get cache metadata for a category.

  Future<Map<String, dynamic>?> getCacheMetadata(CacheCategory category) async {
    await _ensureInitialized();
    try {
      final timestamp = _timestampBox!.get(category.value);
      final movies = await getCachedMoviesForCategory(category);

      if (timestamp == null || movies == null) return null;

      final age = DateTime.now().difference(timestamp);
      final isValid = await isCacheValid(category);

      return {
        'category': category.value,
        'lastUpdated': timestamp,
        'movieCount': movies.length,
        'isValid': isValid,
        'age': age,
      };
    } catch (e) {
      debugPrint('Error getting cache metadata for ${category.value}: $e');
      return null;
    }
  }

  /// Close Hive boxes when service is disposed.

  Future<void> dispose() async {
    try {
      if (_movieBox != null && _movieBox!.isOpen) {
        await _movieBox!.close();
      }
      if (_timestampBox != null && _timestampBox!.isOpen) {
        await _timestampBox!.close();
      }
      _isInitialized = false;
    } catch (e) {
      debugPrint('Error disposing Hive service: $e');
    }
  }
}
