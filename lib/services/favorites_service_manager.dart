/// Service manager that switches between local and POD storage for favorites.
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

import 'package:shared_preferences/shared_preferences.dart';

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/services/pod_favorites_service.dart';

/// Manager that switches between local and POD storage based on user preferences.

class FavoritesServiceManager extends ChangeNotifier {
  static const String _podStorageEnabledKey = 'pod_storage_enabled';

  final SharedPreferences _prefs;
  final BuildContext _context;
  final Widget _child;

  late FavoritesService _localService;
  PodFavoritesService? _podService;
  bool _isPodStorageEnabled = false;

  /// Creates a new [FavoritesServiceManager] instance.

  FavoritesServiceManager(this._prefs, this._context, this._child) {
    _localService = FavoritesService(_prefs);
    _loadPodStoragePreference();
  }

  /// Loads the POD storage preference from SharedPreferences.

  Future<void> _loadPodStoragePreference() async {
    _isPodStorageEnabled = _prefs.getBool(_podStorageEnabledKey) ?? false;

    if (_isPodStorageEnabled) {
      await _enablePodService();
    }

    notifyListeners();
  }

  /// Enables POD storage service.

  Future<void> _enablePodService() async {
    try {
      _podService = PodFavoritesService(_prefs, _context, _child);
      debugPrint('POD storage service enabled');
    } catch (e) {
      debugPrint('Failed to enable POD service: $e');
      _isPodStorageEnabled = false;
      await _prefs.setBool(_podStorageEnabledKey, false);
    }
  }

  /// Checks if POD storage is currently enabled.

  bool get isPodStorageEnabled => _isPodStorageEnabled;

  /// Gets the SharedPreferences instance.

  SharedPreferences get prefs => _prefs;

  /// Reloads POD data after app folders are initialised.

  Future<void> reloadPodDataAfterInit() async {
    if (_isPodStorageEnabled && _podService != null) {
      await _podService!.reloadFromPod();
    }
  }

  /// Stream of to-watch movies from the active service.

  Stream<List<Movie>> get toWatchMovies {
    if (_isPodStorageEnabled && _podService != null) {
      return _podService!.toWatchMovies;
    }
    return _localService.toWatchMovies;
  }

  /// Stream of watched movies from the active service.

  Stream<List<Movie>> get watchedMovies {
    if (_isPodStorageEnabled && _podService != null) {
      return _podService!.watchedMovies;
    }
    return _localService.watchedMovies;
  }

  /// Retrieves the list of to-watch movies.

  Future<List<Movie>> getToWatch() async {
    if (_isPodStorageEnabled && _podService != null) {
      return _podService!.getToWatch();
    }
    return _localService.getToWatch();
  }

  /// Retrieves the list of watched movies.

  Future<List<Movie>> getWatched() async {
    if (_isPodStorageEnabled && _podService != null) {
      return _podService!.getWatched();
    }
    return _localService.getWatched();
  }

  /// Adds a movie to the to-watch list.

  Future<void> addToWatch(Movie movie) async {
    if (_isPodStorageEnabled && _podService != null) {
      await _podService!.addToWatch(movie);
    } else {
      await _localService.addToWatch(movie);
    }
  }

  /// Adds a movie to the watched list.

  Future<void> addToWatched(Movie movie) async {
    if (_isPodStorageEnabled && _podService != null) {
      await _podService!.addToWatched(movie);
    } else {
      await _localService.addToWatched(movie);
    }
  }

  /// Removes a movie from the to-watch list.

  Future<void> removeFromToWatch(Movie movie) async {
    if (_isPodStorageEnabled && _podService != null) {
      await _podService!.removeFromToWatch(movie);
    } else {
      await _localService.removeFromToWatch(movie);
    }
  }

  /// Removes a movie from the watched list.

  Future<void> removeFromWatched(Movie movie) async {
    if (_isPodStorageEnabled && _podService != null) {
      await _podService!.removeFromWatched(movie);
    } else {
      await _localService.removeFromWatched(movie);
    }
  }

  /// Checks if a movie is in the to-watch list.

  Future<bool> isInToWatch(Movie movie) async {
    if (_isPodStorageEnabled && _podService != null) {
      return _podService!.isInToWatch(movie);
    }
    return _localService.isInToWatch(movie);
  }

  /// Checks if a movie is in the watched list.

  Future<bool> isInWatched(Movie movie) async {
    if (_isPodStorageEnabled && _podService != null) {
      return _podService!.isInWatched(movie);
    }
    return _localService.isInWatched(movie);
  }

  /// Gets the user's personal rating for a movie.

  Future<double?> getPersonalRating(Movie movie) async {
    if (_isPodStorageEnabled && _podService != null) {
      return _podService!.getPersonalRating(movie);
    }
    return _localService.getPersonalRating(movie);
  }

  /// Sets the user's personal rating for a movie.

  Future<void> setPersonalRating(Movie movie, double rating) async {
    if (_isPodStorageEnabled && _podService != null) {
      await _podService!.setPersonalRating(movie, rating);
    } else {
      await _localService.setPersonalRating(movie, rating);
    }
  }

  /// Removes the user's personal rating for a movie.

  Future<void> removePersonalRating(Movie movie) async {
    if (_isPodStorageEnabled && _podService != null) {
      await _podService!.removePersonalRating(movie);
    } else {
      await _localService.removePersonalRating(movie);
    }
  }

  /// Gets the personal comments for a movie.

  Future<String?> getMovieComments(Movie movie) async {
    if (_isPodStorageEnabled && _podService != null) {
      return _podService!.getMovieComments(movie);
    }
    return _localService.getMovieComments(movie);
  }

  /// Sets the personal comments for a movie.

  Future<void> setMovieComments(Movie movie, String comments) async {
    if (_isPodStorageEnabled && _podService != null) {
      await _podService!.setMovieComments(movie, comments);
    } else {
      await _localService.setMovieComments(movie, comments);
    }
  }

  /// Removes the personal comments for a movie.

  Future<void> removeMovieComments(Movie movie) async {
    if (_isPodStorageEnabled && _podService != null) {
      await _podService!.removeMovieComments(movie);
    } else {
      await _localService.removeMovieComments(movie);
    }
  }

  /// Checks if a movie file exists (i.e. user has interacted with this movie).
  /// This is only relevant for POD storage.

  Future<bool> hasMovieFile(Movie movie) async {
    if (_isPodStorageEnabled && _podService != null) {
      return _podService!.hasMovieFile(movie);
    }
    // For local storage, check if either rating or comment exists.

    final hasRating = await getPersonalRating(movie) != null;
    final hasComment = await getMovieComments(movie) != null &&
        (await getMovieComments(movie))!.isNotEmpty;
    return hasRating || hasComment;
  }

  /// Gets the file path for a movie file (used for sharing).
  /// This is only relevant for POD storage.

  String? getMovieFilePath(Movie movie) {
    if (_isPodStorageEnabled && _podService != null) {
      return _podService!.getMovieFilePath(movie);
    }
    // Local storage doesn't have shareable file paths.

    return null;
  }

  /// Enables POD storage and migrates data.

  Future<bool> enablePodStorage() async {
    try {
      // Create POD service.

      _podService = PodFavoritesService(_prefs, _context, _child);

      // Test POD availability.

      final isPodAvailable = await _podService!.isPodAvailable();
      if (!isPodAvailable) {
        debugPrint(
          'POD is not available (user not logged in), cannot enable POD storage',
        );
        _podService = null;
        return false;
      }

      // Migrate data from local to POD.

      await _podService!.migrateToPod();

      // Update preference.

      _isPodStorageEnabled = true;
      await _prefs.setBool(_podStorageEnabledKey, true);

      debugPrint('POD storage enabled successfully');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to enable POD storage: $e');
      _podService = null;
      _isPodStorageEnabled = false;
      await _prefs.setBool(_podStorageEnabledKey, false);
      return false;
    }
  }

  /// Disables POD storage and reverts to local storage.

  Future<void> disablePodStorage() async {
    _isPodStorageEnabled = false;
    await _prefs.setBool(_podStorageEnabledKey, false);

    // Dispose POD service.

    _podService?.dispose();
    _podService = null;

    debugPrint('POD storage disabled, using local storage');
    notifyListeners();
  }

  /// Syncs data with POD if POD storage is enabled.

  Future<void> syncWithPod() async {
    if (_isPodStorageEnabled && _podService != null) {
      await _podService!.syncWithPod();
    }
  }

  @override
  void dispose() {
    _localService.dispose();
    _podService?.dispose();
    super.dispose();
  }
}
