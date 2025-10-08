/// Mock implementation of MovieService for integration testing.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:moviestar/models/movie.dart';

/// Mock implementation of MovieService for testing.
///
/// This mock provides configurable responses for TMDB API operations
/// without making actual network requests.
///
/// Example usage:
/// ```dart
/// final mockService = MockMovieService();
/// mockService.mockSearchResults = [movie1, movie2];
/// final results = await mockService.searchMovies('test');
/// ```

class MockMovieService {
  /// Movies to return from search operations.

  List<Movie> mockSearchResults = [];

  /// Movie to return from getMovieDetails.

  Movie? mockMovieDetails;

  /// Movies to return from getPopularMovies.

  List<Movie> mockPopularMovies = [];

  /// Whether operations should fail (for error testing).

  bool shouldFail = false;

  /// Error message to throw when shouldFail is true.

  String failureMessage = 'Mock movie service configured to fail';

  /// Simulates searching for movies.

  Future<List<Movie>> searchMovies(String query) async {
    if (shouldFail) throw Exception(failureMessage);
    return mockSearchResults;
  }

  /// Simulates getting movie details.

  Future<Movie?> getMovieDetails(int movieId) async {
    if (shouldFail) throw Exception(failureMessage);
    return mockMovieDetails;
  }

  /// Simulates getting popular movies.

  Future<List<Movie>> getPopularMovies() async {
    if (shouldFail) throw Exception(failureMessage);
    return mockPopularMovies;
  }

  /// Configures the mock to simulate failures.

  void configureFailure({bool fail = true, String? message}) {
    shouldFail = fail;
    if (message != null) {
      failureMessage = message;
    }
  }

  /// Resets all state (useful between tests).

  void reset() {
    mockSearchResults = [];
    mockMovieDetails = null;
    mockPopularMovies = [];
    shouldFail = false;
  }
}
