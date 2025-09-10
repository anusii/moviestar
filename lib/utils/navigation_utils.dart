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

/// Navigates to the movie details screen and returns a result.
///
/// This version allows waiting for a result from the details screen.
Future<T?> navigateToMovieDetailsForResult<T>(
  BuildContext context,
  Movie movie,
  FavoritesService favoritesService,
) async {
  return Navigator.push<T>(
    context,
    MaterialPageRoute<T>(
      builder: (context) => MovieDetailsScreen(
        movie: movie,
        favoritesService: favoritesService,
      ),
    ),
  );
}

/// Navigates to movie details and removes all previous routes.
///
/// Useful for deep linking or when you want to reset the navigation stack.
Future<void> navigateToMovieDetailsAndClear(
  BuildContext context,
  Movie movie,
  FavoritesService favoritesService,
) async {
  await Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute<void>(
      builder: (context) => MovieDetailsScreen(
        movie: movie,
        favoritesService: favoritesService,
      ),
    ),
    (route) => false,
  );
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

/// Creates a fade transition route for movie details.
///
/// Provides a smoother transition animation than the default slide.
Route<void> createMovieDetailsFadeRoute(
  Movie movie,
  FavoritesService favoritesService, {
  Duration duration = const Duration(milliseconds: 300),
}) {
  return PageRouteBuilder<void>(
    pageBuilder: (context, animation, secondaryAnimation) => MovieDetailsScreen(
      movie: movie,
      favoritesService: favoritesService,
    ),
    transitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}

/// Creates a slide transition route for movie details.
///
/// Allows customizing the slide direction for the transition.
Route<void> createMovieDetailsSlideRoute(
  Movie movie,
  FavoritesService favoritesService, {
  Offset beginOffset = const Offset(1.0, 0.0),
  Duration duration = const Duration(milliseconds: 300),
}) {
  return PageRouteBuilder<void>(
    pageBuilder: (context, animation, secondaryAnimation) => MovieDetailsScreen(
      movie: movie,
      favoritesService: favoritesService,
    ),
    transitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(begin: beginOffset, end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeInOut));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}
