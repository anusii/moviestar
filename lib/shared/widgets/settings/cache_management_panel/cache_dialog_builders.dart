/// Cache dialog builders for cache management panel.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/providers/cached_movie_service_provider.dart';

/// Static helper class for building cache-related dialogs.

class CacheDialogBuilders {
  /// Shows smart confirmation dialog for clearing cache based on current settings.

  static Future<bool?> showClearCacheDialog({
    required BuildContext context,
    required WidgetRef ref,
    required bool cachingEnabled,
    required bool cacheOnlyMode,
  }) async {
    String dialogTitle;
    String dialogContent;
    String confirmButtonText;
    List<Widget> actions;

    if (!cachingEnabled) {
      // Caching is disabled - clearing cache is harmless.

      dialogTitle = 'Clear All Cache';
      dialogContent = '''
This will remove any cached movie data. Since caching is disabled, this won't affect your ability to load movies from the network.''';
      confirmButtonText = 'Clear';
    } else if (cacheOnlyMode) {
      // Offline mode is enabled - this will break the app!

      dialogTitle = '⚠️ Clear Cache in Offline Mode';
      dialogContent = '''
WARNING: You have Offline Mode enabled, which means no network calls are allowed.

Clearing the cache now will leave you with no movie data and no way to fetch new data!

Recommended: Disable Offline Mode first, then clear cache.''';
      confirmButtonText = 'Clear Anyway';
    } else {
      // Normal case - caching enabled but can fallback to network.

      dialogTitle = 'Clear All Cache';
      dialogContent = '''
This will remove all cached movie data. Fresh data will be downloaded from the network when needed.''';
      confirmButtonText = 'Clear';
    }

    actions = [
      TextButton(
        onPressed: () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
      if (cachingEnabled && cacheOnlyMode) ...[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            // Automatically disable offline mode.

            ref.read(cacheOnlyModeProvider.notifier).setCacheOnlyMode(false);
            // Show feedback.

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Offline Mode disabled. You can now clear cache safely.',
                ),
                backgroundColor: Colors.blue,
              ),
            );
          },
          child: const Text('Disable Offline Mode'),
        ),
      ],
      TextButton(
        onPressed: () => Navigator.of(context).pop(true),
        style: cachingEnabled && cacheOnlyMode
            ? TextButton.styleFrom(foregroundColor: Colors.red)
            : null,
        child: Text(confirmButtonText),
      ),
    ];

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dialogTitle),
        content: Text(dialogContent),
        actions: actions,
      ),
    );
  }

  /// Shows dialog for force refresh with offline mode handling.

  static Future<bool?> showForceRefreshDialog({
    required BuildContext context,
    required WidgetRef ref,
    required bool cacheOnlyMode,
  }) async {
    if (!cacheOnlyMode) {
      // Not in offline mode - just proceed with refresh.

      return true;
    }

    // In offline mode, force refresh would require network calls.

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Force Refresh in Offline Mode'),
        content: const Text('''
Force refresh requires downloading fresh data from the network, but you have Offline Mode enabled.

Do you want to temporarily disable Offline Mode and refresh all data?'''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Disable Offline Mode & Refresh'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Disable offline mode temporarily.

      ref.read(cacheOnlyModeProvider.notifier).setCacheOnlyMode(false);

      // Show feedback.

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offline Mode disabled. Refreshing all data...'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }

    return confirmed;
  }
}
