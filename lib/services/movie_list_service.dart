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
}
