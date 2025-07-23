/// Moviestar - Manage and share ratings through private PODs
///
// Time-stamp: <Wednesday 2025-07-23 16:55:28 +1000 Graham Williams>
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
/// Authors: Kevin Wang, Graham Williams, Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/moviestar.dart';
import 'package:moviestar/providers/theme_provider.dart';
import 'package:moviestar/services/cache_settings_service.dart';
import 'package:moviestar/utils/is_desktop.dart';

/// Main entry point for the Movie Star application.

void main() async {
  // This is the main entry point for the app. The [async] is required because
  // we asynchronously [await] the window manager below. Often, `main()` will
  // include only [runApp].

  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // Initialise cache settings service early.

  await CacheSettingsService.instance.initialize();

  // Initialise Hive for local movie caching.

  await Hive.initFlutter();

  // Register Hive type adapters.

  Hive.registerAdapter(MovieAdapter());

  // Globally remove [debugPrint] messages.

  // debugPrint = (String? message, {int? wrapWidth}) {
  //   null;
  // };

  // Ensure Flutter bindings are initialized for async operations

  WidgetsFlutterBinding.ensureInitialized();

  if (isDesktop) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      // Set various desktop window options here.

      // Setting [alwaysOnTop] here will ensure the app starts on top of other
      // apps on the desktop so that it is visible (otherwise, with GNOME on
      // Ubuntu the app is often lost below other windows on startup).
      // We later turn it off as we don't want to force it always on top.

      alwaysOnTop: true,

      // The [title] is used for the window manager's window title.

      title: 'Movie Star - Manage and share ratings through private PODs',
    );

    // Once the window manager is ready we reconfigure it a little.

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setAlwaysOnTop(false);
    });
  }

  // The runApp() function takes the given Widget and makes it the root of the
  // widget tree.

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MovieStar(),
    ),
  );
}
