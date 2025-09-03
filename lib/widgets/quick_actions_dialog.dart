/// Quick actions dialog for movie cards on hover.
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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:solidpod/solidpod.dart';

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/services/favorites_service_adapter.dart';

/// A floating dialog that shows quick actions for a movie card on hover.

class QuickActionsDialog extends StatefulWidget {
  /// The movie for which to show quick actions.

  final Movie movie;

  /// The favorites service to use for actions.

  final FavoritesService favoritesService;

  /// The parent widget to navigate back to when sharing.

  final Widget? parentWidget;

  /// Callback when the dialog should be closed.

  final VoidCallback? onClose;

  /// Callback when mouse enters the dialog area.

  final VoidCallback? onMouseEnter;

  /// Callback when mouse exits the dialog area.

  final VoidCallback? onMouseExit;

  /// Content type to distinguish between movies and TV shows.

  final ContentType contentType;

  /// Creates a quick actions dialog.

  const QuickActionsDialog({
    super.key,
    required this.movie,
    required this.favoritesService,
    this.parentWidget,
    this.onClose,
    this.onMouseEnter,
    this.onMouseExit,
    this.contentType = ContentType.movie,
  });

  @override
  State<QuickActionsDialog> createState() => _QuickActionsDialogState();
}

class _QuickActionsDialogState extends State<QuickActionsDialog> {
  // Whether the movie is in the to-watch list.

  bool _isInToWatch = false;

  // Whether the movie is in the watched list.

  bool _isInWatched = false;

  // Personal rating for the movie.

  double? _personalRating;

  // Whether data is loading.

  bool _isLoading = true;

  // Whether the movie has a shareable file (rating or comment).

  bool _hasMovieFile = false;

  @override
  void initState() {
    super.initState();
    _loadMovieStatus();
  }

  // Loads the current status of the movie.

  Future<void> _loadMovieStatus() async {
    try {
      final isInToWatch = await widget.favoritesService.isInToWatch(
        widget.movie,
      );
      final isInWatched = await widget.favoritesService.isInWatched(
        widget.movie,
      );
      final rating = await widget.favoritesService.getPersonalRating(
        widget.movie,
      );
      final hasFile = await widget.favoritesService.hasMovieFile(widget.movie);

      if (mounted) {
        setState(() {
          _isInToWatch = isInToWatch;
          _isInWatched = isInWatched;
          _personalRating = rating;
          _hasMovieFile = hasFile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Toggles the to-watch status.

  Future<void> _toggleToWatch() async {
    // Store original state for potential rollback.

    final originalState = _isInToWatch;

    // Update UI immediately for instant feedback.

    if (mounted) {
      setState(() {
        _isInToWatch = !_isInToWatch;
      });
    }

    try {
      if (originalState) {
        await widget.favoritesService.removeFromToWatch(widget.movie);
      } else {
        await widget.favoritesService.addToWatch(
          widget.movie,
          contentType:
              widget.contentType == ContentType.tvShow ? 'tv' : 'movie',
        );
      }
    } catch (e) {
      // Rollback UI state on error.

      if (mounted) {
        setState(() {
          _isInToWatch = originalState;
        });
      }
    }
  }

  // Toggles the watched status.

  Future<void> _toggleWatched() async {
    // Store original state for potential rollback.

    final originalState = _isInWatched;

    // Update UI immediately for instant feedback.

    if (mounted) {
      setState(() {
        _isInWatched = !_isInWatched;
      });
    }

    try {
      if (originalState) {
        await widget.favoritesService.removeFromWatched(widget.movie);
      } else {
        await widget.favoritesService.addToWatched(
          widget.movie,
          contentType:
              widget.contentType == ContentType.tvShow ? 'tv' : 'movie',
        );
      }
    } catch (e) {
      // Rollback UI state on error.

      if (mounted) {
        setState(() {
          _isInWatched = originalState;
        });
      }
    }
  }

  // Updates the personal rating.

  Future<void> _updateRating(double? rating) async {
    try {
      if (rating == null) {
        await widget.favoritesService.removePersonalRating(widget.movie);
      } else {
        await widget.favoritesService.setPersonalRating(widget.movie, rating);
      }
      if (mounted) {
        setState(() {
          _personalRating = rating;
        });
        // Check if movie file status changed.

        _checkMovieFile();
      }
    } catch (e) {
      // Handle error silently for now.
    }
  }

  // Checks if the movie has a shareable file.

  Future<void> _checkMovieFile() async {
    try {
      final hasFile = await widget.favoritesService.hasMovieFile(widget.movie);
      if (mounted) {
        setState(() {
          _hasMovieFile = hasFile;
        });
      }
    } catch (e) {
      // Handle error silently for now.
    }
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

      // Navigate directly to GrantPermissionUi.

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
              recipientTypeList: const ['indi'],
              showAppBar: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: widget.parentWidget ?? widget,
            ),
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

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => widget.onMouseEnter?.call(),
      onExit: (_) => widget.onMouseExit?.call(),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: _isLoading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with content type indicator.

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.movie.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                widget.movie.contentType == ContentType.tvShow
                                    ? Colors.blue.withValues(alpha: 0.2)
                                    : Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color:
                                  widget.movie.contentType == ContentType.tvShow
                                      ? Colors.blue
                                      : Colors.green,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.movie.contentType == ContentType.tvShow
                                ? '📺 TV Show'
                                : '🎬 Movie',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: widget.movie.contentType ==
                                              ContentType.tvShow
                                          ? Colors.blue
                                          : Colors.green,
                                    ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),

                    // Quick action buttons.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Bookmark (To Watch).
                        _buildActionButton(
                          icon: _isInToWatch
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: _isInToWatch
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                          tooltip: _isInToWatch
                              ? 'Remove from To Watch'
                              : 'Add to To Watch',
                          onPressed: _toggleToWatch,
                        ),

                        // Watched.
                        _buildActionButton(
                          icon: _isInWatched
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: _isInWatched
                              ? Theme.of(context).colorScheme.tertiary
                              : Theme.of(context).colorScheme.onSurface,
                          tooltip: _isInWatched
                              ? 'Remove from Watched'
                              : 'Add to Watched',
                          onPressed: _toggleWatched,
                        ),

                        // Share button (only if movie has rating/comment and POD is enabled).
                        if (_hasMovieFile &&
                            widget.favoritesService
                                is FavoritesServiceAdapter &&
                            (widget.favoritesService as FavoritesServiceAdapter)
                                .isPodStorageEnabled)
                          MarkdownTooltip(
                            message: '''

**Share this movie and my review**

Share your rating and comments for this movie with friends via their WebID.
Your shared movies will appear in their "Shared with Me" tab.

                            ''',
                            child: _buildActionButton(
                              icon: Icons.share,
                              color: Theme.of(context).colorScheme.onSurface,
                              tooltip: 'Share movie',
                              onPressed: _shareMovie,
                            ),
                          ),
                      ],
                    ),

                    const Gap(16),

                    // Rating section
                    Text(
                      'Your Rating',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Gap(8),

                    Row(
                      children: [
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.amber,
                              inactiveTrackColor:
                                  Theme.of(context).colorScheme.outline,
                              thumbColor: Colors.amber,
                              trackHeight: 3.0,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6.0,
                              ),
                              overlayColor: Colors.amber.withValues(
                                alpha: 0.2,
                              ),
                              valueIndicatorColor: Colors.amber,
                              valueIndicatorTextStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            child: Slider(
                              value: _personalRating ?? 0,
                              min: 0,
                              max: 10,
                              divisions: 100,
                              label:
                                  _personalRating?.toStringAsFixed(1) ?? '0.0',
                              onChanged: (value) => _updateRating(value),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 18,
                          ),
                          onPressed: _personalRating == null
                              ? null
                              : () => _updateRating(null),
                          tooltip: 'Clear rating',
                        ),
                      ],
                    ),

                    Text(
                      _personalRating == null
                          ? 'No rating yet'
                          : '${_personalRating!.toStringAsFixed(1)}/10',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // Builds an action button with consistent styling.

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
