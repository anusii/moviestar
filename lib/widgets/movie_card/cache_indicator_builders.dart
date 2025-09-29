/// Cache indicator builders for movie cards.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/utils/movie_display_utils.dart';

/// Static helper class for building cache status indicators.

class CacheIndicatorBuilders {
  /// Builds cache status indicator overlay.

  static Widget buildCacheIndicator({
    required bool? fromCache,
  }) {
    if (fromCache == null) return const SizedBox.shrink();

    return Positioned(
      top: 4,
      right: 4,
      child: Container(
        padding: const EdgeInsets.all(Dimensions.xs),
        decoration: BoxDecoration(
          color: fromCache
              ? Colors.green.withValues(alpha: 0.8)
              : Colors.blue.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          fromCache ? Icons.offline_bolt : Icons.wifi,
          size: 12,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Builds offline mode indicator for poster cards.

  static Widget buildOfflineModeIndicator() {
    return Positioned(
      top: 4,
      left: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.s,
          vertical: Dimensions.xs,
        ),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.offline_pin, size: 10, color: Colors.white),
            Gap(Gaps.xs),
            Text(
              'OFFLINE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds content type indicator for poster style.

  static Widget buildContentTypeIndicator(ContentType? contentType) {
    if (contentType == null) return const SizedBox.shrink();

    final isMovie = contentType == ContentType.movie;
    final label = isMovie ? 'Movie' : 'TV Show';
    final icon = isMovie ? '🎬' : '📺';

    return Positioned(
      bottom: 4,
      left: 4,
      child: Builder(
        builder: (context) => Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.ms,
            vertical: Dimensions.xs,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 10)),
              const Gap(Gaps.xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds offline mode icon for list items.

  static Widget buildOfflineModeIcon() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.xs),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.offline_pin, size: 12, color: Colors.white),
    );
  }

  /// Builds cache age information for list items.

  static Widget buildCacheAgeInfo(Duration cacheAge) {
    return Builder(
      builder: (context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: Dimensions.s, vertical: 1),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          formatCacheAge(cacheAge),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10),
        ),
      ),
    );
  }
}
