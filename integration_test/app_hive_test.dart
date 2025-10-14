/// E2E test for Movie Star application (Windows/Desktop compatible).
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Ashley Tang.
///
/// This test uses standard integration_test and can run with:
/// `flutter test integration_test/app.dart`

// ignore_for_file: invalid_use_of_visible_for_testing_member

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moviestar/core/services/cache/settings_service.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/moviestar.dart';
import 'package:moviestar/providers/theme_provider.dart';

import 'utils/delays.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app loads and initializes', (WidgetTester tester) async {
    // Initialize SharedPreferences with fake values

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Initialize cache settings service

    await CacheSettingsService.instance.initialize();

    // Initialize Hive for local caching

    await Hive.initFlutter();

    // Register Hive type adapters

    Hive.registerAdapter(MovieAdapter());
    Hive.registerAdapter(CustomListAdapter());
    Hive.registerAdapter(ContentItemAdapter());
    Hive.registerAdapter(ContentTypeAdapter());

    // Load the full app widget tree with providers

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MovieStar(),
      ),
    );

    // Wait for the app to settle

    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Interactive delay for visual inspection (0s in qtest, 5s in itest)

    await tester.pump(interact);

    // Basic smoke test - verify the app builds without errors
    // The app should load successfully even if we can't interact with POD login

    expect(find.text('Movie Star'), findsWidgets);
  });
}
