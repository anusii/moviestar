/// Theme configuration for the Movie Star application.
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
/// Authors: Kevin Wang

library;

import 'package:flutter/material.dart';

import 'package:solidui/solidui.dart';

/// Theme configuration for the Movie Star application.

class AppTheme {
  /// Primary color for the application.
  /// Using a more balanced red that provides better contrast in both light and dark modes.

  static const Color primaryColor = Color(0xFFD32F2F);

  /// Default padding used throughout the application.

  static double get defaultPadding => SolidDefaultTheme.defaultPadding;

  /// Default border radius for UI elements.

  static double get defaultBorderRadius =>
      SolidDefaultTheme.defaultBorderRadius;

  /// Text color for primary text.

  static Color get primaryTextColor => SolidDefaultTheme.primaryTextColor;

  /// Text color for secondary text.

  static Color get secondaryTextColor => SolidDefaultTheme.secondaryTextColor;

  /// Creates the light theme for the application.

  static ThemeData get lightTheme {
    return SolidDefaultTheme.lightTheme(
      primaryColor: primaryColor,
    );
  }

  /// Creates the dark theme for the application.

  static ThemeData get darkTheme {
    return SolidDefaultTheme.darkTheme(
      primaryColor: primaryColor,
    );
  }
}
