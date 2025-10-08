/// Mock implementation of ContentService for integration testing.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:moviestar/models/movie.dart';

/// Mock implementation of ContentService for testing.
///
/// This mock provides configurable responses for Content API operations
/// (both movies and TV shows) without making actual network requests.
///
/// Example usage:
/// ```dart
/// final mockService = MockContentService();
/// mockService.mockSearchContentResults = [movie1, movie2];
/// final results = await mockService.searchContent('test');
/// ```

class MockContentService {
  /// Content items to return from search operations.

  List<dynamic> mockSearchContentResults = [];

  /// Movies to return from searchMovies.

  List<Movie> mockSearchMoviesResults = [];

  /// Content items to return from getRecommended* methods.

  List<dynamic> mockRecommendedContent = [];

  /// Content items to return from getNowPlaying* methods.

  List<dynamic> mockNowPlayingContent = [];

  /// Content items to return from getTopRated* methods.

  List<dynamic> mockTopRatedContent = [];

  /// Content items to return from getUpcoming* methods.

  List<dynamic> mockUpcomingContent = [];

  /// Content item to return from getMovieDetails/getTVDetails.

  dynamic mockContentDetails;

  /// Whether operations should fail (for error testing).

  bool shouldFail = false;

  /// Error message to throw when shouldFail is true.

  String failureMessage = 'Mock content service configured to fail';

  /// Simulates searching for content (movies and TV shows).

  Future<List<dynamic>> searchContent(String query) async {
    if (shouldFail) throw Exception(failureMessage);
    return mockSearchContentResults;
  }

  /// Simulates searching for movies.

  Future<List<Movie>> searchMovies(String query) async {
    if (shouldFail) throw Exception(failureMessage);
    return mockSearchMoviesResults;
  }

  /// Simulates searching by actor.

  Future<List<dynamic>> searchContentByActor(String actorName) async {
    if (shouldFail) throw Exception(failureMessage);
    return mockSearchContentResults;
  }

  /// Simulates searching by genre.

  Future<List<dynamic>> searchContentByGenre(String genreName) async {
    if (shouldFail) throw Exception(failureMessage);
    return mockSearchContentResults;
  }

  /// Simulates comprehensive search.

  Future<Map<String, List<dynamic>>> searchContentComprehensive(
    String query,
  ) async {
    if (shouldFail) throw Exception(failureMessage);
    return {
      'title': mockSearchContentResults,
      'actor': [],
      'genre': [],
    };
  }

  /// Simulates getting recommended movies.

  Future<List<dynamic>> getRecommendedMovies() async {
    if (shouldFail) throw Exception(failureMessage);
    return mockRecommendedContent;
  }

  /// Simulates getting now playing movies.

  Future<List<dynamic>> getNowPlayingMovies() async {
    if (shouldFail) throw Exception(failureMessage);
    return mockNowPlayingContent;
  }

  /// Simulates getting top rated movies.

  Future<List<dynamic>> getTopRatedMovies() async {
    if (shouldFail) throw Exception(failureMessage);
    return mockTopRatedContent;
  }

  /// Simulates getting upcoming movies.

  Future<List<dynamic>> getUpcomingMovies() async {
    if (shouldFail) throw Exception(failureMessage);
    return mockUpcomingContent;
  }

  /// Simulates getting recommended TV shows.

  Future<List<dynamic>> getRecommendedTVShows() async {
    if (shouldFail) throw Exception(failureMessage);
    return mockRecommendedContent;
  }

  /// Simulates getting mixed recommended content.

  Future<List<dynamic>> getRecommendedMixedContent() async {
    if (shouldFail) throw Exception(failureMessage);
    return mockRecommendedContent;
  }

  /// Simulates getting on the air TV shows.

  Future<List<dynamic>> getOnTheAirTVShows() async {
    if (shouldFail) throw Exception(failureMessage);
    return mockNowPlayingContent;
  }

  /// Simulates getting top rated TV shows.

  Future<List<dynamic>> getTopRatedTVShows() async {
    if (shouldFail) throw Exception(failureMessage);
    return mockTopRatedContent;
  }

  /// Simulates getting airing today TV shows.

  Future<List<dynamic>> getAiringTodayTVShows() async {
    if (shouldFail) throw Exception(failureMessage);
    return mockUpcomingContent;
  }

  /// Simulates getting mixed now playing content.

  Future<List<dynamic>> getNowPlayingMixedContent() async {
    if (shouldFail) throw Exception(failureMessage);
    return mockNowPlayingContent;
  }

  /// Simulates getting mixed top rated content.

  Future<List<dynamic>> getTopRatedMixedContent() async {
    if (shouldFail) throw Exception(failureMessage);
    return mockTopRatedContent;
  }

  /// Simulates getting mixed upcoming content.

  Future<List<dynamic>> getUpcomingMixedContent() async {
    if (shouldFail) throw Exception(failureMessage);
    return mockUpcomingContent;
  }

  /// Simulates getting movie details.

  Future<dynamic> getMovieDetails(int movieId) async {
    if (shouldFail) throw Exception(failureMessage);
    return mockContentDetails;
  }

  /// Simulates getting TV details.

  Future<dynamic> getTVDetails(int tvId) async {
    if (shouldFail) throw Exception(failureMessage);
    return mockContentDetails;
  }

  /// Simulates getting content details (auto-detects type).

  Future<dynamic> getContentDetails(int contentId, dynamic contentType) async {
    if (shouldFail) throw Exception(failureMessage);
    return mockContentDetails;
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
    mockSearchContentResults = [];
    mockSearchMoviesResults = [];
    mockRecommendedContent = [];
    mockNowPlayingContent = [];
    mockTopRatedContent = [];
    mockUpcomingContent = [];
    mockContentDetails = null;
    shouldFail = false;
  }

  /// Disposes resources (no-op for mock).

  void dispose() {}
}
