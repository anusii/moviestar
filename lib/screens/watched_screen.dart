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

import '../models/movie.dart';
import '../services/favorites_service.dart';
import '../services/favorites_service_adapter.dart';
import '../services/movie_list_service.dart';
import '../services/user_profile_service.dart';
import '../utils/movie_sort_util.dart';
import '../utils/turtle_serializer.dart';
import '../widgets/sort_controls.dart';
import 'movie_details_screen.dart';

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
        title: Text('Watched',
            style: Theme.of(context).appBarTheme.titleTextStyle),
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
                    right: 60.0), // Add space to avoid debug banner
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
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.red),
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

  // Shares the watched movies list and all individual movies.

  Future<void> _shareWatchedList(
      BuildContext context, List<Movie> movies) async {
    if (movies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No movies to share')),
      );
      return;
    }

    try {
      // Create MovieList service to create the list file first
      final userProfileService = UserProfileService(context, widget);
      final movieListService =
          MovieListService(context, widget, userProfileService);

      // Create the MovieList TTL file
      final listId = await movieListService.createMovieList(
        'Watched Movies',
        movies: movies,
        description: 'Movies you have watched',
      );

      if (listId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create movie list')),
          );
        }
        return;
      }

      if (!mounted) return;

      // Share the movie list file first
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (navContext) => Theme(
            data: Theme.of(context),
            child: Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                title: const Text('Share "Watched Movies"'),
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
              ),
              body: GrantPermissionUi(
                fileName: 'user_lists/MovieList-$listId.ttl',
                title: '',
                accessModeList: const ['read'],
                recipientList: const ['indi'],
                showAppBar: false,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                child: widget,
                onPermissionGranted: () async {
                  // After movie list sharing, chain individual movie sharing
                  if (mounted) {
                    Navigator.of(navContext).pop(true);

                    // Show loading and start individual movie sharing
                    await _shareIndividualMoviesSequentially(movies);
                  }
                },
                onNavigateBack: () {
                  // Handle back navigation
                  if (mounted) {
                    Navigator.of(navContext).pop(false);
                  }
                },
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error sharing watched list: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing list: $e')),
        );
      }
    }
  }

  // Shares individual movie files sequentially using GrantPermissionUi.

  Future<void> _shareIndividualMoviesSequentially(List<Movie> movies) async {
    try {
      if (movies.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Movie list shared successfully!')),
          );
        }
        return;
      }

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                    'Preparing to share ${movies.length} individual movies with ratings and comments...'),
              ],
            ),
          ),
        );
      }

      // Wait a moment for the dialog to show
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      // Share each movie sequentially using GrantPermissionUi
      await _shareMoviesOneByOne(movies, 0);
    } catch (e) {
      debugPrint('❌ Error in sequential movie sharing: $e');
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing individual movies: $e')),
        );
      }
    }
  }

  // Recursively shares movies one by one using GrantPermissionUi.

  Future<void> _shareMoviesOneByOne(List<Movie> movies, int index) async {
    if (index >= movies.length) {
      // All movies shared, show completion message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully shared movie list and all ${movies.length} individual movies!'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      }
      return;
    }

    final movie = movies[index];
    final adapter = widget.favoritesService as FavoritesServiceAdapter;
    final fullPath = adapter.getMovieFilePath(movie);
    // Remove the 'moviestar/data/' prefix like the individual movie screen does
    final movieFilePath = fullPath?.replaceFirst('moviestar/data/', '') ??
        'movies/Movie-${movie.id}.ttl';

    if (fullPath == null) {
      // Skip this movie and continue with the next
      await _shareMoviesOneByOne(movies, index + 1);
      return;
    }

    // Ensure the individual movie file exists before sharing
    try {
      await _createMovieFileIfNotExists(movie);
    } catch (e) {
      debugPrint('❌ Failed to create movie file for ${movie.title}: $e');
      // Skip this movie and continue with the next
      await _shareMoviesOneByOne(movies, index + 1);
      return;
    }

    if (!mounted) return;

    // Navigate to GrantPermissionUi for this individual movie
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (navContext) => Theme(
          data: Theme.of(context),
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              title: Text(
                  'Share "${movie.title}" (${index + 1}/${movies.length})'),
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
            ),
            body: GrantPermissionUi(
              fileName: movieFilePath,
              title: '',
              accessModeList: const ['read'], // Read-only for individual movies
              recipientList: const ['indi'],
              showAppBar: false,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: widget,
              onPermissionGranted: () async {
                // Movie shared successfully, continue with next movie
                if (mounted) {
                  Navigator.of(navContext).pop(true);
                  await _shareMoviesOneByOne(movies, index + 1);
                }
              },
              onNavigateBack: () {
                // User cancelled, ask if they want to continue or stop
                if (mounted) {
                  Navigator.of(navContext).pop(false);
                  _showContinueSharingDialog(movies, index);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  // Shows dialog asking user if they want to continue sharing remaining movies.

  void _showContinueSharingDialog(List<Movie> movies, int currentIndex) {
    final remainingCount = movies.length - currentIndex;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Continue Sharing?'),
        content: Text(
            'You have $remainingCount movies left to share. Do you want to continue?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Show completion message for partial sharing
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Shared movie list and $currentIndex individual movies.'),
                ),
              );
            },
            child: const Text('Stop'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _shareMoviesOneByOne(movies, currentIndex);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // Creates a movie file if it doesn't exist (needed before sharing).

  Future<void> _createMovieFileIfNotExists(Movie movie) async {
    try {
      final movieFileName = 'movies/Movie-${movie.id}.ttl';

      // Check if the file already exists
      try {
        final existingContent = await readPod(movieFileName, context, widget);
        if (existingContent.isNotEmpty) {
          debugPrint('✅ Movie file already exists for: ${movie.title}');
          return;
        }
      } catch (e) {
        // File doesn't exist, we'll create it
        debugPrint(
            '📝 Movie file doesn\'t exist, creating for: ${movie.title}');
      }

      // Get current rating and comments from favorites service
      final adapter = widget.favoritesService as FavoritesServiceAdapter;
      final currentRating = await adapter.getPersonalRating(movie);
      final currentComments = await adapter.getMovieComments(movie);

      // Create the movie TTL content with any existing user data
      final ttlContent = TurtleSerializer.movieWithUserDataToTurtleOntology(
        movie,
        currentRating,
        currentComments,
      );

      // Write the movie file to POD
      final result = await writePod(
        movieFileName,
        ttlContent,
        context,
        widget,
        encrypted: false,
      );

      if (result == SolidFunctionCallStatus.success) {
        debugPrint('✅ Created individual movie file for: ${movie.title}');
      } else {
        throw Exception('Failed to write movie file to POD');
      }
    } catch (e) {
      debugPrint('❌ Error creating movie file for ${movie.title}: $e');
      rethrow;
    }
  }
}
