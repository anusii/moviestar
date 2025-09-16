/// Service for managing API keys in the Movie Star application.
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
/// Authors: Kevin Wang

library;

import 'package:flutter/material.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solidpod/solidpod.dart';

import 'package:moviestar/constants/timing_constants.dart';
import 'package:moviestar/services/cache_settings_service.dart';
import 'package:moviestar/utils/is_logged_in.dart';
import 'package:moviestar/utils/pod_path_helper.dart';
import 'package:moviestar/utils/turtle_serializer.dart';

class ApiKeyService extends ChangeNotifier {
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

  BuildContext? _context;
  Widget? _child;
  CacheSettingsService? _cacheSettingsService;
  bool _migrationAttempted = false;

  // Cache the API key fetch to avoid redundant calls.

  String? _cachedApiKey;
  DateTime? _cacheTime;
  static const Duration _cacheDuration =
      NetworkTimingConstants.apiKeyCacheDuration;
  Future<String?>? _pendingFetch;

  ApiKeyService({BuildContext? context, Widget? child})
      : _context = context,
        _child = child {
    _cacheSettingsService = CacheSettingsService.instance;
  }

  /// Updates the context and child for POD operations.

  void updateContext(BuildContext context, Widget child) {
    _context = context;
    _child = child;
  }

  /// Gets whether POD-only mode is enabled (local caching disabled).

  bool get isPodOnlyMode {
    return !(_cacheSettingsService?.localApiKeyCachingEnabled ?? false);
  }

  /// Gets the API key for the current user.
  /// Prioritizes POD storage, falls back to local cache if enabled.

  Future<String?> getApiKey() async {
    // Check if we have a valid cached value.

    if (_cachedApiKey != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedApiKey;
    }

    // If a fetch is already in progress, wait for it to complete.

    if (_pendingFetch != null) {
      return await _pendingFetch;
    }

    // Start a new fetch.

    _pendingFetch = _fetchApiKey();

    try {
      final result = await _pendingFetch;
      _cachedApiKey = result;
      _cacheTime = DateTime.now();
      return result;
    } finally {
      _pendingFetch = null;
    }
  }

  /// Internal method to actually fetch the API key.

  Future<String?> _fetchApiKey() async {
    try {
      // Initialize cache settings if needed.

      await _cacheSettingsService?.initialize();

      final loggedIn = await isLoggedIn();

      // If user is logged in, try to get from POD first.

      if (loggedIn) {
        final podApiKey = await _getApiKeyFromPod();
        if (podApiKey != null) {
          return podApiKey;
        }
      }

      // If POD fails or user not logged in, try local cache (if enabled).

      if (_cacheSettingsService?.localApiKeyCachingEnabled == true) {
        final localApiKey = await _getApiKeyFromLocalStorage();
        if (localApiKey != null) {
          return localApiKey;
        }
      }

      // Check for legacy API key that needs migration (only once per session).

      if (!_migrationAttempted) {
        final legacyApiKey = await _getLegacyApiKey();
        if (legacyApiKey != null && loggedIn && _context != null) {
          _migrationAttempted = true;
          // Migrate legacy key to user's POD.

          await _migrateLegacyApiKey(legacyApiKey);
          return legacyApiKey;
        } else if (legacyApiKey != null) {
          return legacyApiKey; // Return legacy key if not logged in or no context.
        }
      } else {
        // Migration already attempted, just return legacy key if it exists.

        return await _getLegacyApiKey();
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching API key: $e');
      return null;
    }
  }

  /// Sets the API key for the current user.
  /// Saves to POD if logged in, and optionally to local cache if enabled.

  Future<void> setApiKey(String apiKey) async {
    try {
      await _cacheSettingsService?.initialize();

      final loggedIn = await isLoggedIn();
      bool savedToPod = false;

      // Save to POD if user is logged in.

      if (loggedIn) {
        savedToPod = await _saveApiKeyToPod(apiKey);
      }

      // Save to local cache if enabled (or if POD save failed and user is logged in).

      if (_cacheSettingsService?.localApiKeyCachingEnabled == true ||
          !loggedIn) {
        await _saveApiKeyToLocalStorage(apiKey);
      }

      // Clean up legacy storage after successful save.

      if (savedToPod || !loggedIn) {
        await _cleanupLegacyApiKey();
      }

      // Invalidate cache.

      _cachedApiKey = apiKey;
      _cacheTime = DateTime.now();

      notifyListeners();
    } catch (e) {
      debugPrint('Error saving API key: $e');
      rethrow;
    }
  }

  /// Clears the API key for the current user from all storage locations.

  Future<void> clearApiKey() async {
    try {
      final loggedIn = await isLoggedIn();

      // Clear from POD if logged in.

      if (loggedIn) {
        await _clearApiKeyFromPod();
      }

      // Clear from local storage.

      await _clearApiKeyFromLocalStorage();

      // Clear legacy storage.

      await _cleanupLegacyApiKey();

      // Invalidate cache.

      _cachedApiKey = null;
      _cacheTime = null;

      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing API key: $e');
      rethrow;
    }
  }

  // PRIVATE HELPER METHODS

  /// Gets the current user's Web ID.

  Future<String?> _getCurrentUserWebId() async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) return null;
      return await getWebId();
    } catch (e) {
      debugPrint('Error getting current user Web ID: $e');
      return null;
    }
  }

  /// Gets API key from the user's POD.

  Future<String?> _getApiKeyFromPod() async {
    try {
      if (_context == null || _child == null) {
        // Silently return null if context not available - this is expected.

        return null;
      }

      final webId = await _getCurrentUserWebId();
      if (webId == null) return null;

      // Try to read user profile to get API key reference.

      final readPath = await getReadPath('profile/profile.ttl');
      if (_context?.mounted != true) return null;

      final profileContent = await readPod(readPath, _context!, _child!);
      if (profileContent.isEmpty) {
        return null;
      }

      // Extract API key ID from profile.

      final apiKeyMatch = RegExp(r'moviestar-data:ApiKey-([a-zA-Z0-9]+)')
          .firstMatch(profileContent);
      if (apiKeyMatch == null) {
        return null;
      }

      final apiKeyId = apiKeyMatch.group(1)!;

      // Read the actual API key file.

      final apiKeyPath = await getReadPath('keys/ApiKey-$apiKeyId.ttl');
      if (_context?.mounted != true) return null;

      final apiKeyContent = await readPod(apiKeyPath, _context!, _child!);
      if (apiKeyContent.isEmpty) {
        return null;
      }

      // Extract the API key value from TTL (using moviestar-onto namespace).

      final valueMatch = RegExp(r'moviestar-onto:keyValue\s+"([^"]+)"')
          .firstMatch(apiKeyContent);
      final apiKeyValue = valueMatch?.group(1);
      return apiKeyValue;
    } catch (e) {
      // Only log if it's not a "resource doesn't exist" error (which is expected).

      if (!e.toString().contains('does not exist')) {
        debugPrint('Error reading API key from POD: $e');
      }
      return null;
    }
  }

  /// Saves API key to the user's POD.

  Future<bool> _saveApiKeyToPod(String apiKey) async {
    try {
      if (_context == null || _child == null) {
        // Context not available - this is expected in some scenarios.

        return false;
      }

      final webId = await _getCurrentUserWebId();
      if (webId == null) return false;

      // Generate unique ID for the API key.

      final apiKeyId = TurtleSerializer.generateId();

      // Create the API key TTL content.

      final apiKeyTtl = TurtleSerializer.createApiKey(apiKeyId, apiKey);

      // Write API key file to POD.

      if (_context?.mounted != true) return false;
      final apiKeyResult = await writePod(
        'keys/ApiKey-$apiKeyId.ttl',
        apiKeyTtl,
        _context!,
        _child!,
        encrypted: false,
      );

      if (apiKeyResult != SolidFunctionCallStatus.success) {
        debugPrint('Failed to write API key file to POD');
        return false;
      }

      // Read existing profile to preserve other data.

      String? existingProfile;
      try {
        final readPath = await getReadPath('profile/profile.ttl');
        if (_context?.mounted == true) {
          existingProfile = await readPod(readPath, _context!, _child!);
        }
      } catch (e) {
        // Expected for new users
      }

      // Create or update user profile with API key reference.

      String profileTtl;
      if (existingProfile != null && existingProfile.isNotEmpty) {
        // Update existing profile by replacing or adding API key reference.

        final updatedProfile = existingProfile.replaceAllMapped(
          RegExp(r'moviestar-data:ApiKey-[a-zA-Z0-9]+'),
          (match) => 'moviestar-data:ApiKey-$apiKeyId',
        );

        // If no existing API key was found, add it.

        if (!updatedProfile.contains('moviestar-data:ApiKey-')) {
          profileTtl = updatedProfile.replaceFirst(
            RegExp(r'(\s*\.\s*)$'),
            ' ;\n    moviestar:apiKey moviestar-data:ApiKey-$apiKeyId .\n',
          );
        } else {
          profileTtl = updatedProfile;
        }
      } else {
        // Create new profile.

        profileTtl = TurtleSerializer.createUserProfile(
          webId,
          apiKey: apiKeyId,
        );
      }

      if (_context?.mounted != true) return false;
      final profileResult = await writePod(
        'profile/profile.ttl',
        profileTtl,
        _context!,
        _child!,
        encrypted: false,
      );

      if (profileResult == SolidFunctionCallStatus.success) {
        return true;
      } else {
        debugPrint('❌ Failed to write profile with API key reference to POD');
        return false;
      }
    } catch (e) {
      debugPrint('Error saving API key to POD: $e');
      return false;
    }
  }

  /// Gets API key from local user-specific storage.

  Future<String?> _getApiKeyFromLocalStorage() async {
    try {
      final webId = await _getCurrentUserWebId();
      if (webId == null) return null;

      final userKey = '$_userApiKeyPrefix${webId.hashCode}';
      return await _secureStorage.read(key: userKey);
    } catch (e) {
      debugPrint('Error reading API key from local storage: $e');
      return null;
    }
  }

  /// Saves API key to local user-specific storage.

  Future<void> _saveApiKeyToLocalStorage(String apiKey) async {
    try {
      final webId = await _getCurrentUserWebId();
      if (webId != null) {
        // Save with user-specific key.

        final userKey = '$_userApiKeyPrefix${webId.hashCode}';
        await _secureStorage.write(key: userKey, value: apiKey);
      } else {
        // Fall back to legacy key if not logged in.

        await _secureStorage.write(key: _legacyApiKeySecureKey, value: apiKey);
      }
    } catch (e) {
      debugPrint('Error writing API key to local storage: $e');
      rethrow;
    }
  }

  /// Clears API key from local storage.

  Future<void> _clearApiKeyFromLocalStorage() async {
    try {
      final webId = await _getCurrentUserWebId();
      if (webId != null) {
        final userKey = '$_userApiKeyPrefix${webId.hashCode}';
        await _secureStorage.delete(key: userKey);
      }
    } catch (e) {
      debugPrint('Error clearing API key from local storage: $e');
    }
  }

  /// Clears API key from the user's POD.

  Future<void> _clearApiKeyFromPod() async {
    try {
      if (_context == null || _child == null) return;

      // This is a simplified version - in practice, you'd want to:
      // 1. Read the profile to get the API key ID
      // 2. Delete the specific API key file
      // 3. Update the profile to remove the API key reference

      // For now, we'll just update the profile to remove the API key reference.

      final webId = await _getCurrentUserWebId();
      if (webId == null) return;

      final profileTtl = TurtleSerializer.createUserProfile(webId);

      if (_context?.mounted == true) {
        await writePod(
          'profile/profile.ttl',
          profileTtl,
          _context!,
          _child!,
          encrypted: false,
        );
      }
    } catch (e) {
      debugPrint('Error clearing API key from POD: $e');
    }
  }

  /// Gets legacy API key from device-level storage.

  Future<String?> _getLegacyApiKey() async {
    try {
      return await _secureStorage.read(key: _legacyApiKeySecureKey);
    } catch (e) {
      debugPrint('Error reading legacy API key: $e');
      return null;
    }
  }

  /// Migrates legacy API key to current user's POD.

  Future<void> _migrateLegacyApiKey(String apiKey) async {
    try {
      // Check if migration was already completed for this user.

      final webId = await _getCurrentUserWebId();
      if (webId != null) {
        final migrationKey = '$_migrationCompleteKey${webId.hashCode}';
        final migrationComplete = await _secureStorage.read(key: migrationKey);
        if (migrationComplete == 'true') {
          return; // Migration already completed for this user.
        }
      }

      final success = await _saveApiKeyToPod(apiKey);
      if (success) {
        await _cleanupLegacyApiKey();
        // Mark migration as complete for this user.

        if (webId != null) {
          final migrationKey = '$_migrationCompleteKey${webId.hashCode}';
          await _secureStorage.write(key: migrationKey, value: 'true');
        }
      }
    } catch (e) {
      debugPrint('Error migrating legacy API key: $e');
    }
  }

  /// Removes the legacy device-level API key.

  Future<void> _cleanupLegacyApiKey() async {
    try {
      await _secureStorage.delete(key: _legacyApiKeySecureKey);
    } catch (e) {
      debugPrint('Error cleaning up legacy API key: $e');
    }
  }

  /// Adds a method to help debug the current state (for development).

  Future<void> debugApiKeyState() async {
    try {
      debugPrint('🔍 === API Key Debug State ===');

      final podApiKey = await _getApiKeyFromPod();
      debugPrint(
        '🌐 POD API key: ${podApiKey != null ? "[${podApiKey.length} chars]" : "null"}',
      );

      final localApiKey = await _getApiKeyFromLocalStorage();
      debugPrint(
        '💻 Local API key: ${localApiKey != null ? "[${localApiKey.length} chars]" : "null"}',
      );

      final legacyApiKey = await _getLegacyApiKey();
      debugPrint(
        '👴 Legacy API key: ${legacyApiKey != null ? "[${legacyApiKey.length} chars]" : "null"}',
      );

      debugPrint('🔍 === End Debug State ===');
    } catch (e) {
      debugPrint('Error in debug: $e');
    }
  }
}
