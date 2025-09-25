/// Test suite for EnhancedSearchScreen - Basic widget creation tests
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

import 'package:moviestar/screens/enhanced_search_screen.dart';
import 'package:moviestar/core/services/api/content_service.dart';
import 'package:moviestar/core/services/favorites/service.dart';

void main() {
  group('EnhancedSearchScreen Tests', () {
    late ContentService contentService;
    late FavoritesService favoritesService;

    setUpAll(() async {
      // Initialize SharedPreferences for tests
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Create services
      contentService = ContentService(null);
      favoritesService = FavoritesService(prefs);
    });

    testWidgets('should create widget with required parameters',
        (WidgetTester tester) async {
      // Act & Assert
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EnhancedSearchScreen(
              favoritesService: favoritesService,
              contentService: contentService,
            ),
          ),
        ),
      );

      expect(find.byType(EnhancedSearchScreen), findsOneWidget);
    });

    testWidgets('should accept FavoritesService parameter',
        (WidgetTester tester) async {
      const testKey = Key('enhanced-search-screen');

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EnhancedSearchScreen(
              key: testKey,
              favoritesService: favoritesService,
              contentService: contentService,
            ),
          ),
        ),
      );

      // Assert
      final searchScreen =
          tester.widget<EnhancedSearchScreen>(find.byKey(testKey));
      expect(searchScreen.favoritesService, isA<FavoritesService>());
    });

    testWidgets('should accept ContentService parameter',
        (WidgetTester tester) async {
      const testKey = Key('enhanced-search-screen');

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EnhancedSearchScreen(
              key: testKey,
              favoritesService: favoritesService,
              contentService: contentService,
            ),
          ),
        ),
      );

      // Assert
      final searchScreen =
          tester.widget<EnhancedSearchScreen>(find.byKey(testKey));
      expect(searchScreen.contentService, isA<ContentService>());
    });

    testWidgets('should be a StatefulWidget', (WidgetTester tester) async {
      const testKey = Key('enhanced-search-screen');

      // Act
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EnhancedSearchScreen(
              key: testKey,
              favoritesService: favoritesService,
              contentService: contentService,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byKey(testKey), findsOneWidget);
      final widget = tester.widget(find.byKey(testKey));
      expect(widget, isA<StatefulWidget>());
    });

    testWidgets('should render without throwing exceptions',
        (WidgetTester tester) async {
      // This test verifies the widget can be instantiated and rendered
      // without any runtime exceptions during build

      // Act & Assert - if this doesn't throw, the test passes
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: EnhancedSearchScreen(
              favoritesService: favoritesService,
              contentService: contentService,
            ),
          ),
        ),
      );

      // Pump once more to ensure no delayed exceptions
      await tester.pump();

      // Verify the widget exists in the tree
      expect(find.byType(EnhancedSearchScreen), findsOneWidget);
    });
  });
}
