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
/// Authors: Kevin Wang

library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:solidpod/solidpod.dart';

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/services/favorites_service_adapter.dart';
import 'package:moviestar/utils/date_format_util.dart';

/// A screen that displays detailed information about a selected movie.

class MovieDetailsScreen extends StatefulWidget {
  /// The movie to display details for.

  final Movie movie;

  /// Service for managing favorite movies.

  final FavoritesService favoritesService;

  /// Optional shared movie data (rating, comments) for when viewing shared movies.

  final Map<String, dynamic>? sharedMovieData;

  /// Creates a new [MovieDetailsScreen] widget.

  const MovieDetailsScreen({
    super.key,
    required this.movie,
    required this.favoritesService,
    this.sharedMovieData,
  });

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

/// State class for the movie details screen.

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  /// Indicates whether the movie is in the to-watch list.

  bool _isInToWatch = false;

  /// Indicates whether the movie is in the watched list.

  bool _isInWatched = false;

  /// Personal rating for the movie.

  double? _personalRating;

  /// Indicates whether the personal rating is being loaded.

  bool _isLoadingRating = true;

  /// Personal comments for the movie.

  String? _personalComments;

  /// Controller for the comments text field.

  final TextEditingController _commentsController = TextEditingController();

  /// Indicates whether the comments are being loaded.

  bool _isLoadingComments = true;

  /// Indicates whether comments have been modified but not saved.

  bool _commentsModified = false;

  /// Indicates whether rating was just saved (shows temporary banner).

  bool _ratingSaved = false;

  /// Indicates whether comments were just saved (shows temporary banner).

  bool _commentsSaved = false;

  /// Timer for hiding the rating saved banner.

  Timer? _ratingSavedTimer;

  /// Timer for hiding the comments saved banner.

  Timer? _commentsSavedTimer;

  /// Indicates whether the movie has a shareable file (rating or comment).

  bool _hasMovieFile = false;

  // Indicates whether this is a shared movie (read-only view).

  bool get _isSharedMovie => widget.sharedMovieData != null;

  // Gets the appropriate text for who shared the movie.

  String _getSharedByText() {
    if (!_isSharedMovie) return 'Unknown';

    final sharedBy = widget.sharedMovieData!['sharedBy'] as String?;
    final sharedByWebId = widget.sharedMovieData!['sharedByWebId'] as String?;

    // Prefer the formatted name if available
    if (sharedBy != null && sharedBy.isNotEmpty && sharedBy != 'Unknown') {
      return sharedBy;
    }

    // Fall back to WebID if formatted name is not available
    if (sharedByWebId != null && sharedByWebId.isNotEmpty) {
      return sharedByWebId;
    }

    // Final fallback
    return 'Unknown';
  }

  @override
  void initState() {
    super.initState();
    _checkListStatus();
    _loadPersonalRating();
    _loadPersonalComments();
    _checkMovieFile();
  }

  @override
  void dispose() {
    _commentsController.dispose();
    _ratingSavedTimer?.cancel();
    _commentsSavedTimer?.cancel();
    super.dispose();
  }

  /// Checks if the current movie is in either list.

  Future<void> _checkListStatus() async {
    // Don't check list status for shared movies
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
    if (_isInToWatch) {
      await widget.favoritesService.removeFromToWatch(widget.movie);
    } else {
      await widget.favoritesService.addToWatch(widget.movie);
    }
    setState(() {
      _isInToWatch = !_isInToWatch;
    });
  }

  /// Toggles the watched status of the current movie.

  Future<void> _toggleWatched() async {
    if (_isInWatched) {
      await widget.favoritesService.removeFromWatched(widget.movie);
    } else {
      await widget.favoritesService.addToWatched(widget.movie);
    }
    setState(() {
      _isInWatched = !_isInWatched;
    });
  }

  Future<void> _loadPersonalRating() async {
    // If this is a shared movie, use the shared rating data.

    if (widget.sharedMovieData != null) {
      final sharedRating = widget.sharedMovieData!['rating'] as double?;
      setState(() {
        _personalRating = sharedRating;
        _isLoadingRating = false;
      });
      return;
    }

    // Otherwise, load from user's own POD data.

    final rating = await widget.favoritesService.getPersonalRating(
      widget.movie,
    );
    setState(() {
      _personalRating = rating;
      _isLoadingRating = false;
    });
  }

  Future<void> _updateRating(double? rating) async {
    // Don't allow rating updates for shared movies.

    if (_isSharedMovie) {
      return;
    }

    if (rating == null) {
      await widget.favoritesService.removePersonalRating(widget.movie);
    } else {
      await widget.favoritesService.setPersonalRating(widget.movie, rating);

      // Auto-add to watched is now handled in PodFavoritesService._createOrUpdateMovieFile()
    }
    setState(() {
      _personalRating = rating;
      // Update watched status - this will be updated by the stream from the service.

      _ratingSaved = true;
    });

    // Refresh the list status to ensure UI is in sync.

    await _checkListStatus();

    // Check movie file status to update share button visibility.

    await _checkMovieFile();

    // Hide the saved banner after 2 seconds.

    _ratingSavedTimer?.cancel();
    _ratingSavedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _ratingSaved = false;
        });
      }
    });
  }

  Future<void> _loadPersonalComments() async {
    // If this is a shared movie, use the shared comments data.

    if (widget.sharedMovieData != null) {
      final sharedComments = widget.sharedMovieData!['comments'] as String?;
      setState(() {
        _personalComments = sharedComments;
        _commentsController.text = sharedComments ?? '';
        _isLoadingComments = false;
      });
      return;
    }

    // Otherwise, load from user's own POD data.

    final comments = await widget.favoritesService.getMovieComments(
      widget.movie,
    );
    setState(() {
      _personalComments = comments;
      _commentsController.text = comments ?? '';
      _isLoadingComments = false;
    });
  }

  Future<void> _updateComments(String? comments) async {
    // Don't allow comment updates for shared movies.

    if (_isSharedMovie) {
      return;
    }

    if (comments == null || comments.trim().isEmpty) {
      await widget.favoritesService.removeMovieComments(widget.movie);
    } else {
      await widget.favoritesService.setMovieComments(widget.movie, comments);
    }
    setState(() {
      _personalComments = comments;
      // Reset modified flag after saving.

      _commentsModified = false;
    });

    // Check movie file status to update share button visibility.

    await _checkMovieFile();
  }

  /// Saves the current comments without automatic triggers.

  Future<void> _saveComments() async {
    final currentText = _commentsController.text.trim();
    await _updateComments(currentText.isEmpty ? null : currentText);

    setState(() {
      _commentsSaved = true;
    });

    // Check movie file status to update share button visibility.

    await _checkMovieFile();

    // Hide the saved banner after 2 seconds.

    _commentsSavedTimer?.cancel();
    _commentsSavedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _commentsSaved = false;
        });
      }
    });
  }

  /// Clears the current comments and shows success banner.

  Future<void> _clearComments() async {
    _commentsController.clear();
    await _updateComments(null);

    setState(() {
      _commentsSaved = true;
    });

    // Check movie file status to update share button visibility.

    await _checkMovieFile();

    // Hide the saved banner after 2 seconds.

    _commentsSavedTimer?.cancel();
    _commentsSavedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _commentsSaved = false;
        });
      }
    });
  }

  /// Checks if the current movie has a file (user has rated or commented).

  Future<void> _checkMovieFile() async {
    // Don't check movie file for shared movies
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

  // Shares the movie file using GrantPermissionUi.

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

      // Check if the movie file exists (user has rated or commented).

      final hasFile = await widget.favoritesService.hasMovieFile(widget.movie);
      if (!hasFile) {
        _showErrorDialog(
          'No movie file to share. Please rate or comment on this movie first.',
        );
        return;
      }

      // Get the movie file path using the service method and make it relative.

      final fullPath = adapter.getMovieFilePath(widget.movie);
      final movieFilePath = fullPath?.replaceFirst('moviestar/data/', '') ??
          'movies/Movie-${widget.movie.id}.ttl';

      // Navigate directly to GrantPermissionUi with improved theming and pre-selected options.

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Theme(
            data: Theme.of(context),
            child: GrantPermissionUi(
              fileName: movieFilePath,
              title: 'Share "${widget.movie.title}"',
              accessModeList: const ['read'],
              recipientList: const ['indi'],
              showAppBar: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: widget,
            ),
          ),
        ),
      );

      // Movie sharing is now tracked through POD permission logs automatically.
      // No need for manual recording.
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
          style:
              TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
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
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: widget.movie.backdropUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isInToWatch
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: _isInToWatch
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            onPressed: _toggleToWatch,
                            tooltip: _isInToWatch
                                ? 'Remove from To Watch'
                                : 'Add to To Watch',
                          ),
                          IconButton(
                            icon: Icon(
                              _isInWatched
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              color: _isInWatched
                                  ? Theme.of(context).colorScheme.tertiary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            onPressed: _toggleWatched,
                            tooltip: _isInWatched
                                ? 'Remove from Watched'
                                : 'Add to Watched',
                          ),
                          if (_hasMovieFile &&
                              widget.favoritesService
                                  is FavoritesServiceAdapter &&
                              (widget.favoritesService
                                      as FavoritesServiceAdapter)
                                  .isPodStorageEnabled)
                            MarkdownTooltip(
                              message: '''

**Share this movie and my review**

Share your rating and comments for this movie with friends via their WebID.
Your shared movies will appear in their "Shared with Me" tab.

                              ''',
                              child: IconButton(
                                icon: Icon(Icons.share,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                                onPressed: _shareMovie,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: _isSharedMovie && _personalRating != null
                            ? Theme.of(context).colorScheme.primary
                            : Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isSharedMovie && _personalRating != null
                            ? _personalRating!.toStringAsFixed(1)
                            : widget.movie.voteAverage.toStringAsFixed(1),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                      if (_isSharedMovie && _personalRating != null)
                        Text(
                          ' (shared)',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormatUtil.formatShort(widget.movie.releaseDate),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Shared Movie Indicator.

                  if (_isSharedMovie)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.share,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'This movie was shared by ${_getSharedByText()}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Personal Rating Section,
                  Row(
                    children: [
                      Text(
                        _isSharedMovie ? 'Shared Rating' : 'Your Rating',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_ratingSaved)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.tertiary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'SAVED',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onTertiary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _isLoadingRating
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          children: [
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  // Track colors.

                                  activeTrackColor: _isSharedMovie
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.amber,
                                  inactiveTrackColor:
                                      Theme.of(context).colorScheme.outline,
                                  disabledActiveTrackColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.7),
                                  disabledInactiveTrackColor:
                                      Theme.of(context).colorScheme.outline,

                                  // Thumb colors.

                                  thumbColor: _isSharedMovie
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.amber,
                                  disabledThumbColor:
                                      Theme.of(context).colorScheme.primary,

                                  // Track height.

                                  trackHeight: 4.0,

                                  // Thumb size.

                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 8.0),

                                  // Overlay (when pressed).

                                  overlayColor: (_isSharedMovie
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.amber)
                                      .withValues(alpha: 0.2),

                                  // Value indicator (tooltip).

                                  valueIndicatorColor: _isSharedMovie
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.amber,
                                  valueIndicatorTextStyle: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: Slider(
                                  value: _personalRating ?? 0,
                                  min: 0,
                                  max: 10,
                                  divisions: 100,
                                  label: _personalRating?.toStringAsFixed(1) ??
                                      '0.0',
                                  onChanged: _isSharedMovie
                                      ? null
                                      : (value) => _updateRating(value),
                                ),
                              ),
                            ),
                            if (!_isSharedMovie)
                              IconButton(
                                icon: Icon(Icons.clear,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                                onPressed: _personalRating == null
                                    ? null
                                    : () => _updateRating(null),
                                tooltip: 'Clear rating',
                              ),
                          ],
                        ),
                  Text(
                    _personalRating == null
                        ? (_isSharedMovie
                            ? 'No rating shared'
                            : 'No rating yet')
                        : (_isSharedMovie
                            ? 'Shared rating: ${_personalRating!.toStringAsFixed(1)}/10'
                            : 'Your rating: ${_personalRating!.toStringAsFixed(1)}/10'),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  // Personal Comments Section
                  Row(
                    children: [
                      Text(
                        _isSharedMovie ? 'Shared Comments' : 'My Comments',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_commentsModified)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'UNSAVED',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (_commentsSaved)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.tertiary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'SAVED',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onTertiary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _isLoadingComments
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _commentsController,
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                              maxLines: 4,
                              readOnly: _isSharedMovie,
                              decoration: InputDecoration(
                                hintText: _isSharedMovie
                                    ? 'No comments shared...'
                                    : 'Add your thoughts about this movie...',
                                hintStyle: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                                filled: true,
                                fillColor: _isSharedMovie
                                    ? Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHigh
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainer,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: _isSharedMovie
                                  ? null
                                  : (value) {
                                      // Mark as modified when user types.

                                      setState(() {
                                        _commentsModified = true;
                                        _commentsSaved = false;
                                      });
                                      // Cancel the saved timer since user is editing again.

                                      _commentsSavedTimer?.cancel();
                                    },
                              onSubmitted: _isSharedMovie
                                  ? null
                                  : (value) {
                                      // Save when user presses Enter (if modified).

                                      if (_commentsModified) {
                                        _saveComments();
                                      }
                                    },
                            ),
                            const SizedBox(height: 8),
                            if (!_isSharedMovie)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (_commentsModified)
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.save, size: 18),
                                      label: const Text('Save Comments'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                      onPressed: _saveComments,
                                    ),
                                  if (_commentsModified &&
                                      (_personalComments != null &&
                                          _personalComments!.isNotEmpty))
                                    const SizedBox(width: 8),
                                  if (_personalComments != null &&
                                      _personalComments!.isNotEmpty)
                                    TextButton.icon(
                                      icon: Icon(
                                        Icons.clear,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                      label: Text(
                                        'Clear Comments',
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface),
                                      ),
                                      onPressed: _clearComments,
                                    ),
                                ],
                              ),
                          ],
                        ),
                  const SizedBox(height: 16),
                  Text(
                    'Overview',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.movie.overview,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      height: 1.5,
                    ),
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
