/// Movie Info Section for Movie Details Screen.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/constants/timing_constants.dart';
import 'package:moviestar/core/services/favorites/favorites_service.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/utils/date_format_util.dart';

/// A widget that displays the main info section of a movie details screen.
/// This component shows the title, rating, content type, and personal sections.
class MovieInfoSection extends StatefulWidget {
  /// The movie to display.
  final Movie movie;

  /// Service for managing favorite movies.
  final FavoritesService favoritesService;

  /// Whether this is a shared movie.
  final bool isSharedMovie;

  /// Shared movie data if applicable.
  final Map<String, dynamic>? sharedMovieData;

  /// Creates a new [MovieInfoSection] widget.
  const MovieInfoSection({
    super.key,
    required this.movie,
    required this.favoritesService,
    required this.isSharedMovie,
    this.sharedMovieData,
  });

  @override
  State<MovieInfoSection> createState() => _MovieInfoSectionState();
}

class _MovieInfoSectionState extends State<MovieInfoSection> {
  double? _personalRating;
  String? _personalComments;
  bool _isLoadingRating = true;
  bool _isLoadingComments = true;
  bool _ratingSaved = false;
  bool _commentsSaved = false;
  bool _commentsModified = false;
  Timer? _ratingSavedTimer;
  Timer? _commentsSavedTimer;
  final TextEditingController _commentsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPersonalRating();
    _loadPersonalComments();
  }

  @override
  void dispose() {
    _ratingSavedTimer?.cancel();
    _commentsSavedTimer?.cancel();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonalRating() async {
    if (widget.sharedMovieData != null) {
      final sharedRating = widget.sharedMovieData!['rating'] as double?;
      setState(() {
        _personalRating = sharedRating;
        _isLoadingRating = false;
      });
      return;
    }

    final rating = await widget.favoritesService.getPersonalRating(
      widget.movie,
    );
    setState(() {
      _personalRating = rating;
      _isLoadingRating = false;
    });
  }

  Future<void> _updateRating(double? rating) async {
    if (widget.isSharedMovie) {
      return;
    }

    if (rating == null) {
      await widget.favoritesService.removePersonalRating(widget.movie);
    } else {
      await widget.favoritesService.setPersonalRating(widget.movie, rating);
    }
    setState(() {
      _personalRating = rating;
      _ratingSaved = true;
    });

    _ratingSavedTimer?.cancel();
    _ratingSavedTimer = Timer(TimingConstants.ratingFeedbackDuration, () {
      if (mounted) {
        setState(() {
          _ratingSaved = false;
        });
      }
    });
  }

  Future<void> _loadPersonalComments() async {
    if (widget.sharedMovieData != null) {
      final sharedComments = widget.sharedMovieData!['comments'] as String?;
      setState(() {
        _personalComments = sharedComments;
        _commentsController.text = sharedComments ?? '';
        _isLoadingComments = false;
      });
      return;
    }

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
    if (widget.isSharedMovie) {
      return;
    }

    if (comments == null || comments.trim().isEmpty) {
      await widget.favoritesService.removeMovieComments(widget.movie);
    } else {
      await widget.favoritesService.setMovieComments(widget.movie, comments);
    }
    setState(() {
      _personalComments = comments;
      _commentsModified = false;
    });
  }

  Future<void> _saveComments() async {
    final currentText = _commentsController.text.trim();
    await _updateComments(currentText.isEmpty ? null : currentText);

    setState(() {
      _commentsSaved = true;
    });

    _commentsSavedTimer?.cancel();
    _commentsSavedTimer = Timer(TimingConstants.ratingFeedbackDuration, () {
      if (mounted) {
        setState(() {
          _commentsSaved = false;
        });
      }
    });
  }

  Future<void> _clearComments() async {
    _commentsController.clear();
    await _updateComments(null);

    setState(() {
      _commentsSaved = true;
    });

    _commentsSavedTimer?.cancel();
    _commentsSavedTimer = Timer(TimingConstants.ratingFeedbackDuration, () {
      if (mounted) {
        setState(() {
          _commentsSaved = false;
        });
      }
    });
  }

  String _getSharedByText() {
    if (widget.sharedMovieData != null) {
      final sharedBy = widget.sharedMovieData!['sharedBy'] as String?;
      return sharedBy ?? 'someone';
    }
    return 'someone';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Movie title
        Text(
          widget.movie.title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(Gaps.m),

        // Rating and content type row
        Row(
          children: [
            // Content type indicator
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: widget.movie.contentType == ContentType.tvShow
                    ? Colors.blue.withValues(alpha: 0.2)
                    : Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: widget.movie.contentType == ContentType.tvShow
                      ? Colors.blue
                      : Colors.green,
                  width: 1,
                ),
              ),
              child: Text(
                widget.movie.contentType == ContentType.tvShow
                    ? '📺 TV Show'
                    : '🎬 Movie',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: widget.movie.contentType == ContentType.tvShow
                          ? Colors.blue
                          : Colors.green,
                    ),
              ),
            ),
            const Gap(12),
            Icon(
              Icons.star,
              color: widget.isSharedMovie && _personalRating != null
                  ? Theme.of(context).colorScheme.primary
                  : Colors.amber,
              size: 20,
            ),
            const Gap(4),
            Text(
              widget.isSharedMovie && _personalRating != null
                  ? _personalRating!.toStringAsFixed(1)
                  : widget.movie.voteAverage.toStringAsFixed(1),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
            if (widget.isSharedMovie && _personalRating != null)
              Text(
                ' (shared)',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const Gap(16),
            Icon(
              Icons.calendar_today,
              color: Theme.of(context).colorScheme.onSurface,
              size: 20,
            ),
            const Gap(4),
            Text(
              DateFormatUtil.formatShort(widget.movie.releaseDate),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const Gap(16),

        // Shared Movie Indicator
        if (widget.isSharedMovie)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.share,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const Gap(Gaps.m),
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

        // Personal Rating Section
        Row(
          children: [
            Text(
              widget.isSharedMovie ? 'Shared Rating' : 'Your Rating',
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
        const Gap(Gaps.m),
        _isLoadingRating
            ? const Center(child: CircularProgressIndicator())
            : Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: widget.isSharedMovie
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
                        thumbColor: widget.isSharedMovie
                            ? Theme.of(context).colorScheme.primary
                            : Colors.amber,
                        disabledThumbColor:
                            Theme.of(context).colorScheme.primary,
                        trackHeight: 4.0,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8.0,
                        ),
                        overlayColor: (widget.isSharedMovie
                                ? Theme.of(context).colorScheme.primary
                                : Colors.amber)
                            .withValues(alpha: 0.2),
                        valueIndicatorColor: widget.isSharedMovie
                            ? Theme.of(context).colorScheme.primary
                            : Colors.amber,
                        valueIndicatorTextStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Slider(
                        value: _personalRating ?? 0,
                        min: 0,
                        max: 10,
                        divisions: 100,
                        label: _personalRating?.toStringAsFixed(1) ?? '0.0',
                        onChanged: widget.isSharedMovie
                            ? null
                            : (value) => _updateRating(value),
                      ),
                    ),
                  ),
                  if (!widget.isSharedMovie)
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Theme.of(context).colorScheme.onSurface,
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
              ? (widget.isSharedMovie ? 'No rating shared' : 'No rating yet')
              : (widget.isSharedMovie
                  ? 'Shared rating: ${_personalRating!.toStringAsFixed(1)}/10'
                  : 'Your rating: ${_personalRating!.toStringAsFixed(1)}/10'),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
        const Gap(16),

        // Personal Comments Section
        Row(
          children: [
            Text(
              widget.isSharedMovie ? 'Shared Comments' : 'My Comments',
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
        const Gap(Gaps.m),
        _isLoadingComments
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _commentsController,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 4,
                    readOnly: widget.isSharedMovie,
                    decoration: InputDecoration(
                      hintText: widget.isSharedMovie
                          ? 'No comments shared...'
                          : 'Add your thoughts about this movie...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      filled: true,
                      fillColor: widget.isSharedMovie
                          ? Theme.of(context).colorScheme.surfaceContainerHigh
                          : Theme.of(context).colorScheme.surfaceContainer,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: widget.isSharedMovie
                        ? null
                        : (value) {
                            setState(() {
                              _commentsModified = true;
                              _commentsSaved = false;
                            });
                            _commentsSavedTimer?.cancel();
                          },
                    onSubmitted: widget.isSharedMovie
                        ? null
                        : (value) {
                            if (_commentsModified) {
                              _saveComments();
                            }
                          },
                  ),
                  const Gap(Gaps.m),
                  if (!widget.isSharedMovie)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_commentsModified)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save, size: 18),
                            label: const Text('Save Comments'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                            ),
                            onPressed: _saveComments,
                          ),
                        if (_commentsModified &&
                            (_personalComments != null &&
                                _personalComments!.isNotEmpty))
                          const Gap(Gaps.m),
                        if (_personalComments != null &&
                            _personalComments!.isNotEmpty)
                          TextButton.icon(
                            icon: Icon(
                              Icons.clear,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            label: Text(
                              'Clear Comments',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            onPressed: _clearComments,
                          ),
                      ],
                    ),
                ],
              ),
        const Gap(16),

        // Overview section
        Text(
          'Overview',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(Gaps.m),
        Text(
          widget.movie.overview,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
