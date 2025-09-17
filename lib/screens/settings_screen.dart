/// Screen for managing user settings and preferences.
///
// Time-stamp: <Tuesday 2025-09-02 15:11:46 +1000 Graham Williams>
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
/// Authors: Kevin Wang, Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:solidpod/solidpod.dart';
import 'package:solidui/solidui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:moviestar/constants/timing_constants.dart';
import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/providers/theme_provider.dart';
import 'package:moviestar/core/services/api/api_key_service.dart';
import 'package:moviestar/core/services/favorites/favorites_service.dart';
import 'package:moviestar/core/services/favorites/favorites_service_manager.dart';
import 'package:moviestar/utils/create_solid_login.dart';
import 'package:moviestar/utils/is_logged_in.dart';
import 'package:moviestar/widgets/base_screen.dart';
import 'package:moviestar/shared/widgets/settings/cache_management_panel.dart';

/// A screen that displays and manages user settings.

class SettingsScreen extends ConsumerStatefulWidget {
  /// Service for managing favorite movies.

  final FavoritesService favoritesService;
  final FavoritesServiceManager favoritesServiceManager;
  final ApiKeyService apiKeyService;

  /// Whether this screen was opened from the API key prompt.

  final bool fromApiKeyPrompt;

  /// Creates a new [SettingsScreen] widget.

  const SettingsScreen({
    super.key,
    required this.favoritesService,
    required this.apiKeyService,
    required this.favoritesServiceManager,
    this.fromApiKeyPrompt = false,
  });

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

/// State class for the settings screen.

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with ScreenStateMixin {
  /// Whether notifications are enabled.

  bool _notificationsEnabled = true;

  /// Whether auto-play is enabled.

  bool _autoPlayEnabled = true;

  /// Whether POD storage is enabled.

  bool _podStorageEnabled = false;

  /// Whether the API key is visible.

  bool _isApiKeyVisible = false;

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



  /// Enable POD storage and migrate data.

  Future<void> _enablePodStorage() async {
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
              Gap(16),
              Text('Enabling POD storage...'),
            ],
          ),
          duration: TimingConstants.snackbarVeryLongDuration,
        ),
      );
    }

    try {
      final success = await widget.favoritesServiceManager.enablePodStorage();

      if (success) {
        safeSetState(() => _podStorageEnabled = true);
        hideCurrentSnackBar();
        showSuccessSnackBar(
          'POD storage enabled successfully! Your movie lists are now stored in your Solid POD.',
        );
      } else {
        safeSetState(() => _podStorageEnabled = false);
        hideCurrentSnackBar();
        showErrorSnackBar(
          'Failed to enable POD storage. Please check your Solid POD login and try again.',
        );
      }
    } catch (e) {
      safeSetState(() => _podStorageEnabled = false);
      hideCurrentSnackBar();
      showErrorSnackBar('Error enabling POD storage: $e');
    }
  }

  /// Disable POD storage and revert to local storage.

  Future<void> _disablePodStorage() async {
    try {
      await widget.favoritesServiceManager.disablePodStorage();
      setState(() => _podStorageEnabled = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('POD storage disabled. Using local storage.'),
            backgroundColor: Colors.orange,
            duration: TimingConstants.snackbarStandardDuration,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error disabling POD storage: $e'),
            backgroundColor: Colors.red,
            duration: TimingConstants.snackbarStandardDuration,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();

    // Update ApiKeyService context for POD operations.

    widget.apiKeyService.updateContext(context, widget);

    _loadApiKey();

    // Initialise POD storage state - enable by default if user is logged in.

    _initializePodStorageState();

    // If navigated from API key prompt, scroll to the API key section and focus the field.

    if (widget.fromApiKeyPrompt) {
      // Use post-frame callback to ensure the widget is fully built.

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _apiKeyFocusNode.requestFocus();
      });
    }
  }

  /// Initialises POD storage state, enabling by default for logged-in users.

  Future<void> _initializePodStorageState() async {
    {
      // Check if user is logged in.

      final loggedIn = await isLoggedIn();

      // If user is logged in and POD storage is not explicitly disabled,
      // enable it by default.

      if (loggedIn && !widget.favoritesServiceManager.isPodStorageEnabled) {
        // Enable POD storage silently for logged-in users.

        setState(() {
          _podStorageEnabled = true;
        });

        // Try to enable POD storage in the background.

        try {
          await widget.favoritesServiceManager.enablePodStorage();
        } catch (e) {
          // If enabling fails, revert to current state.

          if (mounted) {
            setState(() {
              _podStorageEnabled =
                  widget.favoritesServiceManager.isPodStorageEnabled;
            });
          }
        }
      } else {
        // Use current state from service manager.

        _podStorageEnabled = widget.favoritesServiceManager.isPodStorageEnabled;
      }
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
    return BaseScreenFactory.forSettings(
      title: 'Settings',
      body: ListView(
        children: [
          const Gap(20),

          // Profile Picture.

          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
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
                    child: Icon(
                      Icons.edit,
                      size: 20,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(20),

          // Settings Sections.
          _buildSection('API Configuration', [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MovieDB API Key',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const Gap(4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Required to fetch movie data and images',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(fontSize: 12),
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
                  const Gap(8),
                  SizedBox(
                    width: 420,
                    child: TextField(
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
                        enabledBorder: Theme.of(
                          context,
                        ).inputDecorationTheme.enabledBorder,
                        focusedBorder: Theme.of(
                          context,
                        ).inputDecorationTheme.focusedBorder,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isApiKeyVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          onPressed: () {
                            setState(() {
                              _isApiKeyVisible = !_isApiKeyVisible;
                            });
                          },
                          tooltip: _isApiKeyVisible
                              ? 'Hide API key'
                              : 'Show API key',
                        ),
                      ),
                      obscureText: !_isApiKeyVisible,
                    ),
                  ),
                  const Gap(8),
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
                  const Gap(16),
                  ElevatedButton(
                    onPressed: () async {
                      await widget.apiKeyService.setApiKey(
                        _apiKeyController.text,
                      );

                      if (!context.mounted) return;

                      if (mounted) {
                        // Invalidate all movie providers to force refresh with new API key.
                        // IMPORTANT: Must invalidate apiKeyProvider first so dependent providers refresh
                        ref.invalidate(apiKeyProvider);
                        ref.invalidate(popularMoviesWithCacheInfoProvider);
                        ref.invalidate(nowPlayingMoviesWithCacheInfoProvider);
                        ref.invalidate(topRatedMoviesWithCacheInfoProvider);
                        ref.invalidate(upcomingMoviesWithCacheInfoProvider);
                        ref.invalidate(movieServiceProvider);
                        ref.invalidate(contentServiceProvider);

                        // Give providers time to refresh before showing success message
                        await Future.delayed(const Duration(milliseconds: 100));

                        // Show success message.
                        if (context.mounted) {
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

                          // Trigger app reinitialization after API key is set
                          // This will properly initialize POD folders and data loading
                          _triggerAppReinitialization();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
                          const Gap(4),
                          Text(
                            'Switch between light and dark mode',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      AnimatedBuilder(
                        animation: solidThemeNotifier,
                        builder: (context, _) {
                          final themeMode = solidThemeNotifier.themeMode;
                          return Icon(
                            themeMode == ThemeMode.dark
                                ? Icons.dark_mode
                                : themeMode == ThemeMode.light
                                    ? Icons.light_mode
                                    : Icons.computer,
                            color: Theme.of(context).colorScheme.primary,
                          );
                        },
                      ),
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
          CacheManagementPanel(
            buildSwitchTile: _buildSwitchTile,
            buildListTile: _buildListTile,
            showSuccessSnackBar: showSuccessSnackBar,
            showErrorSnackBar: showErrorSnackBar,
          ),
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
            _buildListTile(
              'Sign Out',
              Icons.logout,
              () async {
                // Show logout confirmation dialog and handle logout.

                final prefs = ref.read(sharedPreferencesProvider);

                // Create a properly configured SolidLogin widget using the same function
                // that creates the initial login screen to maintain consistent branding.

                final solidLoginWidget = createSolidLogin(context, prefs);

                await logoutPopup(context, solidLoginWidget);
              },
              isDestructive: true,
            ),
          ]),
        ],
      ),
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
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      value: value,
      onChanged: onChanged,
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

  /// Triggers app reinitialization after API key is set
  void _triggerAppReinitialization() {
    // The provider invalidations we added earlier will handle the reinitialization
    // No additional action needed here since the providers are already invalidated
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
