/// WebID validation utilities with caching support.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

/// Handles WebID validation with caching for POD sharing operations.
class WebIdValidator {
  static final Map<String, bool> _webIdValidationCache = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);
  static final Map<String, DateTime> _cacheTimestamps = {};

  /// Validate a WebID (with caching).
  static Future<bool> validateWebId(String webId) async {
    if (webId.isEmpty) return false;

    // Check cache
    final cacheKey = webId.toLowerCase();
    if (_webIdValidationCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheExpiration) {
        return _webIdValidationCache[cacheKey] ?? false;
      }
    }

    // Basic validation
    final isValid = _isValidWebIdFormat(webId);

    // Cache result
    _webIdValidationCache[cacheKey] = isValid;
    _cacheTimestamps[cacheKey] = DateTime.now();

    return isValid;
  }

  /// Check if WebID format is valid.
  static bool _isValidWebIdFormat(String webId) {
    // Basic WebID format validation
    if (!webId.startsWith('http://') && !webId.startsWith('https://')) {
      return false;
    }

    try {
      final uri = Uri.parse(webId);
      return uri.hasAuthority && uri.path.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Clear WebID validation cache.
  static void clearCache() {
    _webIdValidationCache.clear();
    _cacheTimestamps.clear();
  }

  /// Check if a WebID is in cache.
  static bool hasCachedResult(String webId) {
    final cacheKey = webId.toLowerCase();
    if (_webIdValidationCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      return timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheExpiration;
    }
    return false;
  }

  /// Get cached validation result (if available and not expired).
  static bool? getCachedResult(String webId) {
    if (hasCachedResult(webId)) {
      return _webIdValidationCache[webId.toLowerCase()];
    }
    return null;
  }
}
