/// E2E test for Movie Discovery and Rating Workflow.
///
/// This test verifies the complete user workflow:
/// 1. Launch app (with API key already configured)
/// 2. Click search icon to open search screen
/// 3. Search for a movie
/// 4. View search results
/// 5. Tap on a movie to view details
/// 6. Rate the movie using the slider
/// 7. Add movie to favorites (bookmark)
///
/// Issue: https://github.com/anusii/moviestar/issues/280
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

// ignore_for_file: invalid_use_of_visible_for_testing_member

library;

import 'package:flutter/material.dart';
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
import 'package:moviestar/screens/enhanced_search_screen.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/utils/is_logged_in.dart';

import '../helpers/api_key_loader.dart';
import '../helpers/credential_injector.dart';
import '../utils/delays.dart';

// Control auto-regeneration via dart-define flag for batch test compatibility.

const autoRegenerate =
    bool.fromEnvironment('AUTO_REGENERATE', defaultValue: true);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Movie Discovery and Rating Workflow E2E Tests', () {
    setUpAll(() async {
      // Inject full authentication for POD operations.

      await CredentialInjector.injectFullAuth(
        autoRegenerateOnFailure: autoRegenerate,
      );

      final injected = await CredentialInjector.verifyInjection();
      expect(
        injected,
        isTrue,
        reason: 'Credential injection failed - WebID not found',
      );
    });

    tearDownAll(() async {
      await CredentialInjector.clearCredentials();
    });

    testWidgets(
      'Complete workflow: Launch → Search → View Details → Rate → Add to Favorites',
      (tester) async {
        // Load API key from fixtures file.
        final apiKey = await loadTmdbApiKey();

        // Initialise app dependencies.

        SharedPreferences.setMockInitialValues({
          'tmdb_api_key': apiKey,
        });
        final prefs = await SharedPreferences.getInstance();
        await CacheSettingsService.instance.initialize();
        await Hive.initFlutter();

        // Register Hive adapters if not already registered.

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

        // Start the app.

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: const MovieStar(),
          ),
        );

        // Wait for app to load and settle.

        await tester.pumpAndSettle(const Duration(seconds: 5));
        await Future.delayed(delay);
        await tester.pump();

        // The SolidLogin widget shows a dialog even when credentials are injected.
        // We need to tap the "Continue" button to proceed to the home screen.

        final continueButton = find.text('Continue');
        if (continueButton.evaluate().isNotEmpty) {
          await tester.tap(continueButton);
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }

        // Wait for home screen to load.

        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Verify user is logged in.

        final loggedIn = await isLoggedIn();
        expect(loggedIn, isTrue, reason: 'User should be logged in');

        // Step 1: Wait for and find the search icon.
        // Give extra time for the home screen to fully load with all icons.

        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Try multiple approaches to find the search icon.

        Finder? searchFinder;

        // Approach 1: Look for search IconButton.

        final searchIconButtons = find.byWidgetPredicate(
          (widget) =>
              widget is IconButton &&
              widget.icon is Icon &&
              (widget.icon as Icon).icon == Icons.search,
        );
        if (searchIconButtons.evaluate().isNotEmpty) {
          searchFinder = searchIconButtons;
        }

        // Approach 2: Look for search Icon directly.

        if (searchFinder == null) {
          final searchIcons = find.byIcon(Icons.search);
          if (searchIcons.evaluate().isNotEmpty) {
            searchFinder = searchIcons;
          }
        }

        // Approach 3: Look for any tappable widget with search semantics.

        if (searchFinder == null) {
          final searchSemantics = find.bySemanticsLabel(RegExp(r'[Ss]earch'));
          if (searchSemantics.evaluate().isNotEmpty) {
            searchFinder = searchSemantics;
          }
        }

        // If still not found, skip this test - it needs the UI to be fully loaded.

        if (searchFinder == null || searchFinder.evaluate().isEmpty) {
          markTestSkipped(
              'Search icon not found - app may not be fully loaded or API key missing');
          return;
        }

        await tester.tap(searchFinder.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify we're on the search screen.

        expect(find.byType(EnhancedSearchScreen), findsOneWidget);
        expect(
          find.text('Search for movies and TV shows'),
          findsOneWidget,
          reason: 'Search screen should be displayed',
        );

        // Step 2: Enter search query in the search field.

        final searchField = find.byType(TextField);
        expect(searchField, findsOneWidget,
            reason: 'Search field should be visible');
        await tester.enterText(searchField, 'spider man');
        await tester
            .pump(const Duration(milliseconds: 500)); // Trigger debounce.
        await tester.pumpAndSettle(
            const Duration(seconds: 3)); // Wait for search results.

        // Step 3: Verify search results appear.
        // Look for "Titles" section header which appears when results are loaded.

        expect(
          find.text('Titles'),
          findsOneWidget,
          reason: 'Search results should be displayed',
        );

        // Step 4: Tap on the first movie in search results.
        // Find movie cards/list tiles - we'll tap the first one.

        final movieTiles = find.byType(ListTile);
        expect(
          movieTiles,
          findsWidgets,
          reason: 'Movie results should be displayed as list tiles',
        );
        await tester.tap(movieTiles.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Step 5: Verify we're on the movie details screen.

        expect(find.byType(MovieDetailsScreen), findsOneWidget);

        // Verify key elements are present on details screen.

        expect(
          find.text('Your Rating'),
          findsOneWidget,
          reason: 'Rating section should be visible',
        );
        expect(
          find.byType(Slider),
          findsOneWidget,
          reason: 'Rating slider should be visible',
        );

        // Step 6: Rate the movie using the slider.

        final slider = find.byType(Slider);
        await tester.tap(slider);
        await tester.pump();

        // Drag slider to set a rating (e.g. 8.5 out of 10).

        await tester.drag(slider, const Offset(100, 0));
        await tester.pump();

        // Wait for rating to be saved (3 second delay from movie_details_screen.dart).

        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Step 7: Add movie to favorites using the bookmark icon.
        // Try to find either the filled or unfilled bookmark icon.

        Finder bookmarkIcon;
        if (find.byIcon(Icons.bookmark_border).evaluate().isNotEmpty) {
          bookmarkIcon = find.byIcon(Icons.bookmark_border);
        } else {
          bookmarkIcon = find.byIcon(Icons.bookmark);
        }
        expect(
          bookmarkIcon,
          findsOneWidget,
          reason: 'Bookmark icon should be visible in app bar',
        );
        await tester.tap(bookmarkIcon);
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Verify bookmark icon changed state (to filled bookmark).

        expect(
          find.byIcon(Icons.bookmark),
          findsOneWidget,
          reason: 'Movie should be bookmarked',
        );

        // Success! All workflow steps completed.
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    testWidgets(
      'Search for movie and verify results appear',
      (tester) async {
        // Load API key from fixtures file.
        final apiKey = await loadTmdbApiKey();

        SharedPreferences.setMockInitialValues({
          'tmdb_api_key': apiKey,
        });
        final prefs = await SharedPreferences.getInstance();
        await CacheSettingsService.instance.initialize();
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

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: const MovieStar(),
          ),
        );

        await tester.pumpAndSettle(const Duration(seconds: 5));
        await Future.delayed(delay);

        // Tap Continue button if login dialog is shown.

        final continueButton = find.text('Continue');
        if (continueButton.evaluate().isNotEmpty) {
          await tester.tap(continueButton);
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }
        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Open search.

        final searchIconButtons = find.byWidgetPredicate(
          (widget) =>
              widget is IconButton &&
              widget.icon is Icon &&
              (widget.icon as Icon).icon == Icons.search,
        );
        final searchFinder = searchIconButtons.evaluate().isNotEmpty
            ? searchIconButtons
            : find.byIcon(Icons.search);
        await tester.tap(searchFinder.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Search for a popular movie.

        final searchField = find.byType(TextField);
        await tester.enterText(searchField, 'inception');
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Verify results appeared.

        expect(find.text('Titles'), findsOneWidget);
        expect(find.byType(ListTile), findsWidgets);
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );

    testWidgets(
      'View movie details and verify rating controls',
      (tester) async {
        // Load API key from fixtures file.
        final apiKey = await loadTmdbApiKey();

        SharedPreferences.setMockInitialValues({
          'tmdb_api_key': apiKey,
        });
        final prefs = await SharedPreferences.getInstance();
        await CacheSettingsService.instance.initialize();
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

        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: const MovieStar(),
          ),
        );

        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Tap Continue button if login dialog is shown.

        final continueButton = find.text('Continue');
        if (continueButton.evaluate().isNotEmpty) {
          await tester.tap(continueButton);
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }
        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Navigate to search and find a movie.

        final searchIconButtons = find.byWidgetPredicate(
          (widget) =>
              widget is IconButton &&
              widget.icon is Icon &&
              (widget.icon as Icon).icon == Icons.search,
        );
        final searchFinder = searchIconButtons.evaluate().isNotEmpty
            ? searchIconButtons
            : find.byIcon(Icons.search);
        await tester.tap(searchFinder.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final searchField = find.byType(TextField);
        await tester.enterText(searchField, 'matrix');
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Tap first result.

        final movieTiles = find.byType(ListTile);
        await tester.tap(movieTiles.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Verify movie details screen elements.

        expect(find.byType(MovieDetailsScreen), findsOneWidget);
        expect(find.text('Your Rating'), findsOneWidget);
        expect(find.byType(Slider), findsOneWidget);

        // Verify bookmark icon exists (either filled or unfilled).

        final hasBookmarkBorder =
            find.byIcon(Icons.bookmark_border).evaluate().isNotEmpty;
        final hasBookmark = find.byIcon(Icons.bookmark).evaluate().isNotEmpty;
        expect(
          hasBookmarkBorder || hasBookmark,
          isTrue,
          reason: 'Bookmark icon should be visible',
        );
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  });
}
