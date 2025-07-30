/// Service for managing MovieList entities in the Movie Star application following the ontology structure.
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

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/user_profile_service.dart';
import 'package:moviestar/utils/is_logged_in.dart';
import 'package:moviestar/utils/turtle_serializer.dart';

/// Service for managing MovieList entities in the POD following the ontology structure.

class MovieListService {
  // Widget context for POD operations.

  final BuildContext _context;

  // Widget for returning after operations.

  final Widget _child;

  // User profile service for updating user profile connections.

  final UserProfileService _userProfileService;

  // Cache for movie lists.

  final Map<String, Map<String, dynamic>> _movieListCache = {};

  /// Creates a new [MovieListService] instance.

  MovieListService(this._context, this._child, this._userProfileService);

  /// Creates a new MovieList with the given name and movies.

  Future<String?> createMovieList(String listName,
      {List<Movie>? movies, String? description}) async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        debugPrint('❌ User not logged in, cannot create movie list');
        return null;
      }

      // Generate unique ID for the movie list.

      final movieListId = TurtleSerializer.generateId();

      // Create the MovieList TTL content.

      final movieListTtl = TurtleSerializer.createMovieList(
        movieListId,
        listName,
        movies: movies,
        description: description,
      );

      // Write to POD.

      if (!_context.mounted) return null;
      final result = await writePod(
        'user_lists/MovieList-$movieListId.ttl',
        movieListTtl,
        _context,
        _child,
        encrypted: false,
      );

      if (result == SolidFunctionCallStatus.success) {
        // Update cache.

        _movieListCache[movieListId] = {
          'id': movieListId,
          'name': listName,
          'movies': movies ?? [],
          'filePath':
              'moviestar/data/user_lists/MovieList-$movieListId.ttl', // Use correct user_lists path
        };

        // Add to user profile.

        final profileUpdated =
            await _userProfileService.addMovieListToProfile(movieListId);
        if (!profileUpdated) {
          debugPrint('❌ Failed to add movie list to user profile');
        }

        return movieListId;
      }

      debugPrint('❌ Failed to write movie list to POD');
      return null;
    } catch (e) {
      debugPrint('❌ Exception in create movie list: $e');
      return null;
    }
  }

  /// Gets a MovieList by ID.

  Future<Map<String, dynamic>?> getMovieList(String movieListId,
      {bool forceRefresh = false}) async {
    try {
      // Force refresh bypasses cache.

      if (!forceRefresh && _movieListCache.containsKey(movieListId)) {
        return _movieListCache[movieListId];
      }

      final loggedIn = await isLoggedIn();
      if (!loggedIn) return null;

      // Try to read from POD.

      if (!_context.mounted) return null;
      try {
        // Read directly without getReadPath to avoid double path prefix.

        if (!_context.mounted) return null;
        final result = await readPod(
            'moviestar/data/user_lists/MovieList-$movieListId.ttl',
            _context,
            _child);

        if (result.isNotEmpty) {
          // Parse the MovieList data using TurtleSerializer.

          final movieListData = TurtleSerializer.movieListFromTurtle(result);

          if (movieListData != null) {
            // Update cache with parsed data.

            _movieListCache[movieListId] = movieListData;
            return movieListData;
          } else {
            debugPrint('❌ Failed to parse MovieList TTL content');
          }
        } else {
          debugPrint('❌ MovieList file is empty or not found');
        }
      } catch (e) {
        debugPrint('❌ Failed to read MovieList from POD: $e');
      }

      return null;
    } catch (e) {
      debugPrint('❌ Failed to get movie list: $e');
      return null;
    }
  }

  /// Forces a refresh of a specific MovieList from POD.

  Future<Map<String, dynamic>?> refreshMovieList(String movieListId) async {
    return await getMovieList(movieListId, forceRefresh: true);
  }

  /// Adds a movie to a MovieList.

  Future<bool> addMovieToList(String movieListId, Movie movie) async {
    try {
      final movieList = await getMovieList(movieListId);
      if (movieList == null) {
        debugPrint('❌ MovieList $movieListId not found');
        return false;
      }

      final currentMovies = List<Movie>.from(movieList['movies'] ?? []);

      // Check if movie is already in the list.

      final existingIndex = currentMovies.indexWhere((m) => m.id == movie.id);
      if (existingIndex >= 0) {
        return true;
      }

      currentMovies.add(movie);

      // Update the MovieList.

      final updatedTtl = TurtleSerializer.createMovieList(
        movieListId,
        movieList['name'],
        movies: currentMovies,
      );

      if (!_context.mounted) return false;
      final result = await writePod(
        'user_lists/MovieList-$movieListId.ttl',
        updatedTtl,
        _context,
        _child,
        encrypted: false,
      );

      if (result == SolidFunctionCallStatus.success) {
        // Update cache with new data.

        _movieListCache[movieListId] = {
          'id': movieListId,
          'name': movieList['name'],
          'movies': currentMovies,
          'filePath': movieList['filePath'],
        };
        return true;
      }

      debugPrint('❌ Failed to write updated MovieList to POD');
      return false;
    } catch (e) {
      debugPrint('❌ Failed to add movie to list: $e');
      return false;
    }
  }

  /// Removes a movie from a MovieList.

  Future<bool> removeMovieFromList(String movieListId, Movie movie) async {
    try {
      final movieList = await getMovieList(movieListId);
      if (movieList == null) return false;

      final currentMovies = List<Movie>.from(movieList['movies'] ?? []);

      // Check if movie exists before trying to remove.

      final existingIndex = currentMovies.indexWhere((m) => m.id == movie.id);
      if (existingIndex < 0) {
        return true;
      }

      // Remove the movie.

      currentMovies.removeWhere((m) => m.id == movie.id);

      // Update the MovieList.

      final updatedTtl = TurtleSerializer.createMovieList(
        movieListId,
        movieList['name'],
        movies: currentMovies,
      );

      if (!_context.mounted) return false;
      final result = await writePod(
        'user_lists/MovieList-$movieListId.ttl',
        updatedTtl,
        _context,
        _child,
        encrypted: false,
      );

      if (result == SolidFunctionCallStatus.success) {
        // Update cache with new data.

        _movieListCache[movieListId] = {
          'id': movieListId,
          'name': movieList['name'],
          'movies': currentMovies,
          'filePath': movieList['filePath'],
        };
        return true;
      }

      debugPrint('❌ Failed to write updated MovieList to POD');
      return false;
    } catch (e) {
      debugPrint('❌ Failed to remove movie from list: $e');
      return false;
    }
  }

  /// Gets or creates a standard MovieList (e.g. "to_watch", "watched").

  Future<String?> getOrCreateStandardMovieList(String listType) async {
    try {
      final profile = await _userProfileService.getUserProfile();
      if (profile == null) {
        debugPrint(
            '❌ No user profile found, cannot create standard movie list');
        return null;
      }

      final displayName = listType
          .replaceAll('_', ' ')
          .split(' ')
          .map((word) =>
              word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
          .join(' ');

      // Check if a standard list of this type already exists in the user profile.

      final existingMovieListIds =
          profile['movieListIds'] as List<String>? ?? [];

      for (final movieListId in existingMovieListIds) {
        // Try to read the existing MovieList to check its name/type.

        try {
          if (!_context.mounted) continue;
          // Read directly without getReadPath to avoid double path prefix.

          final result = await readPod(
              'moviestar/data/user_lists/MovieList-$movieListId.ttl',
              _context,
              _child);

          if (result.isNotEmpty) {
            // Robust check: look for the specific sdo:name pattern in TTL.
            // Check for both quoted strings and the expected list type descriptions.

            final namePattern = RegExp(r'sdo:name\s+"([^"]+)"');
            final descPattern = RegExp(r'sdo:description\s+"([^"]+)"');

            final nameMatch = namePattern.firstMatch(result);
            final descMatch = descPattern.firstMatch(result);

            if (nameMatch != null) {
              final foundName = nameMatch.group(1)!.trim();

              // Direct name match.

              if (foundName == displayName) {
                return movieListId;
              }
            }

            if (descMatch != null) {
              final foundDesc = descMatch.group(1)!.trim();

              // Check description patterns for different list types.

              final isToWatchList = foundDesc.contains('want to watch') ||
                  foundDesc.contains('to watch');
              final isWatchedList = foundDesc.contains('have watched') ||
                  foundDesc.contains('you watched');
              final isFavoritesList = foundDesc.contains('favorite');

              if ((listType == 'to_watch' && isToWatchList) ||
                  (listType == 'watched' && isWatchedList) ||
                  (listType == 'favorites' && isFavoritesList)) {
                return movieListId;
              }
            }
          }
        } catch (e) {
          debugPrint('❌ Error checking existing MovieList $movieListId: $e');
          continue;
        }
      }

      // Generate appropriate description for standard lists.

      String description;
      switch (listType) {
        case 'to_watch':
          description = 'List of movies you want to watch';
          break;
        case 'watched':
          description = 'List of movies you have watched';
          break;
        case 'favorites':
          description = 'List of your favorite movies';
          break;
        default:
          description = 'List of movies: $displayName';
      }

      // No existing list found, create a new one.

      final listId = await createMovieList(
        displayName,
        movies: [],
        description: description,
      );

      if (listId == null) {
        debugPrint('❌ Failed to create standard movie list: $listType');
      }

      return listId;
    } catch (e) {
      debugPrint('❌ Exception in get/create standard movie list: $e');
      return null;
    }
  }

  /// Deletes a MovieList.

  Future<bool> deleteMovieList(String movieListId) async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) return false;

      // Remove from user profile first.

      try {
        await _userProfileService.removeMovieListFromProfile(movieListId);
      } catch (e) {
        debugPrint('❌ Failed to remove movie list from profile: $e');
        // Continue with deletion even if profile update fails.
      }

      // Delete from POD.

      if (!_context.mounted) return false;

      await deleteFile('moviestar/data/user_lists/MovieList-$movieListId.ttl');

      // Remove from cache.

      _movieListCache.remove(movieListId);
      return true;
    } catch (e) {
      debugPrint('❌ Failed to delete movie list: $e');
      return false;
    }
  }

  /// Clears the cache.

  void clearCache() {
    _movieListCache.clear();
  }

  // SHARING METHODS.

  /// Shares a MovieList with another user using GrantPermissionUi.
  ///
  /// Returns true if the sharing was successful.

  Future<bool> shareMovieList(
    String listId,
    String recipientWebId,
    List<String> permissions, {
    String? customTitle,
  }) async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        debugPrint('❌ User not logged in, cannot share movie list');
        return false;
      }

      // Check if the list exists.

      final movieList = await getMovieList(listId);
      if (movieList == null) {
        debugPrint('❌ MovieList $listId not found, cannot share');
        return false;
      }

      // Get the relative file path for sharing.

      final filePath = 'user_lists/MovieList-$listId.ttl';
      final listName = movieList['name'] ?? 'Movie List';

      if (!_context.mounted) return false;

      // Navigate to GrantPermissionUi for sharing.

      await Navigator.push(
        _context,
        MaterialPageRoute(
          builder: (context) => Theme(
            data: Theme.of(context),
            child: GrantPermissionUi(
              fileName: filePath,
              title: customTitle ?? 'Share "$listName"',
              accessModeList: permissions,
              recipientTypeList: const ['indi'],
              showAppBar: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: _child,
            ),
          ),
        ),
      );

      return true;
    } catch (e) {
      debugPrint('❌ Failed to share movie list: $e');
      return false;
    }
  }

  /// Gets movie lists that have been shared with the current user.
  ///
  /// Returns a map where keys are list URLs and values contain list metadata.

  Future<Map<String, dynamic>> getSharedLists() async {
    try {
      if (!_context.mounted) return {};

      // Get shared resources from POD.

      final sharedResourcesResult = await sharedResources(_context, _child);

      if (sharedResourcesResult == SolidFunctionCallStatus.notLoggedIn) {
        debugPrint('❌ User not logged in to POD');
        return {};
      }

      if (sharedResourcesResult is! Map) {
        debugPrint('❌ Invalid shared resources data');
        return {};
      }

      final Map<String, dynamic> sharedLists = {};

      // Filter for MovieList files and fetch their content.

      for (final entry in sharedResourcesResult.entries) {
        final resourceUrl = entry.key as String;
        final resourceInfo = entry.value as Map;

        // Check if this is a MovieList file.

        if (resourceUrl.contains('/user_lists/') &&
            resourceUrl.contains('MovieList-') &&
            resourceUrl.endsWith('.ttl')) {
          try {
            if (!_context.mounted) break;

            // Read the MovieList file content.

            final listContent =
                await readExternalPod(resourceUrl, _context, _child);

            if (listContent != null && listContent.isNotEmpty) {
              // Parse the TTL content.

              final parsedList =
                  TurtleSerializer.movieListFromTurtle(listContent);

              if (parsedList != null) {
                sharedLists[resourceUrl] = {
                  ...parsedList,
                  'resourceUrl': resourceUrl,
                  'resourceInfo': resourceInfo,
                  'listContent': listContent,
                  'isSharedWithMe': true,
                };
              }
            }
          } catch (e) {
            debugPrint('⚠️ Could not read shared MovieList $resourceUrl: $e');
          }
        }
      }

      return sharedLists;
    } catch (e) {
      debugPrint('❌ Failed to get shared lists: $e');
      return {};
    }
  }

  /// Gets movie lists that the current user has shared with others.
  ///
  /// Returns a map where keys are list IDs and values contain list metadata and sharing info.

  Future<Map<String, dynamic>> getMySharedLists() async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) return {};

      // Get current user's WebID to construct the user_lists directory URL.

      final currentWebId = await getWebId();
      if (currentWebId == null) return {};

      final webIdWithoutCard = currentWebId.replaceAll('/profile/card#me', '');
      final userListsDir = '$webIdWithoutCard/moviestar/data/user_lists/';

      // Get resources in the user_lists container.

      final resources = await getResourcesInContainer(userListsDir);
      final Map<String, dynamic> mySharedLists = {};

      // Process each MovieList file.

      for (final fileName in resources.files) {
        if (!fileName.endsWith('.ttl') || !fileName.contains('MovieList-')) {
          continue;
        }

        // Extract list ID from filename.

        final listIdMatch =
            RegExp(r'MovieList-(\w+)\.ttl').firstMatch(fileName);
        if (listIdMatch == null) continue;

        final listId = listIdMatch.group(1)!;

        try {
          // Get the movie list.

          final movieList = await getMovieList(listId);
          if (movieList == null) continue;

          // Check if this list has sharing metadata.

          final sharedWith = movieList['sharedWith'] as Map<String, String>?;

          if (sharedWith != null && sharedWith.isNotEmpty) {
            mySharedLists[listId] = {
              ...movieList,
              'fileName': fileName,
              'resourceUrl': '$userListsDir$fileName',
              'isMySharedList': true,
            };
          }
        } catch (e) {
          debugPrint('⚠️ Could not check sharing status for list $listId: $e');
        }
      }

      return mySharedLists;
    } catch (e) {
      debugPrint('❌ Failed to get my shared lists: $e');
      return {};
    }
  }

  /// Revokes access to a MovieList for a specific user.
  ///
  /// Returns true if the revocation was successful.

  Future<bool> revokeListAccess(String listId, String webId) async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        debugPrint('❌ User not logged in, cannot revoke access');
        return false;
      }

      // Get the movie list.

      final movieList = await getMovieList(listId);
      if (movieList == null) {
        debugPrint('❌ MovieList $listId not found');
        return false;
      }

      // Get current sharing metadata.

      final sharedWith =
          Map<String, String>.from(movieList['sharedWith'] ?? {});

      if (!sharedWith.containsKey(webId)) {
        debugPrint(
            '⚠️ WebId $webId not found in shared users for list $listId');
        return true; // Already not shared with this user.
      }

      // Remove the user from shared metadata.

      sharedWith.remove(webId);

      // Update the MovieList with new sharing metadata.

      final updatedTtl = TurtleSerializer.createMovieList(
        listId,
        movieList['name'],
        movies: List<Movie>.from(movieList['movies'] ?? []),
        description: movieList['description'],
        sharedWith: sharedWith.isNotEmpty ? sharedWith : null,
        sharedDate: sharedWith.isNotEmpty ? movieList['sharedDate'] : null,
      );

      if (!_context.mounted) return false;
      final result = await writePod(
        'user_lists/MovieList-$listId.ttl',
        updatedTtl,
        _context,
        _child,
        encrypted: false,
      );

      if (result == SolidFunctionCallStatus.success) {
        // Update cache.

        _movieListCache[listId] = {
          ...movieList,
          'sharedWith': sharedWith.isNotEmpty ? sharedWith : null,
          'sharedDate': sharedWith.isNotEmpty ? movieList['sharedDate'] : null,
        };

        // Note: POD permission revocation should be handled by the POD system
        // when the resource metadata is updated.

        return true;
      } else {
        debugPrint('❌ Failed to update MovieList after revoking access');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Failed to revoke list access: $e');
      return false;
    }
  }

  /// Validates if a user can access a specific MovieList.
  ///
  /// Returns the permission level ('read', 'write', 'control') or null if no access.

  Future<String?> validateUserAccess(String listId, String webId) async {
    try {
      final movieList = await getMovieList(listId);
      if (movieList == null) return null;

      // Check if the user is the owner (can get the list means they have some access).

      final currentWebId = await getWebId();
      if (currentWebId == webId) {
        return 'control'; // Owner has full control.
      }

      // Check sharing metadata.

      final sharedWith = movieList['sharedWith'] as Map<String, String>?;
      if (sharedWith != null && sharedWith.containsKey(webId)) {
        return sharedWith[webId]; // Return the specific permission level.
      }

      return null; // No access
    } catch (e) {
      debugPrint('❌ Failed to validate user access: $e');
      return null;
    }
  }

  /// Checks if the current user can perform a specific operation on a MovieList.
  ///
  /// Operations: 'read', 'write', 'delete', 'share'

  Future<bool> canUserPerformOperation(String listId, String operation) async {
    try {
      final currentWebId = await getWebId();
      if (currentWebId == null) return false;

      final permission = await validateUserAccess(listId, currentWebId);
      if (permission == null) return false;

      // Map operations to required permission levels.

      switch (operation.toLowerCase()) {
        case 'read':
          return ['read', 'write', 'control'].contains(permission);
        case 'write':
        case 'add':
        case 'remove':
          return ['write', 'control'].contains(permission);
        case 'delete':
        case 'share':
          return permission == 'control';
        default:
          return false;
      }
    } catch (e) {
      debugPrint('❌ Failed to check user permissions: $e');
      return false;
    }
  }
}
