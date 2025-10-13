/// Visual test to inspect the SolidLogin widget.
///
/// This test launches the app WITHOUT injecting credentials,
/// so you can see the actual login screen for manual inspection.
///
/// Run with: flutter test integration_test/workflows/visual_login_test.dart -d windows
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moviestar/core/services/cache/settings_service.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/moviestar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moviestar/providers/theme_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Show login screen for visual inspection', (tester) async {
    // Initialize app dependencies WITHOUT injecting credentials
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await CacheSettingsService.instance.initialize();
    await Hive.initFlutter();
    Hive.registerAdapter(MovieAdapter());
    Hive.registerAdapter(CustomListAdapter());
    Hive.registerAdapter(ContentItemAdapter());
    Hive.registerAdapter(ContentTypeAdapter());

    // Start the app
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MovieStar(),
      ),
    );

    // Wait for app to settle and show login screen
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Add a delay to let login styling fully load
    print('Waiting for login styling to fully load...');
    await Future.delayed(const Duration(seconds: 2));

    // Pump to render the fully styled login screen
    await tester.pump();

    // Add a delay so you can inspect the login screen
    print('Login screen is now visible. Inspect it for 5 seconds...');
    await tester.pump(const Duration(seconds: 5));

    // Verify we see the login screen (not the home page)
    expect(find.text('Movie Star'), findsWidgets);
  });
}
