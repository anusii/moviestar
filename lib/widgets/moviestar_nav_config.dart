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
import 'package:solidui/solidui.dart';

import 'package:moviestar/providers/theme_provider.dart';
import 'package:moviestar/providers/view_mode_provider.dart';

/// MovieStar-specific navigation configuration and factory methods.

class MovieStarNavConfig {
  /// Creates the MovieStar app navigation menu items.
  ///
  /// Returns a list of menu items configured specifically for the
  /// MovieStar application with proper titles, icons, and tooltips.

  static List<SolidMenuItem> createMenuItems() {
    return [
      SolidMenuItem(
        title: 'Home',
        icon: Icons.home,
        tooltip: '''

**Home:** Tap here to view your movie dashboard and discover new films.

''',
      ),
      SolidMenuItem(
        title: 'Watch',
        icon: Icons.favorite,
        tooltip: '''

**To Watch:** Tap here to view your watchlist of movies you want to see.

''',
      ),
      SolidMenuItem(
        title: 'Watched',
        icon: Icons.history,
        tooltip: '''

**Watched:** Tap here to view movies you have already watched and rated.

''',
      ),
      SolidMenuItem(
        title: 'Soon',
        icon: Icons.upcoming,
        tooltip: '''

**Coming Soon:** Tap here to discover upcoming movie releases.

''',
      ),
      SolidMenuItem(
        title: 'Shared',
        icon: Icons.movie_outlined,
        tooltip: '''

**Shared Movies:** Tap here to view movies shared from your POD.

''',
      ),
      SolidMenuItem(
        title: 'Files',
        icon: Icons.folder,
        tooltip: '''

**File Management:** Tap here to access file management features for your POD.

You can browse POD storage, upload files, download files, and manage
your movie data files.

''',
      ),
      SolidMenuItem(
        title: 'Settings',
        icon: Icons.person,
        tooltip: '''

**Settings:** Tap here to configure your movie preferences and account settings.

''',
      ),
    ];
  }



  /// Creates a MovieStar-specific AppBar configuration for the SolidScaffold.

  static SolidAppBarConfig createSimpleAppBarConfig({
    required String title,
    required VoidCallback onRefresh,
    required VoidCallback onSearch,
    required VoidCallback onSettings,
    required VoidCallback onLogout,
    required WidgetRef ref,
    VoidCallback? onViewModeToggle,
  }) {
    return SolidAppBarConfig(
      title: title,
      actions: [
        if (onViewModeToggle != null)
          SolidAppBarAction(
            icon: _getViewModeIcon(ref.watch(viewModeProvider)),
            onPressed: onViewModeToggle,
            tooltip: '''

**View Mode:** Tap here to cycle between different view modes (Grid, Kanban, List).

''',
          ),
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
      ],
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
        SolidOverflowMenuItem(
          id: 'logout',
          icon: Icons.logout,
          label: 'Logout',
          onSelected: onLogout,
        ),
      ],
    );
  }

  // Helper method to get the appropriate icon for the current view mode.

  static IconData _getViewModeIcon(HomeViewMode viewMode) {
    switch (viewMode) {
      case HomeViewMode.grid:
        return Icons.grid_view;
      case HomeViewMode.kanban:
        return Icons.view_kanban;
      case HomeViewMode.list:
        return Icons.view_list;
    }
  }
}
