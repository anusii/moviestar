/// Screen displaying detailed view of a custom movie list with all its movies.
///
// Time-stamp: <Monday 2025-08-18 10:00:00 +1000 Ashley Tang>
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
/// Authors: Ashley Tang.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:solidpod/solidpod.dart';

import 'package:moviestar/core/services/favorites/movie_list_service.dart';
import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/core/services/favorites/service_adapter.dart';
import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/services/user_profile_service.dart';
import 'package:moviestar/shared/widgets/custom_list_detail/list_header_widget.dart';
import 'package:moviestar/shared/widgets/custom_list_detail/list_movie_grid.dart';
import 'package:moviestar/utils/serializer.dart';
import 'package:moviestar/widgets/base_screen.dart';
import 'package:moviestar/widgets/moviestar_batch_sharing_ui.dart';

/// A screen that displays the detailed view of a custom movie list.

class CustomListDetailScreen extends ConsumerStatefulWidget {
  /// The custom list to display.

  final CustomList customList;

  /// Service for managing favorite movies and lists.

  final FavoritesService favoritesService;

  /// Creates a new [CustomListDetailScreen] widget.

  const CustomListDetailScreen({
    super.key,
    required this.customList,
    required this.favoritesService,
  });

  @override
  ConsumerState<CustomListDetailScreen> createState() =>
      _CustomListDetailScreenState();
}

// State class for the custom list detail screen.

class _CustomListDetailScreenState extends ConsumerState<CustomListDetailScreen>
    with ScreenStateMixin {
  // Current custom list (may be updated).

  late CustomList _currentList;

  // Map of movie ID to Movie object for movies in this list.

  final Map<int, Movie> _moviesMap = {};

  // Set of movie IDs that are currently being loaded.

  final Set<int> _loadingMovieIds = {};

  // Set of movie IDs that failed to load.

  final Set<int> _failedMovieIds = {};

  @override
  void initState() {
    super.initState();
    _currentList = widget.customList;
    _loadMovies();
  }

  // Gets content as movie with proper type routing.

  Future<Movie> _getContentAsMovieWithType(
    int contentId,
    String contentType,
  ) async {
    final cachedMovieService = ref.read(cachedMovieServiceProvider);
    final contentService = ref.read(contentServiceProvider);

    if (contentType == 'tv') {
      final tvShowContent = await contentService.getTVDetails(contentId);
      return Movie.fromContentItem(tvShowContent);
    } else {
      return await cachedMovieService.getMovieDetails(contentId);
    }
  }

  // Loads movies in this custom list from cache.

  Future<void> _loadMovies() async {
    // First try to get movies directly from POD if using POD storage.

    if (widget.favoritesService is FavoritesServiceAdapter &&
        (widget.favoritesService as FavoritesServiceAdapter)
            .isPodStorageEnabled) {
      try {
        final podMovies = await widget.favoritesService
            .getMoviesInCustomList(_currentList.id);

        if (podMovies.isNotEmpty) {
          if (mounted) {
            safeSetState(() {
              for (final movie in podMovies) {
                _moviesMap[movie.id] = movie;
                _loadingMovieIds.remove(movie.id);
                _failedMovieIds.remove(movie.id);
              }
            });
          }
          // If we got some movies from POD, still try to load any missing ones from API.

          final loadedIds = podMovies.map((m) => m.id).toSet();
          final remainingIds = _currentList.movieIds
              .where((id) => !loadedIds.contains(id))
              .toList();
          if (remainingIds.isNotEmpty) {
            await _loadMoviesFromAPI(remainingIds);
          }
          return;
        }
      } catch (e) {
        // Failed to load cached movies
      }
    }

    // Fallback to loading from API (original behavior).

    await _loadMoviesFromAPI(_currentList.movieIds);
  }

  // Loads specific movies from API.

  Future<void> _loadMoviesFromAPI(List<int> movieIds) async {
    for (int i = 0; i < movieIds.length; i++) {
      final movieId = movieIds[i];

      if (_moviesMap.containsKey(movieId) ||
          _loadingMovieIds.contains(movieId)) {
        continue; // Already loaded or loading.
      }

      safeSetState(() {
        _loadingMovieIds.add(movieId);
      });

      try {
        final contentType = _currentList.getContentTypeAt(
          _currentList.movieIds.indexOf(movieId),
        );
        final movie = await _getContentAsMovieWithType(movieId, contentType);

        if (mounted) {
          safeSetState(() {
            _moviesMap[movieId] = movie;
            _loadingMovieIds.remove(movieId);
            _failedMovieIds
                .remove(movieId); // Remove from failed if it was there.
          });
        }
      } catch (e) {
        if (mounted) {
          safeSetState(() {
            _loadingMovieIds.remove(movieId);
            _failedMovieIds.add(movieId);
          });
        }
      }
    }
  }

  // Shows options for the custom list (edit, share, delete).

  Future<void> _showListOptions() async {
    final hasMovies = _currentList.movieIds.isNotEmpty;
    final isPodEnabled = widget.favoritesService is FavoritesServiceAdapter &&
        (widget.favoritesService as FavoritesServiceAdapter)
            .isPodStorageEnabled;

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
              _showEditListDialog();
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
                    _shareCustomList();
                  }
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete List'),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation();
            },
          ),
        ],
      ),
    );
  }

  // Shows a dialog to edit the custom list.

  Future<void> _showEditListDialog() async {
    final TextEditingController nameController =
        TextEditingController(text: _currentList.name);
    final TextEditingController descriptionController =
        TextEditingController(text: _currentList.description ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'List Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final description = descriptionController.text.trim();
                final updatedList = _currentList.copyWith(
                  name: name,
                  description: description.isEmpty ? null : description,
                );
                await widget.favoritesService.updateCustomList(updatedList);
                setState(() {
                  _currentList = updatedList;
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  showSuccessSnackBar('Updated "$name" list');
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    nameController.dispose();
    descriptionController.dispose();
  }

  // Shows a confirmation dialog before deleting the list.

  Future<void> _showDeleteConfirmation() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: Text(
          'Are you sure you want to delete "${_currentList.name}"? This action cannot be undone.',
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
              await widget.favoritesService.deleteCustomList(_currentList.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog.
                Navigator.pop(context); // Go back to lists screen.
                showSuccessSnackBar('Deleted "${_currentList.name}" list');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Removes a movie from the custom list.

  Future<void> _removeMovieFromList(int movieId) async {
    final movie = _moviesMap[movieId];
    final movieTitle = movie?.title ?? 'Movie';

    await widget.favoritesService
        .removeMovieFromCustomList(_currentList.id, movieId);

    // Update the current list and remove from local map.
    final updatedList = _currentList.copyWith(
      movieIds: _currentList.movieIds.where((id) => id != movieId).toList(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _currentList = updatedList;
      _moviesMap.remove(movieId);
      _loadingMovieIds.remove(movieId);
      _failedMovieIds.remove(movieId);
    });

    if (mounted) {
      showSuccessSnackBar('Removed "$movieTitle" from list');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: _currentList.name,
      automaticallyImplyLeading: true,
      actions: [
        // Share button with tooltip
        MarkdownTooltip(
          message: '''

**📤 Share Custom List**

Share your **"${_currentList.name}"** list with others through your POD.

Recipients will be able to:
- View your custom list
- See all movies in the list
- Access through secure POD sharing

*Requires POD storage to be enabled*

          ''',
          child: IconButton(
            icon: const Icon(Icons.share),
            onPressed: _currentList.movieIds.isNotEmpty &&
                    widget.favoritesService is FavoritesServiceAdapter &&
                    (widget.favoritesService as FavoritesServiceAdapter)
                        .isPodStorageEnabled
                ? () => _shareCustomList()
                : null,
          ),
        ),
        // Add padding to move the button away from the right edge to avoid debug banner.
        Padding(
          padding: const EdgeInsets.only(right: 60),
          child: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showListOptions,
          ),
        ),
      ],
      body: Column(
        children: [
          // List info header.
          ListHeaderWidget(
            customList: _currentList,
            totalMovies: _currentList.movieIds.length,
            loadedMovies: _moviesMap.length,
            onOptionsPressed: _showListOptions,
          ),

          // Movies list.
          Expanded(
            child: _currentList.movieIds.isEmpty
                ? _buildEmptyState()
                : ListMovieGrid(
                    movieIds: _currentList.movieIds,
                    moviesMap: _moviesMap,
                    loadingMovieIds: _loadingMovieIds,
                    failedMovieIds: _failedMovieIds,
                    onRemoveMovie: _removeMovieFromList,
                    onRetryLoad: _retryLoadMovie,
                    onRefresh: _loadMovies,
                    favoritesService: widget.favoritesService,
                  ),
          ),
        ],
      ),
    );
  }

  /// Retry loading a specific movie.
  Future<void> _retryLoadMovie(int movieId) async {
    setState(() {
      _failedMovieIds.remove(movieId);
      _loadingMovieIds.add(movieId);
    });

    // Load the specific movie
    try {
      final movie = await _getContentAsMovieWithType(movieId, 'movie');

      if (mounted) {
        setState(() {
          _moviesMap[movieId] = movie;
          _loadingMovieIds.remove(movieId);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingMovieIds.remove(movieId);
          _failedMovieIds.add(movieId);
        });
      }
    }
  }

  // Builds the empty state when there are no movies in the list.

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Movies Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add movies to this list by using the\n"Add to Custom List" button on movie details!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // Shows a loading dialog during sharing process.
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

  // Shares the custom list and all movies using batch sharing UI.

  Future<void> _shareCustomList() async {
    if (_currentList.movieIds.isEmpty) {
      showErrorSnackBar('No movies to share');
      return;
    }

    // Show loading dialog
    _showSharingDialog();

    // Get all loaded movies from the current list.

    final moviesToShare = <Movie>[];
    for (final movieId in _currentList.movieIds) {
      final movie = _moviesMap[movieId];
      if (movie != null) {
        moviesToShare.add(movie);
      }
    }

    if (moviesToShare.isEmpty) {
      showErrorSnackBar('Movies are still loading. Please wait.');
      return;
    }

    // Store context references before async operations.

    final theme = Theme.of(context);

    try {
      // Create MovieList service to create the list file first.

      final userProfileService = UserProfileService(context, widget);
      final movieListService = MovieListService(
        context,
        widget,
        userProfileService,
      );

      // Create the MovieList TTL file.

      final listId = await movieListService.createMovieList(
        _currentList.name,
        movies: moviesToShare,
        description: _currentList.description ?? 'Custom movie list',
      );

      if (!mounted) return;

      if (listId == null) {
        if (mounted) {
          showErrorSnackBar('Failed to create movie list');
        }
        return;
      }

      // Ensure all individual movie files exist before sharing.

      for (final movie in moviesToShare) {
        try {
          await _createMovieFileIfNotExists(movie);
        } catch (e) {
          // Continue with other movies - the batch UI will handle individual failures.
        }
        if (!mounted) return;
      }

      // Navigate to the batch sharing UI.

      if (mounted) {
        await safeNavigateTo(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => MovieStarBatchSharingUi(
              listId: listId,
              listName: _currentList.name,
              movies: moviesToShare,
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
        showErrorSnackBar('Error sharing list: $e');
      }
    } finally {
      // Dismiss loading dialog
      if (mounted) {
        Navigator.of(context).pop();
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
