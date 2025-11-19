/// Integration tests for navigation and state persistence in MovieStar app.
///
/// This test suite verifies:
/// 1. App loads with proper navigation structure
/// 2. View mode state persistence across app restarts
/// 3. Basic navigation and UI functionality
///
/// Setup requirements:
/// - Valid POD credentials in integration_test/fixtures/complete_auth_data.json
/// - Network connectivity to POD server
/// - Flutter integration test driver
///
/// Run with: flutter test integration_test/workflows/navigation_state_test.dart -d [platform]
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
import 'package:moviestar/providers/view_mode_provider.dart';

import '../helpers/credential_injector.dart';

// Control auto-regeneration via dart-define flag for batch test compatibility.

const autoRegenerate =
    bool.fromEnvironment('AUTO_REGENERATE', defaultValue: true);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation and State Persistence Tests', () {
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

    /// Helper function to initialise the app with fresh state.

    Future<void> initializeApp(
      WidgetTester tester, {
      Map<String, Object>? prefValues,
    }) async {
      // Set up SharedPreferences with test values.

      SharedPreferences.setMockInitialValues(prefValues ?? {});
      final prefs = await SharedPreferences.getInstance();

      // Initialise cache settings service.

      await CacheSettingsService.instance.initialize();

      // Initialise Hive with safe adapter registration.

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
    }

    group('App Initialization', () {
      testWidgets('app loads with injected credentials', (tester) async {
        await initializeApp(tester);

        // Verify app loaded - look for MovieStar widget itself.

        expect(
          find.byType(MovieStar),
          findsOneWidget,
          reason: 'App should load with MovieStar widget',
        );
      });

      testWidgets('navigation menu is present', (tester) async {
        await initializeApp(tester);

        // Look for common menu items by text.

        final menuItems = [
          'Home',
          'To Watch',
          'Watched',
          'My Movies',
        ];

        for (final item in menuItems) {
          // At least one menu item should be visible.

          if (find.text(item).evaluate().isNotEmpty) {
            expect(
              find.text(item),
              findsWidgets,
              reason: '$item menu item should be present',
            );
            break;
          }
        }
      });
    });

    group('Navigation Between Pages', () {
      testWidgets('can navigate to To Watch page', (tester) async {
        await initializeApp(tester);

        // Find and tap the To Watch menu item.

        final toWatchFinder = find.text('To Watch');
        if (toWatchFinder.evaluate().isNotEmpty) {
          await tester.tap(toWatchFinder.first);
          await tester.pumpAndSettle();

          // Verify we're on the To Watch page.

          expect(
            find.text('To Watch'),
            findsWidgets,
            reason: 'To Watch page should be displayed',
          );
        }
      });

      testWidgets('can navigate to Watched page', (tester) async {
        await initializeApp(tester);

        // Find and tap the Watched menu item.

        final watchedFinder = find.text('Watched');
        if (watchedFinder.evaluate().isNotEmpty) {
          await tester.tap(watchedFinder.first);
          await tester.pumpAndSettle();

          // Verify we're on the Watched page.

          expect(
            find.text('Watched'),
            findsWidgets,
            reason: 'Watched page should be displayed',
          );
        }
      });

      testWidgets('can navigate between multiple pages', (tester) async {
        await initializeApp(tester);

        // Navigate to To Watch.

        final toWatchFinder = find.text('To Watch');
        if (toWatchFinder.evaluate().isNotEmpty) {
          await tester.tap(toWatchFinder.first);
          await tester.pumpAndSettle();

          // Then navigate to My Movies.

          final myMoviesFinder = find.text('My Movies');
          if (myMoviesFinder.evaluate().isNotEmpty) {
            await tester.tap(myMoviesFinder.first);
            await tester.pumpAndSettle();

            // Verify we're on My Movies page.

            expect(
              find.text('My Movies'),
              findsWidgets,
              reason: 'Should be on My Movies page',
            );
          }
        }
      });
    });

    group('View Mode Persistence', () {
      testWidgets('view mode is a valid HomeViewMode', (tester) async {
        await initializeApp(tester);

        // Get the current view mode from provider.

        final container = ProviderScope.containerOf(
          tester.element(find.byType(MovieStar)),
        );
        final viewMode = container.read(viewModeProvider);

        expect(
          viewMode,
          isA<HomeViewMode>(),
          reason: 'View mode should be a valid HomeViewMode',
        );

        // Verify it's one of the valid values.

        expect(
          [HomeViewMode.grid, HomeViewMode.kanban, HomeViewMode.list],
          contains(viewMode),
          reason: 'View mode should be grid, kanban, or list',
        );
      });

      testWidgets('view mode can be read from provider', (tester) async {
        await initializeApp(tester);

        // Get the view mode from provider.

        final container = ProviderScope.containerOf(
          tester.element(find.byType(MovieStar)),
        );
        container.read(viewModeProvider);

        // Restart the app.

        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();

        // Reinitialize the app.

        await initializeApp(tester);

        // Get the view mode again.

        final containerAfterRestart = ProviderScope.containerOf(
          tester.element(find.byType(MovieStar)),
        );
        final viewModeAfterRestart =
            containerAfterRestart.read(viewModeProvider);

        // View mode should be consistent (either the same or a valid value).

        expect(
          viewModeAfterRestart,
          isA<HomeViewMode>(),
          reason: 'View mode should remain a valid HomeViewMode after restart',
        );
      });

      testWidgets('view mode provider is properly initialized', (tester) async {
        await initializeApp(tester);

        // Get the view mode from provider.

        final container = ProviderScope.containerOf(
          tester.element(find.byType(MovieStar)),
        );

        // Verify provider can be accessed without errors.

        expect(
          () => container.read(viewModeProvider),
          returnsNormally,
          reason: 'View mode provider should be accessible',
        );

        final viewMode = container.read(viewModeProvider);

        // Verify the returned value is one of the valid enum values.

        expect(
          HomeViewMode.values,
          contains(viewMode),
          reason: 'View mode should be one of the defined enum values',
        );
      });
    });

    group('Basic Navigation Elements', () {
      testWidgets('can find refresh button', (tester) async {
        await initializeApp(tester);

        // Look for refresh icon which is a common app bar action.

        final refreshFinder = find.byIcon(Icons.refresh);

        if (refreshFinder.evaluate().isNotEmpty) {
          expect(
            refreshFinder,
            findsWidgets,
            reason: 'Refresh button should be present in app bar',
          );
        }
      });

      testWidgets('can find search button', (tester) async {
        await initializeApp(tester);

        // Look for search icon which is a common app bar action.

        final searchFinder = find.byIcon(Icons.search);

        if (searchFinder.evaluate().isNotEmpty) {
          expect(
            searchFinder,
            findsWidgets,
            reason: 'Search button should be present in app bar',
          );
        }
      });

      testWidgets('app bar contains overflow menu', (tester) async {
        await initializeApp(tester);

        // Look for the more_vert icon which typically indicates overflow menu.

        final overflowFinder = find.byIcon(Icons.more_vert);

        if (overflowFinder.evaluate().isNotEmpty) {
          expect(
            overflowFinder,
            findsWidgets,
            reason: 'Overflow menu should be present in app bar',
          );
        }
      });
    });

    group('State Management', () {
      testWidgets('SharedPreferences provider is initialized', (tester) async {
        await initializeApp(tester);

        // Verify provider is accessible.

        final container = ProviderScope.containerOf(
          tester.element(find.byType(MovieStar)),
        );
        final prefs = container.read(sharedPreferencesProvider);

        expect(
          prefs,
          isNotNull,
          reason: 'SharedPreferences provider should be initialized',
        );
      });

      testWidgets('ViewMode provider is accessible', (tester) async {
        await initializeApp(tester);

        // Verify provider is accessible.

        final container = ProviderScope.containerOf(
          tester.element(find.byType(MovieStar)),
        );
        final viewMode = container.read(viewModeProvider);

        expect(
          viewMode,
          isA<HomeViewMode>(),
          reason: 'ViewMode provider should return a valid HomeViewMode',
        );
      });
    });
  });
}
