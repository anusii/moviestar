/// Screen for managing movies the user has rated and reviewed.
///
// Time-stamp: <Tuesday 2025-08-20 21:52:00 +1000 Ashley Tang>
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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:solidpod/solidpod.dart';

import 'package:moviestar/core/services/favorites/favorites_service.dart';
import 'package:moviestar/core/services/favorites/favorites_service_adapter.dart';
import 'package:moviestar/core/services/favorites/movie_list_service.dart';
import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/services/user_profile_service.dart';
import 'package:moviestar/utils/movie_sort_util.dart';
import 'package:moviestar/utils/turtle_serializer.dart';
import 'package:moviestar/widgets/base_screen.dart';
import 'package:moviestar/widgets/moviestar_batch_sharing_ui.dart';
import 'package:moviestar/widgets/sort_controls.dart';

/// A screen that displays movies the user has rated and reviewed.

class MyMoviesScreen extends StatefulWidget {
  /// Service for managing favorite movies.

  final FavoritesService favoritesService;

  /// Creates a new [MyMoviesScreen] widget.

  const MyMoviesScreen({super.key, required this.favoritesService});

  @override
  State<MyMoviesScreen> createState() => _MyMoviesScreenState();
}

/// State class for the my movies screen.

class _MyMoviesScreenState extends State<MyMoviesScreen> with ScreenStateMixin {
  /// Currently selected sort criteria.
  MovieSortCriteria _sortCriteria = MovieSortCriteria.nameAsc;

  /// Gets movies that the user has rated (combines both to watch and watched movies with ratings).
  Stream<List<Movie>> get _ratedMovies async* {
    await for (final toWatch in widget.favoritesService.toWatchMovies) {
      await for (final watched in widget.favoritesService.watchedMovies) {
        final allMovies = <Movie>[...toWatch, ...watched];
        final uniqueMovies = <int, Movie>{};

        for (final movie in allMovies) {
          uniqueMovies[movie.id] = movie;
        }

        // Filter to only movies with user ratings if using adapter
        if (widget.favoritesService is FavoritesServiceAdapter) {
          final adapter = widget.favoritesService as FavoritesServiceAdapter;
          final ratedMovies = <Movie>[];

          for (final movie in uniqueMovies.values) {
            final rating = await adapter.getPersonalRating(movie);
            if (rating != null && rating > 0) {
              ratedMovies.add(movie);
            }
          }

          yield ratedMovies;
        } else {
          yield uniqueMovies.values.toList();
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'My Movies',
      actions: [
        StreamBuilder<List<Movie>>(
          stream: _ratedMovies,
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

**📤 Share My Movies**

Share your **rated movies collection** with others through your POD.

Recipients will be able to:
- View your movie ratings and reviews  
- See which movies you've enjoyed
- Access through secure POD sharing

*Requires POD storage to be enabled*

                  ''',
                child: IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: (hasMovies && isPodEnabled)
                      ? () => _shareMyMovies(context, snapshot.data!)
                      : null,
                ),
              ),
            );
          },
        ),
      ],
      body: Column(
        children: [
          SortControls(
            selectedCriteria: _sortCriteria,
            onSortChanged: (criteria) {
              safeSetState(() {
                _sortCriteria = criteria;
              });
            },
          ),
          Expanded(
            child: StreamBuilder<List<Movie>>(
              stream: _ratedMovies,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final movies = sortMovies(snapshot.data!, _sortCriteria);

                if (movies.isEmpty) {
                  return Center(
                    child: Text(
                      'You haven\'t rated any movies yet',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    final movie = movies[index];
                    return FutureBuilder<double?>(
                      future: widget.favoritesService is FavoritesServiceAdapter
                          ? (widget.favoritesService as FavoritesServiceAdapter)
                              .getPersonalRating(movie)
                          : Future.value(null),
                      builder: (context, ratingSnapshot) {
                        final userRating = ratingSnapshot.data;

                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: movie.posterUrl,
                              width: 50,
                              height: 75,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
                          ),
                          title: Text(
                            movie.title,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '⭐ ${movie.voteAverage.toStringAsFixed(1)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (userRating != null)
                                Text(
                                  '🎯 My Rating: ${userRating.toStringAsFixed(1)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MovieDetailsScreen(
                                  movie: movie,
                                  favoritesService: widget.favoritesService,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Shares the user's rated movies using batch sharing UI.

  Future<void> _shareMyMovies(
    BuildContext context,
    List<Movie> movies,
  ) async {
    if (movies.isEmpty) {
      showInfoSnackBar('No movies to share');
      return;
    }

    // Store context references before async operations.
    final navigator = Navigator.of(context);
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
        'My Rated Movies',
        movies: movies,
        description: 'Movies I have rated and reviewed',
      );

      if (!mounted) return;

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
        if (!mounted) return;
      }

      // Navigate to the batch sharing UI.
      if (mounted) {
        await navigator.push<bool>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => MovieStarBatchSharingUi(
              listId: listId,
              listName: 'My Rated Movies',
              movies: movies,
              backgroundColor: theme.scaffoldBackgroundColor,
              onSharingComplete: () {
                // Handle completion callback.
              },
              child: widget,
            ),
          ),
        );
      }
    } catch (e) {
      showErrorSnackBar('Error sharing list: $e');
    }
  }

  // Creates a movie file if it doesn't exist (needed before sharing).

  Future<void> _createMovieFileIfNotExists(Movie movie) async {
    try {
      final movieFileName = 'movies/Movie-${movie.id}.ttl';

      // Check if the file already exists.
      try {
        if (!mounted) return;
        final existingContent = await readPod(movieFileName, context, widget);
        if (existingContent.isNotEmpty) {
          return;
        }
      } catch (e) {
        // File doesn't exist, we'll create it.
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
