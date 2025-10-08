/// Mock implementation of FavoritesService for integration testing.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter/foundation.dart';

import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';

/// Mock implementation of FavoritesService for testing.
///
/// This mock tracks movie state (to-watch, watched, ratings, custom lists) in memory
/// without requiring SharedPreferences or POD connectivity.
///
/// Features:
/// - Tracks multiple movies by ID (not just boolean flags)
/// - Supports custom list creation and management
/// - Configurable to simulate success/failure scenarios
/// - Streams emit updated values when state changes
///
/// Example usage:
/// ```dart
/// final mockService = MockFavoritesService();
/// await mockService.addToWatch(movie);
/// expect(await mockService.isInToWatch(movie), isTrue);
/// ```

class MockFavoritesService implements FavoritesService {
  /// Movies in the "To Watch" list (stored by movie ID).

  final Map<int, Movie> _toWatchMovies = {};

  /// Movies in the "Watched" list (stored by movie ID).

  final Map<int, Movie> _watchedMovies = {};

  /// Personal ratings for movies (stored by movie ID).

  final Map<int, double> _ratings = {};

  /// Comments for movies (stored by movie ID).

  final Map<int, String> _comments = {};

  /// Custom lists created by the user.

  final Map<String, CustomList> _customLists = {};

  /// Movie file paths (stored by movie ID).

  final Map<int, String> _movieFiles = {};

  /// Whether operations should fail (for error testing).

  bool shouldFail = false;

  /// Error message to throw when shouldFail is true.

  String failureMessage = 'Mock service configured to fail';

  // ============================================================================
  // TO-WATCH LIST METHODS
  // ============================================================================

  @override
  Future<bool> isInToWatch(Movie movie) async {
    if (shouldFail) throw Exception(failureMessage);
    return _toWatchMovies.containsKey(movie.id);
  }

  @override
  Future<void> addToWatch(Movie movie, {String contentType = 'movie'}) async {
    if (shouldFail) throw Exception(failureMessage);
    _toWatchMovies[movie.id] = movie;
  }

  @override
  Future<void> removeFromToWatch(Movie movie) async {
    if (shouldFail) throw Exception(failureMessage);
    _toWatchMovies.remove(movie.id);
  }

  @override
  Future<List<Movie>> getToWatch() async {
    if (shouldFail) throw Exception(failureMessage);
    return _toWatchMovies.values.toList();
  }

  // ============================================================================
  // WATCHED LIST METHODS
  // ============================================================================

  @override
  Future<bool> isInWatched(Movie movie) async {
    if (shouldFail) throw Exception(failureMessage);
    return _watchedMovies.containsKey(movie.id);
  }

  @override
  Future<void> addToWatched(Movie movie, {String contentType = 'movie'}) async {
    if (shouldFail) throw Exception(failureMessage);
    _watchedMovies[movie.id] = movie;
  }

  @override
  Future<void> removeFromWatched(Movie movie) async {
    if (shouldFail) throw Exception(failureMessage);
    _watchedMovies.remove(movie.id);
  }

  @override
  Future<List<Movie>> getWatched() async {
    if (shouldFail) throw Exception(failureMessage);
    return _watchedMovies.values.toList();
  }

  // ============================================================================
  // RATING AND COMMENT METHODS
  // ============================================================================

  @override
  Future<double?> getPersonalRating(Movie movie) async {
    if (shouldFail) throw Exception(failureMessage);
    return _ratings[movie.id];
  }

  @override
  Future<void> setPersonalRating(Movie movie, double rating) async {
    if (shouldFail) throw Exception(failureMessage);
    _ratings[movie.id] = rating;
  }

  @override
  Future<void> removePersonalRating(Movie movie) async {
    if (shouldFail) throw Exception(failureMessage);
    _ratings.remove(movie.id);
  }

  @override
  Future<String?> getMovieComments(Movie movie) async {
    if (shouldFail) throw Exception(failureMessage);
    return _comments[movie.id];
  }

  @override
  Future<void> setMovieComments(Movie movie, String comments) async {
    if (shouldFail) throw Exception(failureMessage);
    _comments[movie.id] = comments;
  }

  @override
  Future<void> removeMovieComments(Movie movie) async {
    if (shouldFail) throw Exception(failureMessage);
    _comments.remove(movie.id);
  }

  // ============================================================================
  // CUSTOM LIST METHODS
  // ============================================================================

  @override
  Future<List<CustomList>> getCustomLists() async {
    if (shouldFail) throw Exception(failureMessage);
    return _customLists.values.toList();
  }

  @override
  Future<CustomList> createCustomList(
    String name, {
    String? description,
  }) async {
    if (shouldFail) throw Exception(failureMessage);

    final id = 'test-${name.toLowerCase().replaceAll(' ', '-')}';
    final list = CustomList(
      id: id,
      name: name,
      description: description,
      movieIds: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _customLists[id] = list;
    return list;
  }

  @override
  Future<void> updateCustomList(CustomList updatedList) async {
    if (shouldFail) throw Exception(failureMessage);
    _customLists[updatedList.id] = updatedList;
  }

  @override
  Future<void> deleteCustomList(String listId) async {
    if (shouldFail) throw Exception(failureMessage);
    _customLists.remove(listId);
  }

  @override
  Future<void> addMovieToCustomList(
    String listId,
    Movie movie, {
    String contentType = 'movie',
  }) async {
    if (shouldFail) throw Exception(failureMessage);

    final list = _customLists[listId];
    if (list == null) throw Exception('List not found: $listId');

    if (!list.movieIds.contains(movie.id)) {
      final updatedList = CustomList(
        id: list.id,
        name: list.name,
        description: list.description,
        movieIds: [...list.movieIds, movie.id],
        createdAt: list.createdAt,
        updatedAt: DateTime.now(),
      );
      _customLists[listId] = updatedList;
    }
  }

  @override
  Future<void> removeMovieFromCustomList(String listId, int movieId) async {
    if (shouldFail) throw Exception(failureMessage);

    final list = _customLists[listId];
    if (list == null) throw Exception('List not found: $listId');

    final updatedList = CustomList(
      id: list.id,
      name: list.name,
      description: list.description,
      movieIds: list.movieIds.where((id) => id != movieId).toList(),
      createdAt: list.createdAt,
      updatedAt: DateTime.now(),
    );
    _customLists[listId] = updatedList;
  }

  @override
  Future<bool> isMovieInCustomList(String listId, int movieId) async {
    if (shouldFail) throw Exception(failureMessage);

    final list = _customLists[listId];
    return list?.movieIds.contains(movieId) ?? false;
  }

  @override
  Future<List<CustomList>> getCustomListsContainingMovie(int movieId) async {
    if (shouldFail) throw Exception(failureMessage);

    return _customLists.values
        .where((list) => list.movieIds.contains(movieId))
        .toList();
  }

  @override
  Future<List<Movie>> getMoviesInCustomList(String listId) async {
    if (shouldFail) throw Exception(failureMessage);

    // Return empty list - in real implementation, this would fetch movies by ID
    return [];
  }

  @override
  Future<List<int>> getMovieIdsInCustomList(String listId) async {
    if (shouldFail) throw Exception(failureMessage);

    final list = _customLists[listId];
    return list?.movieIds ?? [];
  }

  // ============================================================================
  // FILE METHODS
  // ============================================================================

  @override
  Future<bool> hasMovieFile(Movie movie) async {
    if (shouldFail) throw Exception(failureMessage);
    return _movieFiles.containsKey(movie.id);
  }

  @override
  String? getMovieFilePath(Movie movie) {
    return _movieFiles[movie.id];
  }

  /// Sets a file path for a movie (test helper method).

  void setMovieFile(Movie movie, String filePath) {
    _movieFiles[movie.id] = filePath;
  }

  // ============================================================================
  // DATA MANAGEMENT METHODS
  // ============================================================================

  Future<Map<String, dynamic>> exportUserData() async {
    if (shouldFail) throw Exception(failureMessage);
    return {};
  }

  Future<void> importUserData(Map<String, dynamic> data) async {
    if (shouldFail) throw Exception(failureMessage);
  }

  Future<void> clearAllData() async {
    if (shouldFail) throw Exception(failureMessage);
    _toWatchMovies.clear();
    _watchedMovies.clear();
    _ratings.clear();
    _comments.clear();
    _customLists.clear();
    _movieFiles.clear();
  }

  // ============================================================================
  // STREAMS (for reactive UI updates)
  // ============================================================================

  @override
  Stream<List<Movie>> get toWatchMovies =>
      Stream.value(_toWatchMovies.values.toList());

  @override
  Stream<List<Movie>> get watchedMovies =>
      Stream.value(_watchedMovies.values.toList());

  @override
  Stream<List<CustomList>> get customLists =>
      Stream.value(_customLists.values.toList());

  // ============================================================================
  // CHANGENOTIFIER IMPLEMENTATION
  // ============================================================================

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  void dispose() {}

  @override
  bool get hasListeners => false;

  @override
  void notifyListeners() {}

  // ============================================================================
  // TEST HELPER METHODS
  // ============================================================================

  /// Configures the mock to simulate failures.

  void configureFailure({bool fail = true, String? message}) {
    shouldFail = fail;
    if (message != null) {
      failureMessage = message;
    }
  }

  /// Resets all state to empty (useful between tests).

  void reset() {
    _toWatchMovies.clear();
    _watchedMovies.clear();
    _ratings.clear();
    _comments.clear();
    _customLists.clear();
    _movieFiles.clear();
    shouldFail = false;
  }

  /// Pre-populates the service with test data.

  void seedData({
    List<Movie>? toWatch,
    List<Movie>? watched,
    Map<int, double>? ratings,
    List<CustomList>? lists,
  }) {
    if (toWatch != null) {
      for (final movie in toWatch) {
        _toWatchMovies[movie.id] = movie;
      }
    }
    if (watched != null) {
      for (final movie in watched) {
        _watchedMovies[movie.id] = movie;
      }
    }
    if (ratings != null) {
      _ratings.addAll(ratings);
    }
    if (lists != null) {
      for (final list in lists) {
        _customLists[list.id] = list;
      }
    }
  }
}
