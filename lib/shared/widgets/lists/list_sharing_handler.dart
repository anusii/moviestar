/// Handler for sharing custom lists functionality.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solidpod/solidpod.dart'
    show SolidFunctionCallStatus, readPod, writePod;

import 'package:moviestar/core/services/favorites/movie_list_service.dart';
import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/core/services/favorites/service_adapter.dart';
import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/services/user_profile_service.dart';
import 'package:moviestar/utils/serializer.dart';
import 'package:moviestar/widgets/moviestar_batch_sharing_ui.dart';

/// Handler for custom list sharing functionality.

class ListSharingHandler {
  final BuildContext context;
  final ConsumerStatefulWidget widget;
  final WidgetRef ref;
  final FavoritesService favoritesService;
  final ScreenStateMixin screenState;

  const ListSharingHandler({
    required this.context,
    required this.widget,
    required this.ref,
    required this.favoritesService,
    required this.screenState,
  });

  /// Shows options for a custom list (edit, share, delete).

  Future<void> showListOptions(
    CustomList list,
    VoidCallback onEdit,
    VoidCallback onDelete,
  ) async {
    final hasMovies = list.movieIds.isNotEmpty;
    final isPodEnabled = favoritesService is FavoritesServiceAdapter &&
        (favoritesService as FavoritesServiceAdapter).isPodStorageEnabled;

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
              onEdit();
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
                    shareCustomList(list);
                  }
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete List'),
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
        ],
      ),
    );
  }

  /// Shows a loading dialog during sharing process.

  void _showSharingDialog() {
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

  /// Shares the custom list and all movies using batch sharing UI.

  Future<void> shareCustomList(CustomList list) async {
    if (list.movieIds.isEmpty) {
      screenState.showInfoSnackBar('No movies to share');
      return;
    }

    _showSharingDialog();

    try {
      final moviesToShare = await _loadMoviesForSharing(list);

      if (moviesToShare.isEmpty) {
        screenState.showErrorSnackBar('Movies are still loading. Please wait.');
        return;
      }

      if (!context.mounted) return;

      final theme = Theme.of(context);
      final userProfileService = UserProfileService(context, widget);
      final movieListService = MovieListService(
        context,
        widget,
        userProfileService,
      );

      final listId = await movieListService.createMovieList(
        list.name,
        movies: moviesToShare,
        description: list.description ?? 'Custom movie list',
      );

      if (!context.mounted) return;

      if (listId == null) {
        if (context.mounted) {
          screenState.showErrorSnackBar('Failed to create movie list');
        }
        return;
      }

      for (final movie in moviesToShare) {
        try {
          await _createMovieFileIfNotExists(movie);
        } catch (e) {
          // Continue with other movies.
        }
        if (!context.mounted) return;
      }

      if (context.mounted) {
        await screenState.safeNavigateTo(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => MovieStarBatchSharingUi(
              listId: listId,
              listName: list.name,
              movies: moviesToShare,
              backgroundColor: theme.scaffoldBackgroundColor,
              onSharingComplete: () {},
              child: widget,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        screenState.showErrorSnackBar('Error sharing list: $e');
      }
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// Loads movies for sharing from POD or API.

  Future<List<Movie>> _loadMoviesForSharing(CustomList list) async {
    final moviesToShare = <Movie>[];

    if (favoritesService is FavoritesServiceAdapter &&
        (favoritesService as FavoritesServiceAdapter).isPodStorageEnabled) {
      final movieListService = MovieListService(
        context,
        widget,
        UserProfileService(context, widget),
      );

      try {
        final listId = list.id;
        final movieListData = await movieListService.getMovieList(listId);

        if (movieListData != null && movieListData['movies'] is List) {
          final podMovies = (movieListData['movies'] as List).cast<Movie>();
          moviesToShare.addAll(podMovies);
        }
      } catch (e) {
        // Failed to get movies from POD.
      }
    }

    if (moviesToShare.isEmpty) {
      final movieService = ref.read(cachedMovieServiceProvider);

      for (int index = 0; index < list.movieIds.length; index++) {
        final movieId = list.movieIds[index];
        try {
          final movie = await movieService.getMovieDetails(movieId);
          final contentTypeString = list.getContentTypeAt(index);
          final contentType = contentTypeString == 'tv'
              ? ContentType.tvShow
              : ContentType.movie;

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
          // Failed to fetch movie details.
        }
      }
    }

    return moviesToShare;
  }

  /// Creates a movie file if it doesn't exist (needed before sharing).

  Future<void> _createMovieFileIfNotExists(Movie movie) async {
    try {
      final isTV = movie.contentType == ContentType.tvShow;
      final filePrefix = isTV ? 'TVShow' : 'Movie';
      final movieFileName = 'movies/$filePrefix-${movie.id}.ttl';

      try {
        if (!context.mounted) return;
        final existingContent = await readPod(movieFileName);
        if (existingContent.isNotEmpty) {
          return;
        }
      } catch (e) {
        // File doesn't exist, we'll create it.
      }

      final adapter = favoritesService as FavoritesServiceAdapter;
      final currentRating = await adapter.getPersonalRating(movie);
      final currentComments = await adapter.getMovieComments(movie);

      final ttlContent = TurtleSerializer.movieWithUserDataToTurtleOntology(
        movie,
        currentRating,
        currentComments,
      );

      if (!context.mounted) return;
      final result = await writePod(
        movieFileName,
        ttlContent,
        context,
        widget,
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
