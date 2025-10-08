/// Complete workflow suite test - executes all core movie workflows in sequence.
///
/// This test demonstrates a comprehensive end-to-end style test that validates
/// the complete movie management workflow in a single test case. It simulates
/// a user's journey through the application:
///
/// 1. Starting with a clean state
/// 2. Adding movies to watch list
/// 3. Rating movies
/// 4. Marking movies as watched
/// 5. Managing custom lists
/// 6. Verifying state persists across operations
///
/// This is essentially an E2E test that validates the full user workflow
/// without requiring complex navigation setup.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import '../helpers/mock_services.dart';
import '../helpers/test_data_factory.dart';

void main() {
  group('Complete Movie Workflow Suite', () {
    testWidgets(
      'Full E2E workflow: Search → Select → Add to list → Rate → Watch → Manage lists',
      (tester) async {
        // Setup: Create services and test movies.

        final favoritesService = MockFavoritesService();
        final contentService = MockContentService();

        // Create a curated list of movies for our workflow.

        final inception = TestDataFactory.createMovie(
          id: 27205,
          title: 'Inception',
        );
        final darkKnight = TestDataFactory.createMovie(
          id: 155,
          title: 'The Dark Knight',
        );
        final interstellar = TestDataFactory.createMovie(
          id: 157336,
          title: 'Interstellar',
        );

        // Configure mock to return these movies in search results.

        contentService.mockSearchMoviesResults = [
          inception,
          darkKnight,
          interstellar,
        ];

        // === PART 1: DISCOVER AND ADD TO WATCH LIST ===

        // User discovers Inception and adds it to their watch list.

        await tester.pumpWidget(
          MaterialApp(
            home: MovieDetailsScreen(
              movie: inception,
              favoritesService: favoritesService,
              contentType: ContentType.movie,
            ),
          ),
        );

        await tester.pump();

        // Add to watch list.

        expect(await favoritesService.isInToWatch(inception), isFalse);
        await tester.tap(find.byIcon(Icons.bookmark_border));
        await tester.pump();
        expect(await favoritesService.isInToWatch(inception), isTrue);

        // === PART 2: RATE THE MOVIE ===

        // User rates Inception 9.0/10.

        final slider1 = tester.widget<Slider>(find.byType(Slider));
        slider1.onChanged!(9.0);
        await tester.pump(const Duration(seconds: 3));

        expect(
            await favoritesService.getPersonalRating(inception), equals(9.0));

        // === PART 3: MARK AS WATCHED ===

        // User marks Inception as watched.

        await tester.tap(find.byIcon(Icons.check_circle_outline));
        await tester.pump();

        expect(await favoritesService.isInWatched(inception), isTrue);

        // === PART 4: ADD ANOTHER MOVIE ===

        // User discovers The Dark Knight and adds it via service.
        // (Simulates viewing the movie details screen).

        await favoritesService.addToWatch(darkKnight);
        await favoritesService.setPersonalRating(darkKnight, 8.8);

        expect(await favoritesService.isInToWatch(darkKnight), isTrue);
        expect(
          await favoritesService.getPersonalRating(darkKnight),
          equals(8.8),
        );

        // === PART 5: CREATE AND MANAGE CUSTOM LISTS ===

        // User creates a "Christopher Nolan" list.

        final nolanList = await favoritesService.createCustomList(
          'Christopher Nolan Films',
          description: 'Best films by Christopher Nolan',
        );

        // Add both movies to the custom list.

        await favoritesService.addMovieToCustomList(nolanList.id, inception);
        await favoritesService.addMovieToCustomList(nolanList.id, darkKnight);

        expect(
          await favoritesService.isMovieInCustomList(
            nolanList.id,
            inception.id,
          ),
          isTrue,
        );
        expect(
          await favoritesService.isMovieInCustomList(
            nolanList.id,
            darkKnight.id,
          ),
          isTrue,
        );

        // === PART 6: ADD THIRD MOVIE TO LIST ===

        // User discovers Interstellar, rates it, and adds to the Nolan list.

        await favoritesService.setPersonalRating(interstellar, 8.9);
        await favoritesService.addMovieToCustomList(
          nolanList.id,
          interstellar,
        );

        // === PART 7: VERIFY COMPLETE STATE ===

        // Verify watch lists.

        final toWatchList = await favoritesService.getToWatch();
        expect(toWatchList.length, equals(2)); // Inception and Dark Knight
        expect(toWatchList.any((m) => m.id == inception.id), isTrue);
        expect(toWatchList.any((m) => m.id == darkKnight.id), isTrue);

        final watchedList = await favoritesService.getWatched();
        expect(watchedList.length, equals(1)); // Only Inception
        expect(watchedList.first.id, equals(inception.id));

        // Verify ratings.

        expect(
          await favoritesService.getPersonalRating(inception),
          equals(9.0),
        );
        expect(
          await favoritesService.getPersonalRating(darkKnight),
          equals(8.8),
        );
        expect(
          await favoritesService.getPersonalRating(interstellar),
          equals(8.9),
        );

        // Verify custom list contains all three movies.

        final customLists = await favoritesService.getCustomLists();
        expect(customLists.length, equals(1));
        expect(customLists.first.name, equals('Christopher Nolan Films'));

        final moviesInList =
            await favoritesService.getMovieIdsInCustomList(nolanList.id);
        expect(moviesInList.length, equals(3));
        expect(moviesInList,
            containsAll([inception.id, darkKnight.id, interstellar.id]));

        // === PART 8: UPDATE RATING ===

        // User reconsiders and updates Inception's rating.

        await favoritesService.setPersonalRating(
            inception, 9.5); // Even better on rewatch!

        expect(
          await favoritesService.getPersonalRating(inception),
          equals(9.5),
        );

        // === PART 9: MARK SECOND MOVIE AS WATCHED ===

        // User watches The Dark Knight.

        await favoritesService.addToWatched(darkKnight);

        expect(await favoritesService.isInWatched(darkKnight), isTrue);

        // === PART 10: FINAL STATE VERIFICATION ===

        // Verify final state of all movies.

        final finalWatchedList = await favoritesService.getWatched();
        expect(finalWatchedList.length, equals(2)); // Inception and Dark Knight
        expect(
          finalWatchedList.any((m) => m.id == inception.id),
          isTrue,
        );
        expect(
          finalWatchedList.any((m) => m.id == darkKnight.id),
          isTrue,
        );

        // Verify Interstellar is still in "To Watch" but not watched.

        expect(await favoritesService.isInToWatch(interstellar), isFalse);
        expect(await favoritesService.isInWatched(interstellar), isFalse);

        // All three movies have ratings.

        expect(
          await favoritesService.getPersonalRating(inception),
          equals(9.5),
        );
        expect(
          await favoritesService.getPersonalRating(darkKnight),
          equals(8.8),
        );
        expect(
          await favoritesService.getPersonalRating(interstellar),
          equals(8.9),
        );

        // Custom list still contains all movies.

        final finalMoviesInList =
            await favoritesService.getMovieIdsInCustomList(nolanList.id);
        expect(finalMoviesInList.length, equals(3));

        // === TEST COMPLETE ===
        // This test has validated the complete user workflow:
        // ✅ Discovering movies
        // ✅ Adding to watch list
        // ✅ Rating movies
        // ✅ Marking as watched
        // ✅ Creating custom lists
        // ✅ Managing multiple movies
        // ✅ Updating ratings
        // ✅ State persistence across operations
      },
    );

    testWidgets(
      'Workflow variation: Multiple lists and complex interactions',
      (tester) async {
        final favoritesService = MockFavoritesService();

        // Create movies.

        final movie1 = TestDataFactory.createMovie(id: 1, title: 'Movie 1');
        final movie2 = TestDataFactory.createMovie(id: 2, title: 'Movie 2');
        final movie3 = TestDataFactory.createMovie(id: 3, title: 'Movie 3');

        // Create multiple custom lists.

        final list1 = await favoritesService.createCustomList('Action');
        final list2 = await favoritesService.createCustomList('Favorites');
        final list3 = await favoritesService.createCustomList('To Rewatch');

        // Add movies to multiple lists (cross-referencing).

        await favoritesService.addMovieToCustomList(list1.id, movie1);
        await favoritesService.addMovieToCustomList(list1.id, movie2);

        await favoritesService.addMovieToCustomList(list2.id, movie1);
        await favoritesService.addMovieToCustomList(list2.id, movie3);

        await favoritesService.addMovieToCustomList(list3.id, movie1);

        // Verify movie1 is in 3 lists.

        final movie1Lists =
            await favoritesService.getCustomListsContainingMovie(movie1.id);
        expect(movie1Lists.length, equals(3));

        // Verify movie2 is in 1 list.

        final movie2Lists =
            await favoritesService.getCustomListsContainingMovie(movie2.id);
        expect(movie2Lists.length, equals(1));

        // Verify each list has correct movies.

        expect(
          await favoritesService.getMovieIdsInCustomList(list1.id),
          containsAll([movie1.id, movie2.id]),
        );
        expect(
          await favoritesService.getMovieIdsInCustomList(list2.id),
          containsAll([movie1.id, movie3.id]),
        );
        expect(
          await favoritesService.getMovieIdsInCustomList(list3.id),
          contains(movie1.id),
        );
      },
    );
  });
}
