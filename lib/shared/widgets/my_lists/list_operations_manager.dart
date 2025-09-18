/// List Operations Manager Component - Complex POD sharing, deletion and management operations
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solidpod/solidpod.dart'
    show SolidFunctionCallStatus, readPod, writePod;

import 'package:moviestar/constants/timing_constants.dart';
import 'package:moviestar/core/services/favorites/favorites_service.dart';
import 'package:moviestar/core/services/favorites/favorites_service_adapter.dart';
import 'package:moviestar/core/services/favorites/movie_list_service.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/services/user_profile_service.dart';
import 'package:moviestar/utils/turtle_serializer.dart';
import 'package:moviestar/widgets/moviestar_batch_sharing_ui.dart';

/// Manager class that handles complex list operations like sharing and deletion
class ListOperationsManager {
  /// Shows options for a custom list (edit, share, delete)
  static Future<void> showListOptions({
    required BuildContext context,
    required CustomList list,
    required FavoritesService favoritesService,
    required Function(CustomList list) onEditList,
  }) async {
    final hasMovies = list.movieIds.isNotEmpty;
    final isPodEnabled = favoritesService is FavoritesServiceAdapter &&
        (favoritesService).isPodStorageEnabled;

    await showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit List'),
            onTap: () {
              Navigator.pop(context);
              onEditList(list);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.share,
              color: (hasMovies && isPodEnabled)
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.38),
            ),
            title: Text(
              'Share List',
              style: TextStyle(
                color: (hasMovies && isPodEnabled)
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.38),
              ),
            ),
            onTap: (hasMovies && isPodEnabled)
                ? () {
                    Navigator.pop(context);
                    _shareCustomList(
                      context: context,
                      list: list,
                      favoritesService: favoritesService,
                    );
                  }
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete List'),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(
                context: context,
                list: list,
                favoritesService: favoritesService,
              );
            },
          ),
        ],
      ),
    );
  }

  /// Shows a confirmation dialog before deleting a list
  static Future<void> _showDeleteConfirmation({
    required BuildContext context,
    required CustomList list,
    required FavoritesService favoritesService,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: Text(
          'Are you sure you want to delete "${list.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await favoritesService.deleteCustomList(list.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Deleted "${list.name}" list',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor:
                        Theme.of(context).colorScheme.errorContainer,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.all(16),
                    elevation: 6,
                    duration: TimingConstants.snackbarStandardDuration,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Shows a loading dialog during sharing process
  static void _showSharingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Preparing to share...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'This may take a few seconds',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shares the custom list and all movies using batch sharing UI
  /// Uses the same mechanism as the app bar sharing by loading movies from POD with correct content types
  static Future<void> _shareCustomList({
    required BuildContext context,
    required CustomList list,
    required FavoritesService favoritesService,
  }) async {
    if (list.movieIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No movies to share')),
      );
      return;
    }

    // Show loading dialog
    _showSharingDialog(context);

    try {
      // Load movies using the same mechanism as the custom list detail screen
      final moviesToShare = <Movie>[];

      // First try to load from POD if using POD storage (same as custom list detail screen)
      if (favoritesService is FavoritesServiceAdapter &&
          (favoritesService).isPodStorageEnabled) {
        final movieListService = MovieListService(
          context,
          context as ConsumerStatefulWidget,
          UserProfileService(context, context as ConsumerStatefulWidget),
        );

        try {
          // Try to find existing movie list in POD that matches our custom list
          final listId = list.id;
          final movieListData = await movieListService.getMovieList(listId);

          if (movieListData != null && movieListData['movies'] is List) {
            // Use the movies from POD which have correct content types
            final podMovies = (movieListData['movies'] as List).cast<Movie>();
            moviesToShare.addAll(podMovies);
          }
        } catch (e) {
          debugPrint('Failed to load from POD: $e');
        }
      }

      // If we didn't get movies from POD, load from API with content type correction
      if (moviesToShare.isEmpty && context.mounted) {
        final movieService =
            ProviderScope.containerOf(context).read(cachedMovieServiceProvider);

        for (int index = 0; index < list.movieIds.length; index++) {
          final movieId = list.movieIds[index];
          try {
            final movie = await movieService.getMovieDetails(movieId);

            // Determine content type from the list's stored content types
            final contentTypeString = list.getContentTypeAt(index);
            final contentType = contentTypeString == 'tv'
                ? ContentType.tvShow
                : ContentType.movie;

            // Create a new movie with the correct content type
            final movieWithContentType = Movie(
              id: movie.id,
              title: movie.title,
              overview: movie.overview,
              posterUrl: movie.posterUrl,
              backdropUrl: movie.backdropUrl,
              voteAverage: movie.voteAverage,
              releaseDate: movie.releaseDate,
              genreIds: movie.genreIds,
              contentType: contentType,
            );

            moviesToShare.add(movieWithContentType);
          } catch (e) {
            debugPrint('Failed to load movie $movieId: $e');
          }
        }
      }

      if (moviesToShare.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Movies are still loading. Please wait.'),
            ),
          );
        }
        return;
      }

      // Check mounted before using context after async operations.
      if (!context.mounted) return;

      // Store context references before async operations.
      final theme = Theme.of(context);

      // Create MovieList service to create the list file first.
      if (!context.mounted) return;
      final userProfileService =
          UserProfileService(context, context as ConsumerStatefulWidget);
      final movieListService = MovieListService(
        context,
        context as ConsumerStatefulWidget,
        userProfileService,
      );

      // Create the MovieList TTL file.
      final listId = await movieListService.createMovieList(
        list.name,
        movies: moviesToShare,
        description: list.description ?? 'Custom movie list',
      );

      if (!context.mounted) return;

      if (listId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create movie list')),
          );
        }
        return;
      }

      // Ensure all individual movie files exist before sharing.
      for (final movie in moviesToShare) {
        try {
          await _createMovieFileIfNotExists(
            movie: movie,
            context: context,
            favoritesService: favoritesService,
          );
        } catch (e) {
          // Continue with other movies - the batch UI will handle individual failures.
        }
        if (!context.mounted) return;
      }

      // Navigate to the batch sharing UI.
      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => MovieStarBatchSharingUi(
              listId: listId,
              listName: list.name,
              movies: moviesToShare,
              backgroundColor: theme.scaffoldBackgroundColor,
              onSharingComplete: () {
                // Handle completion callback.
              },
              child: context as ConsumerStatefulWidget,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing list: $e')),
        );
      }
    } finally {
      // Dismiss loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// Creates a movie file if it doesn't exist (needed before sharing)
  static Future<void> _createMovieFileIfNotExists({
    required Movie movie,
    required BuildContext context,
    required FavoritesService favoritesService,
  }) async {
    try {
      // Construct file name based on content type
      final isTV = movie.contentType == ContentType.tvShow;
      final filePrefix = isTV ? 'TVShow' : 'Movie';
      final movieFileName = 'movies/$filePrefix-${movie.id}.ttl';

      // Check if the file already exists.
      try {
        if (!context.mounted) return;
        final existingContent = await readPod(
          movieFileName,
          context,
          context as ConsumerStatefulWidget,
        );
        if (existingContent.isNotEmpty) {
          return;
        }
      } catch (e) {
        // File doesn't exist, we'll create it.
      }

      // Get current rating and comments from favorites service.
      final adapter = favoritesService as FavoritesServiceAdapter;
      final currentRating = await adapter.getPersonalRating(movie);
      final currentComments = await adapter.getMovieComments(movie);

      // Create the movie TTL content with any existing user data.
      final ttlContent = TurtleSerializer.movieWithUserDataToTurtleOntology(
        movie,
        currentRating,
        currentComments,
      );

      // Write the movie file to POD.
      if (!context.mounted) return;
      final result = await writePod(
        movieFileName,
        ttlContent,
        context,
        context as ConsumerStatefulWidget,
        encrypted: false,
      );

      if (result != SolidFunctionCallStatus.success) {
        throw Exception('Failed to write movie file to POD');
      }
    } catch (e) {
      rethrow;
    }
  }
}
