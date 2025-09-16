/// Test suite for MyListsScreen - Basic widget creation tests
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

import 'package:moviestar/screens/my_lists_screen.dart';
import 'package:moviestar/core/services/favorites/favorites_service.dart';

void main() {
  group('MyListsScreen Tests', () {
    late FavoritesService favoritesService;

    setUpAll(() async {
      // Initialize SharedPreferences for tests
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Create service
      favoritesService = FavoritesService(prefs);
    });

    testWidgets('should create widget with required parameters', (WidgetTester tester) async {
      // Act & Assert
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyListsScreen(
              favoritesService: favoritesService,
            ),
          ),
        ),
      );

      expect(find.byType(MyListsScreen), findsOneWidget);
    });

    testWidgets('should accept FavoritesService parameter', (WidgetTester tester) async {
      const testKey = Key('my-lists-screen');

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyListsScreen(
              key: testKey,
              favoritesService: favoritesService,
            ),
          ),
        ),
      );

      // Assert
      final myListsScreen = tester.widget<MyListsScreen>(find.byKey(testKey));
      expect(myListsScreen.favoritesService, isA<FavoritesService>());
    });

    testWidgets('should be a ConsumerStatefulWidget', (WidgetTester tester) async {
      const testKey = Key('my-lists-screen');

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyListsScreen(
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

    testWidgets('should render without throwing exceptions', (WidgetTester tester) async {
      // This test verifies the widget can be instantiated and rendered
      // without any runtime exceptions during build

      // Act & Assert - if this doesn't throw, the test passes
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyListsScreen(
              favoritesService: favoritesService,
            ),
          ),
        ),
      );

      // Pump once more to ensure no delayed exceptions
      await tester.pump();

      // Verify the widget exists in the tree
      expect(find.byType(MyListsScreen), findsOneWidget);
    });

    testWidgets('should display screen title', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MyListsScreen(
              favoritesService: favoritesService,
            ),
          ),
        ),
      );

      // Pump and settle to ensure all widgets are built
      await tester.pumpAndSettle();

      // Assert - should find the "My Lists" title
      expect(find.text('My Lists'), findsOneWidget);
    });
  });
}