/// E2E test for POD favorites with real credentials.
///
/// This test uses injected test credentials to verify POD operations
/// work correctly with a real Solid POD.
///
/// ## Complete Auth Data Injection
///
/// This test uses COMPLETE authentication data that includes all components
/// required by the solidpod package, including RSA keys for DPoP token
/// generation. This ensures reliable token refresh and POD operations.
///
/// ### First-time Setup:
/// 1. Run the auth extraction tool:
///    ```
///    flutter run integration_test/utils/extract_complete_auth.dart -d linux
///    ```
/// 2. Log in through the app UI with your test POD credentials
/// 3. Click the EXTRACT button to save complete auth data
/// 4. The data will be saved to `integration_test/fixtures/complete_auth_data.json`
/// 5. Run this test: `flutter test integration_test/workflows/pod_favorites_real_test.dart -d linux`
///
/// ### Fallback to Browser Automation:
/// If complete auth data is not available and `autoRegenerateOnFailure` is true,
/// the test will fall back to browser automation to generate tokens. However,
/// this legacy approach may not work reliably due to missing RSA keys.
///
/// ### Batch Test Mode:
/// When running tests in batch mode (`flutter test integration_test/`), disable
/// auto-regeneration to avoid Puppeteer conflicts with the Flutter test runner:
/// ```
/// flutter test integration_test/ -d <platform> --dart-define=AUTO_REGENERATE=false
/// ```
/// For individual tests, auto-regeneration is enabled by default.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

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
import 'package:moviestar/utils/is_logged_in.dart';

import '../helpers/credential_injector.dart';
import '../utils/delays.dart';

// Control auto-regeneration via dart-define flag for batch test compatibility.
// Default: true (auto-regenerate enabled for individual tests).
// Batch mode: flutter test integration_test/ --dart-define=AUTO_REGENERATE=false
const autoRegenerate =
    bool.fromEnvironment('AUTO_REGENERATE', defaultValue: true);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('POD Favorites E2E Tests with Real Credentials', () {
    setUpAll(() async {
      // Inject full authentication with automatic token regeneration.
      // If tokens are expired or missing, they will be automatically
      // regenerated using browser automation (unless AUTO_REGENERATE=false).
      await CredentialInjector.injectFullAuth(
        autoRegenerateOnFailure: autoRegenerate,
      );

      // Verify injection was successful.
      final injected = await CredentialInjector.verifyInjection();
      expect(
        injected,
        isTrue,
        reason: 'Credential injection failed - WebID not found',
      );
    });

    tearDownAll(() async {
      // Clean up credentials after tests.
      await CredentialInjector.clearCredentials();
    });

    testWidgets('app loads with injected credentials', (tester) async {
      // Initialize app dependencies.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await CacheSettingsService.instance.initialize();
      await Hive.initFlutter();
      Hive.registerAdapter(MovieAdapter());
      Hive.registerAdapter(CustomListAdapter());
      Hive.registerAdapter(ContentItemAdapter());
      Hive.registerAdapter(ContentTypeAdapter());

      // Start the app.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MovieStar(),
        ),
      );

      // Wait for app to settle.
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Add delay to let login styling fully load (required for styling).
      await Future.delayed(delay);
      await tester.pump();

      // Interactive delay for visual inspection (0s in qtest, 5s in itest)
      await tester.pump(interact);

      // Verify app loaded.
      expect(find.text('Movie Star'), findsWidgets);
    });

    testWidgets('verifies user is logged in after injection', (tester) async {
      // Check if user is logged in using the app's own login check.
      final loggedIn = await isLoggedIn();

      expect(
        loggedIn,
        isTrue,
        reason: 'User should be logged in after credential injection',
      );
    });

    testWidgets('can access POD data', (tester) async {
      // This test will be expanded to verify actual POD operations.
      // For now, we verify the basic setup.

      // TODO: Add tests for:
      // - Reading favorites from POD
      // - Writing favorites to POD
      // - Syncing favorites
      // - Handling POD errors gracefully

      // Placeholder verification.
      final loggedIn = await isLoggedIn();
      expect(loggedIn, isTrue);
    });
  });

  group('POD Favorites Operations', () {
    // These tests would verify specific POD operations.
    // They require the app to be fully initialized with injected credentials.

    testWidgets(
      'can add movie to favorites on POD',
      (tester) async {
        // TODO: Implement favorite addition test.
        // This would:
        // 1. Create a test movie
        // 2. Add it to favorites
        // 3. Verify it's stored in POD
        // 4. Clean up test data
      },
      skip: true,
    ); // Not yet implemented - requires POD operation testing

    testWidgets(
      'can remove movie from favorites on POD',
      (tester) async {
        // TODO: Implement favorite removal test.
      },
      skip: true,
    ); // Not yet implemented - requires POD operation testing

    testWidgets(
      'can sync favorites from POD',
      (tester) async {
        // TODO: Implement favorite sync test.
      },
      skip: true,
    ); // Not yet implemented - requires POD operation testing
  });
}
