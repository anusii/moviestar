/// Service for managing user profiles in the Movie Star application following the ontology structure.
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
/// Authors: Ashley Tang.

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:moviestar/core/services/api/key_service.dart';
import 'package:moviestar/core/services/pod/file_operations_service.dart';
import 'package:moviestar/utils/is_logged_in.dart';
import 'package:moviestar/utils/pod_path_helper.dart';
import 'package:moviestar/utils/serializer.dart';

/// Service for managing user profiles in the POD following the ontology structure.

class UserProfileService {
  // Widget context for POD operations.

  final BuildContext _context;

  // Widget for returning after operations.

  final Widget _child;

  // Cache for user profile data.

  Map<String, dynamic>? _cachedProfile;

  // Creates a new [UserProfileService] instance.

  UserProfileService(this._context, this._child);

  /// Gets the current user's web ID.

  Future<String?> getCurrentUserWebId() async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) return null;

      // Get the web ID from the POD.

      final webId = await getWebId();
      return webId;
    } catch (e) {
      return null;
    }
  }

  /// Creates or updates the user profile following the ontology structure.

  Future<bool> createOrUpdateUserProfile({
    String? apiKey,
    String? dobString,
    String? genderString,
    List<String>? movieListIds,
  }) async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        return false;
      }

      final webId = await getCurrentUserWebId();
      if (webId == null) {
        return false;
      }

      // First, try to load existing profile data to reuse existing resources.

      final existingProfileData = await _loadExistingProfile();

      // Get API key from secure storage if not provided.

      String? actualApiKey = apiKey;
      if (actualApiKey == null) {
        if (!_context.mounted) return false;
        final apiKeyService = ApiKeyService(_context, _child);
        actualApiKey = await apiKeyService.getApiKey();
        if (!_context.mounted) return false;
      }

      // Use existing API key ID if available, otherwise create new one.

      String? apiKeyFileId = existingProfileData?['apiKeyId'];
      if (apiKeyFileId == null &&
          actualApiKey != null &&
          actualApiKey.isNotEmpty) {
        apiKeyFileId = await _createApiKeyFile(actualApiKey);
      }

      // Merge existing MovieList IDs with any new ones provided.

      final existingMovieListIds =
          existingProfileData?['movieListIds'] as List<String>? ?? [];
      final providedMovieListIds = movieListIds ?? [];

      // Combine and deduplicate MovieList IDs.

      final allMovieListIds = <String>{};
      allMovieListIds.addAll(existingMovieListIds);
      allMovieListIds.addAll(providedMovieListIds);
      final finalMovieListIds = allMovieListIds.toList();

      // Create the profile TTL content.

      final profileTtl = TurtleSerializer.createUserProfile(
        webId,
        apiKey: apiKeyFileId,
        dobString: dobString,
        genderString: genderString,
        movieListIds: finalMovieListIds,
      );

      // Write to POD profile.

      if (!_context.mounted) return false;
      final result = await PodFileOperationsService.writeFile(
        'profile/profile.ttl',
        profileTtl,
        _context,
        _child,
        encrypted: false,
      );

      if (result.success) {
        // Update cache.

        _cachedProfile = {
          'webId': webId,
          'apiKey': actualApiKey,
          'apiKeyId': apiKeyFileId,
          'dob': dobString,
          'gender': genderString,
          'movieListIds': finalMovieListIds,
        };
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Creates an API key file in the POD and returns the generated ID.
  /// First checks if an API key file with the same value already exists.

  Future<String?> _createApiKeyFile(String apiKeyValue) async {
    try {
      // First, check if an API key file already exists with this value.

      final existingApiKeyId = await _findExistingApiKeyFile(apiKeyValue);
      if (existingApiKeyId != null) {
        return existingApiKeyId;
      }

      // Generate a unique ID for the new API key.

      final apiKeyId = TurtleSerializer.generateId();

      // Create the API key TTL content.

      final apiKeyTtl = TurtleSerializer.createApiKey(apiKeyId, apiKeyValue);

      // Write to POD.

      if (!_context.mounted) return null;
      final result = await PodFileOperationsService.writeFile(
        'keys/ApiKey-$apiKeyId.ttl',
        apiKeyTtl,
        _context,
        _child,
        encrypted: false,
      );

      if (result.success) {
        return apiKeyId;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Finds an existing API key file with the given value.
  // Returns the API key ID if found, null otherwise.

  Future<String?> _findExistingApiKeyFile(String apiKeyValue) async {
    try {
      // First check cache for quick lookup.

      if (_cachedProfile != null && _cachedProfile!['apiKeyId'] != null) {
        final cachedId = _cachedProfile!['apiKeyId'];
        return cachedId;
      }

      // TODO: In a full implementation, we would scan the keys/ directory
      // For now, we can check a few common patterns or implement a simple cache
      // This would require listing directory contents which isn't directly supported
      // by the current POD API. A proper implementation would:
      // 1. Maintain an index file of API keys
      // 2. Or scan the keys directory for existing files
      // 3. Or store the API key ID in the user profile and read it back

      return null;
    } catch (e) {
      return null;
    }
  }

  // Loads existing profile data and extracts API key and MovieList references.

  Future<Map<String, dynamic>?> _loadExistingProfile() async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        return null;
      }

      if (!_context.mounted) return null;

      final readPath = await getReadPath('profile/profile.ttl');
      if (!_context.mounted) return null;
      final result =
          await PodFileOperationsService.readFile(readPath, _context, _child);

      if (result.success && (result.data?.isNotEmpty ?? false)) {
        final content = result.data!;
        // Parse the TTL content to extract API key and MovieList references.
        // Note: The TTL now uses static prefixes (moviestar-data:) to match ontology structure.

        final apiKeyMatch = RegExp(
          r'moviestar-data:ApiKey-([a-zA-Z0-9]+)',
        ).firstMatch(content);
        final movieListMatches = RegExp(
          r'moviestar-data:MovieList-([a-zA-Z0-9]+)',
        ).allMatches(content);

        final extractedData = <String, dynamic>{};

        if (apiKeyMatch != null) {
          extractedData['apiKeyId'] = apiKeyMatch.group(1);
        }

        if (movieListMatches.isNotEmpty) {
          extractedData['movieListIds'] =
              movieListMatches.map((m) => m.group(1)!).toList();
        }

        return extractedData;
      }

      return null;
    } catch (e) {
      if (!e.toString().contains('does not exist')) {}
      return null;
    }
  }

  /// Gets the user profile data.

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      // First check cache.

      if (_cachedProfile != null) {
        return _cachedProfile;
      }

      final loggedIn = await isLoggedIn();
      if (!loggedIn) return null;

      // Try to read profile from POD.

      if (!_context.mounted) return null;
      try {
        final readPath = await getReadPath('profile/profile.ttl');
        if (!_context.mounted) return null;

        final result =
            await PodFileOperationsService.readFile(readPath, _context, _child);

        if (result.success && (result.data?.isNotEmpty ?? false)) {
          final content = result.data!;
          // Parse the profile data properly, including MovieList IDs.

          final webId = await getCurrentUserWebId();
          if (webId != null) {
            // Extract MovieList IDs from profile TTL.

            final movieListMatches = RegExp(
              r'moviestar-data:MovieList-([a-zA-Z0-9]+)',
            ).allMatches(content);
            final movieListIds =
                movieListMatches.map((m) => m.group(1)!).toList();

            _cachedProfile = {
              'webId': webId,
              'apiKey': null,
              'dob': null,
              'gender': null,
              'movieListIds': movieListIds,
            };
            return _cachedProfile;
          }
        } else {}
      } catch (e) {
        if (!e.toString().contains('does not exist')) {
        } else {}
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Adds a movie list ID to the user profile.

  Future<bool> addMovieListToProfile(String movieListId) async {
    try {
      var profile = await getUserProfile();
      if (profile == null) {
        // Create a basic profile first
        final created = await createOrUpdateUserProfile();
        if (created) {
          profile = await getUserProfile();
        }
        if (profile == null) {
          return false;
        }
      }

      final movieListIds = List<String>.from(profile['movieListIds'] ?? []);

      if (!movieListIds.contains(movieListId)) {
        movieListIds.add(movieListId);

        final success = await createOrUpdateUserProfile(
          apiKey: profile['apiKey'],
          dobString: profile['dob'],
          genderString: profile['gender'],
          movieListIds: movieListIds,
        );
        return success;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Removes a movie list ID from the user profile.

  Future<bool> removeMovieListFromProfile(String movieListId) async {
    try {
      final profile = await getUserProfile();
      if (profile == null) return false;

      final movieListIds = List<String>.from(profile['movieListIds'] ?? []);
      if (movieListIds.contains(movieListId)) {
        movieListIds.remove(movieListId);

        return await createOrUpdateUserProfile(
          apiKey: profile['apiKey'],
          dobString: profile['dob'],
          genderString: profile['gender'],
          movieListIds: movieListIds,
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Initializes the user profile if it doesn't exist.

  Future<bool> initializeProfileIfNeeded() async {
    try {
      final profile = await getUserProfile();
      if (profile == null) {
        // Create a basic profile.

        return await createOrUpdateUserProfile();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clears the cached profile data.

  void clearCache() {
    _cachedProfile = null;
  }
}
