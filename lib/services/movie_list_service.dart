/// Service for managing MovieList entities in the Movie Star application following the ontology structure.
///
// Copyright (C) 2025, Software Innovation Institute, ANU.
//
// Licensed under the GNU General Public License, Version 3 (the "License").
//
// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';
import 'package:solidpod/solidpod.dart';
import 'package:moviestar/utils/turtle_serializer.dart';
import 'package:moviestar/utils/is_logged_in.dart';
import 'package:moviestar/utils/pod_path_helper.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/user_profile_service.dart';

/// Service for managing MovieList entities in the POD following the ontology structure.
class MovieListService {
  /// Widget context for POD operations.
  final BuildContext _context;

  /// Widget for returning after operations.
  final Widget _child;

  /// User profile service for updating user profile connections.
  final UserProfileService _userProfileService;

  /// Cache for movie lists.
  final Map<String, Map<String, dynamic>> _movieListCache = {};

  /// Creates a new [MovieListService] instance.
  MovieListService(this._context, this._child, this._userProfileService);

  /// Creates a new MovieList with the given name and movies.
  Future<String?> createMovieList(String listName, {List<Movie>? movies, String? description}) async {
    try {
      debugPrint('📝 Creating movie list: $listName');
      
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        debugPrint('❌ User not logged in, cannot create movie list');
        return null;
      }

      // Generate unique ID for the movie list
      final movieListId = TurtleSerializer.generateId();
      debugPrint('🆔 Generated movie list ID: $movieListId');
      
      // Create the MovieList TTL content
      final movieListTtl = TurtleSerializer.createMovieList(
        movieListId,
        listName,
        movies: movies,
        description: description,
      );

      debugPrint('📝 Generated movie list TTL (first 200 chars): ${movieListTtl.substring(0, movieListTtl.length > 200 ? 200 : movieListTtl.length)}...');

      // Write to POD
      if (!_context.mounted) return null;
      final result = await writePod(
        'user_lists/MovieList-$movieListId.ttl',  // Use correct user_lists directory
        movieListTtl,
        _context,
        _child,
        encrypted: false,
      );

      debugPrint('💾 Movie list writePod result: $result');

      if (result == SolidFunctionCallStatus.success) {
        // Update cache
        _movieListCache[movieListId] = {
          'id': movieListId,
          'name': listName,
          'movies': movies ?? [],
          'filePath': 'moviestar/data/user_lists/MovieList-$movieListId.ttl',  // Use correct user_lists path
        };

        debugPrint('✅ Movie list created successfully: $listName');

        // Add to user profile
        final profileUpdated = await _userProfileService.addMovieListToProfile(movieListId);
        if (!profileUpdated) {
          debugPrint('❌ Failed to add movie list to user profile');
        } else {
          debugPrint('✅ Movie list added to user profile');
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
  Future<Map<String, dynamic>?> getMovieList(String movieListId, {bool forceRefresh = false}) async {
    try {
      // Force refresh bypasses cache
      if (!forceRefresh && _movieListCache.containsKey(movieListId)) {
        debugPrint('📋 Returning cached MovieList: $movieListId');
        return _movieListCache[movieListId];
      }

      final loggedIn = await isLoggedIn();
      if (!loggedIn) return null;

      // Try to read from POD
      if (!_context.mounted) return null;
      try {
        // Read directly without getReadPath to avoid double path prefix
        if (!_context.mounted) return null;
        final result = await readPod('moviestar/data/user_lists/MovieList-$movieListId.ttl', _context, _child);

        if (result.isNotEmpty) {
          // Parse the MovieList data using TurtleSerializer
          final movieListData = TurtleSerializer.movieListFromTurtle(result);
          
          if (movieListData != null) {
            // Update cache with parsed data
            _movieListCache[movieListId] = movieListData;
            debugPrint('✅ MovieList loaded from POD: ${movieListData['name']}, Movies: ${movieListData['movies']?.length ?? 0}');
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
    debugPrint('🔄 Force refreshing MovieList: $movieListId');
    return await getMovieList(movieListId, forceRefresh: true);
  }

  /// Adds a movie to a MovieList.
  Future<bool> addMovieToList(String movieListId, Movie movie) async {
    try {
      debugPrint('📝 Adding ${movie.title} to MovieList $movieListId');
      final movieList = await getMovieList(movieListId);
      if (movieList == null) {
        debugPrint('❌ MovieList $movieListId not found');
        return false;
      }

      final currentMovies = List<Movie>.from(movieList['movies'] ?? []);
      debugPrint('📋 Current MovieList has ${currentMovies.length} movies');
      
      // Check if movie is already in the list
      final existingIndex = currentMovies.indexWhere((m) => m.id == movie.id);
      if (existingIndex >= 0) {
        debugPrint('ℹ️ Movie ${movie.title} already in MovieList $movieListId');
        return true; // Already exists
      }

      currentMovies.add(movie);
      debugPrint('➕ Added ${movie.title}, MovieList now has ${currentMovies.length} movies');

      // Update the MovieList
      final updatedTtl = TurtleSerializer.createMovieList(
        movieListId,
        movieList['name'],
        movies: currentMovies,
      );

      if (!_context.mounted) return false;
      final result = await writePod(
        'user_lists/MovieList-$movieListId.ttl',  // Use correct user_lists directory
        updatedTtl,
        _context,
        _child,
        encrypted: false,
      );

      debugPrint('💾 WritePod result for MovieList: $result');

      if (result == SolidFunctionCallStatus.success) {
        // Update cache with new data
        _movieListCache[movieListId] = {
          'id': movieListId,
          'name': movieList['name'],
          'movies': currentMovies,
          'filePath': movieList['filePath'],
        };
        debugPrint('✅ Successfully updated MovieList cache after addition');
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
      
      // Check if movie exists before trying to remove
      final existingIndex = currentMovies.indexWhere((m) => m.id == movie.id);
      if (existingIndex < 0) {
        debugPrint('ℹ️ Movie ${movie.title} not in list $movieListId - nothing to remove');
        return true; // Nothing to remove, consider success
      }

      // Remove the movie
      currentMovies.removeWhere((m) => m.id == movie.id);
      debugPrint('🗑️ Removed ${movie.title} from MovieList, now has ${currentMovies.length} movies');

      // Update the MovieList
      final updatedTtl = TurtleSerializer.createMovieList(
        movieListId,
        movieList['name'],
        movies: currentMovies,
      );

      if (!_context.mounted) return false;
      final result = await writePod(
        'user_lists/MovieList-$movieListId.ttl',  // Use correct user_lists directory
        updatedTtl,
        _context,
        _child,
        encrypted: false,
      );

      if (result == SolidFunctionCallStatus.success) {
        // Update cache with new data
        _movieListCache[movieListId] = {
          'id': movieListId,
          'name': movieList['name'],
          'movies': currentMovies,
          'filePath': movieList['filePath'],
        };
        debugPrint('✅ Successfully updated MovieList cache after removal');
        return true;
      }

      debugPrint('❌ Failed to write updated MovieList to POD');
      return false;
    } catch (e) {
      debugPrint('❌ Failed to remove movie from list: $e');
      return false;
    }
  }

  /// Gets or creates a standard MovieList (e.g., "to_watch", "watched").
  Future<String?> getOrCreateStandardMovieList(String listType) async {
    try {
      debugPrint('🎬 Getting/creating standard movie list: $listType');
      
      final profile = await _userProfileService.getUserProfile();
      if (profile == null) {
        debugPrint('❌ No user profile found, cannot create standard movie list');
        return null;
      }

      final displayName = listType.replaceAll('_', ' ').split(' ').map((word) => 
        word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
      ).join(' ');

      // Check if a standard list of this type already exists in the user profile
      final existingMovieListIds = profile['movieListIds'] as List<String>? ?? [];
      
      for (final movieListId in existingMovieListIds) {
        debugPrint('🔍 Checking existing MovieList: $movieListId');
        
        // Try to read the existing MovieList to check its name/type
        try {
          if (!_context.mounted) continue;
          // Read directly without getReadPath to avoid double path prefix
          final result = await readPod('moviestar/data/user_lists/MovieList-$movieListId.ttl', _context, _child);
          
          if (result.isNotEmpty) {
            // Robust check: look for the specific sdo:name pattern in TTL
            // Check for both quoted strings and the expected list type descriptions
            final namePattern = RegExp(r'sdo:name\s+"([^"]+)"');
            final descPattern = RegExp(r'sdo:description\s+"([^"]+)"');
            
            final nameMatch = namePattern.firstMatch(result);
            final descMatch = descPattern.firstMatch(result);
            
            if (nameMatch != null) {
              final foundName = nameMatch.group(1)!.trim();
              debugPrint('🔍 Found MovieList name: "$foundName", looking for: "$displayName"');
              
              // Direct name match
              if (foundName == displayName) {
                debugPrint('✅ Found existing standard movie list by name: $listType -> $movieListId');
                return movieListId;
              }
            }
            
            if (descMatch != null) {
              final foundDesc = descMatch.group(1)!.trim();
              debugPrint('🔍 Found MovieList description: "$foundDesc"');
              
              // Check description patterns for different list types
              final isToWatchList = foundDesc.contains('want to watch') || foundDesc.contains('to watch');
              final isWatchedList = foundDesc.contains('have watched') || foundDesc.contains('you watched');
              final isFavoritesList = foundDesc.contains('favorite');
              
              if ((listType == 'to_watch' && isToWatchList) ||
                  (listType == 'watched' && isWatchedList) ||
                  (listType == 'favorites' && isFavoritesList)) {
                debugPrint('✅ Found existing standard movie list by description: $listType -> $movieListId');
                return movieListId;
              }
            }
            
            debugPrint('❌ MovieList $movieListId does not match $listType (name: "${nameMatch?.group(1)}", desc: "${descMatch?.group(1)}")');
          }
        } catch (e) {
          debugPrint('❌ Error checking existing MovieList $movieListId: $e');
          continue;
        }
      }
      
      debugPrint('📝 Creating new standard list with display name: $displayName');
      
      // Generate appropriate description for standard lists
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
      
      // No existing list found, create a new one
      final listId = await createMovieList(
        displayName,
        movies: [],
        description: description,
      );

      if (listId != null) {
        debugPrint('✅ Standard movie list created: $listType -> $listId');
      } else {
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

      // Remove from user profile first
      try {
        await _userProfileService.removeMovieListFromProfile(movieListId);
      } catch (e) {
        debugPrint('Warning: Failed to remove movie list from profile: $e');
        // Continue with deletion even if profile update fails
      }

      // Delete from POD
      if (!_context.mounted) return false;
      
      await deleteFile('moviestar/data/user_lists/MovieList-$movieListId.ttl');  // Use correct user_lists path
      
      // Remove from cache
      _movieListCache.remove(movieListId);
      return true;
    } catch (e) {
      debugPrint('Failed to delete movie list: $e');
      return false;
    }
  }

  /// Clears the cache.
  void clearCache() {
    _movieListCache.clear();
  }
} 