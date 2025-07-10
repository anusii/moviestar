/// Adapter to make FavoritesServiceManager compatible with existing screens.
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

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/services/favorites_service_manager.dart';

/// Adapter that makes FavoritesServiceManager look like FavoritesService.
/// This allows us to integrate POD storage without changing all existing screens.

class FavoritesServiceAdapter extends FavoritesService {
  final FavoritesServiceManager _manager;

  FavoritesServiceAdapter(this._manager) : super(_manager.prefs);

  @override
  Stream<List<Movie>> get toWatchMovies => _manager.toWatchMovies;

  @override
  Stream<List<Movie>> get watchedMovies => _manager.watchedMovies;

  @override
  Future<List<Movie>> getToWatch() => _manager.getToWatch();

  @override
  Future<List<Movie>> getWatched() => _manager.getWatched();

  @override
  Future<void> addToWatch(Movie movie) => _manager.addToWatch(movie);

  @override
  Future<void> addToWatched(Movie movie) => _manager.addToWatched(movie);

  @override
  Future<void> removeFromToWatch(Movie movie) =>
      _manager.removeFromToWatch(movie);

  @override
  Future<void> removeFromWatched(Movie movie) =>
      _manager.removeFromWatched(movie);

  @override
  Future<bool> isInToWatch(Movie movie) => _manager.isInToWatch(movie);

  @override
  Future<bool> isInWatched(Movie movie) => _manager.isInWatched(movie);

  @override
  Future<double?> getPersonalRating(Movie movie) =>
      _manager.getPersonalRating(movie);

  @override
  Future<void> setPersonalRating(Movie movie, double rating) =>
      _manager.setPersonalRating(movie, rating);

  @override
  Future<void> removePersonalRating(Movie movie) =>
      _manager.removePersonalRating(movie);

  @override
  Future<String?> getMovieComments(Movie movie) =>
      _manager.getMovieComments(movie);

  @override
  Future<void> setMovieComments(Movie movie, String comments) =>
      _manager.setMovieComments(movie, comments);

  @override
  Future<void> removeMovieComments(Movie movie) =>
      _manager.removeMovieComments(movie);

  @override
  Future<bool> hasMovieFile(Movie movie) => _manager.hasMovieFile(movie);

  @override
  String? getMovieFilePath(Movie movie) => _manager.getMovieFilePath(movie);

  /// Checks if POD storage is currently enabled.

  bool get isPodStorageEnabled => _manager.isPodStorageEnabled;

  @override
  void dispose() {
    // Don't dispose the manager as other components may still be using it.

    super.dispose();
  }
}
