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

import 'package:moviestar/constants/paths.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/services/movie_list_service.dart';
import 'package:moviestar/services/user_profile_service.dart';
import 'package:moviestar/utils/is_desktop.dart';
import 'package:moviestar/utils/is_logged_in.dart';
import 'package:moviestar/utils/turtle_serializer.dart';

/// A POD-based service class that manages the user's movie lists in Solid POD.

class PodFavoritesService extends ChangeNotifier {
  /// File names for storing data in POD - using different paths for read vs write operations.

  static const String _toWatchFileName = 'user_lists/to_watch.ttl';
  static const String _watchedFileName = 'user_lists/watched.ttl';
  static const String _ratingsFileName = 'ratings/ratings.ttl';

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
    // Initialize ontology services.

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
        // Initialize user profile following the ontology structure.
        await _userProfileService.initializeProfileIfNeeded();

        // Platform-specific initialization strategies
        if (isDesktop) {
          await _initializeForDesktop();
        } else {
          await _initializeForWeb();
        }

        // Only load and update streams if we have valid MovieList IDs.
        if (_toWatchListId != null || _watchedListId != null) {
          await _loadFromPod();
        } else {
          // If we couldn't get MovieList IDs, initialize with empty but don't update streams yet.
          _cachedToWatch = [];
          _cachedWatched = [];
          _cachedRatings = {};
          _cachedComments = {};

          // Platform-specific retry strategies
          if (isDesktop) {
            // Desktop: single retry after short delay
            Future.delayed(const Duration(seconds: 1), () {
              retryPodInitialization();
            });
          } else {
            // Web: more aggressive retry sequence
            Future.delayed(const Duration(seconds: 2), () {
              autoRetryPodInitialization(maxRetries: 5);
            });
          }
        }
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
      debugPrint('❌ [POD Init] Failed to initialize POD data: $e');

      // Enhanced error categorization
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('network') ||
          errorMsg.contains('fetch') ||
          errorMsg.contains('cors')) {
        debugPrint(
            '🌐 [POD Init] Network-related initialization error - likely web environment issue');
      } else if (errorMsg.contains('auth') ||
          errorMsg.contains('permission') ||
          errorMsg.contains('unauthorized')) {
        debugPrint(
            '🔐 [POD Init] Authentication/permission error during initialization');
      } else if (errorMsg.contains('timeout')) {
        debugPrint(
            '⏱️ [POD Init] Timeout during initialization - POD may be slow to respond');
      } else {
        debugPrint('🔍 [POD Init] Unknown initialization error type');
      }

      // Initialise with empty data but don't update streams yet.
      _cachedToWatch = [];
      _cachedWatched = [];
      _cachedRatings = {};
      _cachedComments = {};
      // Wait for retry initialisation instead of showing empty state immediately.
    }
  }

  /// Desktop-specific initialization strategy.
  /// Desktop environments typically have more reliable POD access.

  Future<void> _initializeForDesktop() async {
    // Get or create standard movie lists - desktop can handle synchronous operations better
    _toWatchListId =
        await _movieListService.getOrCreateStandardMovieList('to_watch');
    _watchedListId =
        await _movieListService.getOrCreateStandardMovieList('watched');
  }

  /// Web-specific initialization strategy.
  /// Web environments may have authentication delays and network limitations.

  Future<void> _initializeForWeb() async {
    // Web environments often have delayed authentication, so we use more aggressive retry logic
    final List<Future<String?>> listInitFutures = [
      _initializeWebMovieList('to_watch'),
      _initializeWebMovieList('watched'),
    ];

    // Run list initializations in parallel for better performance
    final results = await Future.wait(listInitFutures);

    _toWatchListId = results[0];
    _watchedListId = results[1];
  }

  /// Initialize a specific movie list for web environment with retries.

  Future<String?> _initializeWebMovieList(String listType) async {
    const maxRetries = 2; // Fewer retries for initial load to avoid blocking UI
    const retryDelay = Duration(milliseconds: 500);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final listId =
            await _movieListService.getOrCreateStandardMovieList(listType);
        if (listId != null) {
          return listId;
        }
      } catch (e) {
        debugPrint(
            '❌ [Web List Init] Attempt $attempt failed for $listType: $e');
      }

      if (attempt < maxRetries) {
        await Future.delayed(retryDelay);
      }
    }

    return null;
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

      // Load from MovieList system instead of old TTL files.
      if (_toWatchListId != null) {
        final movieListData = await _movieListService.getMovieList(
          _toWatchListId!,
        );
        if (movieListData != null) {
          _cachedToWatch = List<Movie>.from(movieListData['movies'] ?? []);
        }
      }

      if (_watchedListId != null) {
        final movieListData = await _movieListService.getMovieList(
          _watchedListId!,
        );
        if (movieListData != null) {
          _cachedWatched = List<Movie>.from(movieListData['movies'] ?? []);
        }
      }

      // Load ratings from individual movie files (no longer using ratings.ttl).
      _cachedRatings = {};
      _cachedComments = {};

      // Update streams with loaded data - even if empty, this ensures UI consistency
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
      await writePod(
        _ratingsFileName,
        ttlContent,
        _context,
        _child,
        encrypted: false,
      );
      _cachedRatings = Map.from(ratings);
    } catch (e) {
      // Don't log - this is background save for compatibility
      // debugPrint('Failed to save ratings to POD: $e');
    }
  }

  /// Helper method to ensure a movie has contentType set.

  Movie _ensureContentType(Movie movie) {
    if (movie.contentType != null) {
      return movie;
    }
    // Migrate movies without contentType to have it set as movie.

    return Movie(
      id: movie.id,
      title: movie.title,
      overview: movie.overview,
      posterUrl: movie.posterUrl,
      backdropUrl: movie.backdropUrl,
      voteAverage: movie.voteAverage,
      releaseDate: movie.releaseDate,
      genreIds: movie.genreIds,
      contentType: ContentType.movie,
    );
  }

  /// Helper method to ensure all movies in a list have contentType set.

  List<Movie> _ensureAllContentTypes(List<Movie> movies) {
    return movies.map((movie) => _ensureContentType(movie)).toList();
  }

  /// Retrieves the list of to-watch movies from POD cache.

  Future<List<Movie>> getToWatch({bool forceRefresh = false}) async {
    // Read from MovieList file instead of cached old TTL data.
    if (_toWatchListId != null) {
      try {
        final movieListData = await _movieListService.getMovieList(
          _toWatchListId!,
          forceRefresh: forceRefresh,
        );
        if (movieListData != null) {
          final movies = movieListData['movies'] as List<Movie>? ?? [];
          return _ensureAllContentTypes(movies);
        }
      } catch (e) {
        debugPrint('❌ [Get ToWatch] Error reading from MovieList: $e');
      }
    }

    // Fallback to cached data if MovieList fails.
    if (_cachedToWatch != null) {
      return _ensureAllContentTypes(_cachedToWatch!);
    }

    // Final fallback to SharedPreferences.
    try {
      final fallbackMovies = await _fallbackService.getToWatch();

      // Cache the fallback data for next time
      if (fallbackMovies.isNotEmpty) {
        _cachedToWatch = fallbackMovies;
      }

      return _ensureAllContentTypes(fallbackMovies);
    } catch (e) {
      debugPrint('❌ [Get ToWatch] SharedPreferences fallback failed: $e');
      return <Movie>[];
    }
  }

  /// Retrieves the list of watched movies from POD cache.

  Future<List<Movie>> getWatched({bool forceRefresh = false}) async {
    // Read from MovieList file instead of cached old TTL data.
    if (_watchedListId != null) {
      try {
        final movieListData = await _movieListService.getMovieList(
          _watchedListId!,
          forceRefresh: forceRefresh,
        );
        if (movieListData != null) {
          final movies = movieListData['movies'] as List<Movie>? ?? [];
          return _ensureAllContentTypes(movies);
        }
      } catch (e) {
        debugPrint('❌ [Get Watched] Error reading from MovieList: $e');
      }
    }

    // Fallback to cached data if MovieList fails.
    if (_cachedWatched != null) {
      return _ensureAllContentTypes(_cachedWatched!);
    }

    // Final fallback to SharedPreferences.
    try {
      final fallbackMovies = await _fallbackService.getWatched();

      // Cache the fallback data for next time
      if (fallbackMovies.isNotEmpty) {
        _cachedWatched = fallbackMovies;
      }

      return _ensureAllContentTypes(fallbackMovies);
    } catch (e) {
      debugPrint('❌ [Get Watched] SharedPreferences fallback failed: $e');
      return <Movie>[];
    }
  }

  /// Adds a movie to the to-watch list and saves to POD.
  ///
  /// [contentType] specifies whether this is a movie or TV show.

  Future<void> addToWatch(Movie movie, {String contentType = 'movie'}) async {
    // If toWatchListId is null, try to initialise it first.

    if (_toWatchListId == null) {
      await _retryInitializeMovieListIds();
    }

    // Only use MovieList - remove old TTL operations.
    if (_toWatchListId != null) {
      final success = await _movieListService.addMovieToList(
        _toWatchListId!,
        movie,
        contentType: contentType,
      );
      if (success) {
        // Update stream with fresh data from MovieList.
        final movies = await getToWatch(forceRefresh: true);
        _toWatchController.add(movies);

        // DO NOT call _createOrUpdateMovieFile() here to avoid race condition.
        // The movie file should already be created/updated by the caller.
        return;
      } else {
        debugPrint('❌ Failed to add ${movie.title} to To Watch MovieList');
      }
    } else {
      debugPrint('❌ To Watch list ID is null, cannot add movie to MovieList');
    }

    // Fallback to old system if MovieList fails.
    final toWatch = await getToWatch();
    if (!toWatch.any((m) => m.id == movie.id)) {
      toWatch.add(movie);
      await _saveToWatchToPod(toWatch);
      _toWatchController.add(toWatch);
      // DO NOT call _createOrUpdateMovieFile() here to avoid race condition.
    }
  }

  /// Adds a movie to the watched list.
  ///
  /// [contentType] specifies whether this is a movie or TV show.

  Future<void> addToWatched(Movie movie, {String contentType = 'movie'}) async {
    // If watchedListId is null, try to initialise it first.

    if (_watchedListId == null) {
      await _retryInitializeMovieListIds();
    }

    if (_watchedListId != null) {
      final success = await _movieListService.addMovieToList(
        _watchedListId!,
        movie,
        contentType: contentType,
      );
      if (success) {
        // Update stream with fresh data from MovieList.

        final movies = await getWatched(forceRefresh: true);
        _watchedController.add(movies);

        // Create/update the movie file to ensure it exists.

        await _createOrUpdateMovieFile(movie);
        return;
      } else {
        debugPrint('❌ Failed to add ${movie.title} to Watched MovieList');
      }
    } else {
      debugPrint('❌ Watched list ID is null, cannot add movie to MovieList');
    }

    // Fallback to old system if MovieList fails.

    final watched = await getWatched();
    if (!watched.any((m) => m.id == movie.id)) {
      watched.add(movie);
      await _saveWatchedToPod(watched);
      _watchedController.add(watched);
    }

    // Create/update the movie file to ensure it exists.
    await _createOrUpdateMovieFile(movie);

    // Force refresh cache for UI updates.
    _cachedWatched = null;
  }

  /// Removes a movie from the to-watch list and saves to POD.

  Future<void> removeFromToWatch(Movie movie) async {
    // Only use MovieList - remove old TTL operations.

    if (_toWatchListId != null) {
      final success = await _movieListService.removeMovieFromList(
        _toWatchListId!,
        movie,
      );
      if (success) {
        // Update stream with fresh data from MovieList.

        final movies = await getToWatch(forceRefresh: true);
        _toWatchController.add(movies);
        return;
      } else {
        debugPrint('❌ Failed to remove ${movie.title} from To Watch MovieList');
      }
    }

    // Fallback to old system if MovieList fails.

    final toWatch = await getToWatch();
    toWatch.removeWhere((m) => m.id == movie.id);
    await _saveToWatchToPod(toWatch);
    _toWatchController.add(toWatch);
  }

  /// Removes a movie from the watched list and saves to POD.

  Future<void> removeFromWatched(Movie movie) async {
    // Only use MovieList - remove old TTL operations.

    if (_watchedListId != null) {
      final success = await _movieListService.removeMovieFromList(
        _watchedListId!,
        movie,
      );
      if (success) {
        // Update stream with fresh data from MovieList.

        final movies = await getWatched(forceRefresh: true);
        _watchedController.add(movies);
        return;
      } else {
        debugPrint('❌ Failed to remove ${movie.title} from Watched MovieList');
      }
    }

    // Fallback to old system if MovieList fails.

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
    final watched = await getWatched();
    final result = watched.any((m) => m.id == movie.id);
    return result;
  }

  /// Gets the personal rating for a movie from POD.

  Future<double?> getPersonalRating(Movie movie) async {
    // First check cache.

    if (_cachedRatings != null &&
        _cachedRatings!.containsKey(movie.id.toString())) {
      return _cachedRatings![movie.id.toString()];
    }

    // Try to read file - on first read after app restart, _moviesWithFiles will be empty.
    // But we should still try to read existing files.

    final movieData = await _readMovieFile(movie);
    if (movieData != null && movieData['rating'] != null) {
      final rating = movieData['rating'] as double?;
      if (rating != null) {
        // Cache the result and mark as having a file.

        _cachedRatings ??= {};
        _cachedRatings![movie.id.toString()] = rating;
        _moviesWithFiles.add(movie.id);
        return rating;
      }
    }

    // No rating found - don't cache null values, just return null.

    return null;
  }

  /// Sets the user's personal rating for a movie and saves to POD.

  Future<void> setPersonalRating(Movie movie, double rating) async {
    try {
      // IMMEDIATELY update cache and mark as having file to prevent any reads.

      _cachedRatings ??= {};
      _cachedRatings![movie.id.toString()] = rating;
      _moviesWithFiles.add(movie.id);

      // Create/update the single movie file with the new rating - this is the primary storage now.

      await _createOrUpdateMovieFile(movie, rating: rating);

      // Skip backward compatibility saves to avoid encryption warnings.
      // The movie files are now the primary storage.
    } catch (e) {
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
      // Immediately update cache and mark as having file to prevent any reads.

      _cachedComments ??= {};
      _cachedComments![movie.id.toString()] = comments;
      _moviesWithFiles.add(movie.id);

      // Create/update the single movie file with the new comment - this is the primary storage now.

      await _createOrUpdateMovieFile(movie, comment: comments);

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

  Future<void> _createOrUpdateMovieFile(
    Movie movie, {
    double? rating,
    String? comment,
    String contentType = 'movie',
  }) async {
    if (_isSyncing) {
      return;
    }

    // Cancel any pending update for this movie.

    _pendingMovieUpdates[movie.id]?.cancel();

    // Schedule a new update with a 500ms delay to batch rapid changes.

    _pendingMovieUpdates[movie.id] = Timer(
      const Duration(milliseconds: 500),
      () async {
        await _performMovieFileUpdate(
          movie,
          rating: rating,
          comment: comment,
          contentType: contentType,
        );
        _pendingMovieUpdates.remove(movie.id);
      },
    );
  }

  /// Actually performs the movie file update after debouncing.

  Future<void> _performMovieFileUpdate(
    Movie movie, {
    double? rating,
    String? comment,
    String contentType = 'movie',
  }) async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        debugPrint('❌ User not logged in, skipping movie file update');
        return;
      }

      // ALWAYS read existing data first to preserve any existing rating/comment
      final existingData = await _readMovieFile(movie);
      final existingRating = existingData?['rating'] as double?;
      final existingComment = existingData?['comment'] as String?;

      // Use provided parameters first, then fallback to cache, then fallback to existing file data
      final currentRating =
          rating ?? _cachedRatings?[movie.id.toString()] ?? existingRating;
      final currentComment =
          comment ?? _cachedComments?[movie.id.toString()] ?? existingComment;

      // Create movie file even if no rating/comment data to ensure file exists
      // This prevents "file does not exist" errors when reading movie details
      // Only skip if this would create a completely empty update to an existing file

      final hasExistingFile = _moviesWithFiles.contains(movie.id);
      if (currentRating == null &&
          (currentComment == null || currentComment.isEmpty) &&
          hasExistingFile) {
        return;
      }

      final movieFileName =
          'movies/Movie-${movie.id}.ttl'; // Use Movie-ID pattern to match ontology

      // Use the new ontology-compliant serialization method
      final ttlContent = TurtleSerializer.movieWithUserDataToTurtleOntology(
        movie,
        currentRating,
        currentComment,
      );

      // Write to POD without encryption to prevent multiple encryption keys.

      if (!_context.mounted) return;
      final result = await writePod(
        movieFileName,
        ttlContent,
        _context,
        _child,
        encrypted: false,
      );

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

        // Only auto-add to watched list when rating is set (not for comments)
        // Comments might be negative ("heard it's bad, don't watch") so shouldn't trigger watched status
        if (currentRating != null) {
          final isAlreadyWatched = await isInWatched(movie);

          if (!isAlreadyWatched) {
            await addToWatched(movie, contentType: contentType);
          }
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

      if (!_context.mounted) return null;
      final result = await readPod(movieFileName, _context, _child);

      if (result.isNotEmpty) {
        final movieData = TurtleSerializer.movieWithUserDataFromTurtle(result);
        return movieData;
      } else {
        // This is expected for movies that haven't been rated/commented yet.
      }
    } catch (e) {
      if (e.toString().contains('does not exist')) {
        // This is expected for movies that haven't been rated/commented yet.
      } else {
        debugPrint('❌ Error reading movie file for ${movie.title}: $e');
      }
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

  /// Retries POD initialization with exponential backoff for web environments.
  /// This is useful when initial initialization fails due to timing or auth issues.

  Future<void> retryPodInitialization() async {
    try {
      final isPodReady = await isPodAvailable();
      if (!isPodReady) {
        return;
      }

      // Initialize user profile if needed
      await _userProfileService.initializeProfileIfNeeded();

      bool needsStreamRefresh = false;

      // Retry getting MovieList IDs
      if (_toWatchListId == null) {
        _toWatchListId =
            await _movieListService.getOrCreateStandardMovieList('to_watch');
        if (_toWatchListId != null) {
          needsStreamRefresh = true;
        }
      }

      if (_watchedListId == null) {
        _watchedListId =
            await _movieListService.getOrCreateStandardMovieList('watched');
        if (_watchedListId != null) {
          needsStreamRefresh = true;
        }
      }

      if (needsStreamRefresh) {
        await refreshUIStreams();
      }
    } catch (e) {
      debugPrint('❌ [Retry Init] POD initialization retry failed: $e');
    }
  }

  /// Auto-retry POD initialization with exponential backoff.
  /// Useful for web environments where initial auth may take time.

  Future<void> autoRetryPodInitialization({int maxRetries = 5}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      // Check if we already have both IDs
      if (_toWatchListId != null && _watchedListId != null) {
        return;
      }

      await retryPodInitialization();

      // If we got at least one ID, we can stop retrying
      if (_toWatchListId != null || _watchedListId != null) {
        return;
      }

      if (attempt < maxRetries) {
        // Exponential backoff: 2^attempt seconds
        final waitTime = Duration(seconds: (2 << (attempt - 1)).clamp(2, 30));
        await Future.delayed(waitTime);
      }
    }
  }

  /// Reloads data from POD after app folders are initialized.

  Future<void> reloadFromPod() async {
    try {
      final isPodReady = await isPodAvailable();
      if (isPodReady) {
        // Re-initialise MovieList IDs if they're not set yet.
        // This is crucial after app folders are ready.

        if (_toWatchListId == null || _watchedListId == null) {
          await _userProfileService.initializeProfileIfNeeded();

          _toWatchListId ??=
              await _movieListService.getOrCreateStandardMovieList('to_watch');
          _watchedListId ??=
              await _movieListService.getOrCreateStandardMovieList('watched');
        }

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

      // Load from MovieList system instead of old TTL files.

      if (_toWatchListId != null) {
        final movieListData = await _movieListService.getMovieList(
          _toWatchListId!,
        );
        if (movieListData != null) {
          _cachedToWatch = List<Movie>.from(movieListData['movies'] ?? []);
        }
      }

      if (_watchedListId != null) {
        final movieListData = await _movieListService.getMovieList(
          _watchedListId!,
        );
        if (movieListData != null) {
          _cachedWatched = List<Movie>.from(movieListData['movies'] ?? []);
        }
      }

      // Load ratings from individual movie files (no longer using ratings.ttl).

      _cachedRatings = {};
      _cachedComments = {};

      // Only update streams if we have at least one valid MovieList ID.
      // This prevents showing empty state before MovieList IDs are discovered.

      if (_toWatchListId != null || _watchedListId != null) {
        _toWatchController.add(_cachedToWatch!);
        _watchedController.add(_cachedWatched!);
      }
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

  /// Retry initialization of movie list IDs if they are null.

  Future<void> _retryInitializeMovieListIds() async {
    try {
      // Check if user is logged into POD first.

      final isPodReady = await isPodAvailable();
      if (!isPodReady) {
        debugPrint('❌ POD not available, cannot initialize movie list IDs');
        return;
      }

      // Initialise user profile if needed.

      await _userProfileService.initializeProfileIfNeeded();

      bool needsStreamUpdate = false;

      // Try to get or create standard movie lists if they're still null.

      if (_toWatchListId == null) {
        _toWatchListId = await _movieListService.getOrCreateStandardMovieList(
          'to_watch',
        );
        if (_toWatchListId != null) {
          needsStreamUpdate = true;
        } else {
          debugPrint('❌ Failed to initialize To Watch list ID');
        }
      }

      if (_watchedListId == null) {
        _watchedListId = await _movieListService.getOrCreateStandardMovieList(
          'watched',
        );
        if (_watchedListId != null) {
          needsStreamUpdate = true;
        } else {
          debugPrint('❌ Failed to initialize Watched list ID');
        }
      }

      // Update streams with current data after successful initialisation.

      if (needsStreamUpdate) {
        final toWatchMovies = await getToWatch(forceRefresh: true);
        final watchedMovies = await getWatched(forceRefresh: true);
        _toWatchController.add(toWatchMovies);
        _watchedController.add(watchedMovies);
      }
    } catch (e) {
      debugPrint('❌ Failed to retry initialize movie list IDs: $e');
    }
  }

  /// Forces a refresh of the UI streams with current data from MovieLists.
  /// This ensures the UI shows the latest data after app restart.

  Future<void> refreshUIStreams() async {
    try {
      // Modified logic: Only skip if BOTH IDs are null AND we have no cached data
      // This allows showing cached/fallback data even when MovieList discovery fails
      if (_toWatchListId == null && _watchedListId == null) {
        // Check if we have any cached data to show
        final hasCachedData = (_cachedToWatch?.isNotEmpty == true) ||
            (_cachedWatched?.isNotEmpty == true);

        if (!hasCachedData) {
          // Try to load from SharedPreferences as a last resort
          try {
            final fallbackToWatch = await _fallbackService.getToWatch();
            final fallbackWatched = await _fallbackService.getWatched();

            if (fallbackToWatch.isNotEmpty || fallbackWatched.isNotEmpty) {
              _toWatchController.add(fallbackToWatch);
              _watchedController.add(fallbackWatched);
              return;
            }
          } catch (fallbackError) {
            debugPrint(
                '❌ [Stream Update] Fallback data load failed: $fallbackError');
          }

          return;
        }
      }

      final toWatchMovies = await getToWatch(forceRefresh: true);
      final watchedMovies = await getWatched(forceRefresh: true);

      _toWatchController.add(toWatchMovies);
      _watchedController.add(watchedMovies);
    } catch (e) {
      debugPrint('❌ [Stream Update] Failed to refresh UI streams: $e');

      // Try to provide some fallback data even if refresh fails
      try {
        if (_cachedToWatch != null) {
          _toWatchController.add(_cachedToWatch!);
        }
        if (_cachedWatched != null) {
          _watchedController.add(_cachedWatched!);
        }
      } catch (fallbackError) {
        debugPrint(
            '❌ [Stream Update] Even fallback stream update failed: $fallbackError');
      }
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
