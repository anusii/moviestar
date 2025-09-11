/// Tests for Quick Actions Dialog.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/widgets/quick_actions_dialog.dart';

// Simple test implementation that implements the interface
class MockFavoritesService implements FavoritesService {
  bool _isInToWatch = false;
  bool _isInWatched = false;
  double? _personalRating;
  bool _hasFile = false;

  void setToWatch(bool value) => _isInToWatch = value;
  void setWatched(bool value) => _isInWatched = value;
  void setRating(double? value) => _personalRating = value;
  void setHasFile(bool value) => _hasFile = value;

  @override
  Future<bool> isInToWatch(Movie movie) async => _isInToWatch;

  @override
  Future<bool> isInWatched(Movie movie) async => _isInWatched;

  @override
  Future<double?> getPersonalRating(Movie movie) async => _personalRating;

  @override
  Future<bool> hasMovieFile(Movie movie) async => _hasFile;

  @override
  Future<void> addToWatch(Movie movie, {String contentType = 'movie'}) async {
    _isInToWatch = true;
  }

  @override
  Future<void> removeFromToWatch(Movie movie) async {
    _isInToWatch = false;
  }

  @override
  Future<void> addToWatched(Movie movie, {String contentType = 'movie'}) async {
    _isInWatched = true;
  }

  @override
  Future<void> removeFromWatched(Movie movie) async {
    _isInWatched = false;
  }

  @override
  Future<void> setPersonalRating(Movie movie, double rating) async {
    _personalRating = rating;
  }

  @override
  Future<void> removePersonalRating(Movie movie) async {
    _personalRating = null;
  }

  @override
  Future<void> setMovieComments(Movie movie, String comments) async {}

  @override
  Future<void> removeMovieComments(Movie movie) async {}

  @override
  Future<List<Movie>> getToWatch() async => [];

  @override
  Future<List<Movie>> getWatched() async => [];

  @override
  Future<List<CustomList>> getCustomLists() async => [];

  @override
  Future<CustomList> createCustomList(
    String name, {
    String? description,
  }) async => CustomList(
        id: 'test-${name.toLowerCase().replaceAll(' ', '-')}',
        name: name,
        description: description,
        movieIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  @override
  Future<void> updateCustomList(CustomList updatedList) async {}

  @override
  Future<void> deleteCustomList(String listId) async {}

  @override
  Future<void> addMovieToCustomList(
    String listId,
    Movie movie, {
    String contentType = 'movie',
  }) async {}

  @override
  Future<void> removeMovieFromCustomList(String listId, int movieId) async {}

  @override
  Future<bool> isMovieInCustomList(String listId, int movieId) async => false;

  @override
  Future<List<CustomList>> getCustomListsContainingMovie(int movieId) async => [];

  @override
  Future<List<Movie>> getMoviesInCustomList(String listId) async => [];

  @override
  Future<List<int>> getMovieIdsInCustomList(String listId) async => [];

  @override
  Future<String?> getMovieComments(Movie movie) async => null;

  @override
  String? getMovieFilePath(Movie movie) => null;

  @override
  Future<Map<String, dynamic>> exportUserData() async => {};

  @override
  Future<void> importUserData(Map<String, dynamic> data) async {}

  @override
  Future<void> clearAllData() async {}

  @override
  Stream<List<Movie>> get toWatchMovies => Stream.value([]);

  @override
  Stream<List<Movie>> get watchedMovies => Stream.value([]);

  @override
  Stream<List<CustomList>> get customLists => Stream.value([]);

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  void dispose() {}

  @override
  bool get hasListeners => false;

  @override
  void notifyListeners() {}
}

void main() {
  group('QuickActionsDialog', () {
    late Movie testMovie;
    late MockFavoritesService mockService;

    setUp(() {
      testMovie = Movie(
        id: 123,
        title: 'Test Movie',
        overview: 'A test movie',
        releaseDate: DateTime.parse('2025-01-01'),
        posterUrl: 'https://image.tmdb.org/t/p/w500/test.jpg',
        backdropUrl: 'https://image.tmdb.org/t/p/w1280/test.jpg',
        genreIds: [28],
        voteAverage: 7.5,
      );
      
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

    testWidgets('displays content type indicator for movie', (WidgetTester tester) async {
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

    testWidgets('displays content type indicator for TV show', (WidgetTester tester) async {
      final tvShow = Movie(
        id: 456,
        title: 'Test TV Show',
        overview: 'A test TV show',
        releaseDate: DateTime.parse('2025-01-01'),
        posterUrl: 'https://image.tmdb.org/t/p/w500/test.jpg',
        backdropUrl: 'https://image.tmdb.org/t/p/w1280/test.jpg',
        genreIds: [18],
        voteAverage: 8.0,
        contentType: ContentType.tvShow,
      );

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

    testWidgets('displays no rating text initially', (WidgetTester tester) async {
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

    testWidgets('does not display share button when no file', (WidgetTester tester) async {
      mockService.setHasFile(false);
      
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
      await gesture.addPointer(location: tester.getCenter(find.byType(QuickActionsDialog)));
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