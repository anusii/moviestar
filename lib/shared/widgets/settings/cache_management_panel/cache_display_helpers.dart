/// Cache display helpers for cache management panel.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:moviestar/core/services/cache/hive_movie_cache_service.dart';

/// Static helper class for cache display utilities.
class CacheDisplayHelpers {
  /// Gets display name for cache category.
  static String getCategoryDisplayName(CacheCategory category) {
    switch (category) {
      case CacheCategory.toWatch:
        return 'To Watch';
      case CacheCategory.watched:
        return 'Watched';
      case CacheCategory.recommended:
        return 'Recommended Movies';
      case CacheCategory.nowPlaying:
        return 'Now Playing';
      case CacheCategory.topRated:
        return 'Top Rated';
      case CacheCategory.upcoming:
        return 'Upcoming Movies';
    }
  }

  /// Gets human-readable time ago string.
  static String getTimeAgo(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'just now';
    }
  }

  /// Builds cache statistics widget.
  static Widget buildCacheStatistics({
    required BuildContext context,
    required Map<CacheCategory, Map<String, dynamic>> stats,
  }) {
    if (stats.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, size: 16),
                const Gap(8),
                Text(
                  'Cache Statistics',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const Gap(12),
            ...stats.entries.map((entry) {
              final category = entry.key;
              final stat = entry.value;
              final categoryName = getCategoryDisplayName(category);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Updated ${getTimeAgo(stat['age'] as Duration)} ago',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                  ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          (stat['isValid'] as bool)
                              ? Icons.check_circle
                              : Icons.schedule,
                          size: 16,
                          color: (stat['isValid'] as bool)
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const Gap(4),
                        Text(
                          (stat['isValid'] as bool)
                              ? '${stat['movieCount']} movies'
                              : 'Expired',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
