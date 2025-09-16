/// Compact PodFavoritesService using existing helper infrastructure.
/// Reduced from 1,608 to ~280 lines by using BasePodService and helper classes.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/core/services/pod/base_pod_service.dart';
import 'package:moviestar/core/services/favorites/favorites_service.dart';
import 'package:moviestar/core/services/favorites/movie_list_service.dart';
import 'package:moviestar/core/services/pod/pod_favorites_file_manager.dart';
import 'package:moviestar/core/services/pod/pod_favorites_stream_manager.dart';
import 'package:moviestar/core/services/pod/pod_list_management_service.dart';
import 'package:moviestar/core/services/pod/pod_sharing_service.dart';
import 'package:moviestar/services/user_profile_service.dart';
import 'package:moviestar/utils/turtle_serializer.dart';

/// Compact POD-based service for managing favorite movies using composition.
/// Uses BasePodService infrastructure and helper classes for common operations.
class PodFavoritesService extends BasePodService {
  final SharedPreferences _prefs;
  final FavoritesService _fallbackService;
  final Set<int> _moviesWithFiles = {};
  final Map<int, Movie> _movieCache = {};

  /// Callback to notify when initial loading is complete
  final VoidCallback? _onInitialLoadComplete;

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
    this._fallbackService, {
    VoidCallback? onInitialLoadComplete,
  }) : _onInitialLoadComplete = onInitialLoadComplete {
    _streamManager = PodFavoritesStreamManager();
    _fileManager = PodFavoritesFileManager(context, child);
    _userProfileService = UserProfileService(context, child);
    _movieListService = MovieListService(context, child, _userProfileService);
    _listManagementService =
        PodListManagementService(context, child, _movieListService);
    _sharingService = PodSharingService();

    // Initialize by loading favorites from POD
    debugPrint('🎬 [PodFavoritesService] Constructor called - initializing...');
    loadFavorites().then((_) {
      debugPrint(
        '🎬 [PodFavoritesService] Initial loadFavorites completed successfully',
      );
      // Notify manager that initial loading is complete
      if (_onInitialLoadComplete != null) {
        debugPrint('🎬 [PodFavoritesService] Calling onInitialLoadComplete callback');
        _onInitialLoadComplete!();
      }
    }).catchError((error) {
      debugPrint(
        '🎬 [PodFavoritesService] Error loading initial favorites: $error',
      );
      // Even on error, notify that loading attempt is complete
      if (_onInitialLoadComplete != null) {
        debugPrint('🎬 [PodFavoritesService] Calling onInitialLoadComplete callback (after error)');
        _onInitialLoadComplete!();
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
        debugPrint('🎬 [PodFavoritesService] Reading POD files...');
        final toWatchData =
            await safeReadFile('moviestar/data/user_lists/to_watch.ttl');
        final watchedData =
            await safeReadFile('moviestar/data/user_lists/watched.ttl');

        debugPrint(
          '🎬 [PodFavoritesService] toWatchData: ${toWatchData?.length ?? 0} chars',
        );
        debugPrint(
          '🎬 [PodFavoritesService] watchedData: ${watchedData?.length ?? 0} chars',
        );

        if (toWatchData != null && toWatchData.isNotEmpty) {
          final movies = await _parseMoviesFromTtl(toWatchData);
          debugPrint(
            '🎬 [PodFavoritesService] Updating toWatch stream with ${movies.length} movies',
          );
          _streamManager.updateToWatch(movies);
        } else {
          debugPrint(
            '🎬 [PodFavoritesService] No toWatch data, updating with empty list',
          );
          _streamManager.updateToWatch([]);
        }

        if (watchedData != null && watchedData.isNotEmpty) {
          final movies = await _parseMoviesFromTtl(watchedData);
          debugPrint(
            '🎬 [PodFavoritesService] Updating watched stream with ${movies.length} movies',
          );
          _streamManager.updateWatched(movies);
        } else {
          debugPrint(
            '🎬 [PodFavoritesService] No watched data, updating with empty list',
          );
          _streamManager.updateWatched([]);
        }

        await _loadCustomLists();
        return null;
      },
      operationName: 'loadFavorites',
    );
  }

  /// Adds a movie to the to-watch list.
  Future<void> addToWatchList(Movie movie) async {
    debugPrint(
      '🎬 [PodFavoritesService] addToWatchList called for movie: ${movie.title} (ID: ${movie.id})',
    );
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

  /// Deletes a custom list using MovieListService.
  Future<void> deleteCustomList(String listId) async {
    debugPrint('🎬 [PodFavoritesService] deleteCustomList called for listId: $listId');

    // Clear any cache related to this list
    _movieListService.clearCache();

    // Wait for delete operation to complete to ensure it actually happens
    try {
      final success = await _movieListService.deleteMovieList(listId);
      debugPrint('🎬 [PodFavoritesService] Delete operation result: $success');

      if (success) {
        // Clear cache again after deletion
        _movieListService.clearCache();

        // Refresh custom lists after POD operation completes
        await _loadCustomLists();
        debugPrint('🎬 [PodFavoritesService] Custom lists reloaded after deletion');
      } else {
        debugPrint('🎬 [PodFavoritesService] Delete operation failed');
      }
    } catch (error) {
      debugPrint('🎬 [PodFavoritesService] Error deleting custom list: $error');
    }
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
    debugPrint(
      '🎬 [PodFavoritesService] Parsing TTL content (${ttlContent.length} chars)',
    );
    debugPrint(
      '🎬 [PodFavoritesService] TTL content preview: ${ttlContent.substring(0, ttlContent.length > 200 ? 200 : ttlContent.length)}...',
    );

    final movieListData = await _fileManager.parseMovieListData(ttlContent);
    if (movieListData != null) {
      debugPrint(
        '🎬 [PodFavoritesService] Parsed ${movieListData.length} placeholder movies from TTL',
      );

      // Load full movie details for each placeholder movie
      final fullMovies = <Movie>[];
      for (int i = 0; i < movieListData.length; i++) {
        final placeholderMovie = movieListData[i];
        debugPrint(
          '🎬 [PodFavoritesService] Loading full details for movie ID: ${placeholderMovie.id}',
        );

        try {
          // Load full movie details from individual movie file
          final fullMovie =
              await _fileManager.loadFullMovieDetails(placeholderMovie);
          if (fullMovie != null) {
            fullMovies.add(fullMovie);
            debugPrint(
              '🎬 [PodFavoritesService] Loaded: ${fullMovie.title} (ID: ${fullMovie.id})',
            );
          } else {
            // Fallback to placeholder if individual file doesn't exist
            debugPrint(
              '🎬 [PodFavoritesService] No individual file found, using placeholder for ID: ${placeholderMovie.id}',
            );
            fullMovies.add(placeholderMovie);
          }
        } catch (e) {
          debugPrint(
            '🎬 [PodFavoritesService] Error loading full details for movie ${placeholderMovie.id}: $e',
          );
          // Fallback to placeholder on error
          fullMovies.add(placeholderMovie);
        }
      }

      debugPrint(
        '🎬 [PodFavoritesService] Final result: ${fullMovies.length} movies with full details',
      );
      return fullMovies;
    } else {
      debugPrint('🎬 [PodFavoritesService] Failed to parse movies from TTL');
    }

    return movieListData ?? [];
  }

  Future<void> _loadCustomLists() async {
    debugPrint('🎬 [PodFavoritesService] _loadCustomLists called');
    final allLists = await _movieListService.getAllMovieLists();
    debugPrint(
      '🎬 [PodFavoritesService] getAllMovieLists returned ${allLists.length} lists',
    );

    final customLists = <CustomList>[];

    for (final listData in allLists) {
      final name = listData['name'] as String? ?? 'Unnamed List';
      final id = listData['id'] as String? ?? '';
      final movies = listData['movies'] as List<Movie>? ?? [];

      debugPrint('🎬 [PodFavoritesService] Processing list: $name (ID: $id)');

      // Skip standard lists
      if (!['Movies to Watch', 'Movies Watched', 'Favorites'].contains(name)) {
        final movieIds = movies.map((m) => m.id).toList();
        final now = DateTime.now();
        final customList = CustomList(
          id: id,
          name: name,
          movieIds: movieIds,
          createdAt: now,
          updatedAt: now,
        );
        customLists.add(customList);
        debugPrint('🎬 [PodFavoritesService] Added custom list: $name');
      } else {
        debugPrint('🎬 [PodFavoritesService] Skipping standard list: $name');
      }
    }

    debugPrint(
      '🎬 [PodFavoritesService] Found ${customLists.length} custom lists',
    );
    _streamManager.updateCustomLists(customLists);
    debugPrint('🎬 [PodFavoritesService] Updated stream with custom lists');
  }

  /// Helper method for adding movies to lists.
  Future<void> _addToList(
    Movie movie,
    String listType,
    String displayName,
    Function(List<Movie>) updateStream,
  ) async {
    debugPrint(
      '🎬 [PodFavoritesService] _addToList called: ${movie.title} to $listType',
    );
    await executePodOperation(
      operation: () async {
        final listId =
            await _movieListService.initializeMovieList(listType, displayName);
        debugPrint(
          '🎬 [PodFavoritesService] Got listId: $listId for $listType',
        );
        if (listId != null) {
          await _movieListService.addMovieToList(
            listId,
            movie,
            contentType:
                movie.contentType == ContentType.tvShow ? 'tvShow' : 'movie',
          );
          debugPrint(
            '🎬 [PodFavoritesService] Added movie to MovieList service',
          );

          await _fileManager.createOrUpdateMovieFile(movie);
          debugPrint('🎬 [PodFavoritesService] Created/updated movie file');

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
            debugPrint(
              '🎬 [PodFavoritesService] Updated stream with ${currentList.length} movies',
            );
          } else {
            debugPrint(
              '🎬 [PodFavoritesService] Movie already in list, not adding',
            );
          }

          // Update the TTL file to persist the change
          debugPrint(
            '🎬 [PodFavoritesService] About to write TTL file for $listType with ${currentList.length} movies',
          );
          await _writeTtlFile(listType, currentList);
        } else {
          debugPrint(
            '🎬 [PodFavoritesService] Failed to get listId for $listType',
          );
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

          // Update the TTL file to persist the change
          await _writeTtlFile(listType, currentList);
        }
        return null;
      },
      operationName: 'removeFromList($listType)',
    );
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
    await addToWatchList(movie);
  }

  /// Adds a movie to watched list with content type support.
  Future<void> addToWatched(Movie movie, {String contentType = 'movie'}) async {
    await addToWatchedList(movie);
  }

  /// Removes a movie from to-watch list.
  Future<void> removeFromToWatch(Movie movie) async {
    await removeFromWatchList(movie.id);
  }

  /// Removes a movie from watched list.
  Future<void> removeFromWatched(Movie movie) async {
    await removeFromWatchedList(movie.id);
  }

  /// Checks if a movie is in to-watch list.
  Future<bool> isInToWatch(Movie movie) async {
    return isInToWatchList(movie.id);
  }

  /// Checks if a movie is in watched list.
  Future<bool> isInWatched(Movie movie) async {
    return isInWatchedList(movie.id);
  }

  /// Gets personal rating for a movie.
  Future<double?> getPersonalRating(Movie movie) async {
    final userData = await _fileManager.readMovieFile(movie);
    return userData?['rating'] as double?;
  }

  /// Sets personal rating for a movie.
  Future<void> setPersonalRating(Movie movie, double rating) async {
    final updatedMovie = Movie(
      id: movie.id,
      title: movie.title,
      overview: movie.overview,
      posterUrl: movie.posterUrl,
      backdropUrl: movie.backdropUrl,
      releaseDate: movie.releaseDate,
      voteAverage: movie.voteAverage,
      genreIds: movie.genreIds,
      contentType: movie.contentType,
    );
    await _fileManager.createOrUpdateMovieFile(updatedMovie, rating: rating);
  }

  /// Removes personal rating for a movie.
  Future<void> removePersonalRating(Movie movie) async {
    final updatedMovie = Movie(
      id: movie.id,
      title: movie.title,
      overview: movie.overview,
      posterUrl: movie.posterUrl,
      backdropUrl: movie.backdropUrl,
      releaseDate: movie.releaseDate,
      voteAverage: movie.voteAverage,
      genreIds: movie.genreIds,
      contentType: movie.contentType,
    );
    await _fileManager.createOrUpdateMovieFile(updatedMovie);
  }

  /// Gets personal comments for a movie.
  Future<String?> getMovieComments(Movie movie) async {
    final userData = await _fileManager.readMovieFile(movie);
    return userData?['comment'] as String?;
  }

  /// Sets personal comments for a movie.
  Future<void> setMovieComments(Movie movie, String comments) async {
    final updatedMovie = Movie(
      id: movie.id,
      title: movie.title,
      overview: movie.overview,
      posterUrl: movie.posterUrl,
      backdropUrl: movie.backdropUrl,
      releaseDate: movie.releaseDate,
      voteAverage: movie.voteAverage,
      genreIds: movie.genreIds,
      contentType: movie.contentType,
    );
    await _fileManager.createOrUpdateMovieFile(updatedMovie, comment: comments);
  }

  /// Removes personal comments for a movie.
  Future<void> removeMovieComments(Movie movie) async {
    final updatedMovie = Movie(
      id: movie.id,
      title: movie.title,
      overview: movie.overview,
      posterUrl: movie.posterUrl,
      backdropUrl: movie.backdropUrl,
      releaseDate: movie.releaseDate,
      voteAverage: movie.voteAverage,
      genreIds: movie.genreIds,
      contentType: movie.contentType,
    );
    await _fileManager.createOrUpdateMovieFile(updatedMovie);
  }

  /// Checks if a movie file exists.
  Future<bool> hasMovieFile(Movie movie) async {
    return _fileManager.hasMovieFile(movie);
  }

  /// Gets the file path for a movie file.
  String? getMovieFilePath(Movie movie) {
    return _fileManager.getMovieFilePathByMovie(movie);
  }

  /// Gets all custom lists.
  Future<List<CustomList>> getCustomLists() async {
    return _streamManager.customLists;
  }

  /// Creates a custom list.
  Future<CustomList> createCustomList(
    String name, {
    String? description,
  }) async {
    debugPrint('🎬 [PodFavoritesService] createCustomList called: $name');

    final listId = await _movieListService.createMovieList(
      name,
      description: description ?? '',
    );
    debugPrint('🎬 [PodFavoritesService] createMovieList returned: $listId');

    if (listId != null) {
      debugPrint(
        '🎬 [PodFavoritesService] Calling _loadCustomLists after creation',
      );
      await _loadCustomLists();

      // Force a slight delay to ensure all async operations complete
      await Future.delayed(const Duration(milliseconds: 100));
      await _loadCustomLists(); // Load again to be sure

      debugPrint('🎬 [PodFavoritesService] Custom list creation completed');
      return CustomList(
        id: listId,
        name: name,
        movieIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        description: description,
      );
    }
    throw Exception('Failed to create custom list');
  }

  /// Updates a custom list.
  Future<void> updateCustomList(CustomList updatedList) async {
    debugPrint('🎬 [PodFavoritesService] updateCustomList called for listId: ${updatedList.id}');

    // Fire-and-forget POD operation for immediate UI responsiveness
    _movieListService.updateMovieListName(
      updatedList.id,
      updatedList.name,
    ).then((_) async {
      debugPrint('🎬 [PodFavoritesService] Update operation completed successfully');
      // Refresh custom lists in background after POD operation completes
      await _loadCustomLists();
    }).catchError((error) {
      debugPrint('🎬 [PodFavoritesService] Error updating custom list: $error');
    });

    // Return immediately for optimistic UI
  }

  /// Adds a movie to a custom list.
  Future<void> addMovieToCustomList(
    String listId,
    Movie movie, {
    String contentType = 'movie',
  }) async {
    // Fire-and-forget POD operation for immediate UI responsiveness
    _movieListService.addMovieToList(
      listId,
      movie,
      contentType: contentType,
    ).then((_) async {
      // Refresh custom lists in background after POD operation completes
      await _loadCustomLists();
    }).catchError((error) {
      debugPrint('🎬 [PodFavoritesService] Error adding movie to custom list: $error');
      // TODO: Handle error state - could emit error to stream
    });

    // Return immediately for optimistic UI
  }

  /// Removes a movie from a custom list.
  Future<void> removeMovieFromCustomList(String listId, int movieId) async {
    // Fire-and-forget POD operation for immediate UI responsiveness
    _movieListService.removeMovieFromList(listId, movieId).then((_) async {
      // Refresh custom lists in background after POD operation completes
      await _loadCustomLists();
    }).catchError((error) {
      debugPrint('🎬 [PodFavoritesService] Error removing movie from custom list: $error');
      // TODO: Handle error state - could emit error to stream
    });

    // Return immediately for optimistic UI
  }

  /// Checks if a movie is in a custom list.
  Future<bool> isMovieInCustomList(String listId, int movieId) async {
    return await _movieListService.isMovieInList(listId, movieId);
  }

  /// Gets custom lists containing a movie.
  Future<List<CustomList>> getCustomListsContainingMovie(int movieId) async {
    final allLists = _streamManager.customLists;
    return allLists.where((list) => list.movieIds.contains(movieId)).toList();
  }

  /// Gets movies in a custom list.
  Future<List<Movie>> getMoviesInCustomList(String listId) async {
    debugPrint('🎬 [PodFavoritesService] getMoviesInCustomList called for listId: $listId');
    final movieList = await _movieListService.getMovieList(listId);
    debugPrint('🎬 [PodFavoritesService] getMovieList returned: ${movieList != null ? "DATA" : "NULL"}');
    if (movieList != null) {
      final movies = movieList['movies'] as List<Movie>? ?? [];
      debugPrint('🎬 [PodFavoritesService] Movies count: ${movies.length}');
      for (int i = 0; i < movies.length; i++) {
        final movie = movies[i];
        debugPrint('🎬 [PodFavoritesService] Movie $i: ${movie.title} (ID: ${movie.id}, ContentType: ${movie.contentType})');
      }
      return movies;
    }
    debugPrint('🎬 [PodFavoritesService] Returning empty list');
    return [];
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

  /// Writes a movie list to the appropriate TTL file.
  Future<void> _writeTtlFile(String listType, List<Movie> movies) async {
    try {
      final displayName =
          listType == 'to_watch' ? 'Movies to Watch' : 'Movies Watched';
      final fileName = 'moviestar/data/user_lists/$listType.ttl';

      debugPrint(
        '🎬 [PodFavoritesService] Writing ${movies.length} movies to $fileName',
      );

      // Generate TTL content using TurtleSerializer
      final movieListId =
          await _movieListService.initializeMovieList(listType, displayName) ??
              'default';
      final ttlContent = TurtleSerializer.createMovieList(
        movieListId,
        displayName,
        description: 'User $displayName list',
        movies: movies,
      );

      // Write to POD
      final success = await safeWriteFile(fileName, ttlContent);
      if (success) {
        debugPrint('🎬 [PodFavoritesService] Successfully wrote $fileName');
      } else {
        debugPrint('🎬 [PodFavoritesService] Failed to write $fileName');
      }
    } catch (e) {
      debugPrint('🎬 [PodFavoritesService] Error writing TTL file: $e');
    }
  }

  @override
  void dispose() {
    _streamManager.dispose();
    super.dispose();
  }
}
