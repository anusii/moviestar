/// Stream management for PodFavoritesService.
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

import 'package:flutter/foundation.dart';

import 'package:rxdart/rxdart.dart';

import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';

/// Manages stream controllers for PodFavoritesService.
/// Extracted to reduce main service file size while preserving exact behavior.
class PodFavoritesStreamManager {
  /// Stream controller for to-watch movies.
  final _toWatchController = BehaviorSubject<List<Movie>>();

  /// Stream controller for watched movies.
  final _watchedController = BehaviorSubject<List<Movie>>();

  /// Stream controller for custom lists.
  final _customListsController = BehaviorSubject<List<CustomList>>();

  /// Stream of to-watch movies.
  Stream<List<Movie>> get toWatchStream => _toWatchController.stream;
  Stream<List<Movie>> get toWatchMovies => _toWatchController.stream;

  /// Stream of watched movies.
  Stream<List<Movie>> get watchedStream => _watchedController.stream;
  Stream<List<Movie>> get watchedMovies => _watchedController.stream;

  /// Stream of custom lists.
  Stream<List<CustomList>> get customListsStream =>
      _customListsController.stream;

  /// Current to-watch list.
  List<Movie> get toWatch => _toWatchController.valueOrNull ?? [];

  /// Current watched list.
  List<Movie> get watched => _watchedController.valueOrNull ?? [];

  /// Current custom lists.
  List<CustomList> get customLists => _customListsController.valueOrNull ?? [];

  /// Updates the to-watch stream with new data.
  void updateToWatch(List<Movie> movies) {
    _toWatchController.add(movies);
  }

  /// Updates the watched stream with new data.
  void updateWatched(List<Movie> movies) {
    _watchedController.add(movies);
  }

  /// Updates the custom lists stream with new data.
  void updateCustomLists(List<CustomList> lists) {
    debugPrint(
      '🎬 [PodFavoritesStreamManager] updateCustomLists called with ${lists.length} lists',
    );
    debugPrint(
      '🎬 [PodFavoritesStreamManager] Stream has ${_customListsController.hasListener ? "listeners" : "no listeners"}',
    );
    _customListsController.add(lists);
    debugPrint('🎬 [PodFavoritesStreamManager] Stream updated');
  }

  /// Checks if to-watch stream has listeners.
  bool get hasToWatchListeners => _toWatchController.hasListener;

  /// Checks if watched stream has listeners.
  bool get hasWatchedListeners => _watchedController.hasListener;

  /// Checks if custom lists stream has listeners.
  bool get hasCustomListsListeners => _customListsController.hasListener;

  /// Clears all data in streams.
  void clearAll() {
    _toWatchController.add([]);
    _watchedController.add([]);
    _customListsController.add([]);
  }

  /// Disposes all stream controllers.
  void dispose() {
    _toWatchController.close();
    _watchedController.close();
    _customListsController.close();
  }
}
