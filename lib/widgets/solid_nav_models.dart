/// Solid Navigation Models - Generic data models for navigation components.
///
// Time-stamp: <Tuesday 2025-08-06 16:30:00 +1000 Tony Chen>
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
/// Authors: Tony Chen

library;

import 'package:flutter/material.dart';

/// Configuration for a navigation tab.

class SolidNavTab {
  /// The display title of the tab.

  final String title;

  /// The icon to display for the tab.

  final IconData icon;

  /// Optional custom colour for the icon. If null, uses theme default.

  final Color? color;

  /// The content widget to display when this tab is selected.

  final Widget? content;

  /// Optional tooltip message for the tab (supports Markdown).

  final String? tooltip;

  /// Optional dialog message to show when tab is selected.

  final String? message;

  /// Optional dialog title when showing a message.

  final String? dialogTitle;

  /// Optional custom action to execute when tab is selected.

  final void Function(BuildContext)? action;

  const SolidNavTab({
    required this.title,
    required this.icon,
    this.color,
    this.content,
    this.tooltip,
    this.message,
    this.dialogTitle,
    this.action,
  });
}

/// User information configuration for the navigation drawer.

class SolidNavUserInfo {
  /// The user's display name.

  final String userName;

  /// The user's WebID (optional).

  final String? webId;

  /// Whether to show the WebID in the drawer.

  final bool showWebId;

  /// Custom user avatar widget (optional).

  final Widget? avatar;

  /// Custom user avatar icon (used if avatar widget is null).

  final IconData? avatarIcon;

  /// Custom avatar size.

  final double? avatarSize;

  const SolidNavUserInfo({
    required this.userName,
    this.webId,
    this.showWebId = false,
    this.avatar,
    this.avatarIcon,
    this.avatarSize,
  });
}

/// Configuration for an AppBar action button.

class SolidAppBarAction {
  /// The icon to display.

  final IconData icon;

  /// The tooltip message to show on hover/long press.

  final String? tooltip;

  /// The callback when the button is pressed.

  final VoidCallback onPressed;

  /// Custom colour for the icon. If null, uses theme primary colour.

  final Color? color;

  /// Whether this action should be hidden on narrow screens.

  final bool hideOnNarrowScreen;

  /// Whether this action should be hidden on very narrow screens.

  final bool hideOnVeryNarrowScreen;

  const SolidAppBarAction({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.hideOnNarrowScreen = false,
    this.hideOnVeryNarrowScreen = false,
  });
}

/// Configuration for an overflow menu item.

class SolidOverflowMenuItem {
  /// Unique identifier for this menu item.

  final String id;

  /// The icon to display.

  final IconData icon;

  /// The text label to display.

  final String label;

  /// The callback when the item is selected.

  final VoidCallback onSelected;

  /// Whether this item should be shown in the overflow menu.

  final bool showInOverflow;

  const SolidOverflowMenuItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.onSelected,
    this.showInOverflow = true,
  });
}

/// Configuration for version information display.

class SolidVersionConfig {
  /// The version string to display.

  final String version;

  /// The URL to the changelog.

  final String? changelogUrl;

  /// Whether to show the date alongside the version.

  final bool showDate;

  /// The tooltip message for the version widget.

  final String? tooltip;

  const SolidVersionConfig({
    required this.version,
    this.changelogUrl,
    this.showDate = true,
    this.tooltip,
  });
}

/// Configuration for theme toggle functionality.

class SolidThemeConfig {
  /// Whether the theme toggle is enabled.

  final bool enabled;

  /// The tooltip message for light mode.

  final String lightModeTooltip;

  /// The tooltip message for dark mode.

  final String darkModeTooltip;

  /// Custom callback for theme toggle. If null, uses default behaviour.

  final Future<void> Function()? onToggle;

  const SolidThemeConfig({
    this.enabled = true,
    this.lightModeTooltip = 'Switch to light theme',
    this.darkModeTooltip = 'Switch to dark theme',
    this.onToggle,
  });
}

/// Comprehensive configuration for creating an AppBar.

class SolidAppBarConfig {
  /// The title to display in the AppBar.

  final String title;

  /// Background colour for the AppBar. If null, uses theme default.

  final Color? backgroundColor;

  /// List of action buttons to display.

  final List<SolidAppBarAction> actions;

  /// List of overflow menu items for narrow screens.

  final List<SolidOverflowMenuItem> overflowItems;

  /// Version configuration. If null, version widget is not shown.

  final SolidVersionConfig? versionConfig;

  /// Theme toggle configuration. If null, theme toggle is not shown.

  final SolidThemeConfig? themeConfig;

  /// Width threshold for narrow screens.

  final double narrowScreenThreshold;

  /// Width threshold for very narrow screens.

  final double veryNarrowScreenThreshold;

  const SolidAppBarConfig({
    required this.title,
    this.backgroundColor,
    this.actions = const [],
    this.overflowItems = const [],
    this.versionConfig,
    this.themeConfig,
    this.narrowScreenThreshold = 800.0,
    this.veryNarrowScreenThreshold = 600.0,
  });
}

/// Configuration for navigation drawer user information.

class SolidNavUserConfig {
  /// The user's display name.

  final String userName;

  /// The user's WebID or identifier (optional).

  final String? userId;

  /// Whether to show the user ID in the drawer.

  final bool showUserId;

  /// Custom user avatar widget (optional).

  final Widget? avatar;

  /// Custom user avatar icon (used if avatar widget is null).

  final IconData? avatarIcon;

  /// Custom avatar size.

  final double? avatarSize;

  /// Background colour for the user header.

  final Color? headerBackgroundColor;

  /// Text colour for the user header.

  final Color? headerTextColor;

  const SolidNavUserConfig({
    required this.userName,
    this.userId,
    this.showUserId = false,
    this.avatar,
    this.avatarIcon,
    this.avatarSize,
    this.headerBackgroundColor,
    this.headerTextColor,
  });
}

/// Configuration for logout functionality.

class SolidLogoutConfig {
  /// Whether to show logout option.

  final bool enabled;

  /// Custom logout icon.

  final IconData icon;

  /// Custom logout text.

  final String text;

  /// The logout callback.

  final void Function(BuildContext) onLogout;

  /// Custom colour for logout elements.

  final Color? color;

  const SolidLogoutConfig({
    this.enabled = true,
    this.icon = Icons.logout,
    this.text = 'Logout',
    required this.onLogout,
    this.color,
  });
}
