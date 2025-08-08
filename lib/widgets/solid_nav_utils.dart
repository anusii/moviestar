/// Solid Navigation Utilities.
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:version_widget/version_widget.dart';

import 'package:moviestar/widgets/solid_nav_models.dart';

/// Utility class for navigation components.
///
/// This class provides high-level functions for creating navigation elements
/// that can be used across different applications without coupling to specific
/// app logic.

class SolidNavUtils {
  /// Creates a generic responsive AppBar with configurable actions.
  ///
  /// This method provides a complete AppBar implementation that handles:
  /// - Responsive design (adapts to screen width)
  /// - Action buttons with tooltips
  /// - Overflow menu for narrow screens
  /// - Version display
  /// - Theme toggle
  /// - Proper colour theming

  static AppBar createAppBar({
    required BuildContext context,
    required SolidAppBarConfig config,
    WidgetRef? ref,
  }) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < config.narrowScreenThreshold;
    final isVeryNarrow = screenWidth < config.veryNarrowScreenThreshold;

    return AppBar(
      title: Text(config.title),
      backgroundColor: config.backgroundColor ?? theme.colorScheme.surface,
      actions: [
        // Version widget - hide on very narrow screens.

        if (config.versionConfig != null && !isVeryNarrow)
          _buildVersionWidget(config.versionConfig!, isNarrow),

        if (config.versionConfig != null && !isVeryNarrow) 
          const SizedBox(width: 8),

        // Regular action buttons.

        ...config.actions
            .where((action) => 
                (!isNarrow || !action.hideOnNarrowScreen) &&
                (!isVeryNarrow || !action.hideOnVeryNarrowScreen))
            .map((action) => _buildActionButton(context, action)),

        // Theme toggle - hide on very narrow screens.

        if (config.themeConfig?.enabled == true && !isVeryNarrow && ref != null)
          _buildThemeToggle(context, config.themeConfig!, ref),

        // Overflow menu for narrow screens.

        if (isVeryNarrow && config.overflowItems.isNotEmpty)
          _buildOverflowMenu(context, config, ref),
      ],
    );
  }

  /// Creates a SolidNavUserInfo from user configuration.

  static SolidNavUserInfo createUserInfo(SolidNavUserConfig config) {
    return SolidNavUserInfo(
      userName: config.userName,
      webId: config.userId,
      showWebId: config.showUserId,
      avatar: config.avatar,
      avatarIcon: config.avatarIcon,
      avatarSize: config.avatarSize,
    );
  }

  /// Validates if a list of tabs has valid indices.

  static bool validateTabSelection(List<SolidNavTab> tabs, int selectedIndex) {
    return selectedIndex >= 0 && selectedIndex < tabs.length;
  }

  /// Finds a tab by title (case-insensitive).

  static int? findTabIndexByTitle(List<SolidNavTab> tabs, String title) {
    for (int i = 0; i < tabs.length; i++) {
      if (tabs[i].title.toLowerCase() == title.toLowerCase()) {
        return i;
      }
    }
    return null;
  }

  /// Builds a version widget with proper tooltip.

  static Widget _buildVersionWidget(SolidVersionConfig config, bool isNarrow) {
    final widget = VersionWidget(
      version: config.version,
      changelogUrl: config.changelogUrl,
      showDate: config.showDate && !isNarrow,
    );

    if (config.tooltip != null) {
      return MarkdownTooltip(
        message: config.tooltip!,
        child: widget,
      );
    }

    return widget;
  }

  /// Builds an action button with proper theming and tooltip.

  static Widget _buildActionButton(BuildContext context, SolidAppBarAction action) {
    final theme = Theme.of(context);
    final button = IconButton(
      icon: Icon(
        action.icon,
        color: action.color ?? theme.colorScheme.primary,
      ),
      onPressed: action.onPressed,
    );

    if (action.tooltip != null) {
      return MarkdownTooltip(
        message: action.tooltip!,
        child: button,
      );
    }

    return button;
  }

  /// Builds a theme toggle button with proper theming.

  static Widget _buildThemeToggle(
    BuildContext context,
    SolidThemeConfig config,
    WidgetRef ref,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        return MarkdownTooltip(
          message: isDarkMode ? config.lightModeTooltip : config.darkModeTooltip,
          child: IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () async {
              if (config.onToggle != null) {
                await config.onToggle!();
              }
            },
          ),
        );
      },
    );
  }

  /// Builds an overflow menu for narrow screens.

  static Widget _buildOverflowMenu(
    BuildContext context,
    SolidAppBarConfig config,
    WidgetRef? ref,
  ) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: theme.colorScheme.primary,
      ),
      onSelected: (value) {
        final item = config.overflowItems.firstWhere(
          (item) => item.id == value,
        );
        item.onSelected();
      },
      itemBuilder: (context) => config.overflowItems
          .where((item) => item.showInOverflow)
          .map((item) => PopupMenuItem<String>(
                value: item.id,
                child: Row(
                  children: [
                    Icon(item.icon),
                    const SizedBox(width: 8),
                    Text(item.label),
                  ],
                ),
              ))
          .toList(),
    );
  }

  /// Creates a list of navigation tabs.

  static List<SolidNavTab> createNavTabs(List<Map<String, dynamic>> tabConfigs) {
    return tabConfigs.map((config) => SolidNavTab(
      title: config['title'] as String,
      icon: config['icon'] as IconData,
      tooltip: config['tooltip'] as String?,
      content: config['content'] as Widget?,
      message: config['message'] as String?,
      dialogTitle: config['dialogTitle'] as String?,
      action: config['action'] as void Function(BuildContext)?,
    )).toList();
  }
}
