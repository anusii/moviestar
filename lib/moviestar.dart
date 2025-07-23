/// Moviestar - Manage and share ratings through private PODs.
///
// Time-stamp: <Wednesday 2025-07-23 16:53:46 +1000 Graham Williams>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html
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
/// Authors: Kevin Wang, Graham Williams, Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/providers/theme_provider.dart';
import 'package:moviestar/theme/app_theme.dart';
import 'package:moviestar/utils/create_solid_login.dart';

// The main widget could be in a separate file, but handy having it in main and
// the file is not too large (TO BE FIXED). The widget essentially orchestrates the building
// of other widgets. Generically we set up to build a `Home()` widget containing
// the App. For SolidPod we wrap the `Home()` widget within the `SolidLogin()`
// widget so we start with a login screen, though this is optional.

/// The root widget of the Movie Star application.

class MovieStar extends ConsumerWidget {
  /// Creates a new [MovieStar] widget.

  const MovieStar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final prefs = ref.watch(sharedPreferencesProvider);

    return MaterialApp(
      title: 'Movie Star',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: Builder(builder: (context) => createSolidLogin(context, prefs)),
    );
  }
}
