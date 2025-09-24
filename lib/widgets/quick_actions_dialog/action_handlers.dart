/// Action handlers for quick actions dialog.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/core/services/favorites/service_adapter.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/widgets/movie_sharing_ui.dart';

/// Static helper class for handling quick actions.
class ActionHandlers {
  /// Toggles the to-watch status for a movie.
  static Future<void> toggleToWatch({
    required FavoritesService favoritesService,
    required Movie movie,
    required ContentType contentType,
    required bool currentState,
    required VoidCallback onStateChange,
    required Function(bool) onStateUpdate,
  }) async {
    final originalState = currentState;
    onStateUpdate(!currentState);

    try {
      if (originalState) {
        await favoritesService.removeFromToWatch(movie);
      } else {
        await favoritesService.addToWatch(
          movie,
          contentType: contentType == ContentType.tvShow ? 'tv' : 'movie',
        );
      }
    } catch (e) {
      onStateUpdate(originalState);
    }
  }

  /// Toggles the watched status for a movie.
  static Future<void> toggleWatched({
    required FavoritesService favoritesService,
    required Movie movie,
    required ContentType contentType,
    required bool currentState,
    required VoidCallback onStateChange,
    required Function(bool) onStateUpdate,
  }) async {
    final originalState = currentState;
    onStateUpdate(!currentState);

    try {
      if (originalState) {
        await favoritesService.removeFromWatched(movie);
      } else {
        await favoritesService.addToWatched(
          movie,
          contentType: contentType == ContentType.tvShow ? 'tv' : 'movie',
        );
      }
    } catch (e) {
      onStateUpdate(originalState);
    }
  }

  /// Updates the personal rating for a movie.
  static Future<void> updateRating({
    required FavoritesService favoritesService,
    required Movie movie,
    required double? rating,
    required Function(double?) onRatingUpdate,
    required VoidCallback onMovieFileCheck,
  }) async {
    try {
      if (rating == null) {
        await favoritesService.removePersonalRating(movie);
      } else {
        await favoritesService.setPersonalRating(movie, rating);
      }
      onRatingUpdate(rating);
      onMovieFileCheck();
    } catch (e) {
      // Handle error silently for now.
    }
  }

  /// Shares a movie using the custom movie sharing UI.
  static Future<void> shareMovie({
    required BuildContext context,
    required FavoritesService favoritesService,
    required Movie movie,
    required Function(String) onError,
  }) async {
    try {
      // Check if user has POD storage enabled and is using the adapter.

      if (favoritesService is! FavoritesServiceAdapter) {
        onError('POD storage is required for sharing');
        return;
      }

      // Check if POD storage is enabled.

      if (!favoritesService.isPodStorageEnabled) {
        onError('POD storage must be enabled to share movies');
        return;
      }

      // Ensure the movie file exists before sharing - use simplified approach.

      final hasFile = await favoritesService.hasMovieFile(movie);
      if (!hasFile) {
        // Create a minimal movie file to enable sharing.

        await favoritesService.setMovieComments(movie, '');
        await favoritesService.removeMovieComments(movie);
      }

      // Navigate to MovieSharingUI which handles all the complex sharing logic.

      if (!context.mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MovieSharingUI(
            movie: movie,
            onSharingComplete: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${movie.title}" shared successfully'),
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                  ),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      onError('Error sharing movie: $e');
    }
  }

  /// Checks if the movie has a shareable file.
  static Future<bool> checkMovieFile({
    required FavoritesService favoritesService,
    required Movie movie,
  }) async {
    try {
      return await favoritesService.hasMovieFile(movie);
    } catch (e) {
      return false;
    }
  }
}
