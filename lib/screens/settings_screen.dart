/// Screen for managing user settings and preferences.
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
/// Authors: Kevin Wang

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:moviestar/database/movie_cache_repository.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/services/api_key_service.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/services/favorites_service_manager.dart';
import 'package:moviestar/widgets/cache_feedback_widget.dart';
import 'package:moviestar/widgets/theme_toggle_button.dart';

/// A screen that displays and manages user settings.

class SettingsScreen extends ConsumerStatefulWidget {
  /// Service for managing favorite movies.

  final FavoritesService favoritesService;
  final FavoritesServiceManager? favoritesServiceManager;
  final ApiKeyService apiKeyService;

  /// Whether this screen was opened from the API key prompt.

  final bool fromApiKeyPrompt;

  /// Creates a new [SettingsScreen] widget.

  const SettingsScreen({
    super.key,
    required this.favoritesService,
    required this.apiKeyService,
    this.favoritesServiceManager,
    this.fromApiKeyPrompt = false,
  });

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

/// State class for the settings screen.

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// Whether notifications are enabled.

  bool _notificationsEnabled = true;

  /// Whether auto-play is enabled.

  bool _autoPlayEnabled = true;

  /// Whether POD storage is enabled.

  bool _podStorageEnabled = false;

  /// Selected language for the app.

  String _selectedLanguage = 'English';

  /// Selected video quality.

  String _selectedQuality = 'High';

  /// Controller for the API key input field.

  late final TextEditingController _apiKeyController;

  /// Focus node for the API key input field.

  final FocusNode _apiKeyFocusNode = FocusNode();

  /// Launch a URL in the browser.

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  /// Clears all cached movie data.

  Future<void> _clearAllCache() async {
    try {
      final cachedService = ref.read(configuredCachedMovieServiceProvider);
      await cachedService.clearAllCache();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All cached movie data cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear cache: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Shows smart confirmation dialog for clearing cache based on current settings.

  Future<void> _showClearCacheDialog(
    bool cachingEnabled,
    bool cacheOnlyMode,
  ) async {
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dialogTitle),
        content: Text(dialogContent),
        actions: actions,
      ),
    );

    if (confirmed == true) {
      await _clearAllCache();

      // Show additional warning if they cleared cache in cache-only mode.

      if (cachingEnabled && cacheOnlyMode && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '''
Cache cleared! You're now in Offline Mode with no cached data. Consider disabling Offline Mode to load fresh data.''',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Shows smart confirmation dialog for force refresh based on current settings.

  Future<void> _showForceRefreshDialog(
    bool cachingEnabled,
    bool cacheOnlyMode,
  ) async {
    if (cacheOnlyMode) {
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
        // Disable offline mode temporarily
        ref.read(cacheOnlyModeProvider.notifier).setCacheOnlyMode(false);

        // Show feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offline Mode disabled. Refreshing all data...'),
              backgroundColor: Colors.blue,
            ),
          );
        }

        // Now do the refresh.

        await _forceRefreshAll();
      }
    } else {
      // Normal case - just refresh.

      await _forceRefreshAll();
    }
  }

  /// Forces refresh of all movie categories.

  Future<void> _forceRefreshAll() async {
    try {
      if (mounted) {
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
                SizedBox(width: 16),
                Text('Refreshing all movie data...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }

      final cachedService = ref.read(configuredCachedMovieServiceProvider);
      await cachedService.forceRefreshAll();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All movie data refreshed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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

  /// Enable POD storage and migrate data.

  Future<void> _enablePodStorage() async {
    if (widget.favoritesServiceManager == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('POD storage manager not available.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show loading indicator.

    if (mounted) {
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
              SizedBox(width: 16),
              Text('Enabling POD storage...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );
    }

    try {
      final success = await widget.favoritesServiceManager!.enablePodStorage();

      if (success) {
        setState(() => _podStorageEnabled = true);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '''
POD storage enabled successfully! Your movie lists are now stored in your Solid POD.''',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        setState(() => _podStorageEnabled = false);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '''
Failed to enable POD storage. Please check your Solid POD login and try again.''',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _podStorageEnabled = false);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enabling POD storage: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Disable POD storage and revert to local storage.

  Future<void> _disablePodStorage() async {
    if (widget.favoritesServiceManager == null) return;

    try {
      await widget.favoritesServiceManager!.disablePodStorage();
      setState(() => _podStorageEnabled = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('POD storage disabled. Using local storage.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error disabling POD storage: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _loadApiKey();

    // Initialise POD storage state from service manager.

    if (widget.favoritesServiceManager != null) {
      _podStorageEnabled = widget.favoritesServiceManager!.isPodStorageEnabled;
    }

    // If navigated from API key prompt, scroll to the API key section and focus the field.

    if (widget.fromApiKeyPrompt) {
      // Use post-frame callback to ensure the widget is fully built.

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _apiKeyFocusNode.requestFocus();
      });
    }
  }

  /// Loads the API key from secure storage.

  Future<void> _loadApiKey() async {
    final apiKey = await widget.apiKeyService.getApiKey();
    if (mounted) {
      _apiKeyController.text = apiKey ?? '';
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiKeyFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          'Settings',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),

          // Profile Picture.
          Center(
            child: Stack(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Settings Sections.
          _buildSection('API Configuration', [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MovieDB API Key',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: const Text(
                          'Required to fetch movie data and images',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                      if (widget.fromApiKeyPrompt)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Required',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _apiKeyController,
                    style: Theme.of(context).textTheme.bodyLarge,
                    focusNode: _apiKeyFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Enter your MovieDB API key',
                      hintStyle:
                          Theme.of(context).inputDecorationTheme.hintStyle,
                      filled: true,
                      fillColor:
                          Theme.of(context).inputDecorationTheme.fillColor,
                      border: Theme.of(context).inputDecorationTheme.border,
                      enabledBorder:
                          Theme.of(context).inputDecorationTheme.enabledBorder,
                      focusedBorder:
                          Theme.of(context).inputDecorationTheme.focusedBorder,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      // Launch TMDB website to get API key.

                      final Uri url = Uri.parse(
                        'https://www.themoviedb.org/?language=en-AU',
                      );
                      _launchUrl(url);
                    },
                    child: const Text(
                      'Get your API key from The Movie Database (TMDB)',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await widget.apiKeyService.setApiKey(
                        _apiKeyController.text,
                      );

                      if (!context.mounted) return;

                      if (mounted) {
                        // Show success message.

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('API key saved successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // If we navigated here from the API key prompt, navigate back to home.

                        if (widget.fromApiKeyPrompt) {
                          _navigateToHomeScreen();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save API Key'),
                  ),
                ],
              ),
            ),
          ]),
          _buildSection('Data Storage', [
            _buildSwitchTile(
              'Use Solid POD Storage',
              'Store movie lists in your Solid POD instead of locally',
              _podStorageEnabled,
              (value) async {
                if (value) {
                  await _enablePodStorage();
                } else {
                  await _disablePodStorage();
                }
              },
            ),
          ]),
          _buildSection('Appearance', [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Theme',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Switch between light and dark mode',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const ThemeToggleButton(isIconButton: true),
                    ],
                  ),
                ],
              ),
            ),
          ]),
          _buildSection('Preferences', [
            _buildSwitchTile(
              'Notifications',
              'Get notified about new releases',
              _notificationsEnabled,
              (value) => setState(() => _notificationsEnabled = value),
            ),
            _buildSwitchTile(
              'Auto-play',
              'Play next episode automatically',
              _autoPlayEnabled,
              (value) => setState(() => _autoPlayEnabled = value),
            ),
          ]),
          _buildCacheSection(),
          _buildSection('Playback', [
            _buildDropdownTile(
              'Language',
              _selectedLanguage,
              ['English', 'Spanish', 'French', 'German'],
              (value) => setState(() => _selectedLanguage = value!),
            ),
            _buildDropdownTile(
              'Video Quality',
              _selectedQuality,
              ['Low', 'Medium', 'High', 'Auto'],
              (value) => setState(() => _selectedQuality = value!),
            ),
          ]),
          _buildSection('Account', [
            _buildListTile('Help & Support', Icons.help_outline, () {
              // TODO: Navigate to Help & Support.
            }),
            _buildListTile('Sign Out', Icons.logout, () {
              // TODO: Implement sign out.
            }, isDestructive: true),
          ]),
        ],
      ),
    );
  }

  /// Builds the cache management section.

  Widget _buildCacheSection() {
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
        _buildSwitchTile(
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
        _buildOfflineModeTile(cachingEnabled, cacheOnlyMode),

        // Cache Statistics.
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
                            const SizedBox(width: 8),
                            Text(
                              'Cache Statistics',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...stats.entries.map((entry) {
                          final category = entry.key;
                          final stat = entry.value;
                          final categoryName = _getCategoryDisplayName(
                            category,
                          );

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
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    Text(
                                      'Updated ${_getTimeAgo(stat.age)} ago',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      stat.isValid
                                          ? Icons.check_circle
                                          : Icons.schedule,
                                      size: 16,
                                      color: stat.isValid
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      stat.isValid
                                          ? '${stat.movieCount} movies'
                                          : 'Expired',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
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

        // Cache Actions.
        _buildListTile('Force Refresh All', Icons.refresh, () async {
          await _showForceRefreshDialog(cachingEnabled, cacheOnlyMode);
        }),
        _buildListTile('Clear All Cache', Icons.delete_sweep, () async {
          await _showClearCacheDialog(cachingEnabled, cacheOnlyMode);
        }, isDestructive: true),
        Divider(color: Theme.of(context).dividerColor),
      ],
    );
  }

  /// Gets display name for cache category.

  String _getCategoryDisplayName(CacheCategory category) {
    switch (category) {
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

  /// Gets human-readable time ago string.

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

  /// Builds the offline mode tile with proper enabled/disabled state.

  Widget _buildOfflineModeTile(bool cachingEnabled, bool cacheOnlyMode) {
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

              if (mounted) {
                CacheFeedbackWidget.showOfflineModeNotification(
                  context,
                  isEnabled: value,
                );
              }
            }
          : null,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  /// Builds a section of settings with a title and children widgets.

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        Divider(color: Theme.of(context).dividerColor),
      ],
    );
  }

  /// Builds a switch tile for boolean settings.

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  /// Builds a dropdown tile for selection settings.

  Widget _buildDropdownTile(
    String title,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return ListTile(
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      trailing: DropdownButton<String>(
        value: value,
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }).toList(),
        onChanged: onChanged,
        dropdownColor: Theme.of(context).cardColor,
        underline: const SizedBox(),
      ),
    );
  }

  /// Builds a list tile for navigation items.

  Widget _buildListTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).iconTheme.color,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      onTap: onTap,
    );
  }

  void _navigateToHomeScreen() {
    // Navigate back to the main home screen.

    Navigator.of(context).popUntil((route) => route.isFirst);

    // Find the MyHomePage instance.

    final scaffoldContext = context;

    // Try to find the nearest ancestor of type MyHomePage (or its State) and select the Home tab (index 0).

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use the scaffold to show a message to the user.

      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        const SnackBar(
          content: Text('Movie data will now load with your new API key'),
          backgroundColor: Colors.blue,
        ),
      );
    });
  }
}
