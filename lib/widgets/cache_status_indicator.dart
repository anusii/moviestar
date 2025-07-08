/// Widget for showing current cache status in the UI.
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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/database/movie_cache_repository.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/screens/settings_screen.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/widgets/cache_feedback_widget.dart';

/// A small indicator widget showing current cache status.

class CacheStatusIndicator extends ConsumerWidget {
  /// Whether to show as a compact button or full display.

  final bool compact;

  /// Required services for navigation to settings.

  final FavoritesService? favoritesService;

  /// Creates a cache status indicator.

  const CacheStatusIndicator({
    super.key,
    this.compact = true,
    this.favoritesService,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cachingEnabled = ref.watch(cachingEnabledProvider);
    final cacheOnlyMode = ref.watch(cacheOnlyModeProvider);
    final cacheStatsAsync = ref.watch(cacheStatsProvider);

    if (!cachingEnabled) {
      // Hide if caching is disabled.

      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => _showCacheDetails(context, ref),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: _getStatusColor(cacheOnlyMode, cacheStatsAsync),
          borderRadius: BorderRadius.circular(compact ? 4 : 6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getStatusIcon(cacheOnlyMode, cacheStatsAsync),
              size: compact ? 12 : 16,
              color: Colors.white,
            ),
            if (!compact) ...[
              const SizedBox(width: 4),
              Text(
                _getStatusText(cacheOnlyMode, cacheStatsAsync),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 8 : 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Gets the appropriate color for the cache status.

  Color _getStatusColor(
    bool cacheOnlyMode,
    AsyncValue<Map<CacheCategory, CacheStats>> cacheStatsAsync,
  ) {
    if (cacheOnlyMode) {
      return Colors.orange.withValues(alpha: 0.9);
    }

    return cacheStatsAsync.when(
      data: (stats) {
        if (stats.isEmpty) return Colors.grey.withValues(alpha: 0.8);

        final totalCached = stats.values.fold(
          0,
          (sum, stat) => sum + stat.movieCount,
        );
        if (totalCached > 0) {
          return Colors.green.withValues(alpha: 0.8);
        }
        return Colors.grey.withValues(alpha: 0.8);
      },
      loading: () => Colors.blue.withValues(alpha: 0.8),
      error: (_, __) => Colors.red.withValues(alpha: 0.8),
    );
  }

  /// Gets the appropriate icon for the cache status.

  IconData _getStatusIcon(
    bool cacheOnlyMode,
    AsyncValue<Map<CacheCategory, CacheStats>> cacheStatsAsync,
  ) {
    if (cacheOnlyMode) {
      return Icons.offline_pin;
    }

    return cacheStatsAsync.when(
      data: (stats) {
        final totalCached = stats.values.fold(
          0,
          (sum, stat) => sum + stat.movieCount,
        );
        return totalCached > 0 ? Icons.offline_bolt : Icons.storage;
      },
      loading: () => Icons.sync,
      error: (_, __) => Icons.error_outline,
    );
  }

  /// Gets the appropriate text for the cache status.

  String _getStatusText(
    bool cacheOnlyMode,
    AsyncValue<Map<CacheCategory, CacheStats>> cacheStatsAsync,
  ) {
    if (cacheOnlyMode) {
      return 'OFFLINE';
    }

    return cacheStatsAsync.when(
      data: (stats) {
        final totalCached = stats.values.fold(
          0,
          (sum, stat) => sum + stat.movieCount,
        );
        if (totalCached > 0) {
          return '$totalCached CACHED';
        }
        return 'NO CACHE';
      },
      loading: () => 'LOADING',
      error: (_, __) => 'ERROR',
    );
  }

  /// Shows detailed cache information.

  void _showCacheDetails(BuildContext context, WidgetRef ref) {
    final cacheStatsAsync = ref.read(cacheStatsProvider);
    final cacheOnlyMode = ref.read(cacheOnlyModeProvider);

    cacheStatsAsync.when(
      data: (stats) {
        final totalCached = stats.values.fold(
          0,
          (sum, stat) => sum + stat.movieCount,
        );

        String message;
        if (cacheOnlyMode) {
          message =
              'Offline Mode: Browse movies without internet\n$totalCached movies available offline';
        } else if (totalCached > 0) {
          final validCategories =
              stats.values.where((stat) => stat.isValid).length;
          message =
              'Cache Active: $totalCached movies cached\n$validCategories categories up to date';
        } else {
          message =
              'Cache Empty: No movies cached yet\nData will be cached after first load';
        }

        _showCacheDialog(context, ref, message);
      },
      loading: () {
        _showCacheDialog(context, ref, 'Loading cache statistics...');
      },
      error: (error, _) {
        _showCacheDialog(context, ref, 'Error loading cache stats: $error');
      },
    );
  }

  /// Shows a dialog with cache information and actions.

  void _showCacheDialog(BuildContext context, WidgetRef ref, String message) {
    final cacheOnlyMode = ref.read(cacheOnlyModeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.storage, size: 24),
            SizedBox(width: 8),
            Text('Cache Status'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (cacheOnlyMode)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref
                    .read(cacheOnlyModeProvider.notifier)
                    .setCacheOnlyMode(false);
                CacheFeedbackWidget.showOfflineModeNotification(
                  context,
                  isEnabled: false,
                );
              },
              child: const Text('Go Online'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToSettings(context, ref);
            },
            child: const Text('Cache Settings'),
          ),
        ],
      ),
    );
  }

  /// Navigates to the cache settings page.

  void _navigateToSettings(BuildContext context, WidgetRef ref) {
    if (favoritesService != null) {
      final apiKeyService = ref.read(apiKeyServiceProvider);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SettingsScreen(
            favoritesService: favoritesService!,
            apiKeyService: apiKeyService,
          ),
        ),
      );
    } else {
      // Fallback - show message that settings can be accessed from main navigation.

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Cache Settings from the Settings tab'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
