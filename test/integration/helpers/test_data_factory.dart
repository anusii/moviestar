/// Test data factory for creating consistent test data across integration tests.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';

/// Factory class for creating test data with sensible defaults.
///
/// This class provides static methods to create commonly used test objects
/// like Movies, CustomLists, etc. All methods use sensible defaults that can
/// be overridden via named parameters.
///
/// Example usage:
/// ```dart
/// final movie = TestDataFactory.createMovie(title: 'Inception');
/// final tvShow = TestDataFactory.createTVShow();
/// final list = TestDataFactory.createCustomList(name: 'Favorites');
/// ```.

class TestDataFactory {
  /// Creates a test Movie with sensible defaults.
  ///
  /// Default values:
  /// - id: 123
  /// - title: 'Test Movie'
  /// - overview: 'A test movie for integration testing'
  /// - releaseDate: 2025-01-01
  /// - posterUrl: TMDB w500 test image
  /// - backdropUrl: TMDB w1280 test image
  /// - genreIds: [28] (Action)
  /// - voteAverage: 7.5
  /// - contentType: ContentType.movie

  static Movie createMovie({
    int id = 123,
    String title = 'Test Movie',
    String? overview,
    DateTime? releaseDate,
    String? posterUrl,
    String? backdropUrl,
    List<int>? genreIds,
    double voteAverage = 7.5,
    ContentType contentType = ContentType.movie,
  }) {
    return Movie(
      id: id,
      title: title,
      overview: overview ?? 'A test movie for integration testing',
      releaseDate: releaseDate ?? DateTime.parse('2025-01-01'),
      posterUrl: posterUrl ?? 'https://image.tmdb.org/t/p/w500/test.jpg',
      backdropUrl: backdropUrl ?? 'https://image.tmdb.org/t/p/w1280/test.jpg',
      genreIds: genreIds ?? [28], // Action genre
      voteAverage: voteAverage,
      contentType: contentType,
    );
  }

  /// Creates a test TV Show with sensible defaults.
  ///
  /// This is a convenience method that creates a Movie with contentType set to
  /// ContentType.tvShow and appropriate default values.

  static Movie createTVShow({
    int id = 456,
    String title = 'Test TV Show',
    String? overview,
    DateTime? releaseDate,
    String? posterUrl,
    String? backdropUrl,
    List<int>? genreIds,
    double voteAverage = 8.0,
  }) {
    return Movie(
      id: id,
      title: title,
      overview: overview ?? 'A test TV show for integration testing',
      releaseDate: releaseDate ?? DateTime.parse('2025-01-01'),
      posterUrl: posterUrl ?? 'https://image.tmdb.org/t/p/w500/test-tv.jpg',
      backdropUrl:
          backdropUrl ?? 'https://image.tmdb.org/t/p/w1280/test-tv.jpg',
      genreIds: genreIds ?? [18], // Drama genre
      voteAverage: voteAverage,
      contentType: ContentType.tvShow,
    );
  }

  /// Creates a test Movie that already has a rating.
  ///
  /// Useful for testing rating display and update scenarios.

  static Movie createRatedMovie({
    int id = 789,
    String title = 'Rated Test Movie',
    double personalRating = 8.5,
  }) {
    return createMovie(
      id: id,
      title: title,
      voteAverage: personalRating,
    );
  }

  /// Creates a test CustomList with sensible defaults.
  ///
  /// Default values:
  /// - id: 'test-list'
  /// - name: 'Test List'
  /// - description: 'A test custom list'
  /// - movieIds: []
  /// - createdAt: now
  /// - updatedAt: now

  static CustomList createCustomList({
    String? id,
    String name = 'Test List',
    String? description,
    List<int>? movieIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return CustomList(
      id: id ?? 'test-${name.toLowerCase().replaceAll(' ', '-')}',
      name: name,
      description: description ?? 'A test custom list',
      movieIds: movieIds ?? [],
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  /// Creates a CustomList with pre-populated movie IDs.
  ///
  /// Useful for testing list display with existing content.

  static CustomList createPopulatedList({
    String name = 'My Favorites',
    List<int>? movieIds,
  }) {
    return createCustomList(
      name: name,
      movieIds: movieIds ?? [123, 456, 789], // Default test movie IDs
      description: 'A custom list with movies',
    );
  }

  /// Creates a movie that simulates being shared via POD.
  ///
  /// This creates a movie with metadata that indicates it was shared.

  static Movie createSharedMovie({
    int id = 999,
    String title = 'Shared Test Movie',
    String? sharedBy,
  }) {
    return createMovie(
      id: id,
      title: title,
      overview: 'A movie shared ${sharedBy != null ? 'by $sharedBy' : 'via POD'}',
    );
  }

  /// Creates a list of multiple test movies.
  ///
  /// Useful for testing list views, grids, etc.
  /// Creates movies with sequential IDs starting from [startId].

  static List<Movie> createMovieList({
    int count = 5,
    int startId = 1,
    String titlePrefix = 'Test Movie',
  }) {
    return List.generate(
      count,
      (index) => createMovie(
        id: startId + index,
        title: '$titlePrefix ${index + 1}',
        voteAverage: 5.0 + (index * 0.5), // Varying ratings
      ),
    );
  }

  /// Creates a list of popular movies (high ratings).
  ///
  /// Useful for testing "Popular" or "Top Rated" sections.

  static List<Movie> createPopularMovies({int count = 3}) {
    return [
      createMovie(id: 1, title: 'The Shawshank Redemption', voteAverage: 9.3),
      createMovie(id: 2, title: 'The Godfather', voteAverage: 9.2),
      createMovie(id: 3, title: 'The Dark Knight', voteAverage: 9.0),
    ].take(count).toList();
  }
}
