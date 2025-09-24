/// Preferences Panel Component - UI Preferences, Playback Settings and Account Management.
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
import 'package:solidpod/solidpod.dart' show logoutPopup;
import 'package:solidui/solidui.dart';

import 'package:moviestar/providers/theme_provider.dart';
import 'package:moviestar/utils/create_solid_login.dart';

class PreferencesPanel extends ConsumerStatefulWidget {
  final Function(String title, List<Widget> children) buildSection;
  final Function(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) buildSwitchTile;
  final Function(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive,
  }) buildListTile;

  const PreferencesPanel({
    super.key,
    required this.buildSection,
    required this.buildSwitchTile,
    required this.buildListTile,
  });

  @override
  ConsumerState<PreferencesPanel> createState() => _PreferencesPanelState();
}

class _PreferencesPanelState extends ConsumerState<PreferencesPanel> {
  /// Whether notifications are enabled.
  bool _notificationsEnabled = true;

  /// Whether auto-play is enabled.
  bool _autoPlayEnabled = true;

  /// Selected language for the app.
  String _selectedLanguage = 'English';

  /// Selected video quality.
  String _selectedQuality = 'High';

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
        style: Theme.of(context).textTheme.bodyMedium,
        underline: Container(
          height: 2,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Appearance Section.

        widget.buildSection('Appearance', [
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

        // Preferences Section.

        widget.buildSection('Preferences', [
          widget.buildSwitchTile(
            'Notifications',
            'Get notified about new releases',
            _notificationsEnabled,
            (value) => setState(() => _notificationsEnabled = value),
          ),
          widget.buildSwitchTile(
            'Auto-play',
            'Play next episode automatically',
            _autoPlayEnabled,
            (value) => setState(() => _autoPlayEnabled = value),
          ),
        ]),

        // Playback Section.

        widget.buildSection('Playback', [
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

        // Account Section.

        widget.buildSection('Account', [
          widget.buildListTile('Help & Support', Icons.help_outline, () {
            // TODO: Navigate to Help & Support.
          }),
          widget.buildListTile(
            'Sign Out',
            Icons.logout,
            () async {
              // Show logout confirmation dialog and handle logout.

              final prefs = ref.read(sharedPreferencesProvider);

              // Create a properly configured SolidLogin widget using the same function.
              // that creates the initial login screen to maintain consistent branding.

              final solidLoginWidget = createSolidLogin(context, prefs);

              await logoutPopup(context, solidLoginWidget);
            },
            isDestructive: true,
          ),
        ]),
      ],
    );
  }
}
