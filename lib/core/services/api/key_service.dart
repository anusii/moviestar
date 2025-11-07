/// Compact ApiKeyService using BasePodService infrastructure.
/// Reduced from 575 to ~280 lines by using BasePodService patterns.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'package:flutter/material.dart'; // ignore: unused_import
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solidpod/solidpod.dart' show getWebId;

import 'package:moviestar/core/services/pod/base_pod_service.dart';
import 'package:moviestar/utils/serializer.dart';

/// Compact service for managing API keys with POD and secure storage.
/// Uses BasePodService infrastructure for common POD operations.

class ApiKeyService extends BasePodService {
  static const String _legacyApiKeySecureKey = 'movie_db_api_key';
  static const String _userApiKeyPrefix = 'user_api_key_';
  static const String _migrationCompleteKey = 'api_key_migration_complete';
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: MacOsOptions(synchronizable: false),
    webOptions: WebOptions(),
  );

  String? _cachedApiKey;
  DateTime? _lastCacheTime;

  ApiKeyService(super.context, super.child);

  /// Gets the API key from cache, POD, or secure storage.

  Future<String?> getApiKey() async {
    // Return cached value if valid.

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

  /// Sets the API key in POD storage only.

  Future<void> setApiKey(String apiKey) async {
    await executePodOperation(
      operation: () async {
        // Save to POD only - API keys are shared across devices.

        await _saveApiKeyToPod(apiKey);

        // Update cache.

        _cachedApiKey = apiKey;
        _lastCacheTime = DateTime.now();

        notifyListeners();
        return null;
      },
      operationName: 'setApiKey',
    );
  }

  /// Clears the API key from POD storage.

  Future<void> clearApiKey() async {
    await executePodOperation(
      operation: () async {
        await _clearApiKeyFromPod();

        _cachedApiKey = null;
        _lastCacheTime = null;

        notifyListeners();
        return null;
      },
      operationName: 'clearApiKey',
      requiresLogin: false,
    );
  }

  /// Fetches API key from POD only.

  Future<String?> _fetchApiKey() async {
    return await executePodOperation(
      operation: () async {
        // Check if migration needed (migrate from legacy local storage to POD).

        await _handleLegacyMigration();

        // Read from POD only.

        return await _getApiKeyFromPod();
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

  /// Handles migration from legacy local storage to POD-only storage.

  Future<void> _handleLegacyMigration() async {
    final migrationComplete =
        await _secureStorage.read(key: _migrationCompleteKey);
    if (migrationComplete == 'true') return;

    // Migrate from old legacy key.

    final legacyApiKey = await _secureStorage.read(key: _legacyApiKeySecureKey);
    if (legacyApiKey != null) {
      await _migrateLegacyApiKey(legacyApiKey);
    }

    // Also migrate from user-specific local storage key.

    final userApiKey = await _getApiKeyFromLocalStorage();
    if (userApiKey != null) {
      await _migrateLegacyApiKey(userApiKey);
    }

    await _secureStorage.write(key: _migrationCompleteKey, value: 'true');
  }

  /// Migrates legacy API key from local storage to POD.

  Future<void> _migrateLegacyApiKey(String apiKey) async {
    await _saveApiKeyToPod(apiKey);
    await _secureStorage.delete(key: _legacyApiKeySecureKey);
    await _clearApiKeyFromLocalStorage();
    logDebug('Legacy API key migrated to POD successfully');
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
}
