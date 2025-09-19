/// Rating section builder for movie info section.
/// Extracted to reduce file size and improve organization.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:moviestar/constants/dimensions.dart';

/// Builds the rating section for movie details.
class RatingSection {
  /// Build the rating row with content type and TMDB rating.
  static Widget buildRatingRow(
    BuildContext context, {
    required String contentType,
    required Color contentTypeColor,
    required double tmdbRating,
    required String releaseDate,
  }) {
    return Row(
      children: [
        // Content type indicator
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: contentTypeColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: contentTypeColor,
              width: 1,
            ),
          ),
          child: Text(
            contentType,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: contentTypeColor,
                ),
          ),
        ),
        const Gap(Gaps.m),

        // TMDB Rating
        Row(
          children: [
            const Icon(
              Icons.star,
              color: Colors.amber,
              size: 16,
            ),
            const Gap(Gaps.xs),
            Text(
              tmdbRating.toStringAsFixed(1),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const Gap(Gaps.m),

        // Release Date
        if (releaseDate.isNotEmpty) ...[
          const Icon(
            Icons.calendar_today,
            size: 16,
            color: Colors.grey,
          ),
          const Gap(Gaps.xs),
          Text(
            releaseDate,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ],
    );
  }

  /// Build the personal rating section.
  static Widget buildPersonalRatingSection(
    BuildContext context, {
    required bool isSharedMovie,
    required bool ratingSaved,
    required double? personalRating,
    required Function(double?) onRatingChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              isSharedMovie ? 'Shared Rating' : 'Your Rating',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (ratingSaved)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: const Text(
                  'Saved',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const Gap(Gaps.s),
        _buildStarRating(
          context,
          rating: personalRating,
          onRatingChanged: onRatingChanged,
          isSharedMovie: isSharedMovie,
        ),
      ],
    );
  }

  /// Build the star rating widget.
  static Widget _buildStarRating(
    BuildContext context, {
    required double? rating,
    required Function(double?) onRatingChanged,
    required bool isSharedMovie,
  }) {
    return Row(
      children: [
        for (int i = 1; i <= 5; i++)
          GestureDetector(
            onTap: isSharedMovie
                ? null
                : () {
                    final newRating = i.toDouble();
                    onRatingChanged(rating == newRating ? null : newRating);
                  },
            child: Icon(
              rating != null && i <= rating ? Icons.star : Icons.star_border,
              color: rating != null && i <= rating ? Colors.amber : Colors.grey,
              size: 30,
            ),
          ),
        const Gap(Gaps.m),
        if (rating != null)
          Text(
            '${rating.toStringAsFixed(1)}/5',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          )
        else
          Text(
            'Not rated',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
      ],
    );
  }

  /// Build the shared movie indicator.
  static Widget buildSharedIndicator(
    BuildContext context, {
    required String sharedByText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
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
            'This movie was shared by $sharedByText',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
