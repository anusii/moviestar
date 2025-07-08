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

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/user_profile_service.dart';
import 'package:moviestar/utils/is_logged_in.dart';
import 'package:moviestar/utils/turtle_serializer.dart';

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
  Future<String?> createMovieList(String listName, {List<Movie>? movies}) async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) return null;

      // Generate unique ID for the movie list
      final movieListId = TurtleSerializer.generateId();
      
      // Create the MovieList TTL content
      final movieListTtl = TurtleSerializer.createMovieList(
        movieListId,
        listName,
        movies: movies,
      );

      // Write to POD
      if (!_context.mounted) return null;
      final result = await writePod(
        'user_lists/MovieList-$movieListId.ttl',
        movieListTtl,
        _context,
        _child,
        encrypted: false,
      );

      if (result == SolidFunctionCallStatus.success) {
        // Update cache
        _movieListCache[movieListId] = {
          'id': movieListId,
          'name': listName,
          'movies': movies ?? [],
          'filePath': 'moviestar/data/user_lists/MovieList-$movieListId.ttl',
        };

        // Add to user profile
        try {
          await _userProfileService.addMovieListToProfile(movieListId);
        } catch (e) {
          debugPrint('Failed to add movie list to user profile: $e');
        }

        return movieListId;
      }

      return null;
    } catch (e) {
      debugPrint('Failed to create movie list: $e');
      return null;
    }
  }

  /// Gets a MovieList by ID.
  Future<Map<String, dynamic>?> getMovieList(String movieListId) async {
    try {
      // First check cache
      if (_movieListCache.containsKey(movieListId)) {
        return _movieListCache[movieListId];
      }

      final loggedIn = await isLoggedIn();
      if (!loggedIn) return null;

      // Try to read from POD
      if (!_context.mounted) return null;
      try {
        final result = await readPod('user_lists/MovieList-$movieListId.ttl', _context, _child);

        if (result.isNotEmpty) {
          // Parse the MovieList data (simplified for now)
          final movieListData = {
            'id': movieListId,
            'name': 'MovieList',
            'movies': <Movie>[],
            'filePath': 'moviestar/data/user_lists/MovieList-$movieListId.ttl',
          };

          // Update cache
          _movieListCache[movieListId] = movieListData;
          return movieListData;
        }
      } catch (e) {
        debugPrint('Failed to read MovieList from POD: $e');
      }

      return null;
    } catch (e) {
      debugPrint('Failed to get movie list: $e');
      return null;
    }
  }

  /// Adds a movie to a MovieList.
  Future<bool> addMovieToList(String movieListId, Movie movie) async {
    try {
      final movieList = await getMovieList(movieListId);
      if (movieList == null) return false;

      final currentMovies = List<Movie>.from(movieList['movies'] ?? []);
      
      // Check if movie is already in the list
      final existingIndex = currentMovies.indexWhere((m) => m.id == movie.id);
      if (existingIndex >= 0) {
        return true; // Already exists
      }

      currentMovies.add(movie);

      // Update the MovieList
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
        // Update cache
        _movieListCache[movieListId] = {
          'id': movieListId,
          'name': movieList['name'],
          'movies': currentMovies,
          'filePath': movieList['filePath'],
        };
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Failed to add movie to list: $e');
      return false;
    }
  }

  /// Removes a movie from a MovieList.
  Future<bool> removeMovieFromList(String movieListId, Movie movie) async {
    try {
      final movieList = await getMovieList(movieListId);
      if (movieList == null) return false;

      final currentMovies = List<Movie>.from(movieList['movies'] ?? []);
      
      // Remove the movie
      final removedCount = currentMovies.removeWhere((m) => m.id == movie.id);
      if (removedCount == 0) {
        return true; // Already removed
      }

      // Update the MovieList
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
        // Update cache
        _movieListCache[movieListId] = {
          'id': movieListId,
          'name': movieList['name'],
          'movies': currentMovies,
          'filePath': movieList['filePath'],
        };
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Failed to remove movie from list: $e');
      return false;
    }
  }

  /// Gets or creates a standard MovieList (e.g., "to_watch", "watched").
  Future<String?> getOrCreateStandardMovieList(String listType) async {
    try {
      final profile = await _userProfileService.getUserProfile();
      if (profile == null) return null;

      // For now, we'll create a simple mapping based on list type
      // In the future, we could check if a list with this type already exists
      
      // Create the standard list
      final listId = await createMovieList(
        listType.replaceAll('_', ' ').split(' ').map((word) => 
          word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
        ).join(' '),
        movies: [],
      );

      return listId;
    } catch (e) {
      debugPrint('Failed to get or create standard movie list: $e');
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
      
      await deleteFile('user_lists/MovieList-$movieListId.ttl');
      
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