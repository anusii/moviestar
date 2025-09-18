/// List operations for POD favorites service.
/// Handles custom list management and operations.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:moviestar/core/services/favorites/movie_list_service.dart';
import 'package:moviestar/core/services/pod/pod_favorites_stream_manager.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';

/// Handles custom list operations for POD favorites service.
class PodFavoritesListOperations {
  final PodFavoritesStreamManager _streamManager;
  final MovieListService _movieListService;

  PodFavoritesListOperations(
    this._streamManager,
    this._movieListService,
  );

  /// Loads custom lists from POD.
  Future<void> loadCustomLists() async {
    debugPrint('🎬 [PodFavoritesListOperations] loadCustomLists called');
    final allLists = await _movieListService.getAllMovieLists();
    debugPrint(
      '🎬 [PodFavoritesListOperations] getAllMovieLists returned ${allLists.length} lists',
    );

    final customLists = <CustomList>[];
    final duplicateTracker = <String, List<Map<String, dynamic>>>{};

    // First pass: group lists by name to identify duplicates
    for (final listData in allLists) {
      final name = listData['name'] as String? ?? 'Unnamed List';
      final id = listData['id'] as String? ?? '';

      debugPrint(
          '🎬 [PodFavoritesListOperations] Processing list: $name (ID: $id)',);

      // Skip standard lists
      if (!['Movies to Watch', 'Movies Watched', 'Favorites'].contains(name)) {
        duplicateTracker.putIfAbsent(name, () => []).add(listData);
      } else {
        debugPrint(
            '🎬 [PodFavoritesListOperations] Skipping standard list: $name',);
      }
    }

    // Second pass: process deduplicated lists
    for (final entry in duplicateTracker.entries) {
      final name = entry.key;
      final listsWithSameName = entry.value;

      if (listsWithSameName.length > 1) {
        debugPrint(
          '🎬 [PodFavoritesListOperations] Found ${listsWithSameName.length} duplicate lists named "$name"',
        );
        for (final listData in listsWithSameName) {
          debugPrint(
              '🎬 [PodFavoritesListOperations] Duplicate: ID ${listData['id']}',);
        }
      }

      // Keep the list with the highest ID (most recent)
      final selectedList = listsWithSameName.reduce((a, b) {
        final idA = int.tryParse(a['id'] as String? ?? '0') ?? 0;
        final idB = int.tryParse(b['id'] as String? ?? '0') ?? 0;
        return idA > idB ? a : b;
      });

      final id = selectedList['id'] as String? ?? '';
      final movies = selectedList['movies'] as List<Movie>? ?? [];
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

      if (listsWithSameName.length > 1) {
        debugPrint(
            '🎬 [PodFavoritesListOperations] Selected most recent list: $name (ID: $id)',);
      } else {
        debugPrint('🎬 [PodFavoritesListOperations] Added custom list: $name');
      }
    }

    debugPrint(
      '🎬 [PodFavoritesListOperations] Found ${customLists.length} custom lists after deduplication',
    );
    _streamManager.updateCustomLists(customLists);
    debugPrint(
        '🎬 [PodFavoritesListOperations] Updated stream with custom lists',);
  }

  /// Deletes a custom list using MovieListService.
  Future<void> deleteCustomList(String listId) async {
    debugPrint(
        '🎬 [PodFavoritesListOperations] deleteCustomList called for listId: $listId',);

    // Clear any cache related to this list
    _movieListService.clearCache();

    // Wait for delete operation to complete to ensure it actually happens
    try {
      final success = await _movieListService.deleteMovieList(listId);
      debugPrint(
          '🎬 [PodFavoritesListOperations] Delete operation result: $success',);

      if (success) {
        // Clear cache again after deletion
        _movieListService.clearCache();

        // Refresh custom lists after POD operation completes
        await loadCustomLists();
        debugPrint(
            '🎬 [PodFavoritesListOperations] Custom lists reloaded after deletion',);
      } else {
        debugPrint('🎬 [PodFavoritesListOperations] Delete operation failed');
      }
    } catch (error) {
      debugPrint(
          '🎬 [PodFavoritesListOperations] Error deleting custom list: $error',);
    }
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
    debugPrint(
        '🎬 [PodFavoritesListOperations] createCustomList called: $name',);

    final listId = await _movieListService.createMovieList(
      name,
      description: description ?? '',
    );
    debugPrint(
        '🎬 [PodFavoritesListOperations] createMovieList returned: $listId',);

    if (listId != null) {
      debugPrint(
        '🎬 [PodFavoritesListOperations] Calling loadCustomLists after creation',
      );
      await loadCustomLists();

      debugPrint(
          '🎬 [PodFavoritesListOperations] Custom list creation completed',);
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
    debugPrint(
        '🎬 [PodFavoritesListOperations] updateCustomList called for listId: ${updatedList.id}',);

    // Fire-and-forget POD operation for immediate UI responsiveness
    _movieListService
        .updateMovieListName(
      updatedList.id,
      updatedList.name,
    )
        .then((_) async {
      debugPrint(
          '🎬 [PodFavoritesListOperations] Update operation completed successfully',);
      // Refresh custom lists in background after POD operation completes
      await loadCustomLists();
    }).catchError((error) {
      debugPrint(
          '🎬 [PodFavoritesListOperations] Error updating custom list: $error',);
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
    _movieListService
        .addMovieToList(
      listId,
      movie,
      contentType: contentType,
    )
        .then((_) async {
      // Refresh custom lists in background after POD operation completes
      await loadCustomLists();
    }).catchError((error) {
      debugPrint(
          '🎬 [PodFavoritesListOperations] Error adding movie to custom list: $error',);
      // TODO: Handle error state - could emit error to stream
    });

    // Return immediately for optimistic UI
  }

  /// Removes a movie from a custom list.
  Future<void> removeMovieFromCustomList(String listId, int movieId) async {
    // Fire-and-forget POD operation for immediate UI responsiveness
    _movieListService.removeMovieFromList(listId, movieId).then((_) async {
      // Refresh custom lists in background after POD operation completes
      await loadCustomLists();
    }).catchError((error) {
      debugPrint(
          '🎬 [PodFavoritesListOperations] Error removing movie from custom list: $error',);
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
    debugPrint(
        '🎬 [PodFavoritesListOperations] getMoviesInCustomList called for listId: $listId',);
    final movieList = await _movieListService.getMovieList(listId);
    debugPrint(
        '🎬 [PodFavoritesListOperations] getMovieList returned: ${movieList != null ? "DATA" : "NULL"}',);
    if (movieList != null) {
      final movies = movieList['movies'] as List<Movie>? ?? [];
      debugPrint(
          '🎬 [PodFavoritesListOperations] Movies count: ${movies.length}',);
      for (int i = 0; i < movies.length; i++) {
        final movie = movies[i];
        debugPrint(
            '🎬 [PodFavoritesListOperations] Movie $i: ${movie.title} (ID: ${movie.id}, ContentType: ${movie.contentType})',);
      }
      return movies;
    }
    debugPrint('🎬 [PodFavoritesListOperations] Returning empty list');
    return [];
  }
}
