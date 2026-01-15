/// State notifiers for cache management.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/core/services/api/key_service.dart';
import 'package:moviestar/core/services/cache/settings_service.dart';

/// Notifier for managing caching enabled setting with persistence.

class CachingEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    _init();
    return true;
  }

  CacheSettingsService get _settingsService =>
      ref.read(cacheSettingsServiceProvider);

  Future<void> _init() async {
    await _settingsService.initialize();
    state = _settingsService.cachingEnabled;
  }

  Future<void> setCachingEnabled(bool enabled) async {
    await _settingsService.setCachingEnabled(enabled);
    state = enabled;
  }
}

/// Provider for cache settings service.

final cacheSettingsServiceProvider = Provider<CacheSettingsService>((ref) {
  return CacheSettingsService.instance;
});

/// Notifier for managing offline mode setting with persistence.

class CacheOnlyModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    _init();
    return false;
  }

  CacheSettingsService get _settingsService =>
      ref.read(cacheSettingsServiceProvider);

  Future<void> _init() async {
    await _settingsService.initialize();
    state = _settingsService.cacheOnlyMode;
  }

  Future<void> setCacheOnlyMode(bool enabled) async {
    await _settingsService.setCacheOnlyMode(enabled);
    state = enabled;
  }
}

/// Notifier for managing API key state and changes.

class ApiKeyNotifier extends Notifier<String?> {
  ApiKeyService? _apiKeyService;

  @override
  String? build() {
    _apiKeyService = ref.watch(apiKeyServiceProvider);
    if (_apiKeyService != null) {
      _init();

      // Listen for API key changes.

      _apiKeyService!.addListener(_onApiKeyChanged);
      ref.onDispose(() {
        _apiKeyService?.removeListener(_onApiKeyChanged);
      });
    }
    return null;
  }

  Future<void> _init() async {
    if (_apiKeyService == null) {
      return;
    }
    try {
      final apiKey = await _apiKeyService!.getApiKey();
      state = apiKey;
    } catch (e) {
      // Failed to get API key.
    }
  }

  void _onApiKeyChanged() async {
    if (_apiKeyService == null) return;
    try {
      final apiKey = await _apiKeyService!.getApiKey();
      state = apiKey;
    } catch (e) {
      // Failed to update API key.
    }
  }
}

/// Notifier for managing the API key service instance.

class ApiKeyServiceNotifier extends Notifier<ApiKeyService?> {
  @override
  ApiKeyService? build() => null;

  void setService(ApiKeyService? service) {
    state = service;
  }
}

/// Provider for the API key service.

final apiKeyServiceProvider =
    NotifierProvider<ApiKeyServiceNotifier, ApiKeyService?>(
  ApiKeyServiceNotifier.new,
);

/// Notifier for managing local API key caching setting with persistence.

class LocalApiKeyCachingNotifier extends Notifier<bool> {
  @override
  bool build() {
    _init();
    return false;
  }

  CacheSettingsService get _settingsService =>
      ref.read(cacheSettingsServiceProvider);

  Future<void> _init() async {
    await _settingsService.initialize();
    state = _settingsService.localApiKeyCachingEnabled;
  }

  Future<void> setLocalApiKeyCachingEnabled(bool enabled) async {
    await _settingsService.setLocalApiKeyCachingEnabled(enabled);
    state = enabled;
  }
}
