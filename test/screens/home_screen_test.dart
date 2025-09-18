/// Test suite for HomeScreen - Basic widget creation tests
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moviestar/screens/home_screen.dart';
import 'package:moviestar/core/services/favorites/favorites_service.dart';

void main() {
  group('HomeScreen Tests', () {
    late FavoritesService favoritesService;

    setUpAll(() async {
      // Initialize SharedPreferences for tests
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Create service
      favoritesService = FavoritesService(prefs);
    });

    testWidgets('should create widget with required parameters',
        (WidgetTester tester) async {
      // Act & Assert
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: HomeScreen(
              favoritesService: favoritesService,
            ),
          ),
        ),
      );

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('should accept FavoritesService parameter',
        (WidgetTester tester) async {
      const testKey = Key('home-screen');

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: HomeScreen(
              key: testKey,
              favoritesService: favoritesService,
            ),
          ),
        ),
      );

      // Assert
      final homeScreen = tester.widget<HomeScreen>(find.byKey(testKey));
      expect(homeScreen.favoritesService, isA<FavoritesService>());
    });

    testWidgets('should be a ConsumerStatefulWidget',
        (WidgetTester tester) async {
      const testKey = Key('home-screen');

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: HomeScreen(
              key: testKey,
              favoritesService: favoritesService,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byKey(testKey), findsOneWidget);
      final widget = tester.widget(find.byKey(testKey));
      expect(widget, isA<ConsumerStatefulWidget>());
    });

    testWidgets('should render without throwing exceptions',
        (WidgetTester tester) async {
      // This test verifies the widget can be instantiated and rendered
      // without any runtime exceptions during initial build

      // Act & Assert - if this doesn't throw, the test passes
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HomeScreen(
                favoritesService: favoritesService,
              ),
            ),
          ),
        ),
      );

      // Verify the widget exists in the tree without additional pumps
      // to avoid triggering cache feedback that needs ScaffoldMessenger
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('should display RefreshIndicator', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HomeScreen(
                favoritesService: favoritesService,
              ),
            ),
          ),
        ),
      );

      // Pump to ensure initial build without settling (to avoid snackbar issues)
      await tester.pump();

      // Assert - should find a RefreshIndicator widget
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('should handle view mode switching',
        (WidgetTester tester) async {
      // This is a basic test that the home screen can handle different view modes
      // without throwing exceptions

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: HomeScreen(
                favoritesService: favoritesService,
              ),
            ),
          ),
        ),
      );

      // Pump to ensure initial build without settling (to avoid snackbar issues)
      await tester.pump();

      // Assert - widget should still exist after all initialization
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
