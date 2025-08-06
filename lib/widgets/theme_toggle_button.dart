/// Theme toggle button widget for switching between light and dark modes.
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
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:moviestar/providers/theme_provider.dart';

/// A widget that displays a theme toggle button.

class ThemeToggleButton extends ConsumerWidget {
  /// Whether to show as an icon button or a regular button.

  final bool isIconButton;

  /// Custom icon for light mode (defaults to sun icon).

  final IconData? lightModeIcon;

  /// Custom icon for dark mode (defaults to moon icon).

  final IconData? darkModeIcon;

  /// Tooltip text for the button.

  final String? tooltip;

  /// Creates a new [ThemeToggleButton] widget.

  const ThemeToggleButton({
    super.key,
    this.isIconButton = true,
    this.lightModeIcon,
    this.darkModeIcon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeModeNotifier = ref.read(themeModeProvider.notifier);

    final isDarkMode = themeMode == ThemeMode.dark;
    final icon =
        isDarkMode
            ? (lightModeIcon ?? Icons.light_mode)
            : (darkModeIcon ?? Icons.dark_mode);

    if (isIconButton) {
      return MarkdownTooltip(
        message: '''

**Theme Toggle**

${isDarkMode ? '☀️ Switch to **Light Mode**' : '🌙 Switch to **Dark Mode**'}

Tap to toggle between light and dark themes for better viewing experience.

        ''',
        child: IconButton(
          icon: Icon(icon),
          onPressed: () async {
            await themeModeNotifier.toggleTheme();
          },
        ),
      );
    } else {
      return MarkdownTooltip(
        message: '''

**Theme Toggle**

${isDarkMode ? '☀️ Switch to **Light Mode**' : '🌙 Switch to **Dark Mode**'}

Click to toggle between light and dark themes.

        ''',
        child: ElevatedButton.icon(
          onPressed: () async {
            await themeModeNotifier.toggleTheme();
          },
          icon: Icon(icon, size: 18),
          label: Text(isDarkMode ? 'Light' : 'Dark'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      );
    }
  }
}
