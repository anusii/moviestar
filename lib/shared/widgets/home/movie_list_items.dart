/// Movie List Items for Home Screen.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Ashley Tang, Kevin Wang

library;

import 'package:flutter/material.dart';

import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/widgets/movie_card.dart';

/// A widget that builds movie list items for list view mode in the home screen.
/// This component displays up to 5 movies in a vertical list format.

class HomeMovieListItems extends StatelessWidget {
  /// List of movies to display.

  final List<Movie> movies;

  /// Whether the movies are from cache.

  final bool fromCache;

  /// Service for managing favorite movies.

  final FavoritesService favoritesService;

  /// Parent widget for navigation context.

  final StatefulWidget parentWidget;

  /// Callback for safe navigation.

  final void Function(Route<dynamic> route) onNavigate;

  /// Creates a new [HomeMovieListItems] widget.

  const HomeMovieListItems({
    super.key,
    required this.movies,
    required this.fromCache,
    required this.favoritesService,
    required this.parentWidget,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    if (movies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No movies available'),
      );
    }

    return Column(
      children: movies.take(5).map((movie) {
        return MovieCard.listItem(
          movie: movie,
          fromCache: fromCache,
          favoritesService: favoritesService,
          parentWidget: parentWidget,
          onTap: () {
            onNavigate(
              MaterialPageRoute(
                builder: (context) => MovieDetailsScreen(
                  movie: movie,
                  favoritesService: favoritesService,
                  contentType: movie.contentType ?? ContentType.movie,
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
