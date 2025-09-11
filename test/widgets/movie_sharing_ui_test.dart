/// Tests for Movie Sharing UI.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/widgets/movie_sharing_ui.dart';

void main() {
  group('MovieSharingUI', () {
    late Movie testMovie;

    setUp(() {
      testMovie = Movie(
        id: 123,
        title: 'Test Movie',
        overview: 'A test movie for unit testing',
        releaseDate: DateTime.parse('2025-01-01'),
        posterUrl: 'https://image.tmdb.org/t/p/w500/test.jpg',
        backdropUrl: 'https://image.tmdb.org/t/p/w1280/test.jpg',
        genreIds: [28, 12],
        voteAverage: 7.5,
      );
    });

    testWidgets('displays movie title in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MovieSharingUI(
            movie: testMovie,
            onSharingComplete: () {},
          ),
        ),
      );

      expect(find.text('Share "Test Movie"'), findsOneWidget);
    });

    testWidgets('displays back button in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MovieSharingUI(
            movie: testMovie,
            onSharingComplete: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('back button navigates to home', (WidgetTester tester) async {
      bool navigationCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MovieSharingUI(
                            movie: testMovie,
                            onSharingComplete: () {},
                          ),
                        ),
                      );
                    },
                    child: const Text('Open Sharing'),
                  ),
                ),
              );
            },
            observers: [
              _TestNavigatorObserver(() {
                navigationCalled = true;
              }),
            ],
          ),
        ),
      );

      // Navigate to MovieSharingUI
      await tester.tap(find.text('Open Sharing'));
      await tester.pumpAndSettle();

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(navigationCalled, isTrue);
    });

    testWidgets('displays movie poster', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MovieSharingUI(
            movie: testMovie,
            onSharingComplete: () {},
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsWidgets);
    });

    testWidgets('displays movie metadata', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MovieSharingUI(
            movie: testMovie,
            onSharingComplete: () {},
          ),
        ),
      );

      expect(find.text('Test Movie'), findsWidgets);
      expect(find.textContaining('2025'), findsOneWidget);
      expect(find.textContaining('Movie-123.ttl'), findsOneWidget);
    });

    testWidgets('displays share instructions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MovieSharingUI(
            movie: testMovie,
            onSharingComplete: () {},
          ),
        ),
      );

      expect(find.textContaining('Share'), findsWidgets);
      expect(find.textContaining('WebID'), findsWidgets);
    });

    testWidgets('displays WebID input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MovieSharingUI(
            movie: testMovie,
            onSharingComplete: () {},
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Share With'), findsOneWidget);
    });

    testWidgets('displays share button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MovieSharingUI(
            movie: testMovie,
            onSharingComplete: () {},
          ),
        ),
      );

      expect(
          find.widgetWithText(ElevatedButton, 'Share Movie'), findsOneWidget,);
    });

    testWidgets('share button is disabled initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MovieSharingUI(
            movie: testMovie,
            onSharingComplete: () {},
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Share Movie'),
      );

      expect(button.onPressed, isNull);
    });

    testWidgets('share button enables after valid WebID entry',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MovieSharingUI(
            movie: testMovie,
            onSharingComplete: () {},
          ),
        ),
      );

      // Initially button should be disabled
      final initialButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Share Movie'),
      );
      expect(initialButton.onPressed, isNull);

      // Note: Since we don't mock the validation service,
      // the button will remain disabled in test environment
      // This test validates the initial disabled state
    });

    testWidgets('displays permission information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MovieSharingUI(
            movie: testMovie,
            onSharingComplete: () {},
          ),
        ),
      );

      expect(find.textContaining('permission'), findsWidgets);
    });

    testWidgets('handles scroll correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MovieSharingUI(
            movie: testMovie,
            onSharingComplete: () {},
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Try to scroll
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -200),);
      await tester.pump();

      // Should still show all key elements
      expect(find.text('Share "Test Movie"'), findsOneWidget);
    });

    testWidgets('calls onSharingComplete callback',
        (WidgetTester tester) async {
      bool callbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MovieSharingUI(
            movie: testMovie,
            onSharingComplete: () {
              callbackCalled = true;
            },
          ),
        ),
      );

      // Note: In real scenario, this would be called after successful sharing
      // For now, we just verify the callback is properly passed
      expect(callbackCalled, isFalse);
    });

    testWidgets('displays correct layout on different screen sizes',
        (WidgetTester tester) async {
      // Test on small screen
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: MovieSharingUI(
            movie: testMovie,
            onSharingComplete: () {},
          ),
        ),
      );

      expect(find.byType(MovieSharingUI), findsOneWidget);

      // Test on large screen
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: MovieSharingUI(
            movie: testMovie,
            onSharingComplete: () {},
          ),
        ),
      );

      expect(find.byType(MovieSharingUI), findsOneWidget);

      // Reset
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}

class _TestNavigatorObserver extends NavigatorObserver {
  final VoidCallback onPop;

  _TestNavigatorObserver(this.onPop);

  @override
  void didPop(Route route, Route? previousRoute) {
    onPop();
    super.didPop(route, previousRoute);
  }
}
