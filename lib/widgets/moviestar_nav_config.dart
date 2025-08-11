/// MovieStar Navigation Configuration - App-specific navigation setup.
///
// Time-stamp: <Sunday 2025-08-10 08:13:23 +1000 Graham Williams>
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

import 'package:moviestar/providers/theme_provider.dart';
import 'package:solidui/solidui.dart';

/// MovieStar-specific navigation configuration and factory methods.

class MovieStarNavConfig {
  /// Creates the MovieStar app navigation tabs.
  ///
  /// Returns a list of navigation tabs configured specifically for the
  /// MovieStar application with proper titles, icons, and tooltips.

  static List<SolidNavTab> createNavTabs() {
    return SolidNavUtils.createNavTabs([
      {
        'title': 'Home',
        'icon': Icons.home,
        'tooltip': '''

**Home:** Tap here to view your movie dashboard and discover new films.

''',
      },
      {
        'title': 'Watch',
        'icon': Icons.favorite,
        'tooltip': '''

**To Watch:** Tap here to view your watchlist of movies you want to see.

''',
      },
      {
        'title': 'Watched',
        'icon': Icons.history,
        'tooltip': '''

**Watched:** Tap here to view movies you have already watched and rated.

''',
      },
      {
        'title': 'Soon',
        'icon': Icons.upcoming,
        'tooltip': '''

**Coming Soon:** Tap here to discover upcoming movie releases.

''',
      },
      {
        'title': 'Shared',
        'icon': Icons.movie_outlined,
        'tooltip': '''

**Shared Movies:** Tap here to view movies shared from your POD.

''',
      },
      {
        'title': 'Files',
        'icon': Icons.folder,
        'tooltip': '''

**File Management:** Tap here to access file management features for your POD.

You can browse POD storage, upload files, download files, and manage
your movie data files.

''',
      },
      {
        'title': 'Settings',
        'icon': Icons.person,
        'tooltip': '''

**Settings:** Tap here to configure your movie preferences and account settings.

''',
      },
    ]);
  }

  /// Creates a MovieStar-specific AppBar configuration.

  static SolidAppBarConfig createAppBarConfig({
    required String title,
    required String appVersion,
    required bool isVersionLoaded,
    required VoidCallback onRefresh,
    required VoidCallback onSearch,
    required VoidCallback onSettings,
    required VoidCallback onLogout,
    required WidgetRef ref,
    VoidCallback? onVersionInfo,
  }) {
    return SolidAppBarConfig(
      title: title,
      narrowScreenThreshold: NavigationConstants.narrowScreenThreshold,
      veryNarrowScreenThreshold: NavigationConstants.veryNarrowScreenThreshold,
      versionConfig: isVersionLoaded
          ? SolidVersionConfig(
              version: appVersion,
              changelogUrl:
                  'https://github.com/anusii/moviestar/blob/dev/CHANGELOG.md',
              tooltip: '''

**Version:** This is the current version of the MovieStar app. If
the version is out of date then the text will be red. You can tap on
the version to view the app's Change Log to determine if it is worth
updating your version.

''',
            )
          : null,
      actions: [
        SolidAppBarAction(
          icon: Icons.refresh,
          onPressed: onRefresh,
          tooltip: '''

**Refresh:** Tap here to refresh all movie data and reload the latest
information from the movie database.

''',
        ),
        SolidAppBarAction(
          icon: Icons.search,
          onPressed: onSearch,
          tooltip: '''

**Search:** Tap here to search for movies by title, genre, or other
criteria.

''',
        ),
        SolidAppBarAction(
          icon: Icons.settings,
          onPressed: onSettings,
          hideOnVeryNarrowScreen: true,
          tooltip: '''

**Settings:** Tap here to view and manage your MovieStar account
settings.

''',
        ),
        SolidAppBarAction(
          icon: Icons.logout,
          onPressed: onLogout,
          hideOnVeryNarrowScreen: true,
          tooltip: '''

**Logout:** Tap here to securely log out of your MovieStar account.
This will clear your current session and return you to the login
screen.

''',
        ),
      ],
      themeConfig: SolidThemeConfig(
        lightModeTooltip: '''

**Theme Toggle:** Tap here to switch to light theme.

''',
        darkModeTooltip: '''

**Theme Toggle:** Tap here to switch to dark theme.

''',
        onToggle: () async {
          await ref.read(themeModeProvider.notifier).toggleTheme();
        },
      ),
      overflowItems: [
        SolidOverflowMenuItem(
          id: 'theme',
          icon: Icons.dark_mode,
          label: 'Toggle Theme',
          onSelected: () async {
            await ref.read(themeModeProvider.notifier).toggleTheme();
          },
        ),
        SolidOverflowMenuItem(
          id: 'settings',
          icon: Icons.settings,
          label: 'Settings',
          onSelected: onSettings,
        ),
        if (isVersionLoaded && onVersionInfo != null)
          SolidOverflowMenuItem(
            id: 'version',
            icon: Icons.info,
            label: 'Version Info',
            onSelected: onVersionInfo,
          ),
        SolidOverflowMenuItem(
          id: 'logout',
          icon: Icons.logout,
          label: 'Logout',
          onSelected: onLogout,
        ),
      ],
    );
  }

  /// Creates a MovieStar-specific user configuration.

  static SolidNavUserConfig createUserConfig({
    required String userName,
    String? webId,
  }) {
    return SolidNavUserConfig(
      userName: userName.isNotEmpty ? userName : 'Not logged in',
      userId: webId,
      showUserId: false, // MovieStar doesn't show WebID by default.
      avatarIcon: Icons.account_circle,
    );
  }

  /// Creates a MovieStar-specific logout configuration.

  static SolidLogoutConfig createLogoutConfig({
    required void Function(BuildContext) onLogout,
  }) {
    return SolidLogoutConfig(
      onLogout: onLogout,
      text: 'Logout',
      icon: Icons.logout,
    );
  }
}
