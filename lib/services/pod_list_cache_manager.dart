/// Cache manager for POD custom lists.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:moviestar/models/custom_list.dart';

/// Manages caching for POD custom lists.
class PodListCacheManager {
  /// Cache for custom lists to avoid frequent POD reads.
  final Map<String, CustomList> _customListsCache = {};

  /// Track the last time we scanned the directory.
  DateTime? _lastDirectoryScan;

  /// Cache expiration duration.
  static const Duration _cacheExpiration = Duration(minutes: 5);

  /// Checks if cache should be refreshed based on expiration or force flag.
  bool shouldRefresh({bool forceRefresh = false}) {
    return forceRefresh ||
        _lastDirectoryScan == null ||
        DateTime.now().difference(_lastDirectoryScan!) > _cacheExpiration;
  }

  /// Gets cached lists if available and not expired.
  List<CustomList>? getCachedLists() {
    if (_customListsCache.isNotEmpty && !shouldRefresh()) {
      return _customListsCache.values.toList();
    }
    return null;
  }

  /// Adds a list to the cache.
  void cacheList(String listId, CustomList list) {
    _customListsCache[listId] = list;
  }

  /// Updates the cache with a new list.
  void updateCachedList(String listId, CustomList updatedList) {
    _customListsCache[listId] = updatedList;
  }

  /// Removes a list from the cache.
  void removeCachedList(String listId) {
    _customListsCache.remove(listId);
  }

  /// Gets a specific cached list.
  CustomList? getCachedList(String listId) {
    return _customListsCache[listId];
  }

  /// Checks if a list exists in cache.
  bool containsList(String listId) {
    return _customListsCache.containsKey(listId);
  }

  /// Marks the directory scan as completed.
  void markDirectoryScanned() {
    _lastDirectoryScan = DateTime.now();
  }

  /// Clears the cache and forces a refresh on next access.
  void clearCache() {
    _customListsCache.clear();
    _lastDirectoryScan = null;
  }

  /// Clears the cache to rebuild it.
  void clearForRebuild() {
    _customListsCache.clear();
  }
}
