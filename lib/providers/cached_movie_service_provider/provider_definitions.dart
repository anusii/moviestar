/// Provider definitions for movie data with cache information.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solidpod/solidpod.dart' show getWebId;

import 'package:moviestar/core/services/cache/hive_movie_cache_service.dart';
import 'package:moviestar/models/movie.dart';
// Import providers from main file to resolve dependencies
import 'package:moviestar/providers/cached_movie_service_provider.dart'
    show
        configuredCachedMovieServiceProvider,
        cachingEnabledProvider,
        cacheOnlyModeProvider;

/// Direct API key provider that accesses secure storage without service dependency
final directApiKeyProvider = FutureProvider<String?>((ref) async {
  try {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
      mOptions: MacOsOptions(synchronizable: false),
    );

    // Try multiple storage keys to find the API key
    String? apiKey;

    // Try user-specific key first (current approach)
    try {
      final webId = await getWebId();
      if (webId != null && webId.isNotEmpty) {
        final userKey = 'user_api_key_$webId';
        apiKey = await storage.read(key: userKey);
      }
    } catch (e) {
      // Failed to read API key from storage
    }

    // Try legacy key if user key not found
    if (apiKey == null || apiKey.isEmpty) {
      apiKey = await storage.read(key: 'movie_db_api_key');
    }

    return apiKey;
  } catch (e) {
    return null;
  }
});

/// Provider for popular movies with caching information.
final popularMoviesWithCacheInfoProvider =
    FutureProvider.autoDispose<CacheResult<List<Movie>>>((ref) async {
  final cachedService = ref.watch(configuredCachedMovieServiceProvider);
  final apiKeyAsync = ref.watch(directApiKeyProvider);
  final apiKey = apiKeyAsync.valueOrNull;

  // If no API key is set, return empty result instead of cached content
  if (apiKey == null || apiKey.trim().isEmpty) {
    return CacheResult<List<Movie>>(
      data: <Movie>[],
      fromCache: false,
      cacheAge: null,
    );
  }

  // Watch cache settings to invalidate when they change.
  ref.watch(cachingEnabledProvider);
  ref.watch(cacheOnlyModeProvider);
  try {
    final result = await cachedService.getPopularMoviesWithCacheInfo();
    return result;
  } catch (e) {
    rethrow;
  }
});

/// Provider for now playing movies with caching information.
final nowPlayingMoviesWithCacheInfoProvider =
    FutureProvider.autoDispose<CacheResult<List<Movie>>>((ref) async {
  final cachedService = ref.watch(configuredCachedMovieServiceProvider);
  final apiKeyAsync = ref.watch(directApiKeyProvider);
  final apiKey = apiKeyAsync.valueOrNull;

  // If no API key is set, return empty result instead of cached content
  if (apiKey == null || apiKey.trim().isEmpty) {
    return CacheResult<List<Movie>>(
      data: <Movie>[],
      fromCache: false,
      cacheAge: null,
    );
  }

  // Watch cache settings to invalidate when they change.
  ref.watch(cachingEnabledProvider);
  ref.watch(cacheOnlyModeProvider);
  return cachedService.getNowPlayingMoviesWithCacheInfo();
});

/// Provider for top rated movies with caching information.
final topRatedMoviesWithCacheInfoProvider =
    FutureProvider.autoDispose<CacheResult<List<Movie>>>((ref) async {
  final cachedService = ref.watch(configuredCachedMovieServiceProvider);
  final apiKeyAsync = ref.watch(directApiKeyProvider);
  final apiKey = apiKeyAsync.valueOrNull;

  // If no API key is set, return empty result instead of cached content
  if (apiKey == null || apiKey.trim().isEmpty) {
    return CacheResult<List<Movie>>(
      data: <Movie>[],
      fromCache: false,
      cacheAge: null,
    );
  }

  // Watch cache settings to invalidate when they change.
  ref.watch(cachingEnabledProvider);
  ref.watch(cacheOnlyModeProvider);
  return cachedService.getTopRatedMoviesWithCacheInfo();
});

/// Provider for upcoming movies with caching information.
final upcomingMoviesWithCacheInfoProvider =
    FutureProvider.autoDispose<CacheResult<List<Movie>>>((ref) async {
  final cachedService = ref.watch(configuredCachedMovieServiceProvider);
  final apiKeyAsync = ref.watch(directApiKeyProvider);
  final apiKey = apiKeyAsync.valueOrNull;

  // If no API key is set, return empty result instead of cached content
  if (apiKey == null || apiKey.trim().isEmpty) {
    return CacheResult<List<Movie>>(
      data: <Movie>[],
      fromCache: false,
      cacheAge: null,
    );
  }

  // Watch cache settings to invalidate when they change.
  ref.watch(cachingEnabledProvider);
  ref.watch(cacheOnlyModeProvider);
  return cachedService.getUpcomingMoviesWithCacheInfo();
});

/// Provider for cache statistics.
final cacheStatsProvider =
    FutureProvider<Map<CacheCategory, Map<String, dynamic>>>((ref) async {
  final cachedService = ref.watch(configuredCachedMovieServiceProvider);
  return await cachedService.getCacheStats();
});

/// These providers are imported from the main file
/// They are used by the movie providers but defined in the main cached_movie_service_provider.dart
/// to avoid circular dependencies.
