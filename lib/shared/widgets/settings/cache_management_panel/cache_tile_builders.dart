/// Cache tile builders for cache management panel.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/constants/timing_constants.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/widgets/cache_feedback_widget.dart';

/// Static helper class for building cache-related tiles.

class CacheTileBuilders {
  /// Builds the offline mode tile with proper enabled/disabled state.

  static Widget buildOfflineModeTile({
    required BuildContext context,
    required WidgetRef ref,
    required bool cachingEnabled,
    required bool cacheOnlyMode,
  }) {
    return SwitchListTile(
      title: Text(
        'Offline Mode',
        style: cachingEnabled
            ? Theme.of(context).textTheme.bodyLarge
            : Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
      ),
      subtitle: Text(
        cachingEnabled
            ? (cacheOnlyMode
                ? 'Browse movies offline using cached data only'
                : 'Allow network access when cache is empty')
            : 'Enable caching first to use offline mode',
        style: cachingEnabled
            ? Theme.of(context).textTheme.bodyMedium
            : Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
      ),
      value: cacheOnlyMode && cachingEnabled,
      onChanged: cachingEnabled
          ? (value) {
              ref.read(cacheOnlyModeProvider.notifier).setCacheOnlyMode(value);

              // Show feedback about the mode change.

              CacheFeedbackWidget.showOfflineModeNotification(
                context,
                isEnabled: value,
              );
            }
          : null,
      thumbColor:
          WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
    );
  }

  /// Builds the API key caching tile.

  static Widget buildApiKeyCachingTile({
    required BuildContext context,
    required WidgetRef ref,
  }) {
    return Consumer(
      builder: (context, ref, child) {
        final localApiKeyCachingEnabled = ref.watch(localApiKeyCachingProvider);

        return SwitchListTile(
          title: const Text('Local API Key Caching'),
          subtitle: Text(
            localApiKeyCachingEnabled
                ? 'API keys cached locally for offline access (shared across accounts on this device)'
                : 'API keys stored only in your POD (recommended for privacy)',
            style: localApiKeyCachingEnabled
                ? TextStyle(color: Colors.orange[600])
                : TextStyle(color: Colors.green[600]),
          ),
          value: localApiKeyCachingEnabled,
          onChanged: (value) {
            ref
                .read(localApiKeyCachingProvider.notifier)
                .setLocalApiKeyCachingEnabled(value);

            // Show feedback about the change.

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  value
                      ? '⚠️ API key caching enabled. Keys will be shared across accounts on this device.'
                      : '✅ API key caching disabled. Keys stored only in your POD.',
                ),
                backgroundColor: value ? Colors.orange : Colors.green,
                duration: TimingConstants.snackbarLongDuration,
              ),
            );
          },
          secondary: Icon(
            localApiKeyCachingEnabled ? Icons.warning : Icons.security,
            color: localApiKeyCachingEnabled ? Colors.orange : Colors.green,
          ),
        );
      },
    );
  }
}
