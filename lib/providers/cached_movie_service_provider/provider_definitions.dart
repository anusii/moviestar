/// Provider definitions for movie data with cache information.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/core/services/cache/hive_movie_cache_service.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart'
    show
        configuredCachedMovieServiceProvider,
        cachingEnabledProvider,
        cacheOnlyModeProvider,
        apiKeyProvider,
        apiKeyServiceProvider,
        apiKeyFutureProvider;

/// Direct API key provider - deprecated, returns null to force use of ApiKeyService.
/// API keys are now stored in POD only, which requires ApiKeyService for access.

final directApiKeyProvider = FutureProvider<String?>((ref) async {
  // Always return null to force the app to use ApiKeyService.
  // ApiKeyService properly reads from POD storage which is shared across devices.
  // This provider is kept for backward compatibility but no longer reads from local storage.

  return null;
});

/// Provider for recommended movies with caching information.

final recommendedMoviesWithCacheInfoProvider =
    FutureProvider.autoDispose<CacheResult<List<Movie>>>(
  (ref) async {
    final cachedService = ref.watch(configuredCachedMovieServiceProvider);
    // Await the API key to be loaded from POD before proceeding.
    final apiKey = await ref.watch(apiKeyFutureProvider.future);

    // If no API key is set, return empty result instead of cached content.

    if (apiKey == null || apiKey.trim().isEmpty) {
      return const CacheResult<List<Movie>>(
        data: <Movie>[],
        fromCache: false,
        cacheAge: null,
      );
    }

    // Watch cache settings to invalidate when they change.

    ref.watch(cachingEnabledProvider);
    ref.watch(cacheOnlyModeProvider);
    try {
      final result = await cachedService.getRecommendedMoviesWithCacheInfo();
      return result;
    } catch (e) {
      rethrow;
    }
  },
  dependencies: [
    apiKeyFutureProvider,
    apiKeyServiceProvider,
    configuredCachedMovieServiceProvider,
  ],
);

/// Provider for now playing movies with caching information.

final nowPlayingMoviesWithCacheInfoProvider =
    FutureProvider.autoDispose<CacheResult<List<Movie>>>(
  (ref) async {
    final cachedService = ref.watch(configuredCachedMovieServiceProvider);
    // Await the API key to be loaded from POD before proceeding.
    final apiKey = await ref.watch(apiKeyFutureProvider.future);

    // If no API key is set, return empty result instead of cached content.

    if (apiKey == null || apiKey.trim().isEmpty) {
      return const CacheResult<List<Movie>>(
        data: <Movie>[],
        fromCache: false,
        cacheAge: null,
      );
    }

    // Watch cache settings to invalidate when they change.

    ref.watch(cachingEnabledProvider);
    ref.watch(cacheOnlyModeProvider);
    return cachedService.getNowPlayingMoviesWithCacheInfo();
  },
  dependencies: [
    apiKeyFutureProvider,
    apiKeyServiceProvider,
    configuredCachedMovieServiceProvider,
  ],
);

/// Provider for top rated movies with caching information.

final topRatedMoviesWithCacheInfoProvider =
    FutureProvider.autoDispose<CacheResult<List<Movie>>>(
  (ref) async {
    final cachedService = ref.watch(configuredCachedMovieServiceProvider);
    // Await the API key to be loaded from POD before proceeding.
    final apiKey = await ref.watch(apiKeyFutureProvider.future);

    // If no API key is set, return empty result instead of cached content.

    if (apiKey == null || apiKey.trim().isEmpty) {
      return const CacheResult<List<Movie>>(
        data: <Movie>[],
        fromCache: false,
        cacheAge: null,
      );
    }

    // Watch cache settings to invalidate when they change.

    ref.watch(cachingEnabledProvider);
    ref.watch(cacheOnlyModeProvider);
    return cachedService.getTopRatedMoviesWithCacheInfo();
  },
  dependencies: [
    apiKeyFutureProvider,
    apiKeyServiceProvider,
    configuredCachedMovieServiceProvider,
  ],
);

/// Provider for upcoming movies with caching information.

final upcomingMoviesWithCacheInfoProvider =
    FutureProvider.autoDispose<CacheResult<List<Movie>>>(
  (ref) async {
    final cachedService = ref.watch(configuredCachedMovieServiceProvider);
    // Await the API key to be loaded from POD before proceeding.
    final apiKey = await ref.watch(apiKeyFutureProvider.future);

    // If no API key is set, return empty result instead of cached content.

    if (apiKey == null || apiKey.trim().isEmpty) {
      return const CacheResult<List<Movie>>(
        data: <Movie>[],
        fromCache: false,
        cacheAge: null,
      );
    }

    // Watch cache settings to invalidate when they change.

    ref.watch(cachingEnabledProvider);
    ref.watch(cacheOnlyModeProvider);
    return cachedService.getUpcomingMoviesWithCacheInfo();
  },
  dependencies: [
    apiKeyFutureProvider,
    apiKeyServiceProvider,
    configuredCachedMovieServiceProvider,
  ],
);

/// Provider for cache statistics.

final cacheStatsProvider =
    FutureProvider<Map<CacheCategory, Map<String, dynamic>>>(
  (ref) async {
    final cachedService = ref.watch(configuredCachedMovieServiceProvider);
    return await cachedService.getCacheStats();
  },
  dependencies: [apiKeyProvider, apiKeyServiceProvider],
);

/// These providers are imported from the main file.
/// They are used by the movie providers but defined in the main cached_movie_service_provider.dart.
/// to avoid circular dependencies.
