/// Compact ApiKeyService using BasePodService infrastructure.
/// Reduced from 575 to ~280 lines by using BasePodService patterns.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'package:flutter/material.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solidpod/solidpod.dart' show getWebId;

import 'package:moviestar/core/services/pod/base_pod_service.dart';
import 'package:moviestar/core/services/cache/cache_settings_service.dart';
import 'package:moviestar/utils/turtle_serializer.dart';

/// Compact service for managing API keys with POD and secure storage.
/// Uses BasePodService infrastructure for common POD operations.
class ApiKeyService extends BasePodService {
  static const String _legacyApiKeySecureKey = 'movie_db_api_key';
  static const String _userApiKeyPrefix = 'user_api_key_';
  static const String _migrationCompleteKey = 'api_key_migration_complete';
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: const AndroidOptions(),
    iOptions: const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: const MacOsOptions(synchronizable: false),
  );

  final BuildContext _context;
  final Widget _child;
  final CacheSettingsService _cacheSettings;

  String? _cachedApiKey;
  DateTime? _lastCacheTime;

  ApiKeyService(this._context, this._child)
      : _cacheSettings = CacheSettingsService.instance,
        super(_context, _child);

  /// Gets the API key from cache, POD, or secure storage.
  Future<String?> getApiKey() async {
    // Return cached value if valid
    if (_cachedApiKey != null &&
        _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!).inHours < 1) {
      return _cachedApiKey;
    }

    final apiKey = await _fetchApiKey();
    if (apiKey != null) {
      _cachedApiKey = apiKey;
      _lastCacheTime = DateTime.now();
    }
    return apiKey;
  }

  /// Sets the API key in both POD and secure storage.
  Future<void> setApiKey(String apiKey) async {
    await executePodOperation(
      operation: () async {
        // Save to POD first
        await _saveApiKeyToPod(apiKey);

        // Always save to local storage as backup
        await _saveApiKeyToLocalStorage(apiKey);

        // Update cache
        _cachedApiKey = apiKey;
        _lastCacheTime = DateTime.now();

        notifyListeners();
        return null;
      },
      operationName: 'setApiKey',
    );
  }

  /// Clears the API key from all storages.
  Future<void> clearApiKey() async {
    await executePodOperation(
      operation: () async {
        await _clearApiKeyFromPod();
        await _clearApiKeyFromLocalStorage();

        _cachedApiKey = null;
        _lastCacheTime = null;

        notifyListeners();
        return null;
      },
      operationName: 'clearApiKey',
      requiresLogin: false,
    );
  }

  /// Fetches API key from multiple sources with fallback.
  Future<String?> _fetchApiKey() async {
    return await executePodOperation(
      operation: () async {
        // Check if migration needed
        await _handleLegacyMigration();

        // Try POD first
        String? apiKey = await _getApiKeyFromPod();
        if (apiKey != null) return apiKey;

        // Fallback to local storage
        apiKey = await _getApiKeyFromLocalStorage();
        if (apiKey != null) {
          // Sync to POD for future use
          await _saveApiKeyToPod(apiKey);
          return apiKey;
        }

        return null;
      },
      operationName: 'fetchApiKey',
      requiresLogin: false,
    );
  }

  /// Gets current user's web ID for POD operations.
  Future<String?> _getCurrentUserWebId() async {
    return await executePodOperation(
      operation: () async {
        try {
          return await getWebId();
        } catch (e) {
          logDebug('Failed to get web ID: $e', isError: true);
          return null;
        }
      },
      operationName: 'getCurrentUserWebId',
    );
  }

  /// Retrieves API key from POD storage.
  Future<String?> _getApiKeyFromPod() async {
    final webId = await _getCurrentUserWebId();
    if (webId == null) return null;

    final apiKeyFileName = createApiKeyFileName(webId);
    final content = await safeReadFile('moviestar/data/keys/$apiKeyFileName');

    if (content != null && content.isNotEmpty) {
      return _extractApiKeyFromTtl(content);
    }
    return null;
  }

  /// Saves API key to POD storage.
  Future<bool> _saveApiKeyToPod(String apiKey) async {
    final webId = await _getCurrentUserWebId();
    if (webId == null) return false;

    final apiKeyId = TurtleSerializer.generateId();
    final apiKeyTtl = TurtleSerializer.createApiKey(apiKeyId, apiKey);
    final apiKeyFileName = createApiKeyFileName(webId);

    return await safeWriteFile(
      'moviestar/data/keys/$apiKeyFileName',
      apiKeyTtl,
    );
  }

  /// Retrieves API key from secure local storage.
  Future<String?> _getApiKeyFromLocalStorage() async {
    final webId = await _getCurrentUserWebId();
    if (webId != null) {
      final userKey = '$_userApiKeyPrefix$webId';
      return await _secureStorage.read(key: userKey);
    }
    return null;
  }

  /// Saves API key to secure local storage.
  Future<void> _saveApiKeyToLocalStorage(String apiKey) async {
    final webId = await _getCurrentUserWebId();
    if (webId != null) {
      final userKey = '$_userApiKeyPrefix$webId';
      await _secureStorage.write(key: userKey, value: apiKey);
    }
  }

  /// Clears API key from POD storage.
  Future<void> _clearApiKeyFromPod() async {
    final webId = await _getCurrentUserWebId();
    if (webId != null) {
      final apiKeyFileName = createApiKeyFileName(webId);
      await safeDeleteFile('moviestar/data/keys/$apiKeyFileName');
    }
  }

  /// Clears API key from secure local storage.
  Future<void> _clearApiKeyFromLocalStorage() async {
    final webId = await _getCurrentUserWebId();
    if (webId != null) {
      final userKey = '$_userApiKeyPrefix$webId';
      await _secureStorage.delete(key: userKey);
    }
  }

  /// Handles migration from legacy API key storage.
  Future<void> _handleLegacyMigration() async {
    final migrationComplete =
        await _secureStorage.read(key: _migrationCompleteKey);
    if (migrationComplete == 'true') return;

    final legacyApiKey = await _secureStorage.read(key: _legacyApiKeySecureKey);
    if (legacyApiKey != null) {
      await _migrateLegacyApiKey(legacyApiKey);
      await _secureStorage.write(key: _migrationCompleteKey, value: 'true');
    }
  }

  /// Migrates legacy API key to new user-specific storage.
  Future<void> _migrateLegacyApiKey(String apiKey) async {
    await _saveApiKeyToLocalStorage(apiKey);
    await _saveApiKeyToPod(apiKey);
    await _secureStorage.delete(key: _legacyApiKeySecureKey);
    logDebug('Legacy API key migrated successfully');
  }

  /// Extracts API key value from TTL content.
  String? _extractApiKeyFromTtl(String ttlContent) {
    final keyValuePattern = RegExp(r'moviestar-onto:keyValue\s+"([^"]+)"');
    final match = keyValuePattern.firstMatch(ttlContent);
    return match?.group(1);
  }

  /// Checks if user has an API key configured.
  Future<bool> hasApiKey() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Clears cached API key to force refresh.
  void clearCache() {
    _cachedApiKey = null;
    _lastCacheTime = null;
  }

  /// Debug method to check API key state across all storages.
  Future<void> debugApiKeyState() async {
    logDebug('=== API Key Debug State ===');
    logDebug('Cached: ${_cachedApiKey != null ? 'Yes' : 'No'}');
    logDebug('POD: ${await _getApiKeyFromPod() != null ? 'Yes' : 'No'}');
    logDebug(
      'Local: ${await _getApiKeyFromLocalStorage() != null ? 'Yes' : 'No'}',
    );
    logDebug('========================');
  }

  /// Creates a filename for API key storage based on web ID.
  String createApiKeyFileName(String webId) {
    final hash = webId.hashCode.abs().toString();
    return 'api-key-$hash.ttl';
  }

  /// Updates context for the service (compatibility method).
  void updateContext(BuildContext newContext, [Widget? newChild]) {
    // Context update logic if needed
    logDebug('Context updated for ApiKeyService');
  }
}
