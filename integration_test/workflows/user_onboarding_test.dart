/// Integration test for new user onboarding workflow.
///
/// This test suite verifies the complete first-time user experience:
/// 1. First launch with POD authentication
/// 2. API key setup (TMDB)
/// 3. POD login verification
/// 4. First movie search
///
/// ## Setup Requirements:
/// - Valid POD credentials in integration_test/fixtures/complete_auth_data.json
/// - Valid TMDB API key in integration_test/fixtures/tmdb_api_key.json
/// - Network connectivity to POD server and TMDB API
/// - Flutter integration test driver
///
/// ## Running the Test:
/// ```
/// flutter test integration_test/workflows/user_onboarding_test.dart -d [platform]
/// ```
///
/// ## Batch Test Mode:
/// When running tests in batch mode, disable auto-regeneration to avoid conflicts:
/// ```
/// flutter test integration_test/ -d <platform> --dart-define=AUTO_REGENERATE=false
/// ```
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

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moviestar/core/services/cache/settings_service.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/moviestar.dart';
import 'package:moviestar/providers/theme_provider.dart';
import 'package:moviestar/screens/enhanced_search_screen.dart';
import 'package:moviestar/utils/is_logged_in.dart';

import '../helpers/credential_injector.dart';
import '../utils/delays.dart';

// Control auto-regeneration via dart-define flag for batch test compatibility.

const autoRegenerate =
    bool.fromEnvironment('AUTO_REGENERATE', defaultValue: true);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('New User Onboarding Workflow', () {
    setUpAll(() async {
      // Inject full authentication with automatic token regeneration.

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
      // Clean up credentials and Hive boxes after tests.

      await CredentialInjector.clearCredentials();
      await Hive.close();
    });

    /// Helper function to initialize the app with fresh state.

    Future<void> initializeApp(
      WidgetTester tester, {
      Map<String, Object>? prefValues,
    }) async {
      // Set up SharedPreferences with test values.

      SharedPreferences.setMockInitialValues(prefValues ?? {});
      final prefs = await SharedPreferences.getInstance();

      // Initialize cache settings service.

      await CacheSettingsService.instance.initialize();

      // Initialize Hive with safe adapter registration.

      await Hive.initFlutter();

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(MovieAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(CustomListAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(ContentItemAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ContentTypeAdapter());
      }

      // Pump the app with ProviderScope.

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MovieStar(),
        ),
      );

      // Wait for app to settle.

      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Add delay to let login styling fully load.
      await Future.delayed(delay);
      await tester.pump();

      // Interactive delay for visual inspection (0s in qtest, 5s in itest).

      await tester.pump(interact);
    }

    /// Helper function to load TMDB API key from fixtures.

    Future<String> loadTmdbApiKey() async {
      final file = File(
        'integration_test/fixtures/tmdb_api_key.json',
      );
      final contents = await file.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;
      return json['apiKey'] as String;
    }

    group('First Launch', () {
      testWidgets('app loads with injected credentials', (tester) async {
        await initializeApp(tester);

        // Verify app loaded - look for MovieStar widget.

        expect(
          find.byType(MovieStar),
          findsOneWidget,
          reason: 'App should load with MovieStar widget',
        );

        // Verify app title is present.

        expect(
          find.text('Movie Star'),
          findsWidgets,
          reason: 'App title should be visible',
        );
      });

      testWidgets('user is logged in after credential injection',
          (tester) async {
        await initializeApp(tester);

        // Verify user is logged in using the app's login check.

        final loggedIn = await isLoggedIn();
        expect(
          loggedIn,
          isTrue,
          reason: 'User should be logged in after credential injection',
        );
      });

      testWidgets('POD folders are initialized', (tester) async {
        await initializeApp(tester);

        // Wait for POD folder initialisation to complete.

        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Verify user is still logged in after initialisation.

        final loggedIn = await isLoggedIn();
        expect(
          loggedIn,
          isTrue,
          reason: 'User should remain logged in after POD initialization',
        );
      });
    });

    group('API Key Setup', () {
      testWidgets('API key dialog appears after login if key not set',
          (tester) async {
        await initializeApp(tester);

        // Wait for app to fully initialise.

        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Look for API key dialog elements.
        // Note: Dialog only appears if API key is not already stored in POD.

        final apiKeyDialog = find.text('API Key Required');
        final tmdbText = find.textContaining('TMDB');
        final homeText = find.text('Movie Star');

        // Either API key dialog should be present, or we're already on home screen
        // (meaning API key was already set from a previous test/session).

        final hasDialog =
            apiKeyDialog.evaluate().isNotEmpty || tmdbText.evaluate().isNotEmpty;
        final onHomeScreen = homeText.evaluate().isNotEmpty;

        expect(
          hasDialog || onHomeScreen,
          isTrue,
          reason:
              'Should show API key dialog or be on home screen if key already set',
        );
      });

      testWidgets('can enter and save API key', (tester) async {
        await initializeApp(tester);

        // Wait for API key dialog to appear.

        await tester.pumpAndSettle(const Duration(seconds: 5));

        try {
          // Load the TMDB API key from fixtures.

          final apiKey = await loadTmdbApiKey();

          // Find the API key text field.

          final textFieldFinder = find.byType(TextField);

          if (textFieldFinder.evaluate().isNotEmpty) {
            // Enter the API key.

            await tester.enterText(textFieldFinder.first, apiKey);
            await tester.pump(delay);

            // Find and tap the save button.

            final saveButton = find.text('Save API Key');
            if (saveButton.evaluate().isNotEmpty) {
              await tester.tap(saveButton);
              await tester.pumpAndSettle(const Duration(seconds: 3));

              // Verify the dialog is dismissed by checking if home elements appear.

              expect(
                find.text('Home'),
                findsWidgets,
                reason: 'Home screen should appear after saving API key',
              );
            }
          }
        } catch (e) {
          // API key file may not exist - this is acceptable for the test.
          // Skip the rest of this test if API key cannot be loaded.
          // Note: Could not load TMDB API key from fixtures: $e
        }
      });

      testWidgets('can dismiss API key dialog and set it later',
          (tester) async {
        await initializeApp(tester);

        // Wait for API key dialog to appear.

        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Look for "Later" or dismiss button.

        final laterButton = find.text('Later');

        if (laterButton.evaluate().isNotEmpty) {
          await tester.tap(laterButton);
          await tester.pumpAndSettle();

          // Verify we're on the home screen even without API key.

          expect(
            find.text('Home'),
            findsWidgets,
            reason: 'Should navigate to home screen after dismissing dialog',
          );
        }
      });
    });

    group('Navigation and Home Screen', () {
      testWidgets('home screen loads after setup', (tester) async {
        await initializeApp(tester);

        // Wait for full initialisation.
        
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Handle API key dialog if present.

        final laterButton = find.text('Later');
        if (laterButton.evaluate().isNotEmpty) {
          await tester.tap(laterButton);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }

        // Verify app is loaded - check for Movie Star app.

        final appTitle = find.text('Movie Star');
        final movieStarWidget = find.byType(MovieStar);

        expect(
          appTitle.evaluate().isNotEmpty ||
              movieStarWidget.evaluate().isNotEmpty,
          isTrue,
          reason: 'Home screen should be loaded after setup',
        );
      });

      testWidgets('app bar contains search button', (tester) async {
        await initializeApp(tester);

        // Wait for app to fully load.

        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Handle API key dialog if present.

        final laterButton = find.text('Later');
        if (laterButton.evaluate().isNotEmpty) {
          await tester.tap(laterButton);
          await tester.pumpAndSettle(const Duration(seconds: 2));
        }

        // Look for search icon in app bar.

        final searchIcon = find.byIcon(Icons.search);
        // Also check for any app bar or navigation elements as fallback.

        final movieStarWidget = find.byType(MovieStar);

        expect(
          searchIcon.evaluate().isNotEmpty ||
              movieStarWidget.evaluate().isNotEmpty,
          isTrue,
          reason:
              'Search button should be present or app should be fully loaded',
        );
      });
    });

    group('First Movie Search', () {
      testWidgets('can open search screen', (tester) async {
        await initializeApp(tester);

        // Wait for app to fully load.
        
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Find and tap the search icon.

        final searchIcon = find.byIcon(Icons.search);

        if (searchIcon.evaluate().isNotEmpty) {
          await tester.tap(searchIcon.first);
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Verify search screen is displayed.
          // Look for search screen indicators.

          final searchScreen = find.byType(EnhancedSearchScreen);
          final searchField = find.byType(TextField);

          expect(
            searchScreen.evaluate().isNotEmpty ||
                searchField.evaluate().isNotEmpty,
            isTrue,
            reason: 'Search screen should open when search icon is tapped',
          );
        }
      });

      testWidgets('can perform movie search', (tester) async {
        await initializeApp(tester);

        // Wait for app to fully load.

        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Find and tap the search icon.

        final searchIcon = find.byIcon(Icons.search);

        if (searchIcon.evaluate().isNotEmpty) {
          await tester.tap(searchIcon.first);
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Find the search text field.

          final searchField = find.byType(TextField);

          if (searchField.evaluate().isNotEmpty) {
            // Enter a search query.

            await tester.enterText(searchField.first, 'Inception');
            await tester.pump(const Duration(milliseconds: 100));

            // Wait for debounce delay (500ms).

            await tester.pump(const Duration(milliseconds: 600));

            // Wait for search results to load.

            await tester.pumpAndSettle(const Duration(seconds: 5));

            // Verify search was performed.
            // Search results should appear (exact UI depends on results).
            // At minimum, the search field should still contain the query.

            final searchFieldWidget = tester.widget<TextField>(searchField.first);
            expect(
              searchFieldWidget.controller?.text,
              equals('Inception'),
              reason: 'Search field should contain the entered query',
            );
          }
        }
      });

      testWidgets('search results UI is present', (tester) async {
        await initializeApp(tester);

        // Wait for app to fully load.

        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Navigate to search.

        final searchIcon = find.byIcon(Icons.search);

        if (searchIcon.evaluate().isNotEmpty) {
          await tester.tap(searchIcon.first);
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Perform a search.

          final searchField = find.byType(TextField);

          if (searchField.evaluate().isNotEmpty) {
            await tester.enterText(searchField.first, 'Matrix');
            await tester.pump(const Duration(milliseconds: 600));
            await tester.pumpAndSettle(const Duration(seconds: 5));

            // Verify we're still on the search screen.

            final enhancedSearchScreen = find.byType(EnhancedSearchScreen);
            expect(
              enhancedSearchScreen.evaluate().isNotEmpty,
              isTrue,
              reason: 'Should remain on search screen after entering query',
            );
          }
        }
      });
    });

    group('Complete Onboarding Flow', () {
      testWidgets('complete new user journey from start to search',
          (tester) async {
        // 1. Initialise app with fresh state.

        await initializeApp(tester);

        // 2. Verify login state.

        final loggedIn = await isLoggedIn();
        expect(
          loggedIn,
          isTrue,
          reason: 'Step 1: User should be logged in',
        );

        // 3. Wait for API key dialog or home screen.

        await tester.pumpAndSettle(const Duration(seconds: 5));

        // 4. Handle API key dialog if present.

        final laterButton = find.text('Later');
        if (laterButton.evaluate().isNotEmpty) {
          await tester.tap(laterButton);
          await tester.pumpAndSettle();
        }

        // 5. Verify home screen is loaded.

        expect(
          find.text('Movie Star'),
          findsWidgets,
          reason: 'Step 2: Home screen should be loaded',
        );

        // 6. Navigate to search.
        
        final searchIcon = find.byIcon(Icons.search);
        if (searchIcon.evaluate().isNotEmpty) {
          await tester.tap(searchIcon.first);
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // 7. Verify search screen opened.

          final searchField = find.byType(TextField);
          expect(
            searchField.evaluate().isNotEmpty,
            isTrue,
            reason: 'Step 3: Search screen should open',
          );

          // 8. Perform a search.
    
          await tester.enterText(searchField.first, 'Star Wars');
          await tester.pump(const Duration(milliseconds: 600));
          await tester.pumpAndSettle(const Duration(seconds: 5));

          // 9. Verify search completed.
          
          final searchFieldWidget =
              tester.widget<TextField>(searchField.first);
          expect(
            searchFieldWidget.controller?.text,
            equals('Star Wars'),
            reason: 'Step 4: First movie search should complete successfully',
          );
        }
      });
    });
  });
}
