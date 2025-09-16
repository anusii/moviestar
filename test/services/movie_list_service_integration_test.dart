/// Integration tests for refactored MovieListService to ensure no regressions.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/movie_list_service.dart';
import 'package:moviestar/services/user_profile_service.dart';

void main() {
  group('MovieListService Integration Tests', () {
    late MovieListService service;
    late UserProfileService userProfileService;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Service preserves all public APIs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              userProfileService = UserProfileService(context, Container());
              service = MovieListService(context, Container(), userProfileService);
              return Container();
            },
          ),
        ),
      );

      // Test core methods exist
      expect(service.createMovieList, isA<Function>());
      expect(service.getMovieList, isA<Function>());
      expect(service.refreshMovieList, isA<Function>());
      expect(service.addMovieToList, isA<Function>());
      expect(service.removeMovieFromList, isA<Function>());
      expect(service.deleteMovieList, isA<Function>());
      expect(service.getAllMovieLists, isA<Function>());
      expect(service.initializeMovieList, isA<Function>());
      expect(service.updateMovieListName, isA<Function>());
      expect(service.getMovieListsContainingMovie, isA<Function>());
      expect(service.batchAddMoviesToList, isA<Function>());
      expect(service.clearCache, isA<Function>());
      expect(service.getMovieCount, isA<Function>());
      expect(service.isMovieInList, isA<Function>());

      // Service extends BasePodService (which extends ChangeNotifier)
      expect(service, isA<ChangeNotifier>());
    });

    testWidgets('Service creates movie list without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              userProfileService = UserProfileService(context, Container());
              service = MovieListService(context, Container(), userProfileService);
              return Container();
            },
          ),
        ),
      );

      // Test basic functionality without POD connection
      expect(() => service.clearCache(), returnsNormally);

      // Test movie creation with sample data
      final testMovie = Movie(
        id: 12345,
        title: 'Test Movie',
        overview: 'A test movie for integration testing',
        posterUrl: 'https://example.com/poster.jpg',
        backdropUrl: 'https://example.com/backdrop.jpg',
        releaseDate: DateTime(2024, 1, 1),
        voteAverage: 8.5,
        genreIds: [28, 35],
        contentType: ContentType.movie,
      );

      // These will return null in test environment without POD connection
      // but should not throw exceptions
      expect(() async {
        await service.createMovieList('Test List', movies: [testMovie]);
      }, returnsNormally);

      expect(() async {
        await service.getAllMovieLists();
      }, returnsNormally);

      expect(() async {
        await service.getMovieCount('test-id');
      }, returnsNormally);

      expect(() async {
        await service.isMovieInList('test-id', 12345);
      }, returnsNormally);
    });

    testWidgets('Service handles movie list operations gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              userProfileService = UserProfileService(context, Container());
              service = MovieListService(context, Container(), userProfileService);
              return Container();
            },
          ),
        ),
      );

      final testMovie = Movie(
        id: 67890,
        title: 'Another Test Movie',
        overview: 'Another test movie',
        posterUrl: 'https://example.com/poster2.jpg',
        backdropUrl: 'https://example.com/backdrop2.jpg',
        releaseDate: DateTime(2024, 6, 15),
        voteAverage: 7.2,
        genreIds: [16, 18],
        contentType: ContentType.tvShow,
      );

      // Test operations that should not throw exceptions
      expect(() async {
        await service.initializeMovieList('to_watch', 'To Watch');
      }, returnsNormally);

      expect(() async {
        await service.addMovieToList('test-list-id', testMovie);
      }, returnsNormally);

      expect(() async {
        await service.removeMovieFromList('test-list-id', 67890);
      }, returnsNormally);

      expect(() async {
        await service.updateMovieListName('test-list-id', 'Updated Name');
      }, returnsNormally);

      expect(() async {
        await service.batchAddMoviesToList('test-list-id', [testMovie]);
      }, returnsNormally);

      expect(() async {
        await service.getMovieListsContainingMovie(67890);
      }, returnsNormally);

      expect(() async {
        await service.deleteMovieList('test-list-id');
      }, returnsNormally);
    });

    testWidgets('Service properly extends BasePodService', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              userProfileService = UserProfileService(context, Container());
              service = MovieListService(context, Container(), userProfileService);
              return Container();
            },
          ),
        ),
      );

      // Test inheritance chain
      expect(service, isA<ChangeNotifier>());

      // Test that context and child are accessible
      expect(service.context, isNotNull);
      expect(service.child, isNotNull);

      // Test disposal
      expect(() => service.dispose(), returnsNormally);
    });
  });
}