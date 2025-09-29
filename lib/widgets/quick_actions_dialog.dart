/// Quick actions dialog for movie cards on hover.
///
// Time-stamp: <Monday 2025-08-18 10:00:00 +1000 Ashley Tang>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Ashley Tang.

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/widgets/quick_actions_dialog/action_handlers.dart';
import 'package:moviestar/widgets/quick_actions_dialog/error_dialogs.dart';
import 'package:moviestar/widgets/quick_actions_dialog/ui_builders.dart';

/// A floating dialog that shows quick actions for a movie card on hover.

class QuickActionsDialog extends StatefulWidget {
  /// The movie for which to show quick actions.

  final Movie movie;

  /// The favorites service to use for actions.

  final FavoritesService favoritesService;

  /// The parent widget to navigate back to when sharing.

  final Widget? parentWidget;

  /// Callback when the dialog should be closed.

  final VoidCallback onClose;

  /// Callback when mouse enters the dialog area.

  final VoidCallback onMouseEnter;

  /// Callback when mouse exits the dialog area.

  final VoidCallback onMouseExit;

  /// Content type to distinguish between movies and TV shows.

  final ContentType contentType;

  /// Creates a quick actions dialog.

  const QuickActionsDialog({
    super.key,
    required this.movie,
    required this.favoritesService,
    this.parentWidget,
    required this.onClose,
    required this.onMouseEnter,
    required this.onMouseExit,
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
    await ActionHandlers.toggleToWatch(
      favoritesService: widget.favoritesService,
      movie: widget.movie,
      contentType: widget.contentType,
      currentState: _isInToWatch,
      onStateChange: () {},
      onStateUpdate: (newState) {
        if (mounted) {
          setState(() {
            _isInToWatch = newState;
          });
        }
      },
    );
  }

  // Toggles the watched status.

  Future<void> _toggleWatched() async {
    await ActionHandlers.toggleWatched(
      favoritesService: widget.favoritesService,
      movie: widget.movie,
      contentType: widget.contentType,
      currentState: _isInWatched,
      onStateChange: () {},
      onStateUpdate: (newState) {
        if (mounted) {
          setState(() {
            _isInWatched = newState;
          });
        }
      },
    );
  }

  // Updates the personal rating.

  Future<void> _updateRating(double? rating) async {
    await ActionHandlers.updateRating(
      favoritesService: widget.favoritesService,
      movie: widget.movie,
      rating: rating,
      onRatingUpdate: (newRating) {
        if (mounted) {
          setState(() {
            _personalRating = newRating;
          });
        }
      },
      onMovieFileCheck: _checkMovieFile,
    );
  }

  // Checks if the movie has a shareable file.

  Future<void> _checkMovieFile() async {
    final hasFile = await ActionHandlers.checkMovieFile(
      favoritesService: widget.favoritesService,
      movie: widget.movie,
    );
    if (mounted) {
      setState(() {
        _hasMovieFile = hasFile;
      });
    }
  }

  // Shares the movie file using the custom movie sharing UI.

  Future<void> _shareMovie() async {
    await ActionHandlers.shareMovie(
      context: context,
      favoritesService: widget.favoritesService,
      movie: widget.movie,
      onError: _showErrorDialog,
    );
  }

  // Shows an error dialog with the given message.

  void _showErrorDialog(String message) {
    ErrorDialogs.showErrorDialog(
      context: context,
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => widget.onMouseEnter(),
      onExit: (_) => widget.onMouseExit(),
      child: Material(
        color: Colors.transparent,
        child: UiBuilders.buildDialogContainer(
          context: context,
          child: _isLoading
              ? UiBuilders.buildLoadingIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UiBuilders.buildTitleSection(
                      context: context,
                      movie: widget.movie,
                    ),
                    const Gap(Gaps.xl),
                    UiBuilders.buildActionButtons(
                      context: context,
                      isInToWatch: _isInToWatch,
                      isInWatched: _isInWatched,
                      hasMovieFile: _hasMovieFile,
                      favoritesService: widget.favoritesService,
                      onToggleToWatch: _toggleToWatch,
                      onToggleWatched: _toggleWatched,
                      onShareMovie: _shareMovie,
                    ),
                    const Gap(Gaps.xxl),
                    UiBuilders.buildRatingSection(
                      context: context,
                      personalRating: _personalRating,
                      onRatingChanged: _updateRating,
                      onClearRating: () => _updateRating(null),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
