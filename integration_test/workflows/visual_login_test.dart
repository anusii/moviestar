/// Visual test to inspect the SolidLogin widget.
///
/// This test launches the app WITHOUT injecting credentials,
/// so you can see the actual login screen for manual inspection.
///
/// Run with: flutter test integration_test/workflows/visual_login_test.dart -d windows
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

// ignore_for_file: avoid_print, invalid_use_of_visible_for_testing_member

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/test_app_helper.dart';
import '../utils/delays.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Show login screen for visual inspection', (tester) async {
    // Initialize app WITHOUT injecting credentials.
    await TestAppHelper.initializeApp(
      tester,
      settleDuration: const Duration(seconds: 2),
    );

    // Add a delay to let login styling fully load (required for styling)
    await Future.delayed(delay);

    // Pump to render the fully styled login screen
    await tester.pump();

    // Interactive delay for visual inspection (0s in qtest, 5s in itest)
    await tester.pump(interact);

    // Verify we see the login screen (not the home page)
    expect(find.text('Movie Star'), findsWidgets);
  });
}
