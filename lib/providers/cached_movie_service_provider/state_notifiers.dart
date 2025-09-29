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
    if (_apiKeyService == null) {
      return;
    }
    try {
      final apiKey = await _apiKeyService.getApiKey();
      if (!mounted) return;
      state = apiKey;
    } catch (e) {
      // Failed to get API key.
    }
  }

  void _onApiKeyChanged() async {
    if (!mounted || _apiKeyService == null) return;
    try {
      final apiKey = await _apiKeyService.getApiKey();
      if (!mounted) return;
      state = apiKey;
    } catch (e) {
      if (mounted) {}
    }
  }

  @override
  void dispose() {
    _apiKeyService?.removeListener(_onApiKeyChanged);
    super.dispose();
  }
}

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
