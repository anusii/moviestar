// Tests for BatchSharingItemCard widget.
//
// Copyright (C) 2025, Software Innovation Institute, ANU.
//
// Licensed under the GNU General Public License, Version 3 (the "License").
//
// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/models/sharing_models.dart';
import 'package:moviestar/widgets/sharing/batch_item_card.dart';

void main() {
  group('BatchSharingItemCard', () {
    late ShareableFile testMovieListFile;
    late ShareableFile testMovieFile;
    late Movie testMovie;

    setUp(() {
      testMovie = Movie(
        id: 123,
        title: 'Test Movie',
        overview: 'Test overview',
        posterUrl: 'https://example.com/poster.jpg',
        backdropUrl: 'https://example.com/backdrop.jpg',
        releaseDate: DateTime(2023, 1, 1),
        voteAverage: 8.5,
        genreIds: [1, 2, 3],
        contentType: ContentType.movie,
      );

      testMovieListFile = ShareableFile(
        fileName: 'user_lists/MovieList-123.ttl',
        displayName: 'My Test List',
        fileType: 'movielist',
        permissions: ['read', 'write'],
      );

      testMovieFile = ShareableFile(
        fileName: 'movies/Movie-123.ttl',
        displayName: 'Test Movie',
        fileType: 'movie',
        movie: testMovie,
        permissions: ['read'],
      );
    });

    testWidgets('displays movie list file correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatchSharingItemCard(
              file: testMovieListFile,
              index: 0,
              onPermissionsChanged: (index, permissions) {},
            ),
          ),
        ),
      );

      expect(find.text('My Test List'), findsOneWidget);
      expect(find.text('Movie List'), findsOneWidget);
      expect(find.byIcon(Icons.list_alt), findsOneWidget);
      expect(
        find.byType(Checkbox),
        findsNWidgets(4),
      ); // read, write, append, control
    });

    testWidgets('displays movie file correctly with read-only indicator',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatchSharingItemCard(
              file: testMovieFile,
              index: 0,
              onPermissionsChanged: (index, permissions) {},
            ),
          ),
        ),
      );

      expect(find.text('Test Movie'), findsOneWidget);
      expect(find.text('Movie File (Read-only)'), findsOneWidget);
      // Find the main file type icon (size 20) - there might be additional small icons for poster placeholders
      expect(find.byIcon(Icons.movie), findsAtLeastNWidgets(1));
      expect(find.text('Read-only access (automatic)'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('handles permission changes for movie list', (tester) async {
      int changedIndex = -1;
      List<String> newPermissions = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatchSharingItemCard(
              file: testMovieListFile,
              index: 2,
              onPermissionsChanged: (index, permissions) {
                changedIndex = index;
                newPermissions = permissions;
              },
            ),
          ),
        ),
      );

      // Find the write checkbox by finding the text first, then locating the checkbox in the same row
      final writeText = find.text('Write');
      expect(writeText, findsOneWidget);

      // Find all checkboxes and select the second one (index 1) which should be the 'Write' checkbox
      // Order: Read (index 0), Write (index 1), Append (index 2), Control (index 3)
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsNWidgets(4));
      await tester.tap(checkboxes.at(1));

      expect(changedIndex, equals(2));
      expect(newPermissions, equals(['read']));
    });

    testWidgets('prevents permission changes for movie files', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BatchSharingItemCard(
              file: testMovieFile,
              index: 0,
              onPermissionsChanged: (index, permissions) {
                // This should never be called for movie files
              },
            ),
          ),
        ),
      );

      // Should not have any interactive checkboxes
      expect(find.byType(Checkbox), findsNothing);
    });
  });
}
