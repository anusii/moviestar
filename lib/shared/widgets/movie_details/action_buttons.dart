/// Movie Action Buttons for Movie Details Screen.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/core/services/favorites/service_adapter.dart';

/// A widget that displays the action buttons for a movie details screen.
/// This component shows bookmark, watched, add to list, and share buttons.
class MovieActionButtons extends StatelessWidget {
  /// Whether the movie is in the to-watch list.
  final bool isInToWatch;

  /// Whether the movie is in the watched list.
  final bool isInWatched;

  /// Whether this is a shared movie.
  final bool isSharedMovie;

  /// Whether the movie has a local file.
  final bool hasMovieFile;

  /// Service for managing favorite movies.
  final FavoritesService favoritesService;

  /// Callback when to-watch is toggled.
  final VoidCallback onToggleToWatch;

  /// Callback when watched is toggled.
  final VoidCallback onToggleWatched;

  /// Callback to show add to lists dialog.
  final VoidCallback onShowAddToLists;

  /// Callback to share the movie.
  final VoidCallback onShareMovie;

  /// Creates a new [MovieActionButtons] widget.
  const MovieActionButtons({
    super.key,
    required this.isInToWatch,
    required this.isInWatched,
    required this.isSharedMovie,
    required this.hasMovieFile,
    required this.favoritesService,
    required this.onToggleToWatch,
    required this.onToggleWatched,
    required this.onShowAddToLists,
    required this.onShareMovie,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            isInToWatch ? Icons.bookmark : Icons.bookmark_border,
            color: isInToWatch
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: onToggleToWatch,
          tooltip: isInToWatch ? 'Remove from To Watch' : 'Add to To Watch',
        ),
        IconButton(
          icon: Icon(
            isInWatched ? Icons.check_circle : Icons.check_circle_outline,
            color: isInWatched
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: onToggleWatched,
          tooltip: isInWatched ? 'Remove from Watched' : 'Add to Watched',
        ),
        if (!isSharedMovie)
          MarkdownTooltip(
            message: '''

**Add to Custom List**

Add this movie to one of your custom lists or create a new list.
Organize your movies the way you want!

            ''',
            child: IconButton(
              icon: Icon(
                Icons.playlist_add,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: onShowAddToLists,
            ),
          ),
        if (hasMovieFile &&
            favoritesService is FavoritesServiceAdapter &&
            (favoritesService as FavoritesServiceAdapter).isPodStorageEnabled)
          MarkdownTooltip(
            message: '''

**Share this movie and my review**

Share your rating and comments for this movie with friends via their WebID.
Your shared movies will appear in their "Shared with Me" tab.

            ''',
            child: IconButton(
              icon: Icon(
                Icons.share,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: onShareMovie,
            ),
          ),
      ],
    );
  }
}
