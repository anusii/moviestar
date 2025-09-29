/// UI builders for quick actions dialog components.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/core/services/favorites/service_adapter.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';

/// Static helper class for building UI components in quick actions dialog.

class UiBuilders {
  /// Builds the main content container for the dialog.

  static Widget buildDialogContainer({
    required BuildContext context,
    required Widget child,
  }) {
    return Container(
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
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: child,
    );
  }

  /// Builds the title section with content type indicator.

  static Widget buildTitleSection({
    required BuildContext context,
    required Movie movie,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            movie.title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Gap(Gaps.m),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: movie.contentType == ContentType.tvShow
                ? Colors.blue.withValues(alpha: 0.2)
                : Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: movie.contentType == ContentType.tvShow
                  ? Colors.blue
                  : Colors.green,
              width: 1,
            ),
          ),
          child: Text(
            movie.contentType == ContentType.tvShow ? '📺 TV Show' : '🎬 Movie',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: movie.contentType == ContentType.tvShow
                      ? Colors.blue
                      : Colors.green,
                ),
          ),
        ),
      ],
    );
  }

  /// Builds the quick action buttons row.

  static Widget buildActionButtons({
    required BuildContext context,
    required bool isInToWatch,
    required bool isInWatched,
    required bool hasMovieFile,
    required FavoritesService favoritesService,
    required VoidCallback onToggleToWatch,
    required VoidCallback onToggleWatched,
    required VoidCallback onShareMovie,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Bookmark (To Watch).

        _buildActionButton(
          context: context,
          icon: isInToWatch ? Icons.bookmark : Icons.bookmark_border,
          color: isInToWatch
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
          tooltip: isInToWatch ? 'Remove from To Watch' : 'Add to To Watch',
          onPressed: onToggleToWatch,
        ),

        // Watched.

        _buildActionButton(
          context: context,
          icon: isInWatched ? Icons.check_circle : Icons.check_circle_outline,
          color: isInWatched
              ? Theme.of(context).colorScheme.tertiary
              : Theme.of(context).colorScheme.onSurface,
          tooltip: isInWatched ? 'Remove from Watched' : 'Add to Watched',
          onPressed: onToggleWatched,
        ),

        // Share button (only if movie has rating/comment and POD is enabled).

        if (hasMovieFile &&
            favoritesService is FavoritesServiceAdapter &&
            favoritesService.isPodStorageEnabled)
          MarkdownTooltip(
            message: '''

**Share this movie and my review**

Share your rating and comments for this movie with friends via their WebID.
Your shared movies will appear in their "Shared with Me" tab.

            ''',
            child: _buildActionButton(
              context: context,
              icon: Icons.share,
              color: Theme.of(context).colorScheme.onSurface,
              tooltip: 'Share movie',
              onPressed: onShareMovie,
            ),
          ),
      ],
    );
  }

  /// Builds the rating section with slider and controls.

  static Widget buildRatingSection({
    required BuildContext context,
    required double? personalRating,
    required Function(double) onRatingChanged,
    required VoidCallback onClearRating,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Rating',
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Gap(Gaps.m),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.amber,
                  inactiveTrackColor: Theme.of(context).colorScheme.outline,
                  thumbColor: Colors.amber,
                  trackHeight: 3.0,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6.0,
                  ),
                  overlayColor: Colors.amber.withValues(alpha: 0.2),
                  valueIndicatorColor: Colors.amber,
                  valueIndicatorTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                child: Slider(
                  value: personalRating ?? 0,
                  min: 0,
                  max: 10,
                  divisions: 100,
                  label: personalRating?.toStringAsFixed(1) ?? '0.0',
                  onChanged: onRatingChanged,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.clear,
                color: Theme.of(context).colorScheme.onSurface,
                size: 18,
              ),
              onPressed: personalRating == null ? null : onClearRating,
              tooltip: 'Clear rating',
            ),
          ],
        ),
        Text(
          personalRating == null
              ? 'No rating yet'
              : '${personalRating.toStringAsFixed(1)}/10',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }

  /// Builds a loading indicator.

  static Widget buildLoadingIndicator() {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  /// Builds an action button with consistent styling.

  static Widget _buildActionButton({
    required BuildContext context,
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
