/// UI constants for the Movie Star application.
///
// Time-stamp: <Tuesday 2025-09-03 16:00:00 +1100 Ashley Tang>
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
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
/// Authors: Ashley Tang.

library;

import 'dart:ui';

/// UI constants for consistent styling throughout the app.

class UIConstants {
  /// Standard opacity for overlays and disabled states (0.6).

  static const double standardOpacity = 0.6;

  /// High opacity for semi-transparent elements (0.8).

  static const double highOpacity = 0.8;

  /// Very high opacity for subtle transparency (0.9).

  static const double veryHighOpacity = 0.9;

  /// Standard background color for widgets.

  static const Color standardBackgroundColor = Color.fromRGBO(210, 210, 210, 1);
}
