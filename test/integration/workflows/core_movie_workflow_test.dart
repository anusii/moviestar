/// Integration tests for core movie workflow.
///
/// Tests the complete movie management workflow including:
/// - Adding movies to "To Watch" list
/// - Rating movies
/// - Marking movies as watched
/// - Adding comments
/// - Managing custom lists
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
  group('Core Movie Workflow Integration Tests', () {
    late MockFavoritesService favoritesService;

    setUp(() {
      favoritesService = MockFavoritesService();
    });

    testWidgets('Add movie to watch list', (tester) async {
      final movie = TestDataFactory.createMovie(title: 'Inception');

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailsScreen(
            movie: movie,
            favoritesService: favoritesService,
            contentType: ContentType.movie,
          ),
        ),
      );

      await tester.pump();

      // Verify initial state - movie not in watch list.

      expect(await favoritesService.isInToWatch(movie), isFalse);

      // Find and tap the bookmark button.

      final bookmarkButton = find.byIcon(Icons.bookmark_border);
      expect(bookmarkButton, findsOneWidget);
      await tester.tap(bookmarkButton);
      await tester.pump();

      // Verify movie was added to watch list.

      expect(await favoritesService.isInToWatch(movie), isTrue);

      // Verify icon changed to filled bookmark.

      expect(find.byIcon(Icons.bookmark), findsOneWidget);
    });

    testWidgets('Remove movie from watch list', (tester) async {
      final movie = TestDataFactory.createMovie(title: 'The Dark Knight');

      // Pre-add movie to watch list.

      await favoritesService.addToWatch(movie);

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailsScreen(
            movie: movie,
            favoritesService: favoritesService,
            contentType: ContentType.movie,
          ),
        ),
      );

      await tester.pump();

      // Should show filled bookmark icon.

      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      expect(await favoritesService.isInToWatch(movie), isTrue);

      // Tap to remove from watch list.

      await tester.tap(find.byIcon(Icons.bookmark));
      await tester.pump();

      // Verify removal.

      expect(await favoritesService.isInToWatch(movie), isFalse);
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    });

    testWidgets('Mark movie as watched', (tester) async {
      final movie = TestDataFactory.createMovie(title: 'Interstellar');

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailsScreen(
            movie: movie,
            favoritesService: favoritesService,
            contentType: ContentType.movie,
          ),
        ),
      );

      await tester.pump();

      // Verify initial state.

      expect(await favoritesService.isInWatched(movie), isFalse);

      // Find and tap the watched button.

      final watchedButton = find.byIcon(Icons.check_circle_outline);
      expect(watchedButton, findsOneWidget);
      await tester.tap(watchedButton);
      await tester.pump();

      // Verify movie was marked as watched.

      expect(await favoritesService.isInWatched(movie), isTrue);

      // Verify icon changed.

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('Toggle between To Watch and Watched states', (tester) async {
      final movie = TestDataFactory.createMovie(title: 'Memento');

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailsScreen(
            movie: movie,
            favoritesService: favoritesService,
            contentType: ContentType.movie,
          ),
        ),
      );

      await tester.pump();

      // Initial state: not in any list.

      expect(await favoritesService.isInToWatch(movie), isFalse);
      expect(await favoritesService.isInWatched(movie), isFalse);

      // Add to "To Watch".

      await tester.tap(find.byIcon(Icons.bookmark_border));
      await tester.pump();
      expect(await favoritesService.isInToWatch(movie), isTrue);
      expect(await favoritesService.isInWatched(movie), isFalse);

      // Mark as watched (does NOT automatically remove from "To Watch").

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pump();
      expect(await favoritesService.isInToWatch(movie), isTrue);
      expect(await favoritesService.isInWatched(movie), isTrue);

      // Remove from watched (movie remains in "To Watch").

      await tester.tap(find.byIcon(Icons.check_circle));
      await tester.pump();
      expect(await favoritesService.isInToWatch(movie), isTrue);
      expect(await favoritesService.isInWatched(movie), isFalse);
    });

    testWidgets('Rate movie using slider', (tester) async {
      final movie = TestDataFactory.createMovie(title: 'The Prestige');

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailsScreen(
            movie: movie,
            favoritesService: favoritesService,
            contentType: ContentType.movie,
          ),
        ),
      );

      await tester.pump();

      // Find the slider.

      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);

      // Get the slider widget to interact with it properly.

      final slider = tester.widget<Slider>(sliderFinder);

      // Call onChanged directly with a rating value (8.5/10).

      slider.onChanged!(8.5);
      await tester.pump();

      // Wait for the rating feedback timer to complete.

      await tester.pump(const Duration(seconds: 3));

      // Verify rating was set.

      final rating = await favoritesService.getPersonalRating(movie);
      expect(rating, equals(8.5));
    });

    testWidgets('Update movie rating multiple times', (tester) async {
      final movie = TestDataFactory.createMovie(title: 'Inception');

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailsScreen(
            movie: movie,
            favoritesService: favoritesService,
            contentType: ContentType.movie,
          ),
        ),
      );

      await tester.pump();

      final sliderFinder = find.byType(Slider);
      final slider = tester.widget<Slider>(sliderFinder);

      // Set initial rating: 7.0/10.

      slider.onChanged!(7.0);
      await tester.pump();

      var rating = await favoritesService.getPersonalRating(movie);
      expect(rating, equals(7.0));

      // Update rating: 9.0/10.

      slider.onChanged!(9.0);
      await tester.pump();

      rating = await favoritesService.getPersonalRating(movie);
      expect(rating, equals(9.0));

      // Update rating again: 8.5/10.

      slider.onChanged!(8.5);
      await tester.pump();

      // Wait for all timers to complete.

      await tester.pump(const Duration(seconds: 3));

      rating = await favoritesService.getPersonalRating(movie);
      expect(rating, equals(8.5));
    });

    testWidgets('Complete workflow: Add to watch → Rate → Mark watched',
        (tester) async {
      final movie = TestDataFactory.createMovie(title: 'The Matrix');

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailsScreen(
            movie: movie,
            favoritesService: favoritesService,
            contentType: ContentType.movie,
          ),
        ),
      );

      await tester.pump();

      // Step 1: Add to "To Watch" list.

      await tester.tap(find.byIcon(Icons.bookmark_border));
      await tester.pump();
      expect(await favoritesService.isInToWatch(movie), isTrue);

      // Step 2: Rate the movie.

      final slider = tester.widget<Slider>(find.byType(Slider));
      slider.onChanged!(8.5);
      await tester.pump();

      // Wait for rating timer.

      await tester.pump(const Duration(seconds: 3));

      final rating = await favoritesService.getPersonalRating(movie);
      expect(rating, equals(8.5));

      // Step 3: Mark as watched.

      await tester.tap(find.byIcon(Icons.check_circle_outline));
      await tester.pump();
      expect(await favoritesService.isInWatched(movie), isTrue);

      // Note: Movie remains in "To Watch" list (current behavior).

      expect(await favoritesService.isInToWatch(movie), isTrue);
    });

    testWidgets('Add movie to custom list', (tester) async {
      final movie = TestDataFactory.createMovie(title: 'Fight Club');

      // Pre-create a custom list.

      final customList = await favoritesService.createCustomList(
        'Favorites',
        description: 'My favorite movies',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MovieDetailsScreen(
            movie: movie,
            favoritesService: favoritesService,
            contentType: ContentType.movie,
          ),
        ),
      );

      await tester.pump();

      // Open "Add to List" dialog.

      final addToListButton = find.byIcon(Icons.playlist_add);
      expect(addToListButton, findsOneWidget);
      await tester.tap(addToListButton);
      await tester.pump();

      // Verify dialog opened.

      expect(find.text('Add to Lists'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);

      // Find and tap the checkbox for the list.

      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsAtLeastNWidgets(1));
      await tester.tap(checkboxFinder.first);
      await tester.pump();

      // Close the dialog (tap outside or find close button).
      // The dialog might have different close buttons, so let's try common ones.

      if (find.text('Close').evaluate().isNotEmpty) {
        await tester.tap(find.text('Close'));
      } else if (find.text('OK').evaluate().isNotEmpty) {
        await tester.tap(find.text('OK'));
      } else if (find.byIcon(Icons.close).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.close).first);
      }

      await tester.pump();

      // Verify movie was added to custom list.

      expect(
        await favoritesService.isMovieInCustomList(customList.id, movie.id),
        isTrue,
      );
    });

    testWidgets('Service tracks multiple movies independently', (tester) async {
      final movie1 = TestDataFactory.createMovie(id: 1, title: 'Movie 1');
      final movie2 = TestDataFactory.createMovie(id: 2, title: 'Movie 2');
      final movie3 = TestDataFactory.createMovie(id: 3, title: 'Movie 3');

      // Add movie1 to watch list.

      await favoritesService.addToWatch(movie1);

      // Add movie2 to watched list.

      await favoritesService.addToWatched(movie2);

      // Rate movie3.

      await favoritesService.setPersonalRating(movie3, 9.0);

      // Verify each movie has independent state.

      expect(await favoritesService.isInToWatch(movie1), isTrue);
      expect(await favoritesService.isInToWatch(movie2), isFalse);
      expect(await favoritesService.isInToWatch(movie3), isFalse);

      expect(await favoritesService.isInWatched(movie1), isFalse);
      expect(await favoritesService.isInWatched(movie2), isTrue);
      expect(await favoritesService.isInWatched(movie3), isFalse);

      expect(await favoritesService.getPersonalRating(movie1), isNull);
      expect(await favoritesService.getPersonalRating(movie2), isNull);
      expect(await favoritesService.getPersonalRating(movie3), equals(9.0));
    });

    testWidgets('Custom lists can contain multiple movies', (tester) async {
      final movie1 = TestDataFactory.createMovie(id: 1, title: 'Movie 1');
      final movie2 = TestDataFactory.createMovie(id: 2, title: 'Movie 2');
      final movie3 = TestDataFactory.createMovie(id: 3, title: 'Movie 3');

      final list = await favoritesService.createCustomList('Top Movies');

      // Add movies to the list.

      await favoritesService.addMovieToCustomList(list.id, movie1);
      await favoritesService.addMovieToCustomList(list.id, movie2);
      await favoritesService.addMovieToCustomList(list.id, movie3);

      // Verify all movies are in the list.

      expect(
        await favoritesService.isMovieInCustomList(list.id, movie1.id),
        isTrue,
      );
      expect(
        await favoritesService.isMovieInCustomList(list.id, movie2.id),
        isTrue,
      );
      expect(
        await favoritesService.isMovieInCustomList(list.id, movie3.id),
        isTrue,
      );

      // Get movie IDs in the list.

      final movieIds = await favoritesService.getMovieIdsInCustomList(list.id);
      expect(movieIds, containsAll([movie1.id, movie2.id, movie3.id]));
      expect(movieIds.length, equals(3));
    });
  });
}
