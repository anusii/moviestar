/// Cache operations for cache management panel.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:moviestar/constants/timing_constants.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';

/// Static helper class for cache operations.
class CacheOperations {
  /// Clears all cached movie data.
  static Future<void> clearAllCache({
    required WidgetRef ref,
    required void Function(String) showSuccessSnackBar,
    required void Function(String) showErrorSnackBar,
  }) async {
    try {
      final cachedService = ref.read(configuredCachedMovieServiceProvider);
      await cachedService.clearAllCache();

      // Invalidate providers that depend on cache state to refresh UI
      ref.invalidate(popularMoviesWithCacheInfoProvider);
      ref.invalidate(nowPlayingMoviesWithCacheInfoProvider);
      ref.invalidate(topRatedMoviesWithCacheInfoProvider);
      ref.invalidate(upcomingMoviesWithCacheInfoProvider);
      ref.invalidate(cacheStatsProvider);
      ref.invalidate(contentServiceProvider);

      showSuccessSnackBar('All cached movie data cleared successfully');
    } catch (e) {
      showErrorSnackBar('Failed to clear cache: $e');
    }
  }

  /// Forces refresh of all movie categories.
  static Future<void> forceRefreshAll({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Gap(16),
              Text('Refreshing all movie data...'),
            ],
          ),
          duration: TimingConstants.snackbarVeryLongDuration,
        ),
      );

      final cachedService = ref.read(configuredCachedMovieServiceProvider);
      await cachedService.forceRefreshAll();

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All movie data refreshed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
