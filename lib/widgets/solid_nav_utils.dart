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
