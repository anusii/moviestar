/// Utility functions for navigation throughout the app.
///
// Time-stamp: <Friday 2025-09-10 05:51:08 +1000 Graham Williams>
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

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/services/favorites_service.dart';

/// Navigates to the movie details screen with the specified movie.
///
/// This centralizes the navigation logic for movie details, ensuring
/// consistent behavior across the app.
Future<void> navigateToMovieDetails(
  BuildContext context,
  Movie movie,
  FavoritesService favoritesService, {
  bool replace = false,
}) async {
  final route = MaterialPageRoute<void>(
    builder: (context) => MovieDetailsScreen(
      movie: movie,
      favoritesService: favoritesService,
    ),
  );

  if (replace) {
    await Navigator.pushReplacement(context, route);
  } else {
    await Navigator.push(context, route);
  }
}

/// Creates a route for the movie details screen.
///
/// This can be used with custom navigation animations or named routes.
Route<void> createMovieDetailsRoute(
  Movie movie,
  FavoritesService favoritesService,
) {
  return MaterialPageRoute<void>(
    builder: (context) => MovieDetailsScreen(
      movie: movie,
      favoritesService: favoritesService,
    ),
  );
}
