// Tests for BatchSharingState.
//
// Copyright (C) 2025, Software Innovation Institute, ANU.
//
// Licensed under the GNU General Public License, Version 3 (the "License").
//
// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

import 'package:flutter_test/flutter_test.dart';

import 'package:moviestar/core/state/batch_sharing_state.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';

void main() {
  group('BatchSharingState', () {
    late BatchSharingState state;
    late List<Movie> testMovies;

    setUp(() {
      state = BatchSharingState();
      testMovies = [
        Movie(
          id: 1,
          title: 'Test Movie 1',
          overview: 'Overview 1',
          posterUrl: 'poster1.jpg',
          backdropUrl: 'backdrop1.jpg',
          releaseDate: DateTime(2023, 1, 1),
          voteAverage: 8.0,
          genreIds: [1, 2],
          contentType: ContentType.movie,
        ),
        Movie(
          id: 2,
          title: 'Test TV Show',
          overview: 'Overview 2',
          posterUrl: 'poster2.jpg',
          backdropUrl: 'backdrop2.jpg',
          releaseDate: DateTime(2023, 2, 1),
          voteAverage: 7.5,
          genreIds: [3, 4],
          contentType: ContentType.tvShow,
        ),
      ];
    });

    tearDown(() {
      state.dispose();
    });

    test('initializes shareable files correctly', () {
      state.initializeShareableFiles('test-list', 'Test List', testMovies);

      expect(state.shareableFiles.length, equals(3)); // 1 list + 2 movies

      // Check movie list file
      final listFile = state.shareableFiles[0];
      expect(listFile.fileName, equals('user_lists/MovieList-test-list.ttl'));
      expect(listFile.displayName, equals('Test List'));
      expect(listFile.fileType, equals('movielist'));
      expect(listFile.permissions, equals(['read']));

      // Check movie file
      final movieFile = state.shareableFiles[1];
      expect(movieFile.fileName, equals('movies/Movie-1.ttl'));
      expect(movieFile.displayName, equals('Test Movie 1'));
      expect(movieFile.fileType, equals('movie'));
      expect(movieFile.permissions, equals(['read']));

      // Check TV show file
      final tvFile = state.shareableFiles[2];
      expect(tvFile.fileName, equals('movies/TVShow-2.ttl'));
      expect(tvFile.displayName, equals('Test TV Show'));
      expect(tvFile.fileType, equals('tv'));
      expect(tvFile.permissions, equals(['read']));
    });

    test('updates WebID correctly', () {
      expect(state.validatedWebId, isNull);

      state.updateWebId('https://example.com/profile#me');
      expect(state.validatedWebId, equals('https://example.com/profile#me'));

      state.updateWebId(null);
      expect(state.validatedWebId, isNull);
    });

    test('updates file permissions correctly', () {
      state.initializeShareableFiles('test-list', 'Test List', testMovies);

      // Update movie list permissions
      state.updateFilePermissions(0, ['read', 'write']);
      expect(state.shareableFiles[0].permissions, equals(['read', 'write']));

      // Try to update movie file permissions (should stay read-only)
      state.updateFilePermissions(1, ['read', 'write']);
      expect(state.shareableFiles[1].permissions, equals(['read']));
    });

    test('resets permissions to defaults correctly', () {
      state.initializeShareableFiles('test-list', 'Test List', testMovies);

      // Modify some permissions first
      state.updateFilePermissions(0, ['read', 'write', 'control']);

      // Reset to defaults
      state.resetPermissionsToDefaults();

      expect(state.shareableFiles[0].permissions, equals(['read', 'write']));
      expect(state.shareableFiles[1].permissions, equals(['read']));
      expect(state.shareableFiles[2].permissions, equals(['read']));
    });

    test('isReadyToShare returns correct values', () {
      state.initializeShareableFiles('test-list', 'Test List', testMovies);

      // No WebID, should be false
      expect(state.isReadyToShare, isFalse);

      // Set WebID but clear all permissions
      state.updateWebId('https://example.com/profile#me');
      state.updateFilePermissions(0, []); // Clear list file permissions
      // Movie files still have read permissions, so this should be true
      expect(state.isReadyToShare, isTrue);

      // Set list permissions, should be true
      state.updateFilePermissions(0, ['read']);
      expect(state.isReadyToShare, isTrue);
    });

    test('BatchSharingResult factory methods work correctly', () {
      final successResult = BatchSharingResult.success(5, 5);
      expect(successResult.success, isTrue);
      expect(successResult.isCompleteSuccess, isTrue);
      expect(successResult.isPartialSuccess, isFalse);

      final partialResult = BatchSharingResult.success(3, 5);
      expect(partialResult.success, isTrue);
      expect(partialResult.isCompleteSuccess, isFalse);
      expect(partialResult.isPartialSuccess, isTrue);

      final errorResult = BatchSharingResult.error('Test error');
      expect(errorResult.success, isFalse);
      expect(errorResult.errorMessage, equals('Test error'));
      expect(errorResult.isCompleteSuccess, isFalse);
      expect(errorResult.isPartialSuccess, isFalse);
    });
  });
}
