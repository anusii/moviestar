/// Cache Management Panel for Settings Screen.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/shared/widgets/settings/cache_management_panel/cache_dialog_builders.dart';
import 'package:moviestar/shared/widgets/settings/cache_management_panel/cache_display_helpers.dart';
import 'package:moviestar/shared/widgets/settings/cache_management_panel/cache_operations.dart';
import 'package:moviestar/shared/widgets/settings/cache_management_panel/cache_tile_builders.dart';

/// A widget that displays cache management settings and statistics.

class CacheManagementPanel extends ConsumerWidget {
  /// Function to build a switch tile widget.

  final Widget Function(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) buildSwitchTile;

  /// Function to build a list tile widget.

  final Widget Function(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive,
  }) buildListTile;

  /// Function to show success snackbar.

  final void Function(String message) showSuccessSnackBar;

  /// Function to show error snackbar.

  final void Function(String message) showErrorSnackBar;

  /// Creates a new [CacheManagementPanel] widget.

  const CacheManagementPanel({
    super.key,
    required this.buildSwitchTile,
    required this.buildListTile,
    required this.showSuccessSnackBar,
    required this.showErrorSnackBar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheStatsAsync = ref.watch(cacheStatsProvider);
    final cachingEnabled = ref.watch(cachingEnabledProvider);
    final cacheOnlyMode = ref.watch(cacheOnlyModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Cache Management',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        buildSwitchTile(
          'Enable Caching',
          'Cache movie data to improve performance',
          cachingEnabled,
          (value) {
            ref.read(cachingEnabledProvider.notifier).setCachingEnabled(value);
            // If disabling caching, also disable cache-only mode.

            if (!value && cacheOnlyMode) {
              ref.read(cacheOnlyModeProvider.notifier).setCacheOnlyMode(false);
            }
          },
        ),
        CacheTileBuilders.buildOfflineModeTile(
          context: context,
          ref: ref,
          cachingEnabled: cachingEnabled,
          cacheOnlyMode: cacheOnlyMode,
        ),
        CacheTileBuilders.buildApiKeyCachingTile(
          context: context,
          ref: ref,
        ),

        // Cache Statistics.

        cacheStatsAsync.when(
          data: (stats) => CacheDisplayHelpers.buildCacheStatistics(
            context: context,
            stats: stats,
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Cache Actions.

        buildListTile('Force Refresh All', Icons.refresh, () async {
          await _showForceRefreshDialog(
            context,
            ref,
            cachingEnabled,
            cacheOnlyMode,
          );
        }),
        buildListTile(
          'Clear All Cache',
          Icons.delete_sweep,
          () async {
            await _showClearCacheDialog(
              context,
              ref,
              cachingEnabled,
              cacheOnlyMode,
            );
          },
          isDestructive: true,
        ),
        Divider(color: Theme.of(context).dividerColor),
      ],
    );
  }

  /// Clears all cached movie data.

  Future<void> _clearAllCache(WidgetRef ref) async {
    await CacheOperations.clearAllCache(
      ref: ref,
      showSuccessSnackBar: showSuccessSnackBar,
      showErrorSnackBar: showErrorSnackBar,
    );
  }

  /// Shows smart confirmation dialog for clearing cache based on current settings.

  Future<void> _showClearCacheDialog(
    BuildContext context,
    WidgetRef ref,
    bool cachingEnabled,
    bool cacheOnlyMode,
  ) async {
    final confirmed = await CacheDialogBuilders.showClearCacheDialog(
      context: context,
      ref: ref,
      cachingEnabled: cachingEnabled,
      cacheOnlyMode: cacheOnlyMode,
    );

    if (confirmed == true) {
      await _clearAllCache(ref);
    }
  }

  /// Shows dialog for force refresh with offline mode handling.

  Future<void> _showForceRefreshDialog(
    BuildContext context,
    WidgetRef ref,
    bool cachingEnabled,
    bool cacheOnlyMode,
  ) async {
    final confirmed = await CacheDialogBuilders.showForceRefreshDialog(
      context: context,
      ref: ref,
      cacheOnlyMode: cacheOnlyMode,
    );

    if (!context.mounted) return;

    if (confirmed == true && context.mounted) {
      await _forceRefreshAll(context, ref);
    }
  }

  /// Forces refresh of all movie categories.

  Future<void> _forceRefreshAll(BuildContext context, WidgetRef ref) async {
    await CacheOperations.forceRefreshAll(
      context: context,
      ref: ref,
    );
  }
}
