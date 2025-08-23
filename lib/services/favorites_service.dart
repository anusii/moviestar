/// Service for managing favorite movies in the Movie Star application.
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
/// Authors: Kevin Wang

library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';

/// A service class that manages the user's movie lists.

class FavoritesService extends ChangeNotifier {
  /// Key used to store to-watch movies in shared preferences.

  static const String _toWatchKey = 'to_watch';

  /// Key used to store watched movies in shared preferences.

  static const String _watchedKey = 'watched';

  /// Key used to store ratings in shared preferences.

  static const String _ratingsKey = 'ratings';

  /// Key used to store custom lists in shared preferences.

  static const String _customListsKey = 'custom_lists';

  /// Shared preferences instance for storing movie lists.

  final SharedPreferences _prefs;

  /// Stream controller for to-watch movies.

  final _toWatchController = BehaviorSubject<List<Movie>>();

  /// Stream controller for watched movies.

  final _watchedController = BehaviorSubject<List<Movie>>();

  /// Stream controller for custom lists.

  final _customListsController = BehaviorSubject<List<CustomList>>();

  /// Stream of to-watch movies.

  Stream<List<Movie>> get toWatchMovies => _toWatchController.stream;

  /// Stream of watched movies.

  Stream<List<Movie>> get watchedMovies => _watchedController.stream;

  /// Stream of custom lists.

  Stream<List<CustomList>> get customLists => _customListsController.stream;

  /// Creates a new [FavoritesService] instance.

  FavoritesService(this._prefs) {
    _loadMovies();
  }

  /// Loads both movie lists and custom lists and emits them to their respective streams.

  Future<void> _loadMovies() async {
    final toWatch = await getToWatch();
    final watched = await getWatched();
    final customLists = await getCustomLists();
    _toWatchController.add(toWatch);
    _watchedController.add(watched);
    _customListsController.add(customLists);
  }

  /// Retrieves the list of to-watch movies.

  Future<List<Movie>> getToWatch() async {
    final String? moviesJson = _prefs.getString(_toWatchKey);
    if (moviesJson == null) return [];

    final List<dynamic> decoded = jsonDecode(moviesJson);
    return decoded.map((movie) => Movie.fromJson(movie)).toList();
  }

  /// Retrieves the list of watched movies.

  Future<List<Movie>> getWatched() async {
    final String? moviesJson = _prefs.getString(_watchedKey);
    if (moviesJson == null) return [];

    final List<dynamic> decoded = jsonDecode(moviesJson);
    return decoded.map((movie) => Movie.fromJson(movie)).toList();
  }

  /// Adds a movie to the to-watch list.

  Future<void> addToWatch(Movie movie) async {
    final toWatch = await getToWatch();
    if (!toWatch.any((m) => m.id == movie.id)) {
      toWatch.add(movie);
      await _saveToWatch(toWatch);
      _toWatchController.add(toWatch);
    }
  }

  /// Adds a movie to the watched list.

  Future<void> addToWatched(Movie movie) async {
    final watched = await getWatched();
    if (!watched.any((m) => m.id == movie.id)) {
      watched.add(movie);
      await _saveWatched(watched);
      _watchedController.add(watched);
    }
  }

  /// Removes a movie from the to-watch list.

  Future<void> removeFromToWatch(Movie movie) async {
    final toWatch = await getToWatch();
    toWatch.removeWhere((m) => m.id == movie.id);
    await _saveToWatch(toWatch);
    _toWatchController.add(toWatch);
  }

  /// Removes a movie from the watched list.

  Future<void> removeFromWatched(Movie movie) async {
    final watched = await getWatched();
    watched.removeWhere((m) => m.id == movie.id);
    await _saveWatched(watched);
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
    return watched.any((m) => m.id == movie.id);
  }

  /// Saves the list of to-watch movies to shared preferences.

  Future<void> _saveToWatch(List<Movie> movies) async {
    final encoded = jsonEncode(movies.map((m) => m.toJson()).toList());
    await _prefs.setString(_toWatchKey, encoded);
  }

  /// Saves the list of watched movies to shared preferences.

  Future<void> _saveWatched(List<Movie> movies) async {
    final encoded = jsonEncode(movies.map((m) => m.toJson()).toList());
    await _prefs.setString(_watchedKey, encoded);
  }

  /// Gets the user's personal rating for a movie.

  Future<double?> getPersonalRating(Movie movie) async {
    final ratingsJson = _prefs.getString(_ratingsKey);
    if (ratingsJson == null) return null;

    final Map<String, dynamic> ratings = jsonDecode(ratingsJson);
    return ratings[movie.id.toString()]?.toDouble();
  }

  /// Sets the user's personal rating for a movie.

  Future<void> setPersonalRating(Movie movie, double rating) async {
    final ratingsJson = _prefs.getString(_ratingsKey);
    Map<String, dynamic> ratings = {};

    if (ratingsJson != null) {
      ratings = jsonDecode(ratingsJson);
    }

    ratings[movie.id.toString()] = rating;
    await _prefs.setString(_ratingsKey, jsonEncode(ratings));
  }

  /// Removes the user's personal rating for a movie.

  Future<void> removePersonalRating(Movie movie) async {
    final ratingsJson = _prefs.getString(_ratingsKey);
    if (ratingsJson == null) return;

    final Map<String, dynamic> ratings = jsonDecode(ratingsJson);
    ratings.remove(movie.id.toString());
    await _prefs.setString(_ratingsKey, jsonEncode(ratings));
  }

  /// Gets the personal comments for a movie.

  Future<String?> getMovieComments(Movie movie) async {
    return _prefs.getString('movie_comments_${movie.id}');
  }

  /// Sets the personal comments for a movie.

  Future<void> setMovieComments(Movie movie, String comments) async {
    await _prefs.setString('movie_comments_${movie.id}', comments);
    notifyListeners();
  }

  /// Removes the personal comments for a movie.

  Future<void> removeMovieComments(Movie movie) async {
    await _prefs.remove('movie_comments_${movie.id}');
    notifyListeners();
  }

  /// Checks if a movie file exists (i.e. user has interacted with this movie).
  /// For local storage, this checks if the user has either a rating or comment.

  Future<bool> hasMovieFile(Movie movie) async {
    final hasRating = await getPersonalRating(movie) != null;
    final hasComment = await getMovieComments(movie) != null &&
        (await getMovieComments(movie))!.isNotEmpty;
    return hasRating || hasComment;
  }

  /// Gets the file path for a movie file (used for sharing).
  /// Local storage doesn't have shareable file paths, so this returns null.

  String? getMovieFilePath(Movie movie) {
    return null; // Local storage doesn't support file sharing
  }

  /// Custom Lists Methods

  /// Retrieves all custom lists.

  Future<List<CustomList>> getCustomLists() async {
    final String? listsJson = _prefs.getString(_customListsKey);
    if (listsJson == null) return [];

    final List<dynamic> decoded = jsonDecode(listsJson);
    return decoded.map((list) => CustomList.fromJson(list)).toList();
  }

  /// Creates a new custom list.

  Future<CustomList> createCustomList(
    String name, {
    String? description,
  }) async {
    final lists = await getCustomLists();
    final newList = CustomList(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description,
      movieIds: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    lists.add(newList);
    await _saveCustomLists(lists);
    _customListsController.add(lists);
    return newList;
  }

  /// Updates an existing custom list.

  Future<void> updateCustomList(CustomList updatedList) async {
    final lists = await getCustomLists();
    final index = lists.indexWhere((list) => list.id == updatedList.id);
    if (index != -1) {
      lists[index] = updatedList.copyWith(updatedAt: DateTime.now());
      await _saveCustomLists(lists);
      _customListsController.add(lists);
    }
  }

  /// Deletes a custom list.

  Future<void> deleteCustomList(String listId) async {
    final lists = await getCustomLists();
    lists.removeWhere((list) => list.id == listId);
    await _saveCustomLists(lists);
    _customListsController.add(lists);
  }

  /// Adds a movie to a custom list.

  Future<void> addMovieToCustomList(String listId, Movie movie,
      {String contentType = 'movie'}) async {
    final lists = await getCustomLists();
    final listIndex = lists.indexWhere((list) => list.id == listId);
    if (listIndex != -1) {
      final currentList = lists[listIndex];
      if (!currentList.movieIds.contains(movie.id)) {
        final updatedMovieIds = [...currentList.movieIds, movie.id];

        // Update content types array.

        List<String> currentContentTypes;
        if (currentList.contentTypes == null) {
          // For backward compatibility, fill existing movies with 'movie' type.

          currentContentTypes =
              List.filled(currentList.movieIds.length, 'movie');
        } else {
          currentContentTypes = [...currentList.contentTypes!];
        }
        final updatedContentTypes = [...currentContentTypes, contentType];

        lists[listIndex] = currentList.copyWith(
          movieIds: updatedMovieIds,
          contentTypes: updatedContentTypes,
          updatedAt: DateTime.now(),
        );
        await _saveCustomLists(lists);
        _customListsController.add(lists);
      }
    }
  }

  /// Removes a movie from a custom list.

  Future<void> removeMovieFromCustomList(String listId, int movieId) async {
    final lists = await getCustomLists();
    final listIndex = lists.indexWhere((list) => list.id == listId);
    if (listIndex != -1) {
      final currentList = lists[listIndex];
      final movieIndex = currentList.movieIds.indexOf(movieId);

      if (movieIndex != -1) {
        final updatedMovieIds =
            currentList.movieIds.where((id) => id != movieId).toList();

        // Update content types array by removing the type at the same index.

        List<String>? updatedContentTypes = currentList.contentTypes;
        if (updatedContentTypes != null &&
            movieIndex < updatedContentTypes.length) {
          updatedContentTypes = [...updatedContentTypes];
          updatedContentTypes.removeAt(movieIndex);
        }

        lists[listIndex] = currentList.copyWith(
          movieIds: updatedMovieIds,
          contentTypes: updatedContentTypes,
          updatedAt: DateTime.now(),
        );
        await _saveCustomLists(lists);
        _customListsController.add(lists);
      }
    }
  }

  /// Checks if a movie is in a specific custom list.

  Future<bool> isMovieInCustomList(String listId, int movieId) async {
    final lists = await getCustomLists();
    final list = lists.firstWhere(
      (list) => list.id == listId,
      orElse: () => CustomList(
        id: '',
        name: '',
        movieIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return list.movieIds.contains(movieId);
  }

  /// Gets all custom lists that contain a specific movie.

  Future<List<CustomList>> getCustomListsContainingMovie(int movieId) async {
    final lists = await getCustomLists();
    return lists.where((list) => list.movieIds.contains(movieId)).toList();
  }

  /// Gets movies in a specific custom list.
  /// Note: This base implementation returns empty list.
  /// The adapter implementation should override this to load from cache.

  Future<List<Movie>> getMoviesInCustomList(String listId) async {
    final lists = await getCustomLists();
    lists.firstWhere(
      (list) => list.id == listId,
      orElse: () => CustomList(
        id: '',
        name: '',
        movieIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    // Base implementation returns empty list
    // This should be overridden in the adapter to load from cache
    return [];
  }

  /// Gets movie IDs in a specific custom list.

  Future<List<int>> getMovieIdsInCustomList(String listId) async {
    final lists = await getCustomLists();
    final list = lists.firstWhere(
      (list) => list.id == listId,
      orElse: () => CustomList(
        id: '',
        name: '',
        movieIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return list.movieIds;
  }

  /// Saves custom lists to shared preferences.

  Future<void> _saveCustomLists(List<CustomList> lists) async {
    final encoded = jsonEncode(lists.map((list) => list.toJson()).toList());
    await _prefs.setString(_customListsKey, encoded);
  }

  /// Disposes the stream controllers.

  @override
  void dispose() {
    super.dispose();
    _toWatchController.close();
    _watchedController.close();
    _customListsController.close();
  }
}
