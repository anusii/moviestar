/// Movie Info Section without title for Movie Details Screen.
/// Extracted to reduce file size and avoid code duplication.
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
import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/shared/widgets/movie_details/info_builders/comments_section.dart';
import 'package:moviestar/shared/widgets/movie_details/info_builders/movie_info.dart';
import 'package:moviestar/shared/widgets/movie_details/info_builders/rating_section.dart';

/// A widget that displays the movie info section without the title.
/// Used when the title is displayed separately with action buttons.
class MovieInfoSectionWithoutTitle extends StatefulWidget {
  /// The movie to display.
  final Movie movie;

  /// Service for managing favorite movies.
  final FavoritesService favoritesService;

  /// Whether this is a shared movie.
  final bool isSharedMovie;

  /// Shared movie data if applicable.
  final Map<String, dynamic>? sharedMovieData;

  /// Creates a new [MovieInfoSectionWithoutTitle] widget.
  const MovieInfoSectionWithoutTitle({
    super.key,
    required this.movie,
    required this.favoritesService,
    required this.isSharedMovie,
    this.sharedMovieData,
  });

  @override
  State<MovieInfoSectionWithoutTitle> createState() =>
      _MovieInfoSectionWithoutTitleState();
}

class _MovieInfoSectionWithoutTitleState
    extends State<MovieInfoSectionWithoutTitle> {
  double? _personalRating;
  String? _personalComments;
  bool _ratingSaved = false;
  bool _commentsSaved = false;
  bool _hasTextInCommentsField = false;

  final TextEditingController _commentsController = TextEditingController();
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _loadPersonalRating();
    _loadPersonalComments();

    // Listen to text changes in comments field.

    _commentsController.addListener(_onCommentsTextChanged);
  }

  void _onCommentsTextChanged() {
    final hasText = _commentsController.text.trim().isNotEmpty;
    if (_hasTextInCommentsField != hasText) {
      setState(() {
        _hasTextInCommentsField = hasText;
      });
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonalRating() async {
    if (widget.isSharedMovie) {
      // For shared movies, extract rating from shared data.

      final rating = widget.sharedMovieData?['rating'];
      if (rating != null) {
        setState(() {
          _personalRating = (rating as num).toDouble();
        });
      }
      return;
    }

    // For own movies, load from favorites service.

    try {
      final rating =
          await widget.favoritesService.getPersonalRating(widget.movie);
      if (mounted) {
        setState(() {
          _personalRating = rating;
        });
      }
    } catch (e) {
      // Error loading rating.
    }
  }

  Future<void> _updateRating(double? rating) async {
    if (widget.isSharedMovie) return;

    setState(() {
      _personalRating = rating;
      _ratingSaved = false;
    });

    try {
      if (rating != null) {
        await widget.favoritesService.setPersonalRating(widget.movie, rating);
      } else {
        await widget.favoritesService.removePersonalRating(widget.movie);
      }
      if (mounted) {
        setState(() {
          _ratingSaved = true;
        });

        Timer(TimingConstants.ratingFeedbackDuration, () {
          if (mounted) {
            setState(() {
              _ratingSaved = false;
            });
          }
        });
      }
    } catch (e) {
      // Error updating rating.
    }
  }

  Future<void> _loadPersonalComments() async {
    if (widget.isSharedMovie) {
      // For shared movies, extract comments from shared data.

      final comments = widget.sharedMovieData?['comments'] as String?;
      if (comments != null && comments.isNotEmpty) {
        setState(() {
          _personalComments = comments;
          _commentsController.text = comments;
        });
      }
      return;
    }

    // For own movies, load from favorites service.

    try {
      final comments =
          await widget.favoritesService.getMovieComments(widget.movie);
      if (mounted && comments != null) {
        setState(() {
          _personalComments = comments;
          _commentsController.text = comments;
        });
      }
    } catch (e) {
      // Error loading comments.
    }
  }

  Future<void> _updateComments(String? comments) async {
    setState(() {
      _personalComments = comments;
    });
  }

  Future<void> _saveComments() async {
    if (widget.isSharedMovie) return;

    final comments = _commentsController.text.trim();
    if (comments.isEmpty) return;

    try {
      await widget.favoritesService.setMovieComments(widget.movie, comments);
      await _updateComments(comments);

      if (mounted) {
        setState(() {
          _commentsSaved = true;
        });

        Timer(TimingConstants.ratingFeedbackDuration, () {
          if (mounted) {
            setState(() {
              _commentsSaved = false;
            });
          }
        });
      }
    } catch (e) {
      // Error saving comments.
    }
  }

  Future<void> _clearComments() async {
    if (widget.isSharedMovie) return;

    try {
      await widget.favoritesService.removeMovieComments(widget.movie);
      await _updateComments(null);

      if (mounted) {
        setState(() {
          _commentsController.clear();
          _commentsSaved = true;
        });

        Timer(TimingConstants.ratingFeedbackDuration, () {
          if (mounted) {
            setState(() {
              _commentsSaved = false;
            });
          }
        });
      }
    } catch (e) {
      // Error clearing comments.
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentTypeInfo = MovieInfoBuilder.getContentTypeInfo(widget.movie);
    final releaseDate = MovieInfoBuilder.getFormattedReleaseDate(widget.movie);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating and content type row (no title).

        RatingSection.buildRatingRow(
          context,
          contentType: contentTypeInfo['text'],
          contentTypeColor: contentTypeInfo['color'],
          tmdbRating: widget.movie.voteAverage,
          releaseDate: releaseDate,
        ),
        const Gap(Gaps.l),

        // Shared movie indicator.

        if (widget.isSharedMovie)
          RatingSection.buildSharedIndicator(
            context,
            sharedByText:
                MovieInfoBuilder.getSharedByText(widget.sharedMovieData),
          ),

        // Personal Rating Section.

        RatingSection.buildPersonalRatingSection(
          context,
          isSharedMovie: widget.isSharedMovie,
          ratingSaved: _ratingSaved,
          personalRating: _personalRating,
          onRatingChanged: _updateRating,
        ),
        const Gap(Gaps.l),

        // Movie Overview/Description Section.

        if (widget.movie.overview.isNotEmpty) ...[
          Text(
            'Overview',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(Gaps.s),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              widget.movie.overview,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
          const Gap(Gaps.l),
        ],

        // Comments Section.

        CommentsSection.buildCommentsSection(
          context,
          isSharedMovie: widget.isSharedMovie,
          comments: _personalComments,
          commentsController: _commentsController,
          commentsSaved: _commentsSaved,
          onSaveComments: _saveComments,
          onClearComments: _clearComments,
          hasTextInField: _hasTextInCommentsField,
        ),
      ],
    );
  }
}
