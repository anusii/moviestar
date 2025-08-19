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

import 'package:solidui/solidui.dart';

/// MovieStar-specific navigation configuration.

class MovieStarNavConfig {
  /// Creates the MovieStar app navigation menu items.
  ///
  /// Returns a list of menu items configured specifically for the
  /// MovieStar application with proper titles, icons, and tooltips.

  static List<SolidMenuItem> createMenuItems() {
    return [
      SolidMenuItem(
        title: 'MOVIE STAR',
        icon: Icons.home,
        tooltip: '''

**Home:** Tap here to view your movie dashboard and discover new films.

''',
      ),
      SolidMenuItem(
        title: 'To Watch',
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
        title: 'Coming Soon',
        icon: Icons.upcoming,
        tooltip: '''

**Coming Soon:** Tap here to discover upcoming movie releases.

''',
      ),
      SolidMenuItem(
        title: 'Shared Movies',
        icon: Icons.movie_outlined,
        tooltip: '''

**Shared Movies:** Tap here to view movies shared from your POD.

''',
      ),
      SolidMenuItem(
        title: 'File Management',
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
}
