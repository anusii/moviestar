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
}
