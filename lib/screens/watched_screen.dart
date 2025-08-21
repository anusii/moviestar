/// Screen for managing the user's list of watched movies.
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
/// Authors: Kevin Wang

library;

import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:solidpod/solidpod.dart';

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/services/favorites_service_adapter.dart';
import 'package:moviestar/services/movie_list_service.dart';
import 'package:moviestar/services/user_profile_service.dart';
import 'package:moviestar/utils/movie_sort_util.dart';
import 'package:moviestar/utils/turtle_serializer.dart';
import 'package:moviestar/widgets/moviestar_batch_sharing_ui.dart';
import 'package:moviestar/widgets/sort_controls.dart';
import 'package:moviestar/screens/movie_details_screen.dart';

/// A screen that displays the user's list of watched movies.

class WatchedScreen extends StatefulWidget {
  /// Service for managing favorite movies.

  final FavoritesService favoritesService;

  /// Creates a new [WatchedScreen] widget.

  const WatchedScreen({super.key, required this.favoritesService});

  @override
  State<WatchedScreen> createState() => _WatchedScreenState();
}

/// State class for the watched screen.

class _WatchedScreenState extends State<WatchedScreen> {
  /// Currently selected sort criteria.
  MovieSortCriteria _sortCriteria = MovieSortCriteria.nameAsc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          StreamBuilder<List<Movie>>(
            stream: widget.favoritesService.watchedMovies,
            builder: (context, snapshot) {
              final hasMovies = snapshot.hasData && snapshot.data!.isNotEmpty;
              final isPodEnabled =
                  widget.favoritesService is FavoritesServiceAdapter &&
                      (widget.favoritesService as FavoritesServiceAdapter)
                          .isPodStorageEnabled;

              return Padding(
                padding: const EdgeInsets.only(
                  right: 60.0,
                ), // Add space to avoid debug banner
                child: MarkdownTooltip(
                  message: '''

**📤 Share Watched List**

Share your **watched movies list** with others through your POD.

Recipients will be able to:
- View your list of watched movies
- See your ratings and reviews
- Access through secure POD sharing

*Requires POD storage to be enabled*

                  ''',
                  child: IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: (hasMovies && isPodEnabled)
                        ? () => _shareWatchedList(context, snapshot.data!)
                        : null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SortControls(
            selectedCriteria: _sortCriteria,
            onSortChanged: (criteria) {
              setState(() {
                _sortCriteria = criteria;
              });
            },
          ),
          Expanded(
            child: StreamBuilder<List<Movie>>(
              stream: widget.favoritesService.watchedMovies,
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
                      'Your watched list is empty',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    final movie = movies[index];
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
                      subtitle: Text(
                        '⭐ ${movie.voteAverage.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          widget.favoritesService.removeFromWatched(movie);
                        },
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
            ),
          ),
        ],
      ),
    );
  }

  // Shares the watched movies list and all individual movies using batch sharing UI.

  Future<void> _shareWatchedList(
    BuildContext context,
    List<Movie> movies,
  ) async {
    if (movies.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No movies to share')));
      return;
    }

    // Store context references before async operations.
    final scaffoldMessenger = ScaffoldMessenger.of(context);
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
        'Watched Movies',
        movies: movies,
        description: 'Movies you have watched',
      );

      if (!mounted) return;

      if (listId == null) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Failed to create movie list')),
          );
        }
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
              listName: 'Watched Movies',
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
      if (mounted) {
        scaffoldMessenger
            .showSnackBar(SnackBar(content: Text('Error sharing list: $e')));
      }
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
