/// Provider for the cached movie service in the Movie Star application.
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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/api_key_service.dart';
import 'package:moviestar/services/cache_settings_service.dart';
import 'package:moviestar/services/cached_movie_service.dart';
import 'package:moviestar/services/content_service.dart';
import 'package:moviestar/services/hive_movie_cache_service.dart';
import 'package:moviestar/services/movie_service.dart';

/// StateNotifier for managing caching enabled setting with persistence.

class CachingEnabledNotifier extends StateNotifier<bool> {
  final CacheSettingsService _settingsService;

  CachingEnabledNotifier(this._settingsService) : super(true) {
    _init();
  }

  Future<void> _init() async {
    await _settingsService.initialize();
    state = _settingsService.cachingEnabled;
  }

  Future<void> setCachingEnabled(bool enabled) async {
    await _settingsService.setCachingEnabled(enabled);
    state = enabled;
  }
}

/// StateNotifier for managing offline mode setting with persistence.

class CacheOnlyModeNotifier extends StateNotifier<bool> {
  final CacheSettingsService _settingsService;

  CacheOnlyModeNotifier(this._settingsService) : super(false) {
    _init();
  }

  Future<void> _init() async {
    await _settingsService.initialize();
    state = _settingsService.cacheOnlyMode;
  }

  Future<void> setCacheOnlyMode(bool enabled) async {
    await _settingsService.setCacheOnlyMode(enabled);
    state = enabled;
  }
}

/// StateNotifier for managing API key state and changes.

class ApiKeyNotifier extends StateNotifier<String?> {
  final ApiKeyService _apiKeyService;

  ApiKeyNotifier(this._apiKeyService) : super(null) {
    _init();
    // Listen for API key changes.

    _apiKeyService.addListener(_onApiKeyChanged);
  }

  Future<void> _init() async {
    state = await _apiKeyService.getApiKey();
  }

  void _onApiKeyChanged() async {
    state = await _apiKeyService.getApiKey();
  }

  @override
  void dispose() {
    _apiKeyService.removeListener(_onApiKeyChanged);
    super.dispose();
  }
}

/// Provider for the API key service.
/// Note: Context needs to be set manually via updateContext() for POD operations.

final apiKeyServiceProvider = Provider<ApiKeyService>((ref) {
  return ApiKeyService();
});

/// Provider for the API key state that watches for changes.

final apiKeyProvider = StateNotifierProvider<ApiKeyNotifier, String?>((ref) {
  final apiKeyService = ref.watch(apiKeyServiceProvider);
  return ApiKeyNotifier(apiKeyService);
});

/// Provider for the movie service.

final movieServiceProvider = Provider<MovieService>((ref) {
  final apiKeyService = ref.watch(apiKeyServiceProvider);
  // Watch the API key to trigger recreation when it changes.

  ref.watch(apiKeyProvider);

  final movieService = MovieService(apiKeyService);

  // Ensure proper disposal.

  ref.onDispose(() {
    movieService.dispose();
  });

  return movieService;
});

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

/// StateNotifier for managing local API key caching setting with persistence.

class LocalApiKeyCachingNotifier extends StateNotifier<bool> {
  final CacheSettingsService _settingsService;

  LocalApiKeyCachingNotifier(this._settingsService) : super(false) {
    _init();
  }

  Future<void> _init() async {
    await _settingsService.initialize();
    state = _settingsService.localApiKeyCachingEnabled;
  }

  Future<void> setLocalApiKeyCachingEnabled(bool enabled) async {
    await _settingsService.setLocalApiKeyCachingEnabled(enabled);
    state = enabled;
  }
}

/// Provider for local API key caching state with persistence.

final localApiKeyCachingProvider =
    StateNotifierProvider<LocalApiKeyCachingNotifier, bool>((ref) {
  final settingsService = ref.watch(cacheSettingsServiceProvider);
  return LocalApiKeyCachingNotifier(settingsService);
});

/// Provider for configured cached movie service (with settings).

final configuredCachedMovieServiceProvider =
    Provider.autoDispose<CachedMovieService>((ref) {
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
});

/// Provider for popular movies with caching information.

final popularMoviesWithCacheInfoProvider =
    FutureProvider.autoDispose<CacheResult<List<Movie>>>((ref) async {
  final cachedService = ref.watch(configuredCachedMovieServiceProvider);
  // Watch cache settings to invalidate when they change.

  ref.watch(cachingEnabledProvider);
  ref.watch(cacheOnlyModeProvider);
  return cachedService.getPopularMoviesWithCacheInfo();
});

/// Provider for now playing movies with caching information.

final nowPlayingMoviesWithCacheInfoProvider =
    FutureProvider.autoDispose<CacheResult<List<Movie>>>((ref) async {
  final cachedService = ref.watch(configuredCachedMovieServiceProvider);
  // Watch cache settings to invalidate when they change.

  ref.watch(cachingEnabledProvider);
  ref.watch(cacheOnlyModeProvider);
  return cachedService.getNowPlayingMoviesWithCacheInfo();
});

/// Provider for top rated movies with caching information.

final topRatedMoviesWithCacheInfoProvider =
    FutureProvider.autoDispose<CacheResult<List<Movie>>>((ref) async {
  final cachedService = ref.watch(configuredCachedMovieServiceProvider);
  // Watch cache settings to invalidate when they change.

  ref.watch(cachingEnabledProvider);
  ref.watch(cacheOnlyModeProvider);
  return cachedService.getTopRatedMoviesWithCacheInfo();
});

/// Provider for upcoming movies with caching information.

final upcomingMoviesWithCacheInfoProvider =
    FutureProvider.autoDispose<CacheResult<List<Movie>>>((ref) async {
  final cachedService = ref.watch(configuredCachedMovieServiceProvider);
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
