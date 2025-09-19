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

  /// Build the rating widget with 0-10 scale and 0.1 increments.
  static Widget _buildStarRating(
    BuildContext context, {
    required double? rating,
    required Function(double?) onRatingChanged,
    required bool isSharedMovie,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isSharedMovie) ...[
          // Slider for interactive rating
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: rating ?? 0.0,
                  min: 0.0,
                  max: 10.0,
                  divisions: 100, // 0.1 increments
                  onChanged: (value) {
                    onRatingChanged(value == 0.0 ? null : value);
                  },
                ),
              ),
              const Gap(Gaps.s),
              SizedBox(
                width: 60,
                child: rating != null
                    ? Text(
                        '${rating.toStringAsFixed(1)}/10',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      )
                    : Text(
                        '0.0/10',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
              ),
            ],
          ),
        ] else ...[
          // Display-only for shared movies
          Row(
            children: [
              // Star icons for visual representation
              for (int i = 1; i <= 5; i++)
                Icon(
                  rating != null && i <= (rating / 2)
                      ? Icons.star
                      : Icons.star_border,
                  color: rating != null && i <= (rating / 2)
                      ? Colors.amber
                      : Colors.grey,
                  size: 24,
                ),
              const Gap(Gaps.m),
              if (rating != null)
                Text(
                  '${rating.toStringAsFixed(1)}/10',
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
          ),
        ],
        const Gap(Gaps.xs),
        // Rating description
        if (rating != null)
          Text(
            _getRatingDescription(rating),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
          )
        else if (!isSharedMovie)
          Text(
            'Move the slider to rate',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
          ),
      ],
    );
  }

  /// Get a descriptive text for the rating value.
  static String _getRatingDescription(double rating) {
    if (rating >= 9.0) return 'Masterpiece';
    if (rating >= 8.0) return 'Excellent';
    if (rating >= 7.0) return 'Very Good';
    if (rating >= 6.0) return 'Good';
    if (rating >= 5.0) return 'Average';
    if (rating >= 4.0) return 'Below Average';
    if (rating >= 3.0) return 'Poor';
    if (rating >= 2.0) return 'Very Poor';
    if (rating >= 1.0) return 'Awful';
    return 'Terrible';
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
