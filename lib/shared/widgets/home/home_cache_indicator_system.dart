/// HomeScreen Cache Indicator System Component - Cache status display and performance feedback system.
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

import 'package:moviestar/core/services/cache/hive_movie_cache_service.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/widgets/cache_feedback_widget.dart';

/// Component that handles cache indicator display and performance feedback.
class HomeCacheIndicatorSystem extends StatefulWidget {
  final WidgetRef ref;
  final bool mounted;
  final AsyncValue<CacheResult<List<Movie>>> popularMovies;
  final AsyncValue<CacheResult<List<Movie>>> nowPlayingMovies;
  final AsyncValue<CacheResult<List<Movie>>> topRatedMovies;
  final AsyncValue<CacheResult<List<Movie>>> upcomingMovies;
  final VoidCallback onForceRefresh;

  const HomeCacheIndicatorSystem({
    super.key,
    required this.ref,
    required this.mounted,
    required this.popularMovies,
    required this.nowPlayingMovies,
    required this.topRatedMovies,
    required this.upcomingMovies,
    required this.onForceRefresh,
  });

  @override
  State<HomeCacheIndicatorSystem> createState() =>
      _HomeCacheIndicatorSystemState();
}

class _HomeCacheIndicatorSystemState extends State<HomeCacheIndicatorSystem> {
  // Track if initial load feedback has been shown
  bool _hasShownInitialFeedback = false;

  @override
  void didUpdateWidget(HomeCacheIndicatorSystem oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Show performance feedback after initial load when providers update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showCachePerformanceFeedback();
      }
    });
  }

  /// Shows cache performance feedback after initial load.
  void _showCachePerformanceFeedback() {
    if (_hasShownInitialFeedback) return;

    // Check if widget is still mounted before proceeding
    if (!widget.mounted) return;

    final popularMovies = widget.popularMovies;
    final nowPlayingMovies = widget.nowPlayingMovies;
    final topRatedMovies = widget.topRatedMovies;
    final upcomingMovies = widget.upcomingMovies;

    // Check if all categories have loaded
    final allLoaded = [
      popularMovies,
      nowPlayingMovies,
      topRatedMovies,
      upcomingMovies,
    ].every((async) => async.hasValue);

    if (!allLoaded) return;

    // Extract cache results
    final results = <String, bool>{};
    popularMovies.whenOrNull(
      data: (result) => results['Popular'] = result.fromCache,
    );
    nowPlayingMovies.whenOrNull(
      data: (result) => results['Now Playing'] = result.fromCache,
    );
    topRatedMovies.whenOrNull(
      data: (result) => results['Top Rated'] = result.fromCache,
    );
    upcomingMovies.whenOrNull(
      data: (result) => results['Upcoming'] = result.fromCache,
    );

    if (results.length == 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Check if widget is still mounted before showing feedback
        if (widget.mounted && mounted) {
          CacheFeedbackWidget.showCacheStatsSummary(
            context,
            categoryResults: results,
            totalTime: const Duration(milliseconds: 500),
          );
        }
      });
      _hasShownInitialFeedback = true;
    }
  }

  /// Forces refresh of all movie data.
  Future<void> forceRefresh() async {
    // Check if widget is still mounted before starting refresh
    if (!widget.mounted) return;

    widget.onForceRefresh();

    // Force refresh through the cached service
    try {
      final cachedService =
          widget.ref.read(configuredCachedMovieServiceProvider);
      await cachedService.forceRefreshAll();
    } catch (e) {
      // Handle error gracefully without causing setState after dispose
      if (widget.mounted) {}
    }
  }

  /// Builds cache indicator for section headers.
  Widget buildSectionCacheIndicator(
    AsyncValue<CacheResult<List<Movie>>> moviesAsync,
    bool cacheOnlyMode,
  ) {
    return moviesAsync.when(
      data: (cacheResult) {
        if (cacheOnlyMode) {
          return buildOfflineModeBadge();
        }

        if (cacheResult.fromCache && cacheResult.cacheAge != null) {
          return buildCacheAgeBadge(cacheResult.cacheAge!);
        }

        if (cacheResult.fromCache) {
          return buildCacheBadge();
        } else {
          return buildNetworkBadge();
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Builds offline mode badge.
  Widget buildOfflineModeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.offline_pin, size: 12, color: Colors.white),
          Gap(4),
          Text(
            'OFFLINE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds cache age badge.
  Widget buildCacheAgeBadge(Duration cacheAge) {
    final ageText = _formatCacheAge(cacheAge);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.offline_bolt, size: 12, color: Colors.white),
          const Gap(4),
          Text(
            ageText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds cache badge for fresh cache data.
  Widget buildCacheBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.offline_bolt, size: 12, color: Colors.white),
          Gap(4),
          Text(
            'CACHED',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds network badge for fresh data.
  Widget buildNetworkBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi, size: 12, color: Colors.white),
          Gap(4),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Formats cache age into human-readable string.
  String _formatCacheAge(Duration age) {
    if (age.inDays > 0) {
      return '${age.inDays}d old';
    } else if (age.inHours > 0) {
      return '${age.inHours}h old';
    } else if (age.inMinutes > 0) {
      return '${age.inMinutes}m old';
    } else {
      return 'cached';
    }
  }

  @override
  Widget build(BuildContext context) {
    // This component doesn't render anything visible - it's purely functional
    // It handles cache performance feedback and provides methods for indicators
    return const SizedBox.shrink();
  }
}

/// Static helper class for cache indicator creation outside of component context.
class CacheIndicatorHelper {
  /// Builds cache indicator for section headers.
  static Widget buildSectionCacheIndicator(
    AsyncValue<CacheResult<List<Movie>>> moviesAsync,
    bool cacheOnlyMode,
  ) {
    return moviesAsync.when(
      data: (cacheResult) {
        if (cacheOnlyMode) {
          return _buildOfflineModeBadge();
        }

        if (cacheResult.fromCache && cacheResult.cacheAge != null) {
          return _buildCacheAgeBadge(cacheResult.cacheAge!);
        }

        if (cacheResult.fromCache) {
          return _buildCacheBadge();
        } else {
          return _buildNetworkBadge();
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  static Widget _buildOfflineModeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.offline_pin, size: 12, color: Colors.white),
          Gap(4),
          Text(
            'OFFLINE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildCacheAgeBadge(Duration cacheAge) {
    final ageText = _formatCacheAge(cacheAge);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.offline_bolt, size: 12, color: Colors.white),
          const Gap(4),
          Text(
            ageText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildCacheBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.offline_bolt, size: 12, color: Colors.white),
          Gap(4),
          Text(
            'CACHED',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildNetworkBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi, size: 12, color: Colors.white),
          Gap(4),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatCacheAge(Duration age) {
    if (age.inDays > 0) {
      return '${age.inDays}d old';
    } else if (age.inHours > 0) {
      return '${age.inHours}h old';
    } else if (age.inMinutes > 0) {
      return '${age.inMinutes}m old';
    } else {
      return 'cached';
    }
  }
}
