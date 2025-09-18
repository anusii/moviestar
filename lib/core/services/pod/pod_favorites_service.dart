/// POD-based service for managing favorite movies using decomposed operations.
/// Facade service delegating to specialized operation classes.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:moviestar/core/services/favorites/movie_list_service.dart';
import 'package:moviestar/core/services/pod/base_pod_service.dart';
import 'package:moviestar/core/services/pod/favorites/pod_favorites_cache_manager.dart';
import 'package:moviestar/core/services/pod/favorites/pod_favorites_file_handler.dart';
import 'package:moviestar/core/services/pod/favorites/pod_favorites_list_operations.dart';
import 'package:moviestar/core/services/pod/favorites/pod_favorites_movie_operations.dart';
import 'package:moviestar/core/services/pod/pod_favorites_file_manager.dart';
import 'package:moviestar/core/services/pod/pod_favorites_stream_manager.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/user_profile_service.dart';

/// POD-based service for managing favorite movies using decomposed operations.
/// Uses specialized operation classes for different concerns.
class PodFavoritesService extends BasePodService {
  final Set<int> _moviesWithFiles = {};
  final Map<int, Movie> _movieCache = {};

  /// Callback to notify when initial loading is complete.
  final VoidCallback? _onInitialLoadComplete;

  late final PodFavoritesStreamManager _streamManager;
  late final PodFavoritesFileManager _fileManager;
  late final MovieListService _movieListService;
  late final UserProfileService _userProfileService;

  // Decomposed operation classes
  late final PodFavoritesMovieOperations _movieOperations;
  late final PodFavoritesListOperations _listOperations;
  late final PodFavoritesCacheManager _cacheManager;
  late final PodFavoritesFileHandler _fileHandler;

  PodFavoritesService(
    super.context,
    super.child, {
    VoidCallback? onInitialLoadComplete,
  }) : _onInitialLoadComplete = onInitialLoadComplete {
    _streamManager = PodFavoritesStreamManager();
    _fileManager = PodFavoritesFileManager(context, child);
    _userProfileService = UserProfileService(context, child);
    _movieListService = MovieListService(context, child, _userProfileService);

    // Initialize decomposed operation classes
    _movieOperations = PodFavoritesMovieOperations(
      _streamManager,
      _fileManager,
      _movieListService,
      _movieCache,
      _moviesWithFiles,
      executePodOperation,
      safeWriteFile,
    );
    _listOperations = PodFavoritesListOperations(
      _streamManager,
      _movieListService,
    );
    _cacheManager = PodFavoritesCacheManager(
      _movieCache,
      _moviesWithFiles,
      _streamManager,
      _fileManager,
    );
    _fileHandler = PodFavoritesFileHandler(
      _fileManager,
      safeReadFile,
    );

    // Initialize by loading favorites from POD
    debugPrint('🎬 [PodFavoritesService] Constructor called - initializing...');
    loadFavorites().then((_) {
      debugPrint(
        '🎬 [PodFavoritesService] Initial loadFavorites completed successfully',
      );
      // Notify manager that initial loading is complete
      if (_onInitialLoadComplete != null) {
        debugPrint(
          '🎬 [PodFavoritesService] Calling onInitialLoadComplete callback',
        );
        _onInitialLoadComplete();
      }
    }).catchError((error) {
      debugPrint(
        '🎬 [PodFavoritesService] Error loading initial favorites: $error',
      );
      // Even on error, notify that loading attempt is complete
      if (_onInitialLoadComplete != null) {
        debugPrint(
          '🎬 [PodFavoritesService] Calling onInitialLoadComplete callback (after error)',
        );
        _onInitialLoadComplete();
      }
    });
  }

  /// Stream of to-watch movies.
  Stream<List<Movie>> get toWatchStream => _streamManager.toWatchStream;
  Stream<List<Movie>> get toWatchMovies => _streamManager.toWatchMovies;

  /// Stream of watched movies.
  Stream<List<Movie>> get watchedStream => _streamManager.watchedStream;
  Stream<List<Movie>> get watchedMovies => _streamManager.watchedMovies;

  /// Stream of custom lists.
  Stream<List<CustomList>> get customListsStream =>
      _streamManager.customListsStream;

  /// Stream of custom lists (compatible interface).
  Stream<List<CustomList>> get customLists => customListsStream;

  /// Current to-watch list.
  List<Movie> get toWatch => _streamManager.toWatch;

  /// Current watched list.
  List<Movie> get watched => _streamManager.watched;

  /// Loads the user's favorites from POD.
  Future<void> loadFavorites() async {
    debugPrint('🎬 [PodFavoritesService] loadFavorites() called');
    await executePodOperation(
      operation: () async {
        final favoritesData = await _fileHandler.loadFavoritesData();

        _streamManager.updateToWatch(favoritesData['toWatch'] ?? []);
        _streamManager.updateWatched(favoritesData['watched'] ?? []);

        await _listOperations.loadCustomLists();
        return null;
      },
      operationName: 'loadFavorites',
    );
  }

  /// Adds a movie to the to-watch list.
  Future<void> addToWatchList(Movie movie) async {
    return _movieOperations.addToWatchList(movie);
  }

  /// Removes a movie from the to-watch list.
  Future<void> removeFromWatchList(int movieId) async {
    return _movieOperations.removeFromWatchList(movieId);
  }

  /// Adds a movie to the watched list.
  Future<void> addToWatchedList(Movie movie) async {
    return _movieOperations.addToWatchedList(movie);
  }

  /// Removes a movie from the watched list.
  Future<void> removeFromWatchedList(int movieId) async {
    return _movieOperations.removeFromWatchedList(movieId);
  }

  /// Gets a movie by ID from cache or delegates to MovieListService.
  Future<Movie?> getMovie(int movieId) async {
    return _movieOperations.getMovie(movieId);
  }

  /// Deletes a custom list using MovieListService.
  Future<void> deleteCustomList(String listId) async {
    return _listOperations.deleteCustomList(listId);
  }

  /// Checks if a movie is in the to-watch list.
  bool isInToWatchList(int movieId) {
    return _movieOperations.isInToWatchList(movieId);
  }

  /// Checks if a movie is in the watched list.
  bool isInWatchedList(int movieId) {
    return _movieOperations.isInWatchedList(movieId);
  }

  /// Clears all caches.
  void clearCache() {
    _cacheManager.clearCache();
  }

  /// Reloads data from POD after initialization.
  Future<void> reloadFromPod() async {
    await loadFavorites();
  }

  /// Refreshes UI streams with latest data.
  Future<void> refreshUIStreams() async {
    await loadFavorites();
  }

  /// Gets the to-watch list.
  Future<List<Movie>> getToWatch() async {
    return _streamManager.toWatch;
  }

  /// Gets the watched list.
  Future<List<Movie>> getWatched() async {
    return _streamManager.watched;
  }

  /// Adds a movie to to-watch list with content type support.
  Future<void> addToWatch(Movie movie, {String contentType = 'movie'}) async {
    return _movieOperations.addToWatch(movie, contentType: contentType);
  }

  /// Adds a movie to watched list with content type support.
  Future<void> addToWatched(Movie movie, {String contentType = 'movie'}) async {
    return _movieOperations.addToWatched(movie, contentType: contentType);
  }

  /// Removes a movie from to-watch list.
  Future<void> removeFromToWatch(Movie movie) async {
    return _movieOperations.removeFromToWatch(movie);
  }

  /// Removes a movie from watched list.
  Future<void> removeFromWatched(Movie movie) async {
    return _movieOperations.removeFromWatched(movie);
  }

  /// Checks if a movie is in to-watch list.
  Future<bool> isInToWatch(Movie movie) async {
    return _movieOperations.isInToWatch(movie);
  }

  /// Checks if a movie is in watched list.
  Future<bool> isInWatched(Movie movie) async {
    return _movieOperations.isInWatched(movie);
  }

  /// Gets personal rating for a movie.
  Future<double?> getPersonalRating(Movie movie) async {
    return _movieOperations.getPersonalRating(movie);
  }

  /// Sets personal rating for a movie.
  Future<void> setPersonalRating(Movie movie, double rating) async {
    return _movieOperations.setPersonalRating(movie, rating);
  }

  /// Removes personal rating for a movie.
  Future<void> removePersonalRating(Movie movie) async {
    return _movieOperations.removePersonalRating(movie);
  }

  /// Gets personal comments for a movie.
  Future<String?> getMovieComments(Movie movie) async {
    return _movieOperations.getMovieComments(movie);
  }

  /// Sets personal comments for a movie.
  Future<void> setMovieComments(Movie movie, String comments) async {
    return _movieOperations.setMovieComments(movie, comments);
  }

  /// Removes personal comments for a movie.
  Future<void> removeMovieComments(Movie movie) async {
    return _movieOperations.removeMovieComments(movie);
  }

  /// Checks if a movie file exists.
  Future<bool> hasMovieFile(Movie movie) async {
    return _cacheManager.hasMovieFile(movie);
  }

  /// Gets the file path for a movie file.
  String? getMovieFilePath(Movie movie) {
    return _cacheManager.getMovieFilePath(movie);
  }

  /// Gets all custom lists.
  Future<List<CustomList>> getCustomLists() async {
    return _listOperations.getCustomLists();
  }

  /// Creates a custom list.
  Future<CustomList> createCustomList(
    String name, {
    String? description,
  }) async {
    return _listOperations.createCustomList(name, description: description);
  }

  /// Updates a custom list.
  Future<void> updateCustomList(CustomList updatedList) async {
    return _listOperations.updateCustomList(updatedList);
  }

  /// Adds a movie to a custom list.
  Future<void> addMovieToCustomList(
    String listId,
    Movie movie, {
    String contentType = 'movie',
  }) async {
    return _listOperations.addMovieToCustomList(
      listId,
      movie,
      contentType: contentType,
    );
  }

  /// Removes a movie from a custom list.
  Future<void> removeMovieFromCustomList(String listId, int movieId) async {
    return _listOperations.removeMovieFromCustomList(listId, movieId);
  }

  /// Checks if a movie is in a custom list.
  Future<bool> isMovieInCustomList(String listId, int movieId) async {
    return _listOperations.isMovieInCustomList(listId, movieId);
  }

  /// Gets custom lists containing a movie.
  Future<List<CustomList>> getCustomListsContainingMovie(int movieId) async {
    return _listOperations.getCustomListsContainingMovie(movieId);
  }

  /// Gets movies in a custom list.
  Future<List<Movie>> getMoviesInCustomList(String listId) async {
    return _listOperations.getMoviesInCustomList(listId);
  }

  /// Checks if POD is available.
  Future<bool> isPodAvailable() async {
    return await executePodOperation(
          operation: () async {
            return true;
          },
          operationName: 'isPodAvailable',
          requiresLogin: false,
        ) !=
        null;
  }

  /// Migrates data to POD.
  Future<void> migrateToPod() async {
    // Migration logic would be implemented here
  }

  /// Migrates custom lists to POD.
  Future<void> migrateCustomListsToPod() async {
    // Custom list migration logic would be implemented here
  }

  /// Syncs data with POD.
  Future<void> syncWithPod() async {
    await loadFavorites();
  }

  @override
  void dispose() {
    _streamManager.dispose();
    super.dispose();
  }
}
