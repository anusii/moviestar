/// Movie List Items for Home Screen
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/core/services/favorites/favorites_service.dart';
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