/// Provider for the cached movie service in the Movie Star application.
///
// Time-stamp: <Thursday 2025-04-10 11:47:48 +1000 Graham Williams>
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
/// Authors: Ashley Tang

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/core/services/api/content_service.dart';
import 'package:moviestar/core/services/api/key_service.dart';
import 'package:moviestar/core/services/api/movie_service.dart';
import 'package:moviestar/core/services/cache/cached_movie_service.dart';
import 'package:moviestar/core/services/cache/hive_movie_cache_service.dart';
import 'package:moviestar/core/services/cache/settings_service.dart';
import 'package:moviestar/providers/cached_movie_service_provider/direct_movie_service.dart';
import 'package:moviestar/providers/cached_movie_service_provider/state_notifiers.dart';

// Re-export the extracted classes for backward compatibility.

export 'package:moviestar/providers/cached_movie_service_provider/direct_movie_service.dart';
export 'package:moviestar/providers/cached_movie_service_provider/provider_definitions.dart';
export 'package:moviestar/providers/cached_movie_service_provider/state_notifiers.dart';

/// Provider for the API key service.
/// Note: This should be overridden with a proper instance from MyHomePage.
/// Use ProviderScope.overrideWithValue() to provide the actual service instance.

final apiKeyServiceProvider = Provider<ApiKeyService?>((ref) {
  // This will be overridden by MyHomePage with the actual service instance.
  // If not overridden, it returns null.

  return null;
});

/// Direct API key provider - deprecated, returns null to force use of ApiKeyService.
/// API keys are now stored in POD only, which requires ApiKeyService for access.

final directApiKeyProvider = FutureProvider<String?>((ref) async {
  // Always return null to force the app to use ApiKeyService.
  // ApiKeyService properly reads from POD storage which is shared across devices.
  // This provider is kept for backward compatibility but no longer reads from local storage.

  return null;
});

/// Provider for the API key state that watches for changes.

final apiKeyProvider = StateNotifierProvider<ApiKeyNotifier, String?>(
  (ref) {
    final apiKeyService = ref.watch(apiKeyServiceProvider);
    return ApiKeyNotifier(apiKeyService);
  },
  dependencies: [apiKeyServiceProvider],
);

/// FutureProvider that waits for the API key to be loaded.
/// Use this in movie providers to ensure they wait for the key to be fetched.

final apiKeyFutureProvider = FutureProvider<String?>(
  (ref) async {
    final apiKeyService = ref.watch(apiKeyServiceProvider);
    if (apiKeyService == null) return null;

    final apiKey = await apiKeyService.getApiKey();
    return apiKey;
  },
  dependencies: [apiKeyServiceProvider],
);

/// Provider for the movie service using API key from POD.

final movieServiceProvider = Provider.autoDispose<MovieService>(
  (ref) {
    // Watch the API key notifier to trigger recreation when it changes.

    final apiKey = ref.watch(apiKeyProvider);

    // Create a DirectMovieService that uses the API key directly.

    final movieService = DirectMovieService(apiKey);

    // Ensure proper disposal.

    ref.onDispose(() {
      movieService.dispose();
    });

    return movieService;
  },
  dependencies: [
    apiKeyProvider,
    apiKeyServiceProvider,
  ],
);

/// Provider for the content service (handles both movies and TV shows).

final contentServiceProvider = Provider<ContentService>((ref) {
  final apiKeyService = ref.watch(apiKeyServiceProvider);
  // Watch the API key to trigger recreation when it changes.

  ref.watch(apiKeyProvider);

  final contentService = ContentService(apiKeyService);

  // Ensure proper disposal.

  ref.onDispose(() {
    contentService.dispose();
  });

  return contentService;
});

/// Direct provider for the content service that uses the direct API key.

final directContentServiceProvider =
    FutureProvider<ContentService>((ref) async {
  final apiKey = await ref.watch(directApiKeyProvider.future);

  // Use the new constructor that accepts API key directly.

  final contentService = ContentService.withApiKey(apiKey);

  // Ensure proper disposal.

  ref.onDispose(() {
    contentService.dispose();
  });

  return contentService;
});

/// Provider for the Hive movie cache service.
/// This creates a singleton instance that auto-initialises on first access.

final hiveCacheServiceProvider = Provider<HiveMovieCacheService>((ref) {
  final service = HiveMovieCacheService();

  // Ensure the service is disposed when the provider is disposed.

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for the cached movie service.

final cachedMovieServiceProvider = Provider<CachedMovieService>((ref) {
  final movieService = ref.watch(movieServiceProvider);
  final cacheService = ref.watch(hiveCacheServiceProvider);

  final cachedService = CachedMovieService(
    movieService,
    cacheService,
    cachingEnabled: true,
    cacheOnlyMode: false,
  );

  // Ensure proper disposal.

  ref.onDispose(() {
    cachedService.dispose();
  });

  return cachedService;
});

/// Provider for the cache settings service.

final cacheSettingsServiceProvider = Provider<CacheSettingsService>((ref) {
  return CacheSettingsService.instance;
});

/// Provider for offline mode state with persistence.

final cacheOnlyModeProvider =
    StateNotifierProvider<CacheOnlyModeNotifier, bool>((ref) {
  final settingsService = ref.watch(cacheSettingsServiceProvider);
  return CacheOnlyModeNotifier(settingsService);
});

/// Provider for caching enabled state with persistence.

final cachingEnabledProvider =
    StateNotifierProvider<CachingEnabledNotifier, bool>((ref) {
  final settingsService = ref.watch(cacheSettingsServiceProvider);
  return CachingEnabledNotifier(settingsService);
});

/// Provider for local API key caching state with persistence.

final localApiKeyCachingProvider =
    StateNotifierProvider<LocalApiKeyCachingNotifier, bool>((ref) {
  final settingsService = ref.watch(cacheSettingsServiceProvider);
  return LocalApiKeyCachingNotifier(settingsService);
});

/// Provider for configured cached movie service (with settings).

final configuredCachedMovieServiceProvider =
    Provider.autoDispose<CachedMovieService>(
  (ref) {
    final movieService = ref.watch(movieServiceProvider);
    final cacheService = ref.watch(hiveCacheServiceProvider);
    final cachingEnabled = ref.watch(cachingEnabledProvider);
    final cacheOnlyMode = ref.watch(cacheOnlyModeProvider);

    final cachedService = CachedMovieService(
      movieService,
      cacheService,
      cachingEnabled: cachingEnabled,
      cacheOnlyMode: cacheOnlyMode,
    );

    // Ensure proper disposal.

    ref.onDispose(() {
      cachedService.dispose();
    });

    return cachedService;
  },
  dependencies: [
    movieServiceProvider,
    apiKeyProvider,
    apiKeyServiceProvider,
  ],
);
