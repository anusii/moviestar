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

import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/core/services/favorites/service_adapter.dart';
import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/screens/custom_list_detail/dialog_builders.dart';
import 'package:moviestar/screens/custom_list_detail/movie_loader.dart';
import 'package:moviestar/shared/widgets/custom_list_detail/list_header_widget.dart';
import 'package:moviestar/shared/widgets/custom_list_detail/list_movie_grid.dart';
import 'package:moviestar/shared/widgets/lists/list_sharing_handler.dart';
import 'package:moviestar/widgets/base_screen.dart';

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
        // Failed to load cached movies.
      }
    }

    // Fallback to loading from API (original behavior).

    await _loadMoviesFromAPI(_currentList.movieIds);
  }

  // Loads specific movies from API.

  Future<void> _loadMoviesFromAPI(List<int> movieIds) async {
    final filtered = movieIds
        .where(
          (id) => !_moviesMap.containsKey(id) && !_loadingMovieIds.contains(id),
        )
        .toList();

    await MovieLoader.loadMoviesFromAPI(
      ref,
      filtered,
      (movieId, movie) {
        if (mounted) {
          safeSetState(() {
            _moviesMap[movieId] = movie;
            _loadingMovieIds.remove(movieId);
            _failedMovieIds.remove(movieId);
          });
        }
      },
      (movieId, error) {
        if (mounted) {
          safeSetState(() {
            _loadingMovieIds.remove(movieId);
            _failedMovieIds.add(movieId);
          });
        }
      },
    );
  }

  // Shows options for the custom list (edit, share, delete).

  Future<void> _showListOptions() async {
    await CustomListDialogBuilders.showListOptions(
      context,
      _currentList,
      onEdit: _showEditListDialog,
      onShare: _shareCustomList,
      onDelete: _showDeleteConfirmation,
    );
  }

  // Shows a dialog to edit the custom list.

  Future<void> _showEditListDialog() async {
    await CustomListDialogBuilders.showEditListDialog(
      context,
      _currentList,
      widget.favoritesService,
      () {
        _loadMovies();
      },
    );
  }

  // Shows a confirmation dialog before deleting the list.

  Future<void> _showDeleteConfirmation() async {
    await CustomListDialogBuilders.showDeleteConfirmation(
      context,
      _currentList,
      widget.favoritesService,
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
        // Share button with tooltip.

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
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: _showListOptions,
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // List info header.

            ListHeaderWidget(
              customList: _currentList,
              totalMovies: _currentList.movieIds.length,
              loadedMovies: _moviesMap.length,
              showTitle: false,
              showOptions: false,
            ),

            const SizedBox(height: 8),

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
      ),
    );
  }

  /// Retry loading a specific movie.

  Future<void> _retryLoadMovie(int movieId) async {
    await MovieLoader.retryLoadMovie(
      ref,
      movieId,
      _moviesMap,
      {},
      (id, movie) {
        if (mounted) {
          setState(() {
            _moviesMap[id] = movie;
            _loadingMovieIds.remove(id);
            _failedMovieIds.remove(id);
          });
        }
      },
      (id, error) {
        if (mounted) {
          setState(() {
            _loadingMovieIds.remove(id);
            _failedMovieIds.add(id);
          });
        }
      },
    );
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

  // Shares the custom list and all movies using batch sharing UI.

  Future<void> _shareCustomList() async {
    final sharingHandler = ListSharingHandler(
      context: context,
      widget: widget,
      ref: ref,
      favoritesService: widget.favoritesService,
      screenState: this,
    );

    await sharingHandler.shareCustomList(_currentList);
  }
}
