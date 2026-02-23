/// Movie Card Builders for Custom Lists.
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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/core/services/api/content_service.dart';
import 'package:moviestar/core/services/cache/cached_movie_service.dart';
import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/shared/widgets/home/custom_list_states.dart';
import 'package:moviestar/widgets/movie_card.dart';

/// A widget that builds movie cards for custom lists from movie IDs.
/// Handles loading movie data on demand and displaying appropriate states.

class CustomListMovieCard extends ConsumerWidget {
  /// ID of the movie to display.

  final int movieId;

  /// Content type (movie or tv).

  final String contentType;

  /// Service for managing favorites.

  final FavoritesService favoritesService;

  /// Parent widget for navigation context.

  final StatefulWidget parentWidget;

  /// Callback for navigation.

  final void Function(Route<dynamic> route) onNavigate;

  /// Whether to display as a list item instead of poster.

  final bool isListItem;

  /// Creates a new [CustomListMovieCard].

  const CustomListMovieCard({
    super.key,
    required this.movieId,
    this.contentType = 'movie',
    required this.favoritesService,
    required this.parentWidget,
    required this.onNavigate,
    this.isListItem = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cachedMovieService = ref.read(cachedMovieServiceProvider);
    final contentService = ref.read(contentServiceProvider);

    return FutureBuilder<Movie>(
      future: _getContentAsMovieWithType(
        movieId,
        contentType,
        cachedMovieService,
        contentService,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MovieErrorCard(
            width: 100,
            height: 150,
            isListItem: isListItem,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return MovieLoadingCard(
            width: 100,
            height: 150,
            isListItem: isListItem,
          );
        }

        final movie = snapshot.data!;
        return _buildMovieCard(context, movie);
      },
    );
  }

  /// Builds the appropriate movie card based on layout type.

  Widget _buildMovieCard(BuildContext context, Movie movie) {
    void onTap() {
      onNavigate(
        MaterialPageRoute(
          builder: (context) => MovieDetailsScreen(
            movie: movie,
            favoritesService: favoritesService,
            contentType: movie.contentType ?? ContentType.movie,
          ),
        ),
      );
    }

    if (isListItem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: MovieCard.listItem(
          movie: movie,
          fromCache: false,
          favoritesService: favoritesService,
          parentWidget: parentWidget,
          onTap: onTap,
        ),
      );
    }

    return MovieCard.poster(
      movie: movie,
      fromCache: false,
      favoritesService: favoritesService,
      parentWidget: parentWidget,
      onTap: onTap,
    );
  }

  /// Helper method to get content as Movie based on known content type.

  Future<Movie> _getContentAsMovieWithType(
    int contentId,
    String contentType,
    CachedMovieService cachedMovieService,
    ContentService contentService,
  ) async {
    if (contentType == 'tv') {
      final tvShowContent = await contentService.getTVDetails(contentId);
      return Movie.fromContentItem(tvShowContent);
    } else {
      return await cachedMovieService.getMovieDetails(contentId);
    }
  }
}

/// A widget that displays a movie card directly from a Movie object.
/// Used when we have full movie data available (e.g., from POD storage).

class CustomListDirectMovieCard extends StatelessWidget {
  /// The movie to display.

  final Movie movie;

  /// Service for managing favorites.

  final FavoritesService favoritesService;

  /// Parent widget for navigation context.

  final StatefulWidget parentWidget;

  /// Callback for navigation.

  final void Function(Route<dynamic> route) onNavigate;

  /// Whether to display as a list item instead of poster.

  final bool isListItem;

  /// Creates a new [CustomListDirectMovieCard].

  const CustomListDirectMovieCard({
    super.key,
    required this.movie,
    required this.favoritesService,
    required this.parentWidget,
    required this.onNavigate,
    this.isListItem = false,
  });

  @override
  Widget build(BuildContext context) {
    void onTap() {
      onNavigate(
        MaterialPageRoute(
          builder: (context) => MovieDetailsScreen(
            movie: movie,
            favoritesService: favoritesService,
            contentType: movie.contentType ?? ContentType.movie,
          ),
        ),
      );
    }

    if (isListItem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: MovieCard.listItem(
          movie: movie,
          fromCache: true,
          favoritesService: favoritesService,
          parentWidget: parentWidget,
          onTap: onTap,
        ),
      );
    }

    return MovieCard.poster(
      movie: movie,
      fromCache: true,
      favoritesService: favoritesService,
      parentWidget: parentWidget,
      onTap: onTap,
    );
  }
}
