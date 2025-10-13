/// Tests for Quick Actions Dialog.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/widgets/quick_actions_dialog.dart';

import '../integration/helpers/mock_services.dart';
import '../integration/helpers/test_data_factory.dart';

void main() {
  group('QuickActionsDialog', () {
    late Movie testMovie;
    late MockFavoritesService mockService;

    setUp(() {
      testMovie = TestDataFactory.createMovie();
      mockService = MockFavoritesService();
    });

    testWidgets('displays movie title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionsDialog(
              movie: testMovie,
              favoritesService: mockService,
              onClose: () {},
              onMouseEnter: () {},
              onMouseExit: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Test Movie'), findsOneWidget);
    });

    testWidgets('displays content type indicator for movie',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionsDialog(
              movie: testMovie,
              favoritesService: mockService,
              contentType: ContentType.movie,
              onClose: () {},
              onMouseEnter: () {},
              onMouseExit: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('🎬 Movie'), findsOneWidget);
    });

    testWidgets('displays content type indicator for TV show',
        (WidgetTester tester) async {
      final tvShow = TestDataFactory.createTVShow();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionsDialog(
              movie: tvShow,
              favoritesService: mockService,
              contentType: ContentType.tvShow,
              onClose: () {},
              onMouseEnter: () {},
              onMouseExit: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('📺 TV Show'), findsOneWidget);
    });

    testWidgets('displays bookmark button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionsDialog(
              movie: testMovie,
              favoritesService: mockService,
              onClose: () {},
              onMouseEnter: () {},
              onMouseExit: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });

    testWidgets('toggles bookmark state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionsDialog(
              movie: testMovie,
              favoritesService: mockService,
              onClose: () {},
              onMouseEnter: () {},
              onMouseExit: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially not bookmarked
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);

      // Tap bookmark button
      await tester.tap(find.byIcon(Icons.bookmark_border));
      await tester.pumpAndSettle();

      // Should now be bookmarked
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
    });

    testWidgets('displays watched button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionsDialog(
              movie: testMovie,
              favoritesService: mockService,
              onClose: () {},
              onMouseEnter: () {},
              onMouseExit: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('displays rating slider', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionsDialog(
              movie: testMovie,
              favoritesService: mockService,
              onClose: () {},
              onMouseEnter: () {},
              onMouseExit: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Your Rating'), findsOneWidget);
    });

    testWidgets('displays no rating text initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionsDialog(
              movie: testMovie,
              favoritesService: mockService,
              onClose: () {},
              onMouseEnter: () {},
              onMouseExit: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('No rating yet'), findsOneWidget);
    });

    testWidgets('does not display share button when no file',
        (WidgetTester tester) async {
      // mockService has no file by default

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionsDialog(
              movie: testMovie,
              favoritesService: mockService,
              onClose: () {},
              onMouseEnter: () {},
              onMouseExit: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.share), findsNothing);
    });

    testWidgets('calls onMouseEnter callback', (WidgetTester tester) async {
      bool mouseEnterCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionsDialog(
              movie: testMovie,
              favoritesService: mockService,
              onClose: () {},
              onMouseEnter: () {
                mouseEnterCalled = true;
              },
              onMouseExit: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate mouse enter
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(
        location: tester.getCenter(find.byType(QuickActionsDialog)),
      );
      addTearDown(gesture.removePointer);

      await tester.pump();
      expect(mouseEnterCalled, isTrue);
    });

    testWidgets('shows correct initial state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickActionsDialog(
              movie: testMovie,
              favoritesService: mockService,
              onClose: () {},
              onMouseEnter: () {},
              onMouseExit: () {},
            ),
          ),
        ),
      );

      // The mock service completes synchronously, so loading should be done immediately
      await tester.pumpAndSettle();

      // Should show the dialog content after loading completes
      expect(find.byType(QuickActionsDialog), findsOneWidget);
      expect(find.text('Test Movie'), findsOneWidget);
    });
  });
}
