/// Compact PodFavoritesService using existing helper infrastructure.
/// Reduced from 1,608 to ~280 lines by using BasePodService and helper classes.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:moviestar/core/services/favorites/favorites_service.dart';
import 'package:moviestar/core/services/favorites/movie_list_service.dart';
import 'package:moviestar/core/services/pod/base_pod_service.dart';
import 'package:moviestar/core/services/pod/pod_favorites_file_manager.dart';
import 'package:moviestar/core/services/pod/pod_favorites_stream_manager.dart';
import 'package:moviestar/core/services/pod/pod_list_management_service.dart';
import 'package:moviestar/core/services/pod/pod_sharing_service.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/user_profile_service.dart';

/// Compact POD-based service for managing favorite movies using composition.
/// Uses BasePodService infrastructure and helper classes for common operations.
class PodFavoritesService extends BasePodService {
  final SharedPreferences _prefs;
  final FavoritesService _fallbackService;
  final Set<int> _moviesWithFiles = {};
  final Map<int, Movie> _movieCache = {};

  late final PodFavoritesStreamManager _streamManager;
  late final PodFavoritesFileManager _fileManager;
  late final MovieListService _movieListService;
  late final UserProfileService _userProfileService;
  late final PodListManagementService _listManagementService;
  late final PodSharingService _sharingService;

  PodFavoritesService(
    super.context,
    super.child,
    this._prefs,
    this._fallbackService,
  ) {
    _streamManager = PodFavoritesStreamManager();
    _fileManager = PodFavoritesFileManager(context, child);
    _userProfileService = UserProfileService(context, child);
    _movieListService = MovieListService(context, child, _userProfileService);
    _listManagementService = PodListManagementService(context, child);
    _sharingService = PodSharingService(context, child);
  }

  /// Stream of to-watch movies.
  Stream<List<Movie>> get toWatchStream => _streamManager.toWatchStream;

  /// Stream of watched movies.
  Stream<List<Movie>> get watchedStream => _streamManager.watchedStream;

  /// Stream of custom lists.
  Stream<List<CustomList>> get customListsStream =>
      _streamManager.customListsStream;

  /// Current to-watch list.
  List<Movie> get toWatch => _streamManager.toWatch;

  /// Current watched list.
  List<Movie> get watched => _streamManager.watched;

  /// Current custom lists.
  List<CustomList> get customLists => _streamManager.customLists;

  /// Loads the user's favorites from POD.
  Future<void> loadFavorites() async {
    await executePodOperation(
      operation: () async {
        final toWatchData =
            await safeReadFile('moviestar/data/user_lists/to_watch.ttl');
        final watchedData =
            await safeReadFile('moviestar/data/user_lists/watched.ttl');

        if (toWatchData != null && toWatchData.isNotEmpty) {
          final movies = await _parseMoviesFromTtl(toWatchData);
          _streamManager.updateToWatch(movies);
        }

        if (watchedData != null && watchedData.isNotEmpty) {
          final movies = await _parseMoviesFromTtl(watchedData);
          _streamManager.updateWatched(movies);
        }

        await _loadCustomLists();
        return null;
      },
      operationName: 'loadFavorites',
    );
  }

  /// Adds a movie to the to-watch list.
  Future<void> addToWatchList(Movie movie) async {
    await _addToList(
      movie,
      'to_watch',
      'Movies to Watch',
      _streamManager.updateToWatch,
    );
  }

  /// Removes a movie from the to-watch list.
  Future<void> removeFromWatchList(int movieId) async {
    await _removeFromList(
      movieId,
      'to_watch',
      'Movies to Watch',
      _streamManager.updateToWatch,
    );
  }

  /// Adds a movie to the watched list.
  Future<void> addToWatchedList(Movie movie) async {
    await _addToList(
      movie,
      'watched',
      'Movies Watched',
      _streamManager.updateWatched,
    );
  }

  /// Removes a movie from the watched list.
  Future<void> removeFromWatchedList(int movieId) async {
    await _removeFromList(
      movieId,
      'watched',
      'Movies Watched',
      _streamManager.updateWatched,
    );
  }

  /// Gets a movie by ID from cache or delegates to MovieListService.
  Future<Movie?> getMovie(int movieId) async {
    return _movieCache[movieId] ?? await _fileManager.loadMovieData(movieId);
  }

  /// Creates a custom list using MovieListService.
  Future<String?> createCustomList(String name, List<Movie> movies) async {
    final listId =
        await _movieListService.createMovieList(name, movies: movies);
    if (listId != null) {
      await _loadCustomLists(); // Refresh custom lists
    }
    return listId;
  }

  /// Deletes a custom list using MovieListService.
  Future<void> deleteCustomList(String listId) async {
    await _movieListService.deleteMovieList(listId);
    await _loadCustomLists(); // Refresh custom lists
  }

  /// Checks if a movie is in the to-watch list.
  bool isInToWatchList(int movieId) {
    return _streamManager.toWatch.any((movie) => movie.id == movieId);
  }

  /// Checks if a movie is in the watched list.
  bool isInWatchedList(int movieId) {
    return _streamManager.watched.any((movie) => movie.id == movieId);
  }

  /// Clears all caches.
  void clearCache() {
    _movieCache.clear();
    _moviesWithFiles.clear();
    _streamManager.clearAll();
  }

  Future<List<Movie>> _parseMoviesFromTtl(String ttlContent) async {
    final movieListData = await _fileManager.parseMovieListData(ttlContent);
    return movieListData ?? [];
  }

  Future<void> _loadCustomLists() async {
    final allLists = await _movieListService.getAllMovieLists();
    final customLists = <CustomList>[];

    for (final listData in allLists) {
      final name = listData['name'] as String? ?? 'Unnamed List';
      final id = listData['id'] as String? ?? '';
      final movies = listData['movies'] as List<Movie>? ?? [];

      // Skip standard lists
      if (!['Movies to Watch', 'Movies Watched', 'Favorites'].contains(name)) {
        customLists.add(
          CustomList(
            id: id,
            name: name,
            movies: movies,
          ),
        );
      }
    }

    _streamManager.updateCustomLists(customLists);
  }

  /// Helper method for adding movies to lists.
  Future<void> _addToList(
    Movie movie,
    String listType,
    String displayName,
    Function(List<Movie>) updateStream,
  ) async {
    await executePodOperation(
      operation: () async {
        final listId =
            await _movieListService.initializeMovieList(listType, displayName);
        if (listId != null) {
          await _movieListService.addMovieToList(
            listId,
            movie,
            contentType:
                movie.contentType == ContentType.tvShow ? 'tvShow' : 'movie',
          );
          await _fileManager.createOrUpdateMovieFile(movie, null, null);
          _movieCache[movie.id] = movie;
          _moviesWithFiles.add(movie.id);

          final currentList = List<Movie>.from(
            listType == 'to_watch'
                ? _streamManager.toWatch
                : _streamManager.watched,
          );
          if (!currentList.any((m) => m.id == movie.id)) {
            currentList.add(movie);
            updateStream(currentList);
          }
        }
        return null;
      },
      operationName: 'addToList($listType)',
    );
  }

  /// Helper method for removing movies from lists.
  Future<void> _removeFromList(
    int movieId,
    String listType,
    String displayName,
    Function(List<Movie>) updateStream,
  ) async {
    await executePodOperation(
      operation: () async {
        final listId =
            await _movieListService.initializeMovieList(listType, displayName);
        if (listId != null) {
          await _movieListService.removeMovieFromList(listId, movieId);

          final currentList = List<Movie>.from(
            listType == 'to_watch'
                ? _streamManager.toWatch
                : _streamManager.watched,
          );
          currentList.removeWhere((m) => m.id == movieId);
          updateStream(currentList);

          _movieCache.remove(movieId);
          _moviesWithFiles.remove(movieId);
        }
        return null;
      },
      operationName: 'removeFromList($listType)',
    );
  }

  @override
  void dispose() {
    _streamManager.dispose();
    super.dispose();
  }
}
