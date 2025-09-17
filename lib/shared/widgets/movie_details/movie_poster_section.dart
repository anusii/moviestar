/// Movie Poster Section for Movie Details Screen
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/utils/movie_display_utils.dart';

/// A widget that displays the poster/hero section of a movie details screen.
/// This component shows the backdrop image with a collapsible app bar.
class MoviePosterSection extends StatelessWidget {
  /// The movie to display.
  final Movie movie;

  /// Creates a new [MoviePosterSection] widget.
  const MoviePosterSection({
    super.key,
    required this.movie,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: Container(
        margin: const EdgeInsets.all(Dimensions.m),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surface
              .withValues(alpha: 0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: isValidImageUrl(movie.backdropUrl)
            ? CachedNetworkImage(
                imageUrl: movie.backdropUrl.trim(),
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.error),
              )
            : Container(
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: Center(
                  child: Icon(
                    Icons.movie,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
      ),
    );
  }
}