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

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solidpod/solidpod.dart' show getWebId;

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/api_key_service.dart';
import 'package:moviestar/services/cache_settings_service.dart';
import 'package:moviestar/services/cached_movie_service.dart';
import 'package:moviestar/services/content_service.dart';
import 'package:moviestar/services/hive_movie_cache_service.dart';
import 'package:moviestar/services/movie_service.dart';
import 'package:moviestar/utils/network_client.dart';

/// A simple API key service that returns the provided API key directly.
/// This bypasses the complex POD/secure storage chain when we already have the key.
class DirectApiKeyService {
  final String? _apiKey;

  DirectApiKeyService(this._apiKey);

  Future<String?> getApiKey() async {
    debugPrint(
      '🔑 [DirectApiKeyService] Returning API key: ${_apiKey != null ? 'Present (${_apiKey.length} chars)' : 'NULL'}',
    );
    return _apiKey;
  }

  void addListener(VoidCallback listener) {
    // No-op since the key doesn't change
  }

  void removeListener(VoidCallback listener) {
    // No-op since the key doesn't change
  }
}

/// A MovieService that initializes with a direct API key instead of using ApiKeyService.
/// This bypasses the complex POD/secure storage chain when we already have the key.
class DirectMovieService extends MovieService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  final String? _apiKey;
  NetworkClient? _directClient;
  DirectApiKeyService? _directApiKeyService;

  DirectMovieService(this._apiKey) : super(null) {
    _initializeWithDirectApiKey();
  }

  /// Initializes the service with the provided API key directly.
  void _initializeWithDirectApiKey() {
    debugPrint(
      '🔑 [DirectMovieService] Initializing with API key: ${_apiKey != null ? 'Present (${_apiKey.length} chars)' : 'NULL'}',
    );

    // Create NetworkClient directly without ContentService to avoid type compatibility issues
    _directClient = NetworkClient(baseUrl: _baseUrl, apiKey: _apiKey ?? '');

    debugPrint(
      '🔑 [DirectMovieService] NetworkClient created directly with API key',
    );
  }

  /// Ensures our direct client is initialized.
  Future<void> _ensureDirectClientInitialized() async {
    if (_directClient == null) {
      _initializeWithDirectApiKey();
    }
  }

  @override
  Future<List<Movie>> getPopularMovies() async {
    debugPrint('🔑 [DirectMovieService] getPopularMovies() called');
    await _ensureDirectClientInitialized();
    debugPrint(
      '🔑 [DirectMovieService] Client initialized, fetching mixed content directly',
    );

    // Fetch both popular movies and TV shows directly
    final moviesFuture = _directClient!.getJsonList('movie/popular');
    final tvShowsFuture = _directClient!.getJsonList('tv/popular');

    final results = await Future.wait([moviesFuture, tvShowsFuture]);
    final movies = results[0];
    final tvShows = results[1];

    // Convert to ContentItems
    final movieItems =
        movies.map((movie) => ContentItem.fromMovieJson(movie)).toList();
    final tvItems = tvShows.map((tv) => ContentItem.fromTVJson(tv)).toList();

    // Combine and sort by vote average
    final combined = <ContentItem>[];
    combined.addAll(movieItems);
    combined.addAll(tvItems);
    combined.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));

    debugPrint(
      '🔑 [DirectMovieService] Got ${combined.length} content items directly',
    );
    return combined.map((content) => Movie.fromContentItem(content)).toList();
  }

  @override
  Future<List<Movie>> getNowPlayingMovies() async {
    await _ensureDirectClientInitialized();

    // Fetch both now playing movies and on the air TV shows directly
    final moviesFuture = _directClient!.getJsonList('movie/now_playing');
    final tvShowsFuture = _directClient!.getJsonList('tv/on_the_air');

    final results = await Future.wait([moviesFuture, tvShowsFuture]);
    final movies = results[0];
    final tvShows = results[1];

    final movieItems =
        movies.map((movie) => ContentItem.fromMovieJson(movie)).toList();
    final tvItems = tvShows.map((tv) => ContentItem.fromTVJson(tv)).toList();

    final combined = <ContentItem>[];
    combined.addAll(movieItems);
    combined.addAll(tvItems);
    combined.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));

    return combined.map((content) => Movie.fromContentItem(content)).toList();
  }

  @override
  Future<List<Movie>> getTopRatedMovies() async {
    await _ensureDirectClientInitialized();

    // Fetch both top rated movies and TV shows directly
    final moviesFuture = _directClient!.getJsonList('movie/top_rated');
    final tvShowsFuture = _directClient!.getJsonList('tv/top_rated');

    final results = await Future.wait([moviesFuture, tvShowsFuture]);
    final movies = results[0];
    final tvShows = results[1];

    final movieItems =
        movies.map((movie) => ContentItem.fromMovieJson(movie)).toList();
    final tvItems = tvShows.map((tv) => ContentItem.fromTVJson(tv)).toList();

    final combined = <ContentItem>[];
    combined.addAll(movieItems);
    combined.addAll(tvItems);
    combined.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));

    return combined.map((content) => Movie.fromContentItem(content)).toList();
  }

  @override
  Future<List<Movie>> getUpcomingMovies() async {
    await _ensureDirectClientInitialized();

    // Fetch both upcoming movies and airing today TV shows directly
    final moviesFuture = _directClient!.getJsonList('movie/upcoming');
    final tvShowsFuture = _directClient!.getJsonList('tv/airing_today');

    final results = await Future.wait([moviesFuture, tvShowsFuture]);
    final movies = results[0];
    final tvShows = results[1];

    final movieItems =
        movies.map((movie) => ContentItem.fromMovieJson(movie)).toList();
    final tvItems = tvShows.map((tv) => ContentItem.fromTVJson(tv)).toList();

    final combined = <ContentItem>[];
    combined.addAll(movieItems);
    combined.addAll(tvItems);
    combined.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));

    return combined.map((content) => Movie.fromContentItem(content)).toList();
  }

  @override
  Future<List<Movie>> searchMovies(String query) async {
    await _ensureDirectClientInitialized();
    final results = await _directClient!
        .getJsonList('search/movie?query=${Uri.encodeComponent(query)}');
    return results.map((movie) => Movie.fromJson(movie)).toList();
  }

  @override
  Future<List<Movie>> searchMoviesByActor(String actorName) async {
    await _ensureDirectClientInitialized();
    // First search for the person
    final personResults = await _directClient!
        .getJsonList('search/person?query=${Uri.encodeComponent(actorName)}');
    if (personResults.isEmpty) return [];

    final personId = personResults[0]['id'];
    final credits =
        await _directClient!.getJson('person/$personId/movie_credits');
    final cast = credits['cast'] as List<dynamic>? ?? [];

    return cast.map((movie) => Movie.fromJson(movie)).toList();
  }

  @override
  Future<List<Movie>> searchMoviesByGenre(String genreName) async {
    await _ensureDirectClientInitialized();
    // First get genre list to find the ID
    final genreData = await _directClient!.getJson('genre/movie/list');
    final genres = genreData['genres'] as List<dynamic>? ?? [];

    final genre = genres.firstWhere(
      (g) =>
          g['name'].toString().toLowerCase().contains(genreName.toLowerCase()),
      orElse: () => null,
    );

    if (genre == null) return [];

    final genreId = genre['id'];
    final results =
        await _directClient!.getJsonList('discover/movie?with_genres=$genreId');
    return results.map((movie) => Movie.fromJson(movie)).toList();
  }

  @override
  void dispose() {
    debugPrint('🔑 [DirectMovieService] Disposing services');
    _directClient?.dispose();
    _directClient = null;
    _directApiKeyService = null;
    super.dispose();
  }
}

/// StateNotifier for managing caching enabled setting with persistence.

class CachingEnabledNotifier extends StateNotifier<bool> {
  final CacheSettingsService _settingsService;

  CachingEnabledNotifier(this._settingsService) : super(true) {
    _init();
  }

  Future<void> _init() async {
    await _settingsService.initialize();
    if (!mounted) return;
    state = _settingsService.cachingEnabled;
  }

  Future<void> setCachingEnabled(bool enabled) async {
    await _settingsService.setCachingEnabled(enabled);
    if (!mounted) return;
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
    if (!mounted) return;
    state = _settingsService.cacheOnlyMode;
  }

  Future<void> setCacheOnlyMode(bool enabled) async {
    await _settingsService.setCacheOnlyMode(enabled);
    if (!mounted) return;
    state = enabled;
  }
}

/// StateNotifier for managing API key state and changes.

class ApiKeyNotifier extends StateNotifier<String?> {
  final ApiKeyService? _apiKeyService;

  ApiKeyNotifier(this._apiKeyService) : super(null) {
    if (_apiKeyService != null) {
      _init();
      // Listen for API key changes.
      _apiKeyService.addListener(_onApiKeyChanged);
    }
  }

  Future<void> _init() async {
    debugPrint(
      '🔑 [ApiKeyNotifier] Initializing - service: ${_apiKeyService != null ? 'available' : 'NULL'}',
    );
    if (_apiKeyService == null) {
      debugPrint('🔑 [ApiKeyNotifier] No API service available');
      return;
    }
    try {
      final apiKey = await _apiKeyService.getApiKey();
      debugPrint(
        '🔑 [ApiKeyNotifier] Got API key: ${apiKey != null ? 'YES (${apiKey.length} chars)' : 'NULL'}',
      );
      if (!mounted) return;
      state = apiKey;
    } catch (e) {
      debugPrint('🔑 [ApiKeyNotifier] ERROR getting API key: $e');
    }
  }

  void _onApiKeyChanged() async {
    debugPrint(
      '🔑 [ApiKeyNotifier] API key changed - mounted: $mounted, service: ${_apiKeyService != null}',
    );
    if (!mounted || _apiKeyService == null) return;
    try {
      final apiKey = await _apiKeyService.getApiKey();
      debugPrint(
        '🔑 [ApiKeyNotifier] Updated API key: ${apiKey != null ? 'YES (${apiKey.length} chars)' : 'NULL'}',
      );
      if (!mounted) return;
      state = apiKey;
    } catch (e) {
      if (mounted) {
        debugPrint('🔑 [ApiKeyNotifier] ERROR in _onApiKeyChanged: $e');
      }
    }
  }

  @override
  void dispose() {
    _apiKeyService?.removeListener(_onApiKeyChanged);
    super.dispose();
  }
}

/// Provider for the API key service.
/// Note: Context needs to be set manually via updateContext() for POD operations.

final apiKeyServiceProvider = Provider<ApiKeyService?>((ref) {
  // ApiKeyService requires BuildContext and Widget, so return null here
  // Services should create their own instance with proper context
  return null;
});

/// Direct API key provider that accesses secure storage without service dependency
final directApiKeyProvider = FutureProvider<String?>((ref) async {
  debugPrint('🔑 [DirectApiKeyProvider] Starting direct API key fetch');
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
        debugPrint(
          '🔑 [DirectApiKeyProvider] Tried user key: ${apiKey != null ? 'FOUND' : 'NOT FOUND'}',
        );
      }
    } catch (e) {
      debugPrint('🔑 [DirectApiKeyProvider] Failed to get webId: $e');
    }

    // Try legacy key if user key not found
    if (apiKey == null || apiKey.isEmpty) {
      apiKey = await storage.read(key: 'movie_db_api_key');
      debugPrint(
        '🔑 [DirectApiKeyProvider] Tried legacy key: ${apiKey != null ? 'FOUND' : 'NOT FOUND'}',
      );
    }

    debugPrint(
      '🔑 [DirectApiKeyProvider] Final result: ${apiKey != null ? 'SUCCESS (${apiKey.length} chars)' : 'NULL'}',
    );
    return apiKey;
  } catch (e) {
    debugPrint('🔑 [DirectApiKeyProvider] ERROR: $e');
    return null;
  }
});

/// Provider for the API key state that watches for changes.

final apiKeyProvider = StateNotifierProvider<ApiKeyNotifier, String?>((ref) {
  final apiKeyService = ref.watch(apiKeyServiceProvider);
  return ApiKeyNotifier(apiKeyService);
});

/// Provider for the movie service using direct API key access.

final movieServiceProvider = Provider.autoDispose<MovieService>((ref) {
  // Watch the direct API key to trigger recreation when it changes.
  final apiKeyAsync = ref.watch(directApiKeyProvider);
  final apiKey = apiKeyAsync.valueOrNull;

  debugPrint(
    '🔑 [MovieServiceProvider] Creating DirectMovieService with API key: ${apiKey != null ? 'Present (${apiKey.length} chars)' : 'NULL'}',
  );

  // Create a DirectMovieService that uses the API key directly
  final movieService = DirectMovieService(apiKey);

  // Ensure proper disposal.
  ref.onDispose(() {
    debugPrint('🔑 [MovieServiceProvider] Disposing DirectMovieService');
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

/// Direct provider for the content service that uses the direct API key.

final directContentServiceProvider = FutureProvider<ContentService>((ref) async {
  final apiKey = await ref.watch(directApiKeyProvider.future);

  print('🔍 [DirectContentServiceProvider] Creating ContentService with API key: ${apiKey != null ? 'Present (${apiKey.length} chars)' : 'NULL'}');

  // Use the new constructor that accepts API key directly
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

/// StateNotifier for managing local API key caching setting with persistence.

class LocalApiKeyCachingNotifier extends StateNotifier<bool> {
  final CacheSettingsService _settingsService;

  LocalApiKeyCachingNotifier(this._settingsService) : super(false) {
    _init();
  }

  Future<void> _init() async {
    await _settingsService.initialize();
    if (!mounted) return;
    state = _settingsService.localApiKeyCachingEnabled;
  }

  Future<void> setLocalApiKeyCachingEnabled(bool enabled) async {
    await _settingsService.setLocalApiKeyCachingEnabled(enabled);
    if (!mounted) return;
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

  debugPrint(
    '🔑 [ConfiguredCachedMovieServiceProvider] Creating cached service with movieService type: ${movieService.runtimeType}',
  );

  final cachedService = CachedMovieService(
    movieService,
    cacheService,
    cachingEnabled: cachingEnabled,
    cacheOnlyMode: cacheOnlyMode,
  );

  // Ensure proper disposal.

  ref.onDispose(() {
    debugPrint(
      '🔑 [ConfiguredCachedMovieServiceProvider] Disposing cached service',
    );
    cachedService.dispose();
  });

  return cachedService;
});

/// Provider for popular movies with caching information.

final popularMoviesWithCacheInfoProvider =
    FutureProvider.autoDispose<CacheResult<List<Movie>>>((ref) async {
  debugPrint('🎬 [PopularMoviesProvider] Starting to fetch popular movies');
  final cachedService = ref.watch(configuredCachedMovieServiceProvider);
  final apiKeyAsync = ref.watch(directApiKeyProvider);
  final apiKey = apiKeyAsync.valueOrNull;
  debugPrint(
    '🎬 [PopularMoviesProvider] API Key status: ${apiKey != null ? 'Present (${apiKey.length} chars)' : 'NULL'}',
  );

  // If no API key is set, return empty result instead of cached content
  if (apiKey == null || apiKey.trim().isEmpty) {
    debugPrint(
      '🎬 [PopularMoviesProvider] No API key configured - returning empty result',
    );
    return CacheResult<List<Movie>>(
      data: <Movie>[],
      fromCache: false,
      cacheAge: null,
    );
  }

  // Watch cache settings to invalidate when they change.
  ref.watch(cachingEnabledProvider);
  ref.watch(cacheOnlyModeProvider);
  debugPrint(
    '🎬 [PopularMoviesProvider] Calling cachedService.getPopularMoviesWithCacheInfo()',
  );
  try {
    final result = await cachedService.getPopularMoviesWithCacheInfo();
    debugPrint(
      '🎬 [PopularMoviesProvider] Success: got ${result.data.length} movies from ${result.fromCache ? 'cache' : 'API'}',
    );
    return result;
  } catch (e) {
    debugPrint('🎬 [PopularMoviesProvider] ERROR: $e');
    rethrow;
  }
});

/// Provider for now playing movies with caching information.

final nowPlayingMoviesWithCacheInfoProvider =
    FutureProvider.autoDispose<CacheResult<List<Movie>>>((ref) async {
  final cachedService = ref.watch(configuredCachedMovieServiceProvider);
  final apiKeyAsync = ref.watch(directApiKeyProvider);
  final apiKey = apiKeyAsync.valueOrNull;
  debugPrint(
    '🎬 [NowPlayingProvider] API Key status: ${apiKey != null ? 'Present (${apiKey.length} chars)' : 'NULL'}',
  );

  // If no API key is set, return empty result instead of cached content
  if (apiKey == null || apiKey.trim().isEmpty) {
    debugPrint(
      '🎬 [NowPlayingProvider] No API key configured - returning empty result',
    );
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
  debugPrint(
    '🎬 [TopRatedProvider] API Key status: ${apiKey != null ? 'Present (${apiKey.length} chars)' : 'NULL'}',
  );

  // If no API key is set, return empty result instead of cached content
  if (apiKey == null || apiKey.trim().isEmpty) {
    debugPrint(
      '🎬 [TopRatedProvider] No API key configured - returning empty result',
    );
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
  debugPrint(
    '🎬 [UpcomingProvider] API Key status: ${apiKey != null ? 'Present (${apiKey.length} chars)' : 'NULL'}',
  );

  // If no API key is set, return empty result instead of cached content
  if (apiKey == null || apiKey.trim().isEmpty) {
    debugPrint(
      '🎬 [UpcomingProvider] No API key configured - returning empty result',
    );
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
