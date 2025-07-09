/// POD-based service for managing favorite movies using Solid POD storage.
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

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solidpod/solidpod.dart';

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/services/user_profile_service.dart';
import 'package:moviestar/services/movie_list_service.dart';
import 'package:moviestar/utils/is_logged_in.dart';
import 'package:moviestar/utils/turtle_serializer.dart';
import 'package:moviestar/constants/paths.dart';

/// A POD-based service class that manages the user's movie lists in Solid POD.

class PodFavoritesService extends ChangeNotifier {
  /// File names for storing data in POD - using different paths for read vs write operations.

  static const String _toWatchFileName = 'user_lists/to_watch.ttl';
  static const String _watchedFileName = 'user_lists/watched.ttl';
  static const String _ratingsFileName = 'ratings/ratings.ttl';

  // Full paths for reading operations (where files are actually stored).

  static const String _toWatchFileNameRead = 'user_lists/to_watch.ttl';
  static const String _watchedFileNameRead = 'user_lists/watched.ttl';
  static const String _ratingsFileNameRead = 'ratings/ratings.ttl';

  /// Widget context for POD operations.

  final BuildContext _context;

  /// Widget for returning after operations.

  final Widget _child;

  /// SharedPreferences for fallback storage.

  final SharedPreferences _prefs;

  /// Fallback favorites service for compatibility.

  final FavoritesService _fallbackService;

  /// Track which movies have files to avoid unnecessary reads.

  final Set<int> _moviesWithFiles = {};

  /// Cache for movie data to avoid frequent POD reads.

  List<Movie>? _cachedToWatch;
  List<Movie>? _cachedWatched;
  Map<String, double>? _cachedRatings;
  Map<String, String>? _cachedComments;

  /// Track if we're currently syncing with POD.

  bool _isSyncing = false;

  /// Stream controller for to-watch movies.

  final _toWatchController = BehaviorSubject<List<Movie>>();

  /// Stream controller for watched movies.

  final _watchedController = BehaviorSubject<List<Movie>>();

  /// Stream of to-watch movies.

  Stream<List<Movie>> get toWatchMovies => _toWatchController.stream;

  /// Stream of watched movies.

  Stream<List<Movie>> get watchedMovies => _watchedController.stream;

  /// Track pending movie file updates to batch them.

  final Map<int, Timer> _pendingMovieUpdates = {};

  /// User profile service for ontology-based user management.

  late final UserProfileService _userProfileService;

  /// MovieList service for ontology-based list management.

  late final MovieListService _movieListService;

  /// IDs for standard movie lists.

  String? _toWatchListId;
  String? _watchedListId;

  /// Creates a new [PodFavoritesService] instance.

  PodFavoritesService(this._prefs, this._context, this._child)
      : _fallbackService = FavoritesService(_prefs) {
    // Initialize ontology services
    _userProfileService = UserProfileService(_context, _child);
    _movieListService = MovieListService(_context, _child, _userProfileService);
    _initializePodData();
  }

  /// Initialize POD data by loading from POD if available.

  Future<void> _initializePodData() async {
    try {
      // Check if user is logged into POD first.

      final isPodReady = await isPodAvailable();
      if (isPodReady) {
        // Initialize user profile following the ontology structure
        await _userProfileService.initializeProfileIfNeeded();

        // Get or create standard movie lists
        _toWatchListId =
            await _movieListService.getOrCreateStandardMovieList('to_watch');
        _watchedListId =
            await _movieListService.getOrCreateStandardMovieList('watched');

        // Try to load from POD, but don't fail if folders aren't ready yet.

        await _loadFromPod();
      } else {
        // Initialize with empty data for new POD storage.

        _cachedToWatch = [];
        _cachedWatched = [];
        _cachedRatings = {};
        _cachedComments = {};
        _toWatchController.add(_cachedToWatch!);
        _watchedController.add(_cachedWatched!);
      }
    } catch (e) {
      debugPrint('Failed to initialize POD data: $e');
      // Initialize with empty data.

      _cachedToWatch = [];
      _cachedWatched = [];
      _cachedRatings = {};
      _cachedComments = {};
      _toWatchController.add(_cachedToWatch!);
      _watchedController.add(_cachedWatched!);
    }
  }

  /// Loads data from POD and caches it locally.

  Future<void> _loadFromPod() async {
    _isSyncing = true;

    try {
      // Initialize with empty data first.

      _cachedToWatch = [];
      _cachedWatched = [];
      _cachedRatings = {};
      _cachedComments = {};

      // Try to load each file individually without key validation to avoid encryption conflicts

      await _loadFileFromPodWithoutKey(_toWatchFileNameRead, (content) {
        if (content is String) {
          _cachedToWatch = TurtleSerializer.moviesFromTurtle(content);
        }
      });

      await _loadFileFromPodWithoutKey(_watchedFileNameRead, (content) {
        if (content is String) {
          _cachedWatched = TurtleSerializer.moviesFromTurtle(content);
        }
      });

      await _loadFileFromPodWithoutKey(_ratingsFileNameRead, (content) {
        if (content is String) {
          _cachedRatings = TurtleSerializer.ratingsFromTurtle(content);
        }
      });

      // Skip loading old comments file - we use individual movie files now.
      // The old comments.ttl file has encryption key conflicts.

      _cachedComments = {};

      // Update streams with POD data.

      _toWatchController.add(_cachedToWatch!);
      _watchedController.add(_cachedWatched!);
    } catch (e) {
      debugPrint('Error loading from POD: $e');
      // Initialize with empty data if POD fails.

      _cachedToWatch = [];
      _cachedWatched = [];
      _cachedRatings = {};
      _cachedComments = {};
    } finally {
      _isSyncing = false;
    }
  }

  /// Helper method to load a single file from POD without key validation.

  Future<void> _loadFileFromPodWithoutKey(
    String fileName,
    Function(dynamic) onSuccess,
  ) async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        return;
      }

      if (!_context.mounted) return;

      // Skip getKeyFromUserIfRequired to avoid encryption key conflicts.

      final content = await readPod(fileName, _context, _child);
      onSuccess(content);
      return;
    } catch (e) {
      // Handle specific encryption key conflicts.

      if (e.toString().contains('Duplicated encryption key')) {
        // Skip this file - we'll use movie files instead.

        return;
      }

      // Suppress "does not exist" errors - these are expected for new files.

      if (e.toString().contains('does not exist')) {
        return;
      }

      // For other errors, we can try to continue without this file.

      debugPrint('Error loading file $fileName: $e');
      return;
    }
  }

  /// Saves to-watch list to POD.

  Future<void> _saveToWatchToPod(List<Movie> movies) async {
    if (_isSyncing) return;

    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        final encoded = jsonEncode(movies.map((m) => m.toJson()).toList());
        await _prefs.setString('to_watch', encoded);
        return;
      }

      final ttlContent = TurtleSerializer.moviesToTurtleWithJson(
        movies,
        'toWatchList',
      );

      if (!_context.mounted) return;

      // Skip getKeyFromUserIfRequired to avoid encryption key conflicts.

      final result = await writePod(
        _toWatchFileName,
        ttlContent,
        _context,
        _child,
      );

      if (result == SolidFunctionCallStatus.success) {
        _cachedToWatch = List.from(movies);
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        debugPrint('WritePod failed with status: $result');
        throw Exception('WritePod failed with status: $result');
      }
    } catch (e) {
      debugPrint('Failed to save to-watch list to POD: $e');
      final encoded = jsonEncode(movies.map((m) => m.toJson()).toList());
      await _prefs.setString('to_watch', encoded);
    }
  }

  /// Saves watched list to POD.

  Future<void> _saveWatchedToPod(List<Movie> movies) async {
    if (_isSyncing) return;

    try {
      final ttlContent = TurtleSerializer.moviesToTurtleWithJson(
        movies,
        'watchedList',
      );
      await writePod(_watchedFileName, ttlContent, _context, _child);
      _cachedWatched = List.from(movies);
    } catch (e) {
      debugPrint('Failed to save watched list to POD: $e');

      // Fallback to SharedPreferences.

      final encoded = jsonEncode(movies.map((m) => m.toJson()).toList());
      await _prefs.setString('watched', encoded);
    }
  }

  /// Saves ratings to POD.

  Future<void> _saveRatingsToPod(Map<String, double> ratings) async {
    if (_isSyncing) return;

    try {
      final ttlContent = TurtleSerializer.ratingsToTurtleWithJson(ratings);
      await writePod(_ratingsFileName, ttlContent, _context, _child,
          encrypted: false);
      _cachedRatings = Map.from(ratings);
    } catch (e) {
      // Don't log - this is background save for compatibility
      // debugPrint('Failed to save ratings to POD: $e');
    }
  }

  /// Retrieves the list of to-watch movies from POD cache.

  Future<List<Movie>> getToWatch({bool forceRefresh = false}) async {
    // Read from MovieList file instead of cached old TTL data
    if (_toWatchListId != null) {
      final movieListData = await _movieListService
          .getMovieList(_toWatchListId!, forceRefresh: forceRefresh);
      if (movieListData != null) {
        final movies = movieListData['movies'] as List<Movie>? ?? [];
        debugPrint(
            '✅ Loaded ${movies.length} movies from To Watch MovieList${forceRefresh ? " (force refresh)" : ""}');
        return List.from(movies);
      }
    }

    // Fallback to cached data if MovieList fails
    if (_cachedToWatch != null) {
      debugPrint(
          '🔄 Using cached To Watch data (${_cachedToWatch!.length} movies)');
      return List.from(_cachedToWatch!);
    }

    // Final fallback to SharedPreferences
    debugPrint('⚠️ Falling back to SharedPreferences for To Watch data');
    return _fallbackService.getToWatch();
  }

  /// Retrieves the list of watched movies from POD cache.

  Future<List<Movie>> getWatched({bool forceRefresh = false}) async {
    // Read from MovieList file instead of cached old TTL data
    if (_watchedListId != null) {
      final movieListData = await _movieListService
          .getMovieList(_watchedListId!, forceRefresh: forceRefresh);
      if (movieListData != null) {
        final movies = movieListData['movies'] as List<Movie>? ?? [];
        debugPrint(
            '✅ Loaded ${movies.length} movies from Watched MovieList${forceRefresh ? " (force refresh)" : ""}');
        return List.from(movies);
      }
    }

    // Fallback to cached data if MovieList fails
    if (_cachedWatched != null) {
      debugPrint(
          '🔄 Using cached Watched data (${_cachedWatched!.length} movies)');
      return List.from(_cachedWatched!);
    }

    // Final fallback to SharedPreferences
    debugPrint('⚠️ Falling back to SharedPreferences for Watched data');
    return _fallbackService.getWatched();
  }

  /// Adds a movie to the to-watch list and saves to POD.

  Future<void> addToWatch(Movie movie) async {
    // Only use MovieList - remove old TTL operations
    if (_toWatchListId != null) {
      final success =
          await _movieListService.addMovieToList(_toWatchListId!, movie);
      if (success) {
        debugPrint('✅ Added ${movie.title} to To Watch MovieList');

        // Update stream with fresh data from MovieList
        final movies = await getToWatch(forceRefresh: true);
        _toWatchController.add(movies);
        debugPrint(
            '📺 Updated to-watch stream with ${movies.length} movies (force refreshed)');

        // DO NOT call _createOrUpdateMovieFile() here to avoid race condition
        // The movie file should already be created/updated by the caller
        return;
      } else {
        debugPrint('❌ Failed to add ${movie.title} to To Watch MovieList');
      }
    }

    // Fallback to old system if MovieList fails
    debugPrint('🔄 Falling back to old TTL system for to-watch list');
    final toWatch = await getToWatch();
    if (!toWatch.any((m) => m.id == movie.id)) {
      toWatch.add(movie);
      await _saveToWatchToPod(toWatch);
      _toWatchController.add(toWatch);
      // DO NOT call _createOrUpdateMovieFile() here to avoid race condition
    }
  }

  /// Adds a movie to the watched list.

  Future<void> addToWatched(Movie movie) async {
    debugPrint('🎬 Adding ${movie.title} (ID: ${movie.id}) to watched list...');
    if (_watchedListId != null) {
      debugPrint('🔍 Using watched list ID: $_watchedListId');
      await _movieListService.addMovieToList(_watchedListId!, movie);
      debugPrint('✅ Movie added to watched MovieList');
    } else {
      debugPrint('❌ Watched list ID is null, cannot add movie');
    }

    // Create/update the movie file to ensure it exists
    await _createOrUpdateMovieFile(movie);
    debugPrint('✅ Movie file created/updated');

    // Force refresh cache for UI updates
    _cachedWatched = null;
    debugPrint('🔄 Watched cache cleared, will refresh on next access');
  }

  /// Removes a movie from the to-watch list and saves to POD.

  Future<void> removeFromToWatch(Movie movie) async {
    // Only use MovieList - remove old TTL operations
    if (_toWatchListId != null) {
      final success =
          await _movieListService.removeMovieFromList(_toWatchListId!, movie);
      if (success) {
        debugPrint('✅ Removed ${movie.title} from To Watch MovieList');

        // Update stream with fresh data from MovieList
        final movies = await getToWatch(forceRefresh: true);
        _toWatchController.add(movies);
        debugPrint(
            '📺 Updated to-watch stream with ${movies.length} movies (force refreshed)');
        return;
      } else {
        debugPrint('❌ Failed to remove ${movie.title} from To Watch MovieList');
      }
    }

    // Fallback to old system if MovieList fails
    final toWatch = await getToWatch();
    toWatch.removeWhere((m) => m.id == movie.id);
    await _saveToWatchToPod(toWatch);
    _toWatchController.add(toWatch);
  }

  /// Removes a movie from the watched list and saves to POD.

  Future<void> removeFromWatched(Movie movie) async {
    // Only use MovieList - remove old TTL operations
    if (_watchedListId != null) {
      final success =
          await _movieListService.removeMovieFromList(_watchedListId!, movie);
      if (success) {
        debugPrint('✅ Removed ${movie.title} from Watched MovieList');

        // Update stream with fresh data from MovieList
        final movies = await getWatched(forceRefresh: true);
        _watchedController.add(movies);
        debugPrint(
            '📺 Updated watched stream with ${movies.length} movies (force refreshed)');
        return;
      } else {
        debugPrint('❌ Failed to remove ${movie.title} from Watched MovieList');
      }
    }

    // Fallback to old system if MovieList fails
    final watched = await getWatched();
    watched.removeWhere((m) => m.id == movie.id);
    await _saveWatchedToPod(watched);
    _watchedController.add(watched);
  }

  /// Checks if a movie is in the to-watch list.

  Future<bool> isInToWatch(Movie movie) async {
    final toWatch = await getToWatch();
    return toWatch.any((m) => m.id == movie.id);
  }

  /// Checks if a movie is in the watched list.

  Future<bool> isInWatched(Movie movie) async {
    debugPrint(
        '🔍 Checking if ${movie.title} (ID: ${movie.id}) is in watched list...');
    final watched = await getWatched();
    final result = watched.any((m) => m.id == movie.id);
    debugPrint(
        '📋 Watched list has ${watched.length} movies, contains ${movie.title}: $result');
    if (watched.isNotEmpty) {
      debugPrint(
          '📋 Movies in watched list: ${watched.map((m) => '${m.title} (${m.id})').join(', ')}');
    }
    return result;
  }

  /// Gets the personal rating for a movie from POD.

  Future<double?> getPersonalRating(Movie movie) async {
    // First check cache.

    if (_cachedRatings != null &&
        _cachedRatings!.containsKey(movie.id.toString())) {
      debugPrint(
          '🎬 Retrieved cached rating for ${movie.title}: ${_cachedRatings![movie.id.toString()]}');
      return _cachedRatings![movie.id.toString()];
    }

    // Try to read file - on first read after app restart, _moviesWithFiles will be empty.
    // But we should still try to read existing files.

    debugPrint('🔍 Loading rating for ${movie.title} from POD...');
    final movieData = await _readMovieFile(movie);
    if (movieData != null && movieData['rating'] != null) {
      final rating = movieData['rating'] as double?;
      if (rating != null) {
        // Cache the result and mark as having a file.

        _cachedRatings ??= {};
        _cachedRatings![movie.id.toString()] = rating;
        _moviesWithFiles.add(movie.id);
        debugPrint('✅ Loaded rating for ${movie.title}: $rating');
        return rating;
      }
    }

    // No rating found - don't cache null values, just return null.

    debugPrint('❌ No rating found for ${movie.title}');
    return null;
  }

  /// Sets the user's personal rating for a movie and saves to POD.

  Future<void> setPersonalRating(Movie movie, double rating) async {
    try {
      debugPrint(
          '🎬 Setting rating $rating for movie ${movie.title} (ID: ${movie.id})');

      // IMMEDIATELY update cache and mark as having file to prevent any reads.

      _cachedRatings ??= {};
      _cachedRatings![movie.id.toString()] = rating;
      _moviesWithFiles.add(movie.id);

      // Create/update the single movie file with the new rating - this is the primary storage now.

      await _createOrUpdateMovieFile(movie, rating: rating);

      debugPrint('✅ Rating saved successfully for movie ${movie.title}');

      // Skip backward compatibility saves to avoid encryption warnings.
      // The movie files are now the primary storage.
    } catch (e) {
      debugPrint('❌ Failed to save rating: $e');
      // Let the UI handle error feedback.
    }
  }

  /// Removes the user's personal rating for a movie from POD.

  Future<void> removePersonalRating(Movie movie) async {
    // Update the cache first to remove the rating.

    final ratings = _cachedRatings ?? {};
    ratings.remove(movie.id.toString());
    _cachedRatings = ratings;

    // Update the single movie file (primary storage) - will remove rating but keep comment if exists.

    await _createOrUpdateMovieFile(movie);

    // Skip backward compatibility saves to avoid encryption warnings.
  }

  /// Gets the personal comments for a movie from POD.

  Future<String?> getMovieComments(Movie movie) async {
    // First check cache.

    if (_cachedComments != null &&
        _cachedComments!.containsKey(movie.id.toString())) {
      final cached = _cachedComments![movie.id.toString()];
      return cached?.isNotEmpty == true ? cached : null;
    }

    // Try to read file - on first read after app restart, _moviesWithFiles will be empty.
    // But we should still try to read existing files.

    final movieData = await _readMovieFile(movie);
    if (movieData != null && movieData['comment'] != null) {
      final comment = movieData['comment'] as String?;
      if (comment != null && comment.isNotEmpty) {
        // Cache the result and mark as having a file.

        _cachedComments ??= {};
        _cachedComments![movie.id.toString()] = comment;
        _moviesWithFiles.add(movie.id);
        return comment;
      }
    }

    // No comment found - don't cache null values, just return null
    return null;
  }

  /// Sets the personal comments for a movie and saves to POD.

  Future<void> setMovieComments(Movie movie, String comments) async {
    try {
      debugPrint(
          '💬 Setting comment for movie ${movie.title} (ID: ${movie.id}): $comments');

      // Immediately update cache and mark as having file to prevent any reads.

      _cachedComments ??= {};
      _cachedComments![movie.id.toString()] = comments;
      _moviesWithFiles.add(movie.id);

      // Create/update the single movie file with the new comment - this is the primary storage now.

      await _createOrUpdateMovieFile(movie, comment: comments);

      debugPrint('✅ Comment saved successfully for movie ${movie.title}');

      // Skip backward compatibility saves to avoid encryption warnings.
      // The movie files are now the primary storage.

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to save comments: $e');
      // Let the UI handle error feedback.
    }
  }

  /// Removes the personal comments for a movie from POD.

  Future<void> removeMovieComments(Movie movie) async {
    // Update the cache first to remove the comment.

    final comments = _cachedComments ?? {};
    comments.remove(movie.id.toString());
    _cachedComments = comments;

    // Update the single movie file (primary storage) - will remove comment but keep rating if exists.

    await _createOrUpdateMovieFile(movie);

    // Skip backward compatibility saves to avoid encryption warnings.

    notifyListeners();
  }

  // NEW SINGLE-FILE MOVIE METHODS

  /// Creates or updates a single movie file containing movie data and user's personal rating/comment.
  /// This is called whenever a user rates or comments on a movie.

  Future<void> _createOrUpdateMovieFile(Movie movie,
      {double? rating, String? comment}) async {
    debugPrint(
        '⏱️ Scheduling debounced movie file update for ${movie.title} (ID: ${movie.id})');

    if (_isSyncing) {
      debugPrint('⏸️ Currently syncing, skipping movie file update');
      return;
    }

    // Cancel any pending update for this movie.

    _pendingMovieUpdates[movie.id]?.cancel();

    // Schedule a new update with a 500ms delay to batch rapid changes.

    _pendingMovieUpdates[movie.id] =
        Timer(const Duration(milliseconds: 500), () async {
      debugPrint('🚀 Executing debounced update for ${movie.title}');
      await _performMovieFileUpdate(movie, rating: rating, comment: comment);
      _pendingMovieUpdates.remove(movie.id);
    });
  }

  /// Actually performs the movie file update after debouncing.

  Future<void> _performMovieFileUpdate(Movie movie,
      {double? rating, String? comment}) async {
    try {
      debugPrint(
          '🔄 Performing movie file update for ${movie.title} (ID: ${movie.id})');

      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        debugPrint('❌ User not logged in, skipping movie file update');
        return;
      }

      // ALWAYS read existing data first to preserve any existing rating/comment
      final existingData = await _readMovieFile(movie);
      final existingRating = existingData?['rating'] as double?;
      final existingComment = existingData?['comment'] as String?;

      debugPrint(
          '📖 Existing data - Rating: $existingRating, Comment: $existingComment');

      // Use provided parameters first, then fallback to cache, then fallback to existing file data
      final currentRating =
          rating ?? _cachedRatings?[movie.id.toString()] ?? existingRating;
      final currentComment =
          comment ?? _cachedComments?[movie.id.toString()] ?? existingComment;

      debugPrint(
          '📊 Final data to save - Rating: $currentRating, Comment: $currentComment');

      // Create movie file even if no rating/comment data to ensure file exists
      // This prevents "file does not exist" errors when reading movie details
      // Only skip if this would create a completely empty update to an existing file

      final hasExistingFile = _moviesWithFiles.contains(movie.id);
      if (currentRating == null &&
          (currentComment == null || currentComment.isEmpty) &&
          hasExistingFile) {
        debugPrint('⏭️ No new data to save for existing file, skipping update');
        return;
      }

      final movieFileName =
          'movies/Movie-${movie.id}.ttl'; // Use Movie-ID pattern to match ontology
      debugPrint('📁 Writing movie file: $movieFileName');

      // Use the new ontology-compliant serialization method
      final ttlContent = TurtleSerializer.movieWithUserDataToTurtleOntology(
        movie,
        currentRating,
        currentComment,
      );

      debugPrint(
          '📝 Generated TTL content (first 200 chars): ${ttlContent.substring(0, ttlContent.length > 200 ? 200 : ttlContent.length)}...');
      debugPrint('📝 Full write path will be: $basePath/$movieFileName');

      // Write to POD without encryption to prevent multiple encryption keys.

      if (!_context.mounted) return;
      final result = await writePod(
        movieFileName,
        ttlContent,
        _context,
        _child,
        encrypted: false,
      );

      debugPrint('💾 WritePod result: $result');

      if (result == SolidFunctionCallStatus.success) {
        // Success - file saved, now update caches with the final saved data
        _moviesWithFiles.add(movie.id);

        // Update caches to match what was actually saved
        if (currentRating != null) {
          _cachedRatings ??= {};
          _cachedRatings![movie.id.toString()] = currentRating;
        }
        if (currentComment != null && currentComment.isNotEmpty) {
          _cachedComments ??= {};
          _cachedComments![movie.id.toString()] = currentComment;
        }

        debugPrint('✅ Movie file saved successfully: $movieFileName');
        debugPrint(
            '💾 Updated caches - Rating: $currentRating, Comment: $currentComment');

        // Only auto-add to watched list when rating is set (not for comments)
        // Comments might be negative ("heard it's bad, don't watch") so shouldn't trigger watched status
        if (currentRating != null) {
          debugPrint(
              '🎭 Rating provided ($currentRating), checking if movie should be auto-added to watched list');
          debugPrint('🔍 Watched list ID: $_watchedListId');

          final isAlreadyWatched = await isInWatched(movie);
          debugPrint(
              '🔍 Movie ${movie.title} already in watched list: $isAlreadyWatched');

          if (!isAlreadyWatched) {
            debugPrint(
                '🎭 Auto-adding ${movie.title} to watched list due to rating $currentRating');
            await addToWatched(movie);
            debugPrint('✅ Completed auto-add to watched list');
          } else {
            debugPrint('🎭 Movie already in watched list, skipping auto-add');
          }
        } else {
          debugPrint(
              '💬 No rating provided, skipping auto-add to watched list');
        }
      } else {
        debugPrint('❌ Failed to save movie file: $result');
        throw Exception('WritePod failed with status: $result');
      }
    } catch (e) {
      debugPrint('❌ Error in movie file update: $e');
    }
  }

  /// Checks if a movie file exists (i.e., user has interacted with this movie).

  Future<bool> hasMovieFile(Movie movie) async {
    // First check our cache.

    if (_moviesWithFiles.contains(movie.id)) {
      return true;
    }

    // Try to read the file to see if it exists.

    final movieData = await _readMovieFile(movie);
    if (movieData != null) {
      final hasRating = movieData['rating'] != null;
      final hasComment = movieData['comment'] != null &&
          (movieData['comment'] as String?)?.isNotEmpty == true;

      if (hasRating || hasComment) {
        // Add to cache since we found the file exists.

        _moviesWithFiles.add(movie.id);

        // Also populate our data caches.

        if (hasRating && movieData['rating'] is double) {
          _cachedRatings ??= {};
          _cachedRatings![movie.id.toString()] = movieData['rating'] as double;
        }
        if (hasComment && movieData['comment'] is String) {
          _cachedComments ??= {};
          _cachedComments![movie.id.toString()] =
              movieData['comment'] as String;
        }

        return true;
      }
    }

    return false;
  }

  /// Gets the file path for a movie file (used for sharing).

  String getMovieFilePath(Movie movie) {
    return '$basePath/movies/Movie-${movie.id}.ttl'; // Use Movie-ID pattern to match ontology
  }

  /// Reads movie data from a single movie file.

  Future<Map<String, dynamic>?> _readMovieFile(Movie movie) async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        debugPrint('❌ User not logged in, cannot read movie file');
        return null;
      }

      // Use full path for readPod to match where files are actually stored.

      final movieFileName =
          '$basePath/movies/Movie-${movie.id}.ttl'; // Use Movie-ID pattern
      debugPrint('🔍 Reading movie file: $movieFileName');
      debugPrint('🔍 Using full path: $movieFileName');

      if (!_context.mounted) return null;
      final result = await readPod(movieFileName, _context, _child);

      if (result.isNotEmpty) {
        debugPrint('✅ Movie file content loaded, length: ${result.length}');
        final movieData = TurtleSerializer.movieWithUserDataFromTurtle(result);
        if (movieData != null) {
          debugPrint('✅ Movie data parsed successfully');
          debugPrint(
              '📊 Rating: ${movieData['rating']}, Comment: ${movieData['comment']}');
        } else {
          debugPrint('❌ Failed to parse movie data from TTL');
        }
        return movieData;
      } else {
        debugPrint('❌ Movie file is empty or not found');
      }
    } catch (e) {
      debugPrint('❌ Error reading movie file for ${movie.title}: $e');
    }
    return null;
  }

  /// Migrates data from SharedPreferences to POD.

  Future<void> migrateToPod() async {
    try {
      // Load data from SharedPreferences.

      final toWatch = await _fallbackService.getToWatch();
      final watched = await _fallbackService.getWatched();

      // Migrate ratings.

      final Map<String, double> ratings = {};
      for (final movie in [...toWatch, ...watched]) {
        final rating = await _fallbackService.getPersonalRating(movie);
        if (rating != null) {
          ratings[movie.id.toString()] = rating;
        }
      }

      // Migrate comments.

      final Map<String, String> comments = {};
      for (final movie in [...toWatch, ...watched]) {
        final comment = await _fallbackService.getMovieComments(movie);
        if (comment != null) {
          comments[movie.id.toString()] = comment;
        }
      }

      // Save to POD.

      await _saveToWatchToPod(toWatch);
      await _saveWatchedToPod(watched);
      await _saveRatingsToPod(ratings);
      // Skip saving comments to old format - we use individual movie files now
      // await _saveCommentsToPod(comments);
    } catch (e) {
      debugPrint('Failed to migrate data to POD: $e');
      rethrow;
    }
  }

  /// Syncs data between POD and local cache.

  Future<void> syncWithPod() async {
    await _loadFromPod();
  }

  /// Reloads data from POD after app folders are initialized.

  Future<void> reloadFromPod() async {
    try {
      final isPodReady = await isPodAvailable();
      if (isPodReady) {
        // Load data without triggering encryption key validation.

        await _loadFromPodWithoutKeyValidation();
      }
    } catch (e) {
      debugPrint('Failed to reload from POD: $e');
    }
  }

  /// Loads data from POD without triggering encryption key validation.
  /// This avoids the encryption key conflicts during initialization.

  Future<void> _loadFromPodWithoutKeyValidation() async {
    _isSyncing = true;

    try {
      // Initialize with empty data first.

      _cachedToWatch = [];
      _cachedWatched = [];
      _cachedRatings = {};
      _cachedComments = {};

      // Try to load each file individually without key validation.

      await _loadFileFromPodWithoutKey(_toWatchFileNameRead, (content) {
        if (content is String) {
          _cachedToWatch = TurtleSerializer.moviesFromTurtle(content);
        }
      });

      await _loadFileFromPodWithoutKey(_watchedFileNameRead, (content) {
        if (content is String) {
          _cachedWatched = TurtleSerializer.moviesFromTurtle(content);
        }
      });

      await _loadFileFromPodWithoutKey(_ratingsFileNameRead, (content) {
        if (content is String) {
          _cachedRatings = TurtleSerializer.ratingsFromTurtle(content);
        }
      });

      // Skip loading old comments file - we use individual movie files now.

      _cachedComments = {};

      // Update streams with POD data.

      _toWatchController.add(_cachedToWatch!);
      _watchedController.add(_cachedWatched!);
    } catch (e) {
      debugPrint('Error loading from POD: $e');
      // Initialize with empty data if POD fails.

      _cachedToWatch = [];
      _cachedWatched = [];
      _cachedRatings = {};
      _cachedComments = {};
    } finally {
      _isSyncing = false;
    }
  }

  /// Checks if POD storage is available and user is logged in.

  Future<bool> isPodAvailable() async {
    try {
      // Import the isLoggedIn function to check POD login status.
      // This is better than trying to read a non-existent file.

      final loggedIn = await isLoggedIn();
      return loggedIn;
    } catch (e) {
      debugPrint('POD availability check failed: $e');
      return false;
    }
  }

  /// Disposes the stream controllers.

  @override
  void dispose() {
    super.dispose();

    // Cancel any pending movie file updates to prevent memory leaks.

    for (final timer in _pendingMovieUpdates.values) {
      timer.cancel();
    }
    _pendingMovieUpdates.clear();

    _toWatchController.close();
    _watchedController.close();
    _fallbackService.dispose();
  }
}
