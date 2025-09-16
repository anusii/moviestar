/// Data Management Panel Component - Cache Management and Data Operations
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
import 'package:moviestar/core/services/cache/hive_movie_cache_service.dart';
import 'package:moviestar/widgets/cache_feedback_widget.dart';

class DataManagementPanel extends ConsumerWidget {
  final Function(String title, List<Widget> children) buildSection;
  final Function(String title, String subtitle, bool value, ValueChanged<bool> onChanged) buildSwitchTile;
  final Function(String title, IconData icon, VoidCallback onTap, {bool isDestructive}) buildListTile;
  final Function(String message) showSuccessSnackBar;
  final Function(String message) showErrorSnackBar;

  const DataManagementPanel({
    super.key,
    required this.buildSection,
    required this.buildSwitchTile,
    required this.buildListTile,
    required this.showSuccessSnackBar,
    required this.showErrorSnackBar,
  });

  Future<void> _clearAllCache(WidgetRef ref, BuildContext context) async {
    try {
      final cachedService = ref.read(configuredCachedMovieServiceProvider);
      await cachedService.clearAllCache();

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

  Future<void> _showClearCacheDialog(
    WidgetRef ref,
    BuildContext context,
    bool cachingEnabled,
    bool cacheOnlyMode,
  ) async {
    String dialogTitle;
    String dialogContent;
    String confirmButtonText;
    List<Widget> actions;

    if (!cachingEnabled) {
      dialogTitle = 'Clear All Cache';
      dialogContent = '''
This will remove any cached movie data. Since caching is disabled, this won't affect your ability to load movies from the network.''';
      confirmButtonText = 'Clear';
    } else if (cacheOnlyMode) {
      dialogTitle = '⚠️ Clear Cache in Offline Mode';
      dialogContent = '''
WARNING: You have Offline Mode enabled, which means no network calls are allowed.

Clearing the cache now will leave you with no movie data and no way to fetch new data!

Recommended: Disable Offline Mode first, then clear cache.''';
      confirmButtonText = 'Clear Anyway';
    } else {
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
            ref.read(cacheOnlyModeProvider.notifier).setCacheOnlyMode(false);
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dialogTitle),
        content: Text(dialogContent),
        actions: actions,
      ),
    );

    if (confirmed == true) {
      await _clearAllCache(ref, context);

      if (cachingEnabled && cacheOnlyMode && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '''
Cache cleared! You're now in Offline Mode with no cached data. Consider disabling Offline Mode to load fresh data.''',
            ),
            backgroundColor: Colors.orange,
            duration: TimingConstants.snackbarExtendedDuration,
          ),
        );
      }
    }
  }

  Future<void> _showForceRefreshDialog(
    WidgetRef ref,
    BuildContext context,
    bool cachingEnabled,
    bool cacheOnlyMode,
  ) async {
    if (cacheOnlyMode) {
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
        ref.read(cacheOnlyModeProvider.notifier).setCacheOnlyMode(false);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offline Mode disabled. Refreshing all data...'),
              backgroundColor: Colors.blue,
            ),
          );
        }

        await _forceRefreshAll(ref, context);
      }
    } else {
      await _forceRefreshAll(ref, context);
    }
  }

  Future<void> _forceRefreshAll(WidgetRef ref, BuildContext context) async {
    try {
      if (context.mounted) {
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
      }

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

  String _getCategoryDisplayName(CacheCategory category) {
    switch (category) {
      case CacheCategory.toWatch:
        return 'To Watch';
      case CacheCategory.watched:
        return 'Watched';
      case CacheCategory.popular:
        return 'Popular Movies';
      case CacheCategory.nowPlaying:
        return 'Now Playing';
      case CacheCategory.topRated:
        return 'Top Rated';
      case CacheCategory.upcoming:
        return 'Upcoming Movies';
    }
  }

  String _getTimeAgo(Duration duration) {
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

  Widget _buildOfflineModeTile(bool cachingEnabled, bool cacheOnlyMode, WidgetRef ref, BuildContext context) {
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

              if (context.mounted) {
                CacheFeedbackWidget.showOfflineModeNotification(
                  context,
                  isEnabled: value,
                );
              }
            }
          : null,
      thumbColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary),
    );
  }

  Widget _buildApiKeyCachingTile(WidgetRef ref, BuildContext context) {
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

            if (context.mounted) {
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
            }
          },
          secondary: Icon(
            localApiKeyCachingEnabled ? Icons.warning : Icons.security,
            color: localApiKeyCachingEnabled ? Colors.orange : Colors.green,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheStatsAsync = ref.watch(cacheStatsProvider);
    final cachingEnabled = ref.watch(cachingEnabledProvider);
    final cacheOnlyMode = ref.watch(cacheOnlyModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSection('Cache Management', [
          buildSwitchTile(
            'Enable Caching',
            'Cache movie data to improve performance',
            cachingEnabled,
            (value) {
              ref.read(cachingEnabledProvider.notifier).setCachingEnabled(value);
              if (!value && cacheOnlyMode) {
                ref.read(cacheOnlyModeProvider.notifier).setCacheOnlyMode(false);
              }
            },
          ),
          _buildOfflineModeTile(cachingEnabled, cacheOnlyMode, ref, context),
          _buildApiKeyCachingTile(ref, context),

          // Cache Statistics
          cacheStatsAsync.when(
            data: (stats) => stats.isEmpty
                ? const SizedBox.shrink()
                : Card(
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
                            final categoryName = _getCategoryDisplayName(category);

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
                                        'Updated ${_getTimeAgo(stat['age'] as Duration)} ago',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Theme.of(context).textTheme.bodyMedium?.color,
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
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Cache Actions
          buildListTile('Force Refresh All', Icons.refresh, () async {
            await _showForceRefreshDialog(ref, context, cachingEnabled, cacheOnlyMode);
          }),
          buildListTile(
            'Clear All Cache',
            Icons.delete_sweep,
            () async {
              await _showClearCacheDialog(ref, context, cachingEnabled, cacheOnlyMode);
            },
            isDestructive: true,
          ),
        ]),
      ],
    );
  }
}