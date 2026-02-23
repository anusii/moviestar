/// Cache Badges for Home Screen.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Ashley Tang, Kevin Wang

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:moviestar/core/services/cache/hive_movie_cache_service.dart';
import 'package:moviestar/models/movie.dart';

/// A widget that provides cache badge functionality for the home screen.
/// This component handles different types of cache indicators and badges.

class HomeCacheBadges {
  /// Builds cache indicator for section headers.

  static Widget buildSectionCacheIndicator(
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

  static Widget buildOfflineModeBadge() {
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

  static Widget buildCacheAgeBadge(Duration cacheAge) {
    final ageText = formatCacheAge(cacheAge);
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

  static Widget buildCacheBadge() {
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

  static Widget buildNetworkBadge() {
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

  static String formatCacheAge(Duration age) {
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
