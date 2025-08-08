/// Navigation utilities for Solid navigation system.
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

import 'package:moviestar/constants/navigation_constants.dart';
import 'package:moviestar/providers/theme_provider.dart';
import 'package:moviestar/widgets/solid_nav_bar.dart';
import 'package:moviestar/widgets/solid_nav_drawer.dart';

/// Utility class for navigation-related helper functions.

class SolidNavUtils {
  /// Creates a SolidNavUserInfo from basic user information.

  static SolidNavUserInfo createUserInfo({
    required String userName,
    String? webId,
    bool showWebId = false,
  }) {
    return SolidNavUserInfo(
      userName: userName,
      webId: webId,
      showWebId: showWebId,
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

  /// Creates a MovieStar-specific AppBar with responsive design.
  ///
  /// This method handles the complex logic for creating an AppBar that adapts
  /// to different screen sizes and includes all necessary action buttons.

  static AppBar createMovieStarAppBar({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String appVersion,
    required bool isVersionLoaded,
    required VoidCallback onRefresh,
    required VoidCallback onSearch,
    required VoidCallback onSettings,
    required VoidCallback onLogout,
  }) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryNarrow = screenWidth < NavigationConstants.veryNarrowScreenThreshold;
    final isNarrow = screenWidth < NavigationConstants.narrowScreenThreshold;

    return AppBar(
      title: Text(title),
      backgroundColor: theme.colorScheme.surface,
      actions: [
        // Version widget - hide on very narrow screens.
        if (isVersionLoaded && !isVeryNarrow)
          MarkdownTooltip(
            message: '''

            **Version:** This is the current version of the MovieStar app. If
            the version is out of date then the text will be red. You can tap on
            the version to view the app's Change Log to determine if it is worth
            updating your version.

            ''',
            child: VersionWidget(
              version: appVersion,
              changelogUrl:
                  'https://github.com/anusii/moviestar/blob/dev/CHANGELOG.md',
              showDate: !isNarrow, // Hide date on narrow screens.
            ),
          ),

        if (!isVeryNarrow) const SizedBox(width: 8), // Reduced spacing.

        // Essential buttons - always show.
        MarkdownTooltip(
          message: '''

          **Refresh:** Tap here to refresh all movie data and reload the latest
          information from the movie database.

          ''',
          child: IconButton(
            icon: Icon(
              Icons.refresh,
              color: theme.colorScheme.primary,
            ),
            onPressed: onRefresh,
          ),
        ),

        // Search button.
        MarkdownTooltip(
          message: '''

          **Search:** Tap here to search for movies by title, genre, or other
          criteria.

          ''',
          child: IconButton(
            icon: Icon(
              Icons.search,
              color: theme.colorScheme.primary,
            ),
            onPressed: onSearch,
          ),
        ),

        // Theme toggle - hide on very narrow screens.
        if (!isVeryNarrow)
          Consumer(
            builder: (context, ref, child) {
              final themeMode = ref.watch(themeModeProvider);
              final isDarkMode = themeMode == ThemeMode.dark;
              return MarkdownTooltip(
                message: '''

                **Theme Toggle:** Tap here to switch between light and dark themes.

                ''',
                child: IconButton(
                  icon: Icon(
                    isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () async {
                    await ref.read(themeModeProvider.notifier).toggleTheme();
                  },
                ),
              );
            },
          ),

        // Overflow menu for narrow screens.
        if (isVeryNarrow)
          _buildOverflowMenu(
            context,
            ref,
            theme,
            isVersionLoaded,
            appVersion,
            onSettings,
            onLogout,
          )
        else ...[
          // Settings and logout buttons for wider screens.
          MarkdownTooltip(
            message: '''

            **Settings:** Tap here to view and manage your MovieStar account
            settings.

            ''',
            child: IconButton(
              icon: Icon(
                Icons.settings,
                color: theme.colorScheme.primary,
              ),
              onPressed: onSettings,
            ),
          ),

          MarkdownTooltip(
            message: '''

            **Logout:** Tap here to securely log out of your MovieStar account.
            This will clear your current session and return you to the login
            screen.

            ''',
            child: IconButton(
              icon: Icon(
                Icons.logout,
                color: theme.colorScheme.primary,
              ),
              onPressed: onLogout,
            ),
          ),
        ],
      ],
    );
  }

  /// Builds the overflow menu for very narrow screens.

  static Widget _buildOverflowMenu(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    bool isVersionLoaded,
    String appVersion,
    VoidCallback onSettings,
    VoidCallback onLogout,
  ) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: theme.colorScheme.primary,
      ),
      onSelected: (value) async {
        switch (value) {
          case 'theme':
            await ref.read(themeModeProvider.notifier).toggleTheme();
            break;
          case 'settings':
            onSettings();
            break;
          case 'logout':
            onLogout();
            break;
          case 'version':
            // Show version info in a dialog.
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Version Information'),
                  content: Text('Version: $appVersion'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'theme',
          child: Row(
            children: [
              Icon(
                ref.watch(themeModeProvider) == ThemeMode.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              const SizedBox(width: 8),
              const Text('Toggle Theme'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings),
              SizedBox(width: 8),
              Text('Settings'),
            ],
          ),
        ),
        if (isVersionLoaded)
          const PopupMenuItem(
            value: 'version',
            child: Row(
              children: [
                Icon(Icons.info),
                SizedBox(width: 8),
                Text('Version Info'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout),
              SizedBox(width: 8),
              Text('Logout'),
            ],
          ),
        ),
      ],
    );
  }

  /// Creates the MovieStar app navigation tabs.
  ///
  /// This provides the specific configuration for the MovieStar application
  /// with titles matching the original screen titles.

  static List<SolidNavTab> createMovieStarNavTabs() {
    return [
      const SolidNavTab(
        title: 'MOVIE STAR',
        icon: Icons.home,
        tooltip: '''

        **Home:** Tap here to view your movie dashboard and discover new films.

        ''',
      ),
      const SolidNavTab(
        title: 'To Watch',
        icon: Icons.favorite,
        tooltip: '''

        **To Watch:** Tap here to view your watchlist of movies you want to see.

        ''',
      ),
      const SolidNavTab(
        title: 'Watched',
        icon: Icons.history,
        tooltip: '''

        **Watched:** Tap here to view movies you have already watched and rated.

        ''',
      ),
      const SolidNavTab(
        title: 'Coming Soon',
        icon: Icons.upcoming,
        tooltip: '''

        **Coming Soon:** Tap here to discover upcoming movie releases.

        ''',
      ),
      const SolidNavTab(
        title: 'Shared Movies',
        icon: Icons.movie_outlined,
        tooltip: '''

        **Shared Movies:** Tap here to view movies shared from your POD.

        ''',
      ),
      const SolidNavTab(
        title: 'File Management',
        icon: Icons.folder,
        tooltip: '''

        **File Management:** Tap here to access file management features for your POD.

        You can browse POD storage, upload files, download files, and manage
        your movie data files.

        ''',
      ),
      const SolidNavTab(
        title: 'Settings',
        icon: Icons.person,
        tooltip: '''

        **Settings:** Tap here to configure your movie preferences and account settings.

        ''',
      ),
    ];
  }
}
