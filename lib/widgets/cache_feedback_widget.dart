/// Widget for providing user feedback about cache performance.
///
// Time-stamp: <Thursday 2025-04-10 11:47:48 +1000 Graham Williams>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
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
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

/// Utility class for showing cache performance feedback to users.

class CacheFeedbackWidget {
  /// Shows a toast message about cache performance.

  static void showCachePerformanceToast(
    BuildContext context, {
    required bool fromCache,
    required String category,
    Duration? cacheAge,
    int? movieCount,
    bool showSuccessToasts = true,
  }) {
    if (!showSuccessToasts && fromCache) return;

    final String message;
    final Color backgroundColor;
    final IconData icon;

    if (fromCache) {
      final ageText = cacheAge != null ? _formatCacheAge(cacheAge) : '';
      final countText = movieCount != null ? ' ($movieCount movies)' : '';
      message = 'Loaded $category from cache instantly! $ageText$countText';
      backgroundColor = Colors.green;
      icon = Icons.offline_bolt;
    } else {
      final countText = movieCount != null ? ' ($movieCount movies)' : '';
      message = 'Downloaded fresh $category from network$countText';
      backgroundColor = Colors.blue;
      icon = Icons.wifi;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration:
            fromCache ? const Duration(seconds: 2) : const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Shows cache statistics summary.

  static void showCacheStatsSummary(
    BuildContext context, {
    required Map<String, bool> categoryResults,
    required Duration totalTime,
  }) {
    final cacheHits =
        categoryResults.values.where((fromCache) => fromCache).length;
    final totalCategories = categoryResults.length;
    final networkCalls = totalCategories - cacheHits;

    final String message;
    final Color backgroundColor;

    if (cacheHits == totalCategories) {
      message =
          'All $totalCategories categories loaded from cache instantly! ⚡';
      backgroundColor = Colors.green;
    } else if (cacheHits > 0) {
      message =
          '$cacheHits cached, $networkCalls from network in ${totalTime.inMilliseconds}ms';
      backgroundColor = Colors.blue;
    } else {
      message =
          'All $totalCategories categories downloaded from network in ${totalTime.inMilliseconds}ms';
      backgroundColor = Colors.orange;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              cacheHits == totalCategories ? Icons.offline_bolt : Icons.wifi,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Shows offline mode notification.

  static void showOfflineModeNotification(
    BuildContext context, {
    required bool isEnabled,
  }) {
    final message =
        isEnabled
            ? 'Offline Mode enabled - browse movies without internet'
            : 'Offline Mode disabled - network access restored';

    final backgroundColor = isEnabled ? Colors.orange : Colors.blue;
    final icon = isEnabled ? Icons.offline_pin : Icons.wifi;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Formats cache age into human-readable string.

  static String _formatCacheAge(Duration age) {
    if (age.inDays > 0) {
      return '(${age.inDays}d old)';
    } else if (age.inHours > 0) {
      return '(${age.inHours}h old)';
    } else if (age.inMinutes > 0) {
      return '(${age.inMinutes}m old)';
    } else {
      return '(fresh)';
    }
  }
}

/// Settings for cache feedback display.

class CacheFeedbackSettings {
  /// Whether to show success toasts for cache hits.

  static bool showSuccessToasts = true;

  /// Whether to show performance statistics.

  static bool showPerformanceStats = true;

  /// Whether to show offline mode notifications.

  static bool showOfflineNotifications = true;
}
