/// E2E basic startup and quite test.
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
/// Authors: Ashley Tang, Graham Williams

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:moviestar/core/services/cache/settings_service.dart';
import 'package:moviestar/main.dart' as app;

import 'utils/delays.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app loads and initializes', (WidgetTester tester) async {
    app.main();
    // Trigger a frame. Finish animation and scheduled microtasks.

    await tester.pumpAndSettle();

    // Leave time to see the first page during an interactive test. We use a
    // [interact] delay which for qtest is 0s and for itest is 5s. Lutra-fs
    // notes that 0s is problematic on their testing (hence qtest
    // failing). Perhaps then try with itest.

    await tester.pump(interact);

    // Initialize cache settings service

    await CacheSettingsService.instance.initialize();

    // Wait for the app to settle

    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Basic smoke test - verify the app builds without errors
    // The app should load successfully even if we can't interact with POD login

    expect(find.text('Movie Star'), findsWidgets);
  });
}
