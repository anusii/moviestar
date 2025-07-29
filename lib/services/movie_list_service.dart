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

      // All MovieLists follow the ontology naming convention: MovieList-{ID}.ttl.

      final fileName = 'user_lists/MovieList-$movieListId.ttl';

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
        fileName,
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
          'filePath': 'moviestar/data/$fileName',
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

  /// Gets a MovieList by ID and loads full movie data for each movie reference.

  Future<Map<String, dynamic>?> getMovieList(String movieListId,
      {bool forceRefresh = false}) async {
    try {
      // Force refresh bypasses cache.

      if (!forceRefresh && _movieListCache.containsKey(movieListId)) {
        final cachedData = _movieListCache[movieListId]!;
        // Check if cached movies have full data (not just placeholders).

        if (cachedData['movies'] is List<Movie>) {
          final movies = cachedData['movies'] as List<Movie>;
          if (movies.isNotEmpty && movies.first.posterUrl.isNotEmpty) {
            return cachedData;
          }
        }
      }

      final loggedIn = await isLoggedIn();
      if (!loggedIn) return null;

      // Try to read from POD.

      if (!_context.mounted) return null;
      try {
        // Get the standard file path for this MovieList.

        final filePath = _getMovieListFilePath(movieListId);

        if (!_context.mounted) return null;
        final result =
            await readPod('moviestar/data/$filePath', _context, _child);

        if (result.isNotEmpty) {
          // Parse the MovieList data using TurtleSerializer.

          final movieListData = TurtleSerializer.movieListFromTurtle(result);

          if (movieListData != null) {
            // Load full movie data for each movie reference.

            final placeholderMovies =
                movieListData['movies'] as List<Movie>? ?? [];
            final fullMovies = <Movie>[];

            for (final placeholderMovie in placeholderMovies) {
              try {
                // Try to load full movie data from individual movie file.

                final fullMovieData =
                    await _loadFullMovieData(placeholderMovie.id);
                if (fullMovieData != null) {
                  fullMovies.add(fullMovieData);
                } else {
                  // If no individual movie file exists, keep the placeholder.
                  // but try to get basic data from TMDB if we have a movie service.

                  fullMovies.add(placeholderMovie);
                }
              } catch (e) {
                debugPrint(
                    '❌ Failed to load full data for movie ${placeholderMovie.id}: $e');
                // Keep placeholder as fallback.

                fullMovies.add(placeholderMovie);
              }
            }

            // Update the movie list data with full movie objects.

            movieListData['movies'] = fullMovies;

            // Update cache with enhanced data.

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

  /// Loads full movie data from individual movie file or fallback sources.

  Future<Movie?> _loadFullMovieData(int movieId) async {
    try {
      // First try to load from individual movie file.

      final movieFileName = 'moviestar/data/movies/Movie-$movieId.ttl';

      if (!_context.mounted) return null;
      final result = await readPod(movieFileName, _context, _child);

      if (result.isNotEmpty) {
        final movieData = TurtleSerializer.movieWithUserDataFromTurtle(result);
        if (movieData != null && movieData['movie'] is Movie) {
          return movieData['movie'] as Movie;
        }
      }

      debugPrint('💡 No individual movie file found for movie $movieId');
      return null;
    } catch (e) {
      debugPrint('❌ Error loading full movie data for $movieId: $e');
      return null;
    }
  }

  /// Gets the standard file path for a MovieList following ontology convention.

  String _getMovieListFilePath(String movieListId) {
    // All MovieLists follow the ontology naming convention.

    return 'user_lists/MovieList-$movieListId.ttl';
  }

  /// Scans the user_lists directory for existing MovieLists of the specified type.
  /// This is more efficient than relying on potentially stale profile data.

  Future<String?> _findExistingMovieListInDirectory(
      String listType, String displayName) async {
    try {
      // Get the list of resources in the user_lists directory.

      final dirUrl = await getDirUrl('moviestar/data/user_lists');
      final resources = await getResourcesInContainer(dirUrl);

      // Look for MovieList files.

      for (final fileName in resources.files) {
        if (fileName.startsWith('MovieList-') && fileName.endsWith('.ttl')) {
          // Extract the MovieList ID from the filename.

          final movieListId =
              fileName.replaceAll('MovieList-', '').replaceAll('.ttl', '');

          try {
            // Read the MovieList file to check its type.

            final filePath = 'user_lists/$fileName';
            if (!_context.mounted) return null;

            final result =
                await readPod('moviestar/data/$filePath', _context, _child);

            if (result.isNotEmpty) {
              // Check for the specific sdo:name and sdo:description patterns.

              final namePattern = RegExp(r'sdo:name\s+"([^"]+)"');
              final descPattern = RegExp(r'sdo:description\s+"([^"]+)"');

              final nameMatch = namePattern.firstMatch(result);
              final descMatch = descPattern.firstMatch(result);

              if (nameMatch != null) {
                final foundName = nameMatch.group(1)!.trim();
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
            // Skip files that can't be read (deleted, corrupted, etc.).

            continue;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error scanning user_lists directory: $e');
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

      // Create individual movie file to ensure full data is available.

      await _createMovieFile(movie);

      currentMovies.add(movie);

      // Update the MovieList.

      final updatedTtl = TurtleSerializer.createMovieList(
        movieListId,
        movieList['name'],
        movies: currentMovies,
      );

      // Get the standard file path for writing.

      final filePath = _getMovieListFilePath(movieListId);

      if (!_context.mounted) return false;
      final result = await writePod(
        filePath,
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

  /// Creates an individual movie file with full movie data.

  Future<void> _createMovieFile(Movie movie) async {
    try {
      final movieFileName = 'movies/Movie-${movie.id}.ttl';

      // Create the movie TTL content with full data.

      final ttlContent = TurtleSerializer.movieWithUserDataToTurtleOntology(
        movie,
        null, // No rating initially.
        null, // No comment initially.
      );

      if (!_context.mounted) return;
      final result = await writePod(
        movieFileName,
        ttlContent,
        _context,
        _child,
        encrypted: false,
      );

      if (result == SolidFunctionCallStatus.success) {
        debugPrint('✅ Created individual movie file for ${movie.title}');
      } else {
        debugPrint(
            '❌ Failed to create individual movie file for ${movie.title}');
      }
    } catch (e) {
      debugPrint('❌ Error creating movie file for ${movie.title}: $e');
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

      // Get the standard file path for writing.

      final filePath = _getMovieListFilePath(movieListId);

      if (!_context.mounted) return false;
      final result = await writePod(
        filePath,
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
      final displayName = listType
          .replaceAll('_', ' ')
          .split(' ')
          .map((word) =>
              word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
          .join(' ');

      // Scan the user_lists directory for existing MovieLists instead of relying on profile data.

      final existingMovieListId =
          await _findExistingMovieListInDirectory(listType, displayName);
      if (existingMovieListId != null) {
        return existingMovieListId;
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

      // Get the standard file path for deletion.

      final filePath = _getMovieListFilePath(movieListId);
      await deleteFile('moviestar/data/$filePath');

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
