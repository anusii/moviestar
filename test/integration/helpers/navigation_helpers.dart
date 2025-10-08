/// Navigation and assertion helpers for integration testing.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/screens/enhanced_search_screen.dart';
import 'package:moviestar/screens/home_screen.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/screens/my_lists_screen.dart';

// ============================================================================
// FINDER HELPERS
// ============================================================================

/// Finds the home screen widget.

Finder findHomeScreen() => find.byType(HomeScreen);

/// Finds the search screen widget.

Finder findSearchScreen() => find.byType(EnhancedSearchScreen);

/// Finds the movie details screen widget.

Finder findMovieDetailsScreen() => find.byType(MovieDetailsScreen);

/// Finds the my lists screen widget.

Finder findMyListsScreen() => find.byType(MyListsScreen);

/// Finds a movie card by title.
///
/// Searches for text matching the movie title within the widget tree.

Finder findMovieCard(String movieTitle) => find.text(movieTitle);

/// Finds a button by icon.

Finder findButtonByIcon(IconData icon) => find.byIcon(icon);

/// Finds a button by text label.

Finder findButtonByText(String text) =>
    find.widgetWithText(ElevatedButton, text);

/// Finds a dialog by title.

Finder findDialog(String title) => find.text(title);

/// Finds a widget by test key.

Finder findByTestKey(String key) => find.byKey(Key(key));

// ============================================================================
// NAVIGATION ACTION HELPERS
// ============================================================================

/// Navigates to the search screen.
///
/// Taps the search icon and waits for the screen to settle.

Future<void> navigateToSearch(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.search));
  await tester.pumpAndSettle();
}

/// Navigates back using the back button.

Future<void> navigateBack(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.arrow_back));
  await tester.pumpAndSettle();
}

/// Taps on a movie card by title.
///
/// Waits for the tap to settle and the next screen to load.

Future<void> tapMovieCard(WidgetTester tester, String movieTitle) async {
  await tester.tap(findMovieCard(movieTitle));
  await tester.pumpAndSettle();
}

/// Enters a search query in the search field.
///
/// Finds the TextField, enters text, and triggers a search.

Future<void> enterSearchQuery(WidgetTester tester, String query) async {
  final searchField = find.byType(TextField);
  expect(searchField, findsOneWidget);

  await tester.enterText(searchField, query);
  await tester.pumpAndSettle();

  // Optionally trigger search by tapping search button or pressing enter.

  final searchButton = find.byIcon(Icons.search);
  if (searchButton.evaluate().isNotEmpty) {
    await tester.tap(searchButton);
    await tester.pumpAndSettle();
  }
}

/// Taps a button by icon.

Future<void> tapButton(WidgetTester tester, IconData icon) async {
  await tester.tap(find.byIcon(icon));
  await tester.pumpAndSettle();
}

/// Taps a button by text.

Future<void> tapButtonByText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

// ============================================================================
// MOVIE ACTION HELPERS
// ============================================================================

/// Adds a movie to the "To Watch" list.
///
/// Taps the bookmark icon to add the movie.

Future<void> addToWatchList(WidgetTester tester) async {
  final bookmarkIcon = find.byIcon(Icons.bookmark_border);
  if (bookmarkIcon.evaluate().isEmpty) {
    // Already bookmarked, look for filled icon.

    expect(find.byIcon(Icons.bookmark), findsOneWidget);
    return;
  }

  await tester.tap(bookmarkIcon);
  await tester.pumpAndSettle();
}

/// Removes a movie from the "To Watch" list.
///
/// Taps the filled bookmark icon to remove the movie.

Future<void> removeFromWatchList(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.bookmark));
  await tester.pumpAndSettle();
}

/// Adds a movie to the "Watched" list.
///
/// Taps the check circle icon to mark as watched.

Future<void> markAsWatched(WidgetTester tester) async {
  final watchedIcon = find.byIcon(Icons.check_circle_outline);
  if (watchedIcon.evaluate().isEmpty) {
    // Already watched, look for filled icon.

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    return;
  }

  await tester.tap(watchedIcon);
  await tester.pumpAndSettle();
}

/// Sets a movie rating using the slider.
///
/// Finds the slider and sets it to the specified rating (0-10).

Future<void> setMovieRating(WidgetTester tester, double rating) async {
  final sliderFinder = find.byType(Slider);
  expect(sliderFinder, findsOneWidget);

  // Sliders typically use 0-1 range, so normalize if needed.
  // Adjust based on your app's slider configuration.

  final normalizedRating = rating / 10.0; // Assuming 0-10 rating scale.

  await tester.drag(sliderFinder, Offset(normalizedRating * 100, 0));
  await tester.pumpAndSettle();
}

/// Adds a movie to a custom list.
///
/// Opens the "Add to List" dialog and selects the specified list.

Future<void> addToCustomList(WidgetTester tester, String listName) async {
  // This will vary based on your UI - adjust as needed.
  // Example: tap "Add to List" button.

  final addToListButton = find.text('Add to List');
  if (addToListButton.evaluate().isNotEmpty) {
    await tester.tap(addToListButton);
    await tester.pumpAndSettle();

    // Select the list from dialog.

    await tester.tap(find.text(listName));
    await tester.pumpAndSettle();
  }
}

/// Shares a movie via POD.

Future<void> shareMovie(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.share));
  await tester.pumpAndSettle();
}

// ============================================================================
// ASSERTION HELPERS
// ============================================================================

/// Verifies that a movie is in the specified list.

void expectMovieInList(Movie movie, String listName) {
  // This is a placeholder - actual implementation will depend on
  // how you access and verify list state in tests.
  // You might need to pass in a service reference or use finders.
}

/// Verifies that the current screen is of the specified type.

void expectOnScreen(Type screenType) {
  expect(find.byType(screenType), findsOneWidget);
}

/// Verifies that a specific widget exists on screen.

void expectWidgetExists(Finder finder, {int count = 1}) {
  if (count == 1) {
    expect(finder, findsOneWidget);
  } else {
    expect(finder, findsNWidgets(count));
  }
}

/// Verifies that a specific widget does NOT exist on screen.

void expectWidgetNotFound(Finder finder) {
  expect(finder, findsNothing);
}

/// Verifies that text appears on screen.

void expectTextOnScreen(String text) {
  expect(find.text(text), findsOneWidget);
}

/// Verifies that an icon appears on screen.

void expectIconOnScreen(IconData icon) {
  expect(find.byIcon(icon), findsOneWidget);
}

/// Verifies the navigation stack depth.
///
/// Note: This requires a NavigatorObserver to be set up in your test app.

void expectNavigationStackDepth(int depth, {required int actualDepth}) {
  expect(actualDepth, equals(depth));
}

// ============================================================================
// DIALOG HELPERS
// ============================================================================

/// Waits for a dialog to appear.

Future<void> waitForDialog(WidgetTester tester, String dialogTitle) async {
  await tester.pumpAndSettle();
  expect(find.text(dialogTitle), findsOneWidget);
}

/// Closes a dialog by tapping the close button.

Future<void> closeDialog(WidgetTester tester) async {
  final closeButton = find.byIcon(Icons.close);
  if (closeButton.evaluate().isNotEmpty) {
    await tester.tap(closeButton.first);
    await tester.pumpAndSettle();
  }
}

/// Confirms a dialog by tapping the confirm button.

Future<void> confirmDialog(
  WidgetTester tester, {
  String confirmText = 'OK',
}) async {
  await tester.tap(find.text(confirmText));
  await tester.pumpAndSettle();
}

/// Cancels a dialog by tapping the cancel button.

Future<void> cancelDialog(
  WidgetTester tester, {
  String cancelText = 'Cancel',
}) async {
  await tester.tap(find.text(cancelText));
  await tester.pumpAndSettle();
}

// ============================================================================
// WAIT HELPERS
// ============================================================================

/// Waits for a specific widget to appear.

Future<void> waitForWidget(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final endTime = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(endTime)) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 100));
  }

  throw Exception('Widget not found within timeout: $finder');
}

/// Waits for a widget to disappear.

Future<void> waitForWidgetToDisappear(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final endTime = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(endTime)) {
    if (finder.evaluate().isEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 100));
  }

  throw Exception('Widget did not disappear within timeout: $finder');
}
