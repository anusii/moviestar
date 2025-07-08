/// Service for managing cache settings with persistent storage.
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

import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing cache-related settings with persistent storage.

class CacheSettingsService {
  static const String _cachingEnabledKey = 'cache_settings_caching_enabled';
  static const String _cacheOnlyModeKey = 'cache_settings_cache_only_mode';

  static CacheSettingsService? _instance;
  SharedPreferences? _prefs;
  bool _initialized = false;

  CacheSettingsService._();

  /// Gets the singleton instance of CacheSettingsService.

  static CacheSettingsService get instance {
    _instance ??= CacheSettingsService._();
    return _instance!;
  }

  /// Initialises the service and loads settings from SharedPreferences.

  Future<void> initialize() async {
    if (_initialized) return;

    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    developer.log(
      'Cache settings service initialized',
      name: 'CacheSettingsService',
    );
  }

  /// Gets whether caching is enabled (defaults to true).

  bool get cachingEnabled {
    return _prefs?.getBool(_cachingEnabledKey) ?? true;
  }

  /// Sets whether caching is enabled.

  Future<void> setCachingEnabled(bool enabled) async {
    await _prefs?.setBool(_cachingEnabledKey, enabled);
    developer.log(
      'Caching enabled setting changed to: $enabled',
      name: 'CacheSettingsService',
    );
  }

  /// Gets whether offline mode is enabled (defaults to false)

  bool get cacheOnlyMode {
    return _prefs?.getBool(_cacheOnlyModeKey) ?? false;
  }

  /// Sets whether offline mode is enabled.

  Future<void> setCacheOnlyMode(bool enabled) async {
    await _prefs?.setBool(_cacheOnlyModeKey, enabled);
    developer.log(
      'Offline mode setting changed to: $enabled',
      name: 'CacheSettingsService',
    );
  }

  /// Resets all cache settings to defaults.

  Future<void> resetToDefaults() async {
    await _prefs?.remove(_cachingEnabledKey);
    await _prefs?.remove(_cacheOnlyModeKey);
    developer.log(
      'Cache settings reset to defaults',
      name: 'CacheSettingsService',
    );
  }
}
