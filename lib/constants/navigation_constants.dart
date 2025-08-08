/// Navigation style constants.
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

/// Navigation constants used throughout the application.

class NavigationConstants {
  /// The width threshold for determining narrow/wide screen layout.
  ///
  /// Screens wider than this value will use the navigation rail,
  /// while narrower screens will use the navigation drawer.

  static const double narrowScreenThreshold = 800.0;

  /// The width threshold for determining very narrow screen layout.

  static const double veryNarrowScreenThreshold = 600.0;

  /// Minimum width for the navigation rail.

  static const double navRailMinWidth = 80.0;

  /// Vertical alignment for navigation rail items.

  static const double navRailGroupAlignment = -1.0;

  /// Icon size for navigation items.

  static const double navIconSize = 26.0;

  /// Font size for navigation labels.

  static const double navLabelFontSize = 10.5;

  /// Letter spacing for navigation labels.

  static const double navLabelLetterSpacing = 0.2;

  /// Vertical padding for navigation rail destinations.

  static const double navDestinationVerticalPadding = 6.0;

  /// Maximum lines for navigation labels.

  static const int navLabelMaxLines = 2;

  /// Padding for navigation drawer items.

  static const double navDrawerPadding = 15.0;

  /// User info header top padding.

  static const double userHeaderTopPadding = 24.0;

  /// User info header bottom padding.

  static const double userHeaderBottomPadding = 24.0;

  /// User avatar icon size.

  static const double userAvatarSize = 64.0;

  /// User name font size.

  static const double userNameFontSize = 20.0;

  /// WebID font size.

  static const double webIdFontSize = 12.0;

  /// Spacing between user info elements.

  static const double userInfoSpacing = 12.0;

  /// Spacing for WebID text.

  static const double webIdSpacing = 8.0;

  /// Divider height in navigation drawer.

  static const double navDividerHeight = 32.0;

  /// Horizontal padding for WebID container.

  static const double webIdHorizontalPadding = 16.0;
}
