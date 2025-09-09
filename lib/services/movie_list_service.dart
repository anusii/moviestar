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

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/models/movie_list_operation.dart';
import 'package:moviestar/models/shared_movie_list.dart';
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

  Future<String?> createMovieList(
    String listName, {
    List<Movie> movies = const [],
    String description = '',
  }) async {
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
          'movies': movies,
          'filePath': 'moviestar/data/$fileName',
        };

        // Add to user profile.

        final profileUpdated = await _userProfileService.addMovieListToProfile(
          movieListId,
        );
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

  Future<Map<String, dynamic>?> getMovieList(
    String movieListId, {
    bool forceRefresh = false,
  }) async {
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
        final result = await readPod(
          'moviestar/data/$filePath',
          _context,
          _child,
        );

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
                // Check content type from placeholder if available
                final contentType =
                    placeholderMovie.contentType == ContentType.tvShow
                        ? 'tv'
                        : 'movie';
                final fullMovieData = await _loadFullMovieData(
                  placeholderMovie.id,
                  contentType: contentType,
                );

                if (fullMovieData != null) {
                  fullMovies.add(fullMovieData);
                } else {
                  // If no individual movie file exists, keep the placeholder.
                  // but mark it as needing to be fetched from API.
                  // The UI should handle fetching the full data.

                  fullMovies.add(placeholderMovie);
                }
              } catch (e) {
                debugPrint(
                  '❌ [MovieList] Failed to load full data for movie ${placeholderMovie.id}: $e',
                );
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

  Future<Movie?> _loadFullMovieData(int movieId,
      {String contentType = 'movie'}) async {
    try {
      // First try to load from individual movie file.
      // Check both Movie and TVShow patterns for backward compatibility
      final movieFileName = 'moviestar/data/movies/Movie-$movieId.ttl';
      final tvShowFileName = 'moviestar/data/movies/TVShow-$movieId.ttl';

      if (!_context.mounted) return null;

      try {
        String result = '';
        // For TV shows, try TVShow file first, then fall back to Movie file
        if (contentType == 'tv' || contentType == 'tvShow') {
          try {
            result = await readPod(tvShowFileName, _context, _child);
          } catch (e) {
            // Fall back to Movie file for backward compatibility
            if (!e.toString().contains('does not exist')) {
              rethrow;
            }
            result = await readPod(movieFileName, _context, _child);
          }
        } else {
          // For movies, just try Movie file
          result = await readPod(movieFileName, _context, _child);
        }

        if (result.isNotEmpty) {
          final movieData =
              TurtleSerializer.movieWithUserDataFromTurtle(result);

          if (movieData != null && movieData['movie'] is Movie) {
            final movie = movieData['movie'] as Movie;
            return movie;
          } else {}
        }
      } catch (e) {
        // File doesn't exist or can't be read, continue to fallback.

        if (!e.toString().contains('does not exist')) {
        } else {}
      }

      // If no file exists, this is expected for movies that were added before
      // individual files were created, return null to trigger fetching from API.

      return null;
    } catch (e) {
      debugPrint(
        '❌ [MovieList] Error loading full movie data for $movieId: $e',
      );
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
    String listType,
    String displayName,
  ) async {
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

            final result = await readPod(
              'moviestar/data/$filePath',
              _context,
              _child,
            );

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

            debugPrint('⚠️ Could not read MovieList file $fileName: $e');
            continue;
          }
        }
      }

      return null;
    } catch (e) {
      // Enhanced error handling with specific web-related error detection.

      final errorMsg = e.toString().toLowerCase();

      if (errorMsg.contains('network') ||
          errorMsg.contains('fetch') ||
          errorMsg.contains('cors') ||
          errorMsg.contains('connection')) {
        debugPrint(
          '🌐 Web-specific network error scanning user_lists directory: $e',
        );
        debugPrint(
          '🔄 This may be due to web environment POD access limitations',
        );
      } else if (errorMsg.contains('permission') ||
          errorMsg.contains('auth') ||
          errorMsg.contains('unauthorized') ||
          errorMsg.contains('forbidden')) {
        debugPrint(
          '🔐 Permission/Auth error scanning user_lists directory: $e',
        );
        debugPrint('🔄 May need to wait for POD authentication to complete');
      } else {
        if (!e.toString().contains('does not exist') &&
            !e.toString().contains('Failed to get resource list')) {
          debugPrint('❌ Error scanning user_lists directory: $e');
        }
      }

      // Return null to trigger fallback creation instead of failing completely.

      return null;
    }
  }

  /// Forces a refresh of a specific MovieList from POD.

  Future<Map<String, dynamic>?> refreshMovieList(String movieListId) async {
    return await getMovieList(movieListId, forceRefresh: true);
  }

  /// Adds a movie to a MovieList.
  ///
  /// [contentType] specifies whether this is a movie or TV show.
  /// Only creates individual files for actual movies, not TV shows.

  Future<bool> addMovieToList(
    String movieListId,
    Movie movie, {
    String contentType = 'movie',
  }) async {
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

      // Create individual files for both movies and TV shows with proper naming
      await _createMovieFile(movie, contentType: contentType);

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

  Future<void> _createMovieFile(Movie movie,
      {String contentType = 'movie'}) async {
    try {
      // Don't create a file for placeholder movies
      if (movie.title == 'Loading...' || movie.posterUrl.isEmpty) {
        debugPrint(
          '⚠️ Skipping movie file creation for placeholder movie ${movie.id}',
        );
        return;
      }

      // Use content-type aware file naming
      final contentPrefix =
          (contentType == 'tv' || contentType == 'tvShow') ? 'TVShow' : 'Movie';
      final movieFileName = 'movies/$contentPrefix-${movie.id}.ttl';

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
      } else {
        debugPrint(
          '❌ Failed to create individual movie file for ${movie.title}',
        );
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
          .map(
            (word) =>
                word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
          )
          .join(' ');

      // Check if user is logged in first.

      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        debugPrint('⚠️ User not logged in, cannot create/access MovieLists');
        return null;
      }

      // Scan the user_lists directory for existing MovieLists instead of relying on profile data.

      final existingMovieListId = await _findExistingMovieListInDirectory(
        listType,
        displayName,
      );
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

      // Attempt to create new list with multiple retry strategies for web environments.

      String? listId;
      int retryCount = 0;
      const maxRetries = 3;

      while (listId == null && retryCount < maxRetries) {
        retryCount++;

        try {
          listId = await createMovieList(
            displayName,
            movies: [],
            description: description,
          );

          if (listId != null) {
            break;
          }
        } catch (createError) {
          debugPrint('❌ Create attempt $retryCount threw error: $createError');

          // Wait before retry, with exponential backoff for web environments.

          if (retryCount < maxRetries) {
            final waitTime = Duration(milliseconds: 1000 * retryCount);
            await Future.delayed(waitTime);
          }
        }
      }

      if (listId == null) {
        debugPrint(
          '❌ Failed to create standard movie list after $maxRetries attempts: $listType',
        );
        debugPrint(
          '🔄 This may be due to web environment POD limitations or authentication issues',
        );

        // For web environments, we should still return a placeholder ID
        // to prevent the app from being completely unusable.

        final fallbackId =
            'fallback-$listType-${DateTime.now().millisecondsSinceEpoch}';

        // Cache the fallback data locally.

        _movieListCache[fallbackId] = {
          'id': fallbackId,
          'name': displayName,
          'movies': <Movie>[],
          'filePath': 'user_lists/MovieList-$fallbackId.ttl',
          'isFallback': true, // Mark as fallback for later recovery.
        };

        return fallbackId;
      }

      return listId;
    } catch (e) {
      debugPrint('❌ Exception in get/create standard movie list: $e');

      // Enhanced error categorization for better debugging.

      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('network') ||
          errorMsg.contains('fetch') ||
          errorMsg.contains('cors')) {
        debugPrint(
          '🌐 Network-related error - may be web environment limitation',
        );
      } else if (errorMsg.contains('auth') || errorMsg.contains('permission')) {
        debugPrint(
          '🔐 Authentication/permission error - POD access may not be ready',
        );
      }

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

  /// Gets the file path for a MovieList for sharing purposes.
  /// Returns the relative path that can be used with GrantPermissionUi.

  String? getMovieListFilePath(String movieListId) {
    try {
      // Return the relative path for the movie list file
      return 'user_lists/MovieList-$movieListId.ttl';
    } catch (e) {
      debugPrint('❌ Error getting movie list file path: $e');
      return null;
    }
  }

  /// Validates that a MovieList exists and can be shared.

  Future<bool> canShareMovieList(String movieListId) async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        debugPrint('❌ User not logged in, cannot share movie list');
        return false;
      }

      final movieList = await getMovieList(movieListId);
      return movieList != null;
    } catch (e) {
      debugPrint('❌ Error checking if movie list can be shared: $e');
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

  /// Shares a MovieList and all its associated movie files with another user.
  /// This is a comprehensive sharing method that ensures the recipient
  /// can access both the list structure and all individual movie data.
  ///
  /// [listId] - The ID of the MovieList to share.
  /// [permissions] - List of permissions (e.g., ['read', 'write']).
  /// [customTitle] - Optional custom title for the sharing dialog.
  ///
  /// Returns true if the sharing was successful.

  Future<bool> shareMovieListWithMovies(
    String listId,
    List<String> permissions, {
    String? customTitle,
  }) async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        debugPrint('❌ User not logged in, cannot share movie list with movies');
        return false;
      }

      // Get the movie list data.

      final movieList = await getMovieList(listId);
      if (movieList == null) {
        debugPrint('❌ MovieList $listId not found, cannot share');
        return false;
      }

      final listName = movieList['name'] ?? 'Movie List';

      if (!_context.mounted) return false;

      // Navigate directly to GrantPermissionUi for sharing
      final result = await Navigator.push<bool>(
        _context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (navContext) => Theme(
            data: Theme.of(_context),
            child: Scaffold(
              backgroundColor: Theme.of(_context).scaffoldBackgroundColor,
              appBar: AppBar(
                title: Text('Share "$listName"'),
                backgroundColor: Theme.of(_context).appBarTheme.backgroundColor,
                foregroundColor: Theme.of(_context).appBarTheme.foregroundColor,
              ),
              body: GrantPermissionUi(
                fileName: 'user_lists/MovieList-$listId.ttl',
                title: '',
                accessModeList: const ['read'],
                recipientTypeList: const ['indi'],
                showAppBar: false,
                backgroundColor: Theme.of(_context).scaffoldBackgroundColor,
                child: _child,
              ),
            ),
          ),
        ),
      );

      return result ?? false;
    } catch (e) {
      debugPrint('❌ Failed to share movie list with movies: $e');
      return false;
    }
  }

  /// Gets movie lists that have been shared with the current user.
  ///
  /// Returns a list of SharedMovieList objects representing lists shared with the user.

  Future<List<SharedMovieList>> getSharedLists() async {
    try {
      if (!_context.mounted) return [];

      // Get shared resources from POD.

      final sharedResourcesResult = await sharedResources(_context, _child);

      if (sharedResourcesResult == SolidFunctionCallStatus.notLoggedIn) {
        debugPrint('❌ User not logged in to POD');
        return [];
      }

      if (sharedResourcesResult is! Map) {
        debugPrint('❌ Invalid shared resources data');
        return [];
      }

      final List<SharedMovieList> sharedLists = [];

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

            final listContent = await readExternalPod(
              resourceUrl,
              _context,
              _child,
            );

            if (listContent != null && listContent.isNotEmpty) {
              // Parse the TTL content.

              final parsedList = TurtleSerializer.movieListFromTurtle(
                listContent,
              );

              if (parsedList != null) {
                final sharedMovieList = SharedMovieList.fromMap(resourceUrl, {
                  ...parsedList,
                  'resourceUrl': resourceUrl,
                  'resourceInfo': resourceInfo,
                  'listContent': listContent,
                  'isSharedWithMe': true,
                });
                sharedLists.add(sharedMovieList);
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
      return [];
    }
  }

  /// Gets movie lists that the current user has shared with others.
  ///
  /// Returns a list of MySharedMovieList objects representing lists the user has shared.

  Future<List<MySharedMovieList>> getMySharedLists() async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) return [];

      // Get current user's WebID to construct the user_lists directory URL.

      final currentWebId = await getWebId();
      if (currentWebId == null) return [];

      final webIdWithoutCard = currentWebId.replaceAll('/profile/card#me', '');
      final userListsDir = '$webIdWithoutCard/moviestar/data/user_lists/';

      // Get resources in the user_lists container.

      final resources = await getResourcesInContainer(userListsDir);
      final List<MySharedMovieList> mySharedLists = [];

      // Process each MovieList file.

      for (final fileName in resources.files) {
        if (!fileName.endsWith('.ttl') || !fileName.contains('MovieList-')) {
          continue;
        }

        // Extract list ID from filename.

        final listIdMatch = RegExp(
          r'MovieList-(\w+)\.ttl',
        ).firstMatch(fileName);
        if (listIdMatch == null) continue;

        final listId = listIdMatch.group(1)!;

        try {
          // Get the movie list.

          final movieList = await getMovieList(listId);
          if (movieList == null) continue;

          // Check if this list has sharing metadata.

          final sharedWith = movieList['sharedWith'] as Map<String, String>?;

          if (sharedWith != null && sharedWith.isNotEmpty) {
            final mySharedMovieList = MySharedMovieList.fromMap(listId, {
              ...movieList,
              'fileName': fileName,
              'resourceUrl': '$userListsDir$fileName',
              'isMySharedList': true,
            });
            mySharedLists.add(mySharedMovieList);
          }
        } catch (e) {
          debugPrint('⚠️ Could not check sharing status for list $listId: $e');
        }
      }

      return mySharedLists;
    } catch (e) {
      debugPrint('❌ Failed to get my shared lists: $e');
      return [];
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

      final sharedWith = Map<String, String>.from(
        movieList['sharedWith'] ?? {},
      );

      if (!sharedWith.containsKey(webId)) {
        debugPrint(
          '⚠️ WebId $webId not found in shared users for list $listId',
        );
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

  Future<bool> canUserPerformOperation(
    String listId,
    MovieListOperation operation,
  ) async {
    try {
      final currentWebId = await getWebId();
      if (currentWebId == null) return false;

      final permission = await validateUserAccess(listId, currentWebId);
      if (permission == null) return false;

      // Map operations to required permission levels.

      switch (operation) {
        case MovieListOperation.read:
          return ['read', 'write', 'control'].contains(permission);
        case MovieListOperation.write:
        case MovieListOperation.add:
        case MovieListOperation.remove:
          return ['write', 'control'].contains(permission);
        case MovieListOperation.delete:
        case MovieListOperation.share:
          return permission == 'control';
      }
    } catch (e) {
      debugPrint('❌ Failed to check user permissions: $e');
      return false;
    }
  }
}
