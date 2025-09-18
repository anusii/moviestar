/// Screen for managing the user's list of movies to watch.
///
// Time-stamp: <Thursday 2025-04-10 11:47:48 +1000 Graham Williams>
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
/// Authors: Kevin Wang.

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/core/services/favorites/service_adapter.dart';
import 'package:moviestar/core/services/favorites/movie_list_service.dart';
import 'package:moviestar/core/services/pod/pod_file_operations_service.dart';
import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/user_profile_service.dart';
import 'package:moviestar/utils/movie_sort_util.dart';
import 'package:moviestar/utils/navigation_utils.dart';
import 'package:moviestar/utils/serializer.dart';
import 'package:moviestar/widgets/base_screen.dart';
import 'package:moviestar/widgets/movie_list_widget.dart';
import 'package:moviestar/widgets/moviestar_batch_sharing_ui.dart';
import 'package:moviestar/widgets/sort_controls.dart';

/// A screen that displays the user's list of movies to watch.

class ToWatchScreen extends StatefulWidget {
  /// Service for managing favorite movies.

  final FavoritesService favoritesService;

  /// Creates a new [ToWatchScreen] widget.

  const ToWatchScreen({super.key, required this.favoritesService});

  @override
  State<ToWatchScreen> createState() => _ToWatchScreenState();
}

/// State class for the to watch screen.

class _ToWatchScreenState extends State<ToWatchScreen> with ScreenStateMixin {
  /// Currently selected sort criteria.

  MovieSortCriteria _sortCriteria = MovieSortCriteria.nameAsc;

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'To Watch',
      actions: [
        StreamBuilder<List<Movie>>(
          stream: widget.favoritesService.toWatchMovies,
          builder: (context, snapshot) {
            final hasMovies = snapshot.hasData && snapshot.data!.isNotEmpty;
            final isPodEnabled =
                widget.favoritesService is FavoritesServiceAdapter &&
                    (widget.favoritesService as FavoritesServiceAdapter)
                        .isPodStorageEnabled;

            return Padding(
              padding: const EdgeInsets.only(
                right: 60.0,
              ),
              child: MarkdownTooltip(
                message: '''

**📤 Share To-Watch List**

Share your **to-watch movies list** with others through your POD.

Recipients will be able to:
- View your list of movies to watch
- See movie details and ratings
- Access through secure POD sharing

*Requires POD storage to be enabled*

                ''',
                child: IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: (hasMovies && isPodEnabled)
                      ? () => _shareToWatchList(context, snapshot.data!)
                      : null,
                ),
              ),
            );
          },
        ),
      ],
      body: StreamBuilder<List<Movie>>(
        stream: widget.favoritesService.toWatchMovies,
        builder: (context, snapshot) {
          final movies = snapshot.data ?? [];
          final sortedMovies =
              movies.isNotEmpty ? sortMovies(movies, _sortCriteria) : <Movie>[];

          return MovieListWidget(
            movies: sortedMovies,
            favoritesService: widget.favoritesService,
            isLoading: snapshot.connectionState == ConnectionState.waiting,
            errorMessage: snapshot.hasError ? 'Error: ${snapshot.error}' : null,
            showSorting: true,
            initialSortCriteria: _sortCriteria,
            onSortChanged: (criteria) {
              safeSetState(() {
                _sortCriteria = criteria;
              });
            },
            onMovieTap: (movie) {
              safeNavigateTo(
                createMovieDetailsRoute(movie, widget.favoritesService),
              );
            },
            trailingBuilder: (movie) => IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: Colors.red,
              ),
              onPressed: () {
                widget.favoritesService.removeFromToWatch(movie);
              },
            ),
            emptyWidget: Center(
              child: Text(
                'Your watchlist is empty',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        },
      ),
    );
  }

  // Shares the to-watch movies list using batch sharing UI.

  Future<void> _shareToWatchList(
    BuildContext context,
    List<Movie> movies,
  ) async {
    if (movies.isEmpty) {
      showErrorSnackBar('No movies to share');
      return;
    }

    // Store context references before async operations.
    final theme = Theme.of(context);

    try {
      // Create MovieList service to create the list file first
      final userProfileService = UserProfileService(context, widget);
      final movieListService = MovieListService(
        context,
        widget,
        userProfileService,
      );

      // Create the MovieList TTL file
      final listId = await movieListService.createMovieList(
        'To Watch Movies',
        movies: movies,
        description: 'Movies you want to watch',
      );

      if (listId == null) {
        showErrorSnackBar('Failed to create movie list');
        return;
      }

      // Ensure all individual movie files exist before sharing.
      for (final movie in movies) {
        try {
          await _createMovieFileIfNotExists(movie);
        } catch (e) {
          // Continue with other movies - the batch UI will handle individual failures.
        }
      }

      // Navigate to the batch sharing UI.
      await safeNavigateTo<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => MovieStarBatchSharingUi(
            listId: listId,
            listName: 'To Watch Movies',
            movies: movies,
            backgroundColor: theme.scaffoldBackgroundColor,
            onSharingComplete: () {
              // Handle completion callback.
            },
            child: widget,
          ),
        ),
      );
    } catch (e) {
      showErrorSnackBar('Error sharing list: $e');
    }
  }

  // Creates a movie file if it doesn't exist (needed before sharing).

  Future<void> _createMovieFileIfNotExists(Movie movie) async {
    try {
      final movieFileName = 'movies/Movie-${movie.id}.ttl';

      // Check if the file already exists.
      if (await PodFileOperationsService.fileExists(
        movieFileName,
        context,
        widget,
      )) {
        return;
      }

      // Get current rating and comments from favorites service.
      final adapter = widget.favoritesService as FavoritesServiceAdapter;
      final currentRating = await adapter.getPersonalRating(movie);
      final currentComments = await adapter.getMovieComments(movie);

      // Create the movie TTL content with any existing user data.
      final ttlContent = TurtleSerializer.movieWithUserDataToTurtleOntology(
        movie,
        currentRating,
        currentComments,
      );

      // Write the movie file to POD.
      if (!mounted) return;
      final result = await PodFileOperationsService.writeFile(
        movieFileName,
        ttlContent,
        context,
        widget,
        encrypted: false,
      );

      if (!result.success) {
        throw Exception('Failed to write movie file to POD: ${result.error}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
