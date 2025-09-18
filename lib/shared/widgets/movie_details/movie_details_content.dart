/// Movie Details Content Component - Synopsis, Cast, Crew and Technical Details.
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
import 'package:moviestar/core/services/favorites/favorites_service.dart';
import 'package:moviestar/models/movie.dart';

class MovieDetailsContent extends StatefulWidget {
  final Movie movie;
  final bool isSharedMovie;
  final double? personalRating;
  final bool isLoadingRating;
  final String? personalComments;
  final bool isLoadingComments;
  final bool commentsModified;
  final bool ratingSaved;
  final bool commentsSaved;
  final TextEditingController commentsController;
  final FavoritesService favoritesService;
  final Function(double?) onUpdateRating;
  final Function(String?) onUpdateComments;
  final VoidCallback onSaveComments;
  final VoidCallback onClearComments;
  final Function(bool) onCommentsModified;
  final Map<String, dynamic>? sharedMovieData;

  const MovieDetailsContent({
    super.key,
    required this.movie,
    required this.isSharedMovie,
    required this.personalRating,
    required this.isLoadingRating,
    required this.personalComments,
    required this.isLoadingComments,
    required this.commentsModified,
    required this.ratingSaved,
    required this.commentsSaved,
    required this.commentsController,
    required this.favoritesService,
    required this.onUpdateRating,
    required this.onUpdateComments,
    required this.onSaveComments,
    required this.onClearComments,
    required this.onCommentsModified,
    this.sharedMovieData,
  });

  @override
  State<MovieDetailsContent> createState() => _MovieDetailsContentState();
}

class _MovieDetailsContentState extends State<MovieDetailsContent> {
  Timer? _commentsSavedTimer;

  @override
  void dispose() {
    _commentsSavedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPersonalRatingSection(),
        const Gap(16),
        _buildPersonalCommentsSection(),
        const Gap(16),
        _buildMovieOverviewSection(),
      ],
    );
  }

  Widget _buildPersonalRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            if (widget.ratingSaved)
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
        widget.isLoadingRating
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
                        value: widget.personalRating ?? 0,
                        min: 0,
                        max: 10,
                        divisions: 100,
                        label:
                            widget.personalRating?.toStringAsFixed(1) ?? '0.0',
                        onChanged: widget.isSharedMovie
                            ? null
                            : (value) => widget.onUpdateRating(value),
                      ),
                    ),
                  ),
                  if (!widget.isSharedMovie)
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: widget.personalRating == null
                          ? null
                          : () => widget.onUpdateRating(null),
                      tooltip: 'Clear rating',
                    ),
                ],
              ),
        Text(
          widget.personalRating == null
              ? (widget.isSharedMovie ? 'No rating shared' : 'No rating yet')
              : (widget.isSharedMovie
                  ? 'Shared rating: ${widget.personalRating!.toStringAsFixed(1)}/10'
                  : 'Your rating: ${widget.personalRating!.toStringAsFixed(1)}/10'),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            if (widget.commentsModified)
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
            if (widget.commentsSaved)
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
        widget.isLoadingComments
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: widget.commentsController,
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
                            widget.onCommentsModified(true);
                            _commentsSavedTimer?.cancel();
                          },
                    onSubmitted: widget.isSharedMovie
                        ? null
                        : (value) {
                            if (widget.commentsModified) {
                              widget.onSaveComments();
                            }
                          },
                  ),
                  const Gap(Gaps.m),
                  if (!widget.isSharedMovie)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (widget.commentsModified)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.save, size: 18),
                            label: const Text('Save Comments'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                            ),
                            onPressed: widget.onSaveComments,
                          ),
                        if (widget.commentsModified &&
                            (widget.personalComments != null &&
                                widget.personalComments!.isNotEmpty))
                          const Gap(Gaps.m),
                        if (widget.personalComments != null &&
                            widget.personalComments!.isNotEmpty)
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
                            onPressed: widget.onClearComments,
                          ),
                      ],
                    ),
                ],
              ),
      ],
    );
  }

  Widget _buildMovieOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
