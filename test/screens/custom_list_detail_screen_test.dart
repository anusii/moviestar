/// Test suite for CustomListDetailScreen.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/screens/custom_list_detail_screen.dart';
import 'package:moviestar/core/services/favorites/favorites_service.dart';

void main() {
  group('CustomListDetailScreen Tests', () {
    late CustomList testCustomList;
    late FavoritesService mockFavoritesService;

    setUp(() async {
      testCustomList = CustomList(
        id: '123456789',
        name: 'Test List',
        description: 'A test custom list',
        movieIds: [],
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
      );

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      mockFavoritesService = FavoritesService(prefs);
    });

    testWidgets('should create CustomListDetailScreen widget', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CustomListDetailScreen(
              customList: testCustomList,
              favoritesService: mockFavoritesService,
            ),
          ),
        ),
      );

      expect(find.byType(CustomListDetailScreen), findsOneWidget);
    });

    testWidgets('should be a ConsumerStatefulWidget', (tester) async {
      final widget = CustomListDetailScreen(
        customList: testCustomList,
        favoritesService: mockFavoritesService,
      );

      expect(widget, isA<ConsumerStatefulWidget>());
    });

    testWidgets('should accept CustomList and FavoritesService parameters', (tester) async {
      final widget = CustomListDetailScreen(
        customList: testCustomList,
        favoritesService: mockFavoritesService,
      );

      expect(widget.customList, equals(testCustomList));
      expect(widget.favoritesService, equals(mockFavoritesService));
    });

    group('CustomList properties', () {
      test('should have correct structure', () {
        expect(testCustomList.id, equals('123456789'));
        expect(testCustomList.name, equals('Test List'));
        expect(testCustomList.description, equals('A test custom list'));
        expect(testCustomList.movieIds, isEmpty);
        expect(testCustomList.createdAt, equals(DateTime(2025, 1, 1)));
        expect(testCustomList.updatedAt, equals(DateTime(2025, 1, 2)));
      });

      test('should handle empty movie list', () {
        expect(testCustomList.movieIds, isEmpty);
      });
    });
  });
}