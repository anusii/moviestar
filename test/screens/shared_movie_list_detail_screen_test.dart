/// Test suite for SharedMovieListDetailScreen widget decomposition
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moviestar/screens/shared_movie_list_detail_screen.dart';

void main() {
  group('SharedMovieListDetailScreen Tests', () {
    late SharedPreferences mockPrefs;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      mockPrefs = await SharedPreferences.getInstance();
    });

    testWidgets('should create widget with required parameters',
        (tester) async {
      final screen = SharedMovieListDetailScreen(
        listName: 'Test List',
        listDescription: 'Test Description',
        owner: 'Test Owner',
        ownerWebId: 'test-owner-webid',
        sharedBy: 'Test Sharer',
        sharedByWebId: 'test-sharer-webid',
        movies: [
          {
            'movieId': '123',
            'fileName': 'test-movie.ttl',
            'filePath': '/movies/test-movie.ttl',
          }
        ],
        permissions: 'read',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: screen,
          ),
        ),
      );

      expect(find.byType(SharedMovieListDetailScreen), findsOneWidget);
    });

    testWidgets('should accept string listName parameter', (tester) async {
      const testListName = 'My Shared List';

      final screen = SharedMovieListDetailScreen(
        listName: testListName,
        listDescription: 'Description',
        owner: 'Owner',
        ownerWebId: 'owner-webid',
        sharedBy: 'Sharer',
        sharedByWebId: 'sharer-webid',
        movies: [],
        permissions: 'read',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: screen,
          ),
        ),
      );

      expect(screen.listName, equals(testListName));
    });

    testWidgets('should accept movies list parameter', (tester) async {
      final testMovies = [
        {
          'movieId': '456',
          'fileName': 'movie1.ttl',
          'filePath': '/movies/movie1.ttl',
        },
        {
          'movieId': '789',
          'fileName': 'movie2.ttl',
          'filePath': '/movies/movie2.ttl',
        }
      ];

      final screen = SharedMovieListDetailScreen(
        listName: 'Test',
        listDescription: 'Description',
        owner: 'Owner',
        ownerWebId: 'owner-webid',
        sharedBy: 'Sharer',
        sharedByWebId: 'sharer-webid',
        movies: testMovies,
        permissions: 'read',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: screen,
          ),
        ),
      );

      expect(screen.movies, equals(testMovies));
      expect(screen.movies.length, equals(2));
    });

    testWidgets('should accept permissions parameter', (tester) async {
      const testPermissions = 'read-write';

      final screen = SharedMovieListDetailScreen(
        listName: 'Test',
        listDescription: 'Description',
        owner: 'Owner',
        ownerWebId: 'owner-webid',
        sharedBy: 'Sharer',
        sharedByWebId: 'sharer-webid',
        movies: [],
        permissions: testPermissions,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: screen,
          ),
        ),
      );

      expect(screen.permissions, equals(testPermissions));
    });

    testWidgets('should be a ConsumerStatefulWidget', (tester) async {
      final screen = SharedMovieListDetailScreen(
        listName: 'Test',
        listDescription: 'Description',
        owner: 'Owner',
        ownerWebId: 'owner-webid',
        sharedBy: 'Sharer',
        sharedByWebId: 'sharer-webid',
        movies: [],
        permissions: 'read',
      );

      expect(screen, isA<ConsumerStatefulWidget>());
    });
  });
}
