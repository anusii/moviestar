/// Screen displaying detailed information about a selected movie.
///
// Time-stamp: <Friday 2025-07-25 11:58:16 +1000 Graham Williams>
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

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/core/services/favorites/service_adapter.dart';
import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/shared/widgets/movie_details/action_buttons.dart';
import 'package:moviestar/shared/widgets/movie_details/add_to_lists_dialog.dart';
import 'package:moviestar/shared/widgets/movie_details/info_section.dart';
import 'package:moviestar/shared/widgets/movie_details/poster_section.dart';
import 'package:moviestar/widgets/movie_sharing_ui.dart';

/// A screen that displays detailed information about a selected movie.

class MovieDetailsScreen extends StatefulWidget {
  /// The movie to display details for.

  final Movie movie;

  /// Service for managing favorite movies.

  final FavoritesService favoritesService;

  /// Optional shared movie data (rating, comments) for when viewing shared movies.

  final Map<String, dynamic>? sharedMovieData;

  /// Content type to distinguish between movies and TV shows.
  /// Defaults to movie for backward compatibility.

  final ContentType contentType;

  /// Creates a new [MovieDetailsScreen] widget.

  const MovieDetailsScreen({
    super.key,
    required this.movie,
    required this.favoritesService,
    this.sharedMovieData,
    this.contentType = ContentType.movie,
  });

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

/// State class for the movie details screen.

class _MovieDetailsScreenState extends State<MovieDetailsScreen>
    with ScreenStateMixin {
  /// Indicates whether the movie is in the to-watch list.

  bool _isInToWatch = false;

  /// Indicates whether the movie is in the watched list.

  bool _isInWatched = false;

  /// Indicates whether the movie has a shareable file (rating or comment).

  bool _hasMovieFile = false;

  /// List of all custom lists.

  List<CustomList> _customLists = [];

  // Indicates whether this is a shared movie (read-only view).

  bool get _isSharedMovie => widget.sharedMovieData != null;

  @override
  void initState() {
    super.initState();
    _checkListStatus();
    _checkMovieFile();
    _loadCustomLists();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Checks if the current movie is in either list.

  Future<void> _checkListStatus() async {
    // Don't check list status for shared movies.

    if (_isSharedMovie) {
      setState(() {
        _isInToWatch = false;
        _isInWatched = false;
      });
      return;
    }

    final isInToWatch = await widget.favoritesService.isInToWatch(widget.movie);
    final isInWatched = await widget.favoritesService.isInWatched(widget.movie);
    setState(() {
      _isInToWatch = isInToWatch;
      _isInWatched = isInWatched;
    });
  }

  /// Toggles the to-watch status of the current movie.

  Future<void> _toggleToWatch() async {
    // Store original state for potential rollback.

    final originalState = _isInToWatch;

    // Update UI immediately for instant feedback.

    setState(() {
      _isInToWatch = !_isInToWatch;
    });

    try {
      if (originalState) {
        await widget.favoritesService.removeFromToWatch(widget.movie);
      } else {
        await widget.favoritesService.addToWatch(
          widget.movie,
          contentType: (widget.movie.contentType ?? widget.contentType) ==
                  ContentType.tvShow
              ? 'tv'
              : 'movie',
        );
      }
    } catch (e) {
      // Rollback UI state on error.

      setState(() {
        _isInToWatch = originalState;
      });
    }
  }

  /// Toggles the watched status of the current movie.

  Future<void> _toggleWatched() async {
    // Store original state for potential rollback.

    final originalState = _isInWatched;

    // Update UI immediately for instant feedback.

    setState(() {
      _isInWatched = !_isInWatched;
    });

    try {
      if (originalState) {
        await widget.favoritesService.removeFromWatched(widget.movie);
      } else {
        await widget.favoritesService.addToWatched(
          widget.movie,
          contentType: (widget.movie.contentType ?? widget.contentType) ==
                  ContentType.tvShow
              ? 'tv'
              : 'movie',
        );
      }
    } catch (e) {
      // Rollback UI state on error.

      setState(() {
        _isInWatched = originalState;
      });
    }
  }

  /// Checks if the current movie has a file (user has rated or commented).

  Future<void> _checkMovieFile() async {
    // Don't check movie file for shared movies.

    if (_isSharedMovie) {
      setState(() {
        _hasMovieFile = false;
      });
      return;
    }

    final hasFile = await widget.favoritesService.hasMovieFile(widget.movie);
    setState(() {
      _hasMovieFile = hasFile;
    });
  }

  // Shares the movie file using the common sharing UI.
  Future<void> _shareMovie() async {
    try {
      // Check if user has POD storage enabled and is using the adapter.
      if (widget.favoritesService is! FavoritesServiceAdapter) {
        _showErrorDialog('POD storage is required for sharing');
        return;
      }

      final adapter = widget.favoritesService as FavoritesServiceAdapter;

      // Check if POD storage is enabled.
      if (!adapter.isPodStorageEnabled) {
        _showErrorDialog('POD storage must be enabled to share movies');
        return;
      }

      // Ensure the movie file exists before sharing.
      final hasFile = await widget.favoritesService.hasMovieFile(widget.movie);
      if (!hasFile) {
        // Create the movie file by setting an empty comment to enable sharing
        await widget.favoritesService.setMovieComments(widget.movie, '');
        // Then remove the empty comment to keep the file clean
        await widget.favoritesService.removeMovieComments(widget.movie);
      }

      // Movie file path logic is handled by MovieSharingUI

      // Use our custom movie sharing UI
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MovieSharingUI(
            movie: widget.movie,
            onSharingComplete: () {
              Navigator.of(context).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('"${widget.movie.title}" shared successfully'),
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                  ),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      _showErrorDialog('Error sharing movie: $e');
    }
  }

  // Shows an error dialog with the given message.

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        title: Text(
          'Cannot Share Movie',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Loads all custom lists.

  Future<void> _loadCustomLists() async {
    if (_isSharedMovie) {
      if (mounted) {
        setState(() {
          _customLists = [];
        });
      }
      return;
    }

    final lists = await widget.favoritesService.getCustomLists();
    if (mounted) {
      setState(() {
        _customLists = lists;
      });
    }
  }

  /// Shows a dialog to add the movie to custom lists.

  Future<void> _showAddToCustomListsDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AddToListsDialog(
        movie: widget.movie,
        favoritesService: widget.favoritesService,
        customLists: _customLists,
        onListsUpdated: _loadCustomLists,
        contentType: widget.contentType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          MoviePosterSection(movie: widget.movie),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.movie.title,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      MovieActionButtons(
                        isInToWatch: _isInToWatch,
                        isInWatched: _isInWatched,
                        isSharedMovie: _isSharedMovie,
                        hasMovieFile: _hasMovieFile,
                        favoritesService: widget.favoritesService,
                        onToggleToWatch: _toggleToWatch,
                        onToggleWatched: _toggleWatched,
                        onShowAddToLists: _showAddToCustomListsDialog,
                        onShareMovie: _shareMovie,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Rest of movie info (without title)
                  MovieInfoSectionWithoutTitle(
                    movie: widget.movie,
                    favoritesService: widget.favoritesService,
                    isSharedMovie: _isSharedMovie,
                    sharedMovieData: widget.sharedMovieData,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
