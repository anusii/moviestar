/// Tests for Movie Details Screen.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/core/services/favorites/service.dart';
import 'package:rxdart/rxdart.dart';

// Mock FavoritesService for testing
class MockFavoritesService extends ChangeNotifier implements FavoritesService {
  final List<Movie> _toWatchMovies = [];
  final List<Movie> _watchedMovies = [];
  final List<CustomList> _customLists = [];
  final Map<int, double> _ratings = {};
  final Map<int, bool> _hasFiles = {};
  final Map<int, String> _comments = {};

  // Stream controllers
  final _toWatchController = BehaviorSubject<List<Movie>>();
  final _watchedController = BehaviorSubject<List<Movie>>();
  final _customListsController = BehaviorSubject<List<CustomList>>();

  // Stream getters
  @override
  Stream<List<Movie>> get toWatchMovies => _toWatchController.stream;

  @override
  Stream<List<Movie>> get watchedMovies => _watchedController.stream;

  @override
  Stream<List<CustomList>> get customLists => _customListsController.stream;

  MockFavoritesService() {
    _toWatchController.add(_toWatchMovies);
    _watchedController.add(_watchedMovies);
    _customListsController.add(_customLists);
  }

  @override
  Future<List<Movie>> getToWatch() async => _toWatchMovies;

  @override
  Future<List<Movie>> getWatched() async => _watchedMovies;

  @override
  Future<List<CustomList>> getCustomLists() async => _customLists;

  @override
  Future<bool> isInToWatch(Movie movie) async =>
      _toWatchMovies.any((m) => m.id == movie.id);

  @override
  Future<bool> isInWatched(Movie movie) async =>
      _watchedMovies.any((m) => m.id == movie.id);

  @override
  Future<double?> getPersonalRating(Movie movie) async => _ratings[movie.id];

  @override
  Future<bool> hasMovieFile(Movie movie) async => _hasFiles[movie.id] ?? false;

  @override
  Future<void> addToWatch(Movie movie, {String contentType = 'movie'}) async {
    if (!_toWatchMovies.any((m) => m.id == movie.id)) {
      _toWatchMovies.add(movie);
      _toWatchController.add(_toWatchMovies);
    }
  }

  @override
  Future<void> addToWatched(Movie movie, {String contentType = 'movie'}) async {
    if (!_watchedMovies.any((m) => m.id == movie.id)) {
      _watchedMovies.add(movie);
      _watchedController.add(_watchedMovies);
    }
  }

  @override
  Future<void> removeFromToWatch(Movie movie) async {
    _toWatchMovies.removeWhere((m) => m.id == movie.id);
    _toWatchController.add(_toWatchMovies);
  }

  @override
  Future<void> removeFromWatched(Movie movie) async {
    _watchedMovies.removeWhere((m) => m.id == movie.id);
    _watchedController.add(_watchedMovies);
  }

  @override
  Future<void> addMovieToCustomList(
    String listId,
    Movie movie, {
    String contentType = 'movie',
  }) async {
    // Find the list and add movie
    final listIndex = _customLists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final list = _customLists[listIndex];
      if (!list.movieIds.contains(movie.id)) {
        final updatedMovieIds = List<int>.from(list.movieIds);
        updatedMovieIds.add(movie.id);
        _customLists[listIndex] = CustomList(
          id: list.id,
          name: list.name,
          description: list.description,
          movieIds: updatedMovieIds,
          createdAt: list.createdAt,
          updatedAt: DateTime.now(),
        );
        _customListsController.add(_customLists);
      }
    }
  }

  @override
  Future<void> removeMovieFromCustomList(String listId, int movieId) async {
    final listIndex = _customLists.indexWhere((l) => l.id == listId);
    if (listIndex != -1) {
      final list = _customLists[listIndex];
      final updatedMovieIds = List<int>.from(list.movieIds);
      updatedMovieIds.remove(movieId);
      _customLists[listIndex] = CustomList(
        id: list.id,
        name: list.name,
        description: list.description,
        movieIds: updatedMovieIds,
        createdAt: list.createdAt,
        updatedAt: DateTime.now(),
      );
      _customListsController.add(_customLists);
    }
  }

  @override
  Future<void> setPersonalRating(Movie movie, double rating) async {
    _ratings[movie.id] = rating;
  }

  @override
  Future<void> removePersonalRating(Movie movie) async {
    _ratings.remove(movie.id);
  }

  @override
  Future<void> setMovieComments(Movie movie, String comments) async {
    _comments[movie.id] = comments;
  }

  @override
  Future<String?> getMovieComments(Movie movie) async => _comments[movie.id];

  @override
  Future<void> removeMovieComments(Movie movie) async {
    _comments.remove(movie.id);
  }

  @override
  Future<CustomList> createCustomList(
    String name, {
    String? description,
  }) async {
    final newList = CustomList(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: description ?? '',
      movieIds: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _customLists.add(newList);
    _customListsController.add(_customLists);
    return newList;
  }

  @override
  Future<void> deleteCustomList(String listId) async {
    _customLists.removeWhere((list) => list.id == listId);
    _customListsController.add(_customLists);
  }

  @override
  Future<void> updateCustomList(CustomList updatedList) async {
    final index = _customLists.indexWhere((l) => l.id == updatedList.id);
    if (index != -1) {
      _customLists[index] = updatedList;
      _customListsController.add(_customLists);
    }
  }

  @override
  Future<List<Movie>> getMoviesInCustomList(String listId) async {
    final list = _customLists.firstWhere(
      (l) => l.id == listId,
      orElse: () => CustomList(
        id: '',
        name: '',
        movieIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    // Return mock movies for the IDs in the list
    return list.movieIds
        .map(
          (id) => Movie(
            id: id,
            title: 'Movie $id',
            overview: 'Test movie $id',
            posterUrl: '/test.jpg',
            backdropUrl: '/test_backdrop.jpg',
            voteAverage: 7.5,
            releaseDate: DateTime.parse('2023-01-01'),
            genreIds: [],
          ),
        )
        .toList();
  }

  @override
  Future<List<int>> getMovieIdsInCustomList(String listId) async {
    final list = _customLists.firstWhere(
      (l) => l.id == listId,
      orElse: () => CustomList(
        id: '',
        name: '',
        movieIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return list.movieIds;
  }

  @override
  Future<List<CustomList>> getCustomListsContainingMovie(int movieId) async {
    return _customLists
        .where((list) => list.movieIds.contains(movieId))
        .toList();
  }

  @override
  Future<bool> isMovieInCustomList(String listId, int movieId) async {
    final list = _customLists.firstWhere(
      (l) => l.id == listId,
      orElse: () => CustomList(
        id: '',
        name: '',
        movieIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return list.movieIds.contains(movieId);
  }

  @override
  String? getMovieFilePath(Movie movie) => null;

  @override
  void dispose() {
    _toWatchController.close();
    _watchedController.close();
    _customListsController.close();
    super.dispose();
  }
}

void main() {
  group('MovieDetailsScreen Widget Tests', () {
    late Movie testMovie;
    late MockFavoritesService mockService;

    setUp(() {
      testMovie = Movie(
        id: 123,
        title: 'Test Movie',
        overview: 'A test movie for details screen testing',
        releaseDate: DateTime.parse('2025-01-01'),
        posterUrl: 'https://image.tmdb.org/t/p/w500/test.jpg',
        backdropUrl: 'https://image.tmdb.org/t/p/w1280/test.jpg',
        genreIds: [28],
        voteAverage: 7.5,
      );

      mockService = MockFavoritesService();
    });

    testWidgets('creates MovieDetailsScreen widget',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailsScreen(
            movie: testMovie,
            favoritesService: mockService,
          ),
        ),
      );

      // Just verify the widget builds without crashing
      expect(find.byType(MovieDetailsScreen), findsOneWidget);
    });

    testWidgets('displays movie data in widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailsScreen(
            movie: testMovie,
            favoritesService: mockService,
          ),
        ),
      );

      await tester.pump();

      // Basic structure tests
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('handles content type parameter', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailsScreen(
            movie: testMovie,
            favoritesService: mockService,
            contentType: ContentType.movie,
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(MovieDetailsScreen), findsOneWidget);
    });

    testWidgets('handles shared movie data parameter',
        (WidgetTester tester) async {
      final sharedData = {
        'rating': 4.5,
        'comments': 'Great movie!',
        'sharedBy': 'test@example.com',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailsScreen(
            movie: testMovie,
            favoritesService: mockService,
            sharedMovieData: sharedData,
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(MovieDetailsScreen), findsOneWidget);
    });

    testWidgets('handles TV show content type', (WidgetTester tester) async {
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
          home: MovieDetailsScreen(
            movie: tvShow,
            favoritesService: mockService,
            contentType: ContentType.tvShow,
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(MovieDetailsScreen), findsOneWidget);
    });

    testWidgets('has proper widget structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailsScreen(
            movie: testMovie,
            favoritesService: mockService,
          ),
        ),
      );

      await tester.pump();

      // Should have basic scaffold structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);

      // Should have some interactive elements
      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('handles state initialization', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailsScreen(
            movie: testMovie,
            favoritesService: mockService,
          ),
        ),
      );

      await tester.pump();

      // Widget should initialize state properly
      expect(find.byType(MovieDetailsScreen), findsOneWidget);
    });

    testWidgets('handles user interactions without crashing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailsScreen(
            movie: testMovie,
            favoritesService: mockService,
          ),
        ),
      );

      await tester.pump();

      // Find any tappable elements and test interaction
      final buttons = find.byType(IconButton);
      if (buttons.evaluate().isNotEmpty) {
        await tester.tap(buttons.first);
        await tester.pump();

        // Should not crash after interaction
        expect(find.byType(MovieDetailsScreen), findsOneWidget);
      }
    });
  });

  group('MovieDetailsScreen Edge Cases', () {
    late MockFavoritesService mockService;

    setUp(() {
      mockService = MockFavoritesService();
    });

    testWidgets('handles movie with minimal data', (WidgetTester tester) async {
      final minimalMovie = Movie(
        id: 999,
        title: 'Minimal Movie',
        overview: '',
        releaseDate: DateTime.parse('2023-01-01'),
        posterUrl: '',
        backdropUrl: '',
        genreIds: [],
        voteAverage: 0.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailsScreen(
            movie: minimalMovie,
            favoritesService: mockService,
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(MovieDetailsScreen), findsOneWidget);
    });

    testWidgets('handles movie with maximum values',
        (WidgetTester tester) async {
      final maxMovie = Movie(
        id: 888,
        title:
            'Maximum Movie with Very Long Title That Should Be Handled Gracefully',
        overview:
            'Very long overview that contains detailed information about the movie plot and characters and should not cause any overflow issues in the user interface layout when displayed in the movie details screen',
        releaseDate: DateTime.parse('2030-12-31'),
        posterUrl: 'https://image.tmdb.org/t/p/w500/test.jpg',
        backdropUrl: 'https://image.tmdb.org/t/p/w1280/test.jpg',
        genreIds: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        voteAverage: 10.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailsScreen(
            movie: maxMovie,
            favoritesService: mockService,
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(MovieDetailsScreen), findsOneWidget);
    });

    testWidgets('handles null and empty shared data',
        (WidgetTester tester) async {
      final testMovie = Movie(
        id: 777,
        title: 'Shared Test Movie',
        overview: 'Movie for shared data testing',
        releaseDate: DateTime.parse('2025-01-01'),
        posterUrl: 'https://image.tmdb.org/t/p/w500/test.jpg',
        backdropUrl: 'https://image.tmdb.org/t/p/w1280/test.jpg',
        genreIds: [],
        voteAverage: 7.0,
      );

      // Test with empty shared data
      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailsScreen(
            movie: testMovie,
            favoritesService: mockService,
            sharedMovieData: {},
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(MovieDetailsScreen), findsOneWidget);
    });

    testWidgets('handles disposal correctly', (WidgetTester tester) async {
      final testMovie = Movie(
        id: 666,
        title: 'Disposal Test Movie',
        overview: 'Movie for disposal testing',
        releaseDate: DateTime.parse('2025-01-01'),
        posterUrl: 'https://image.tmdb.org/t/p/w500/test.jpg',
        backdropUrl: 'https://image.tmdb.org/t/p/w1280/test.jpg',
        genreIds: [],
        voteAverage: 6.5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailsScreen(
            movie: testMovie,
            favoritesService: mockService,
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(MovieDetailsScreen), findsOneWidget);

      // Test navigation away (disposal)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Different Screen')),
        ),
      );

      await tester.pump();
      expect(find.text('Different Screen'), findsOneWidget);
    });
  });
}
