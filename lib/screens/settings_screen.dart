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
/// Authors: Kevin Wang, Tony Chen.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:moviestar/core/services/api/key_service.dart';
import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/core/services/favorites/favorites_service_manager.dart';
import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/shared/widgets/settings/api_settings_panel.dart';
import 'package:moviestar/shared/widgets/settings/cache_management_panel.dart';
import 'package:moviestar/shared/widgets/settings/pod_settings_panel.dart';
import 'package:moviestar/shared/widgets/settings/preferences_panel.dart';
import 'package:moviestar/widgets/base_screen.dart';

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
  @override
  void initState() {
    super.initState();
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
          ApiSettingsPanel(
            buildSection: _buildSection,
            apiKeyService: widget.apiKeyService,
            fromApiKeyPrompt: widget.fromApiKeyPrompt,
          ),
          PodSettingsPanel(
            buildSection: _buildSection,
            buildSwitchTile: _buildSwitchTile,
            favoritesServiceManager: widget.favoritesServiceManager,
            showSuccessSnackBar: showSuccessSnackBar,
            showErrorSnackBar: showErrorSnackBar,
            hideCurrentSnackBar: hideCurrentSnackBar,
          ),
          CacheManagementPanel(
            buildSwitchTile: _buildSwitchTile,
            buildListTile: _buildListTile,
            showSuccessSnackBar: showSuccessSnackBar,
            showErrorSnackBar: showErrorSnackBar,
          ),
          PreferencesPanel(
            buildSection: _buildSection,
            buildSwitchTile: _buildSwitchTile,
            buildListTile: _buildListTile,
          ),
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

  /// Triggers app reinitialization after API key is set.
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
