/// Provider for managing movie cache repository access throughout the app.
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

import 'package:moviestar/services/hive_movie_cache_service.dart';

/// Provider for movie cache using Hive.

class MovieCacheProvider extends ChangeNotifier {
  /// The Hive movie cache service instance.

  late final HiveMovieCacheService _service;

  /// Whether the provider is initialised.

  bool _isInitialized = false;

  /// Getter for the service.

  HiveMovieCacheService get service {
    if (!_isInitialized) {
      throw StateError(
        'MovieCacheProvider not initialized. Call initialize() first.',
      );
    }
    return _service;
  }

  /// Whether the provider is initialised.

  bool get isInitialized => _isInitialized;

  /// Initialises the provider with Hive cache service.

  Future<void> initialize() async {
    if (_isInitialized) return;

    _service = HiveMovieCacheService();
    await _service.initialize();
    _isInitialized = true;

    notifyListeners();
  }

  /// Invalidates all cache and notifies listeners.

  Future<void> clearAllCache() async {
    await _service.clearAllCache();
    notifyListeners();
  }

  /// Invalidates specific category cache and notifies listeners.

  Future<void> clearCategoryCache(CacheCategory category) async {
    await _service.clearCacheForCategory(category);
    notifyListeners();
  }

  /// Get cache metadata for a category.

  Future<Map<String, dynamic>?> getCacheMetadata(CacheCategory category) async {
    return await _service.getCacheMetadata(category);
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _service.dispose();
    }
    super.dispose();
  }
}
