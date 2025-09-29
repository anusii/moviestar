/// Direct movie service implementation that bypasses POD/secure storage.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:moviestar/core/services/api/movie_service.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/utils/network_client.dart';

/// A MovieService that initializes with a direct API key instead of using ApiKeyService.
/// This bypasses the complex POD/secure storage chain when we already have the key.

class DirectMovieService extends MovieService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  final String? _apiKey;
  NetworkClient? _directClient;

  DirectMovieService(this._apiKey) : super(null) {
    _initializeWithDirectApiKey();
  }

  /// Initializes the service with the provided API key directly.

  void _initializeWithDirectApiKey() {
    // Create NetworkClient directly without ContentService to avoid type compatibility issues.

    _directClient = NetworkClient(baseUrl: _baseUrl, apiKey: _apiKey ?? '');
  }

  /// Ensures our direct client is initialized.

  Future<void> _ensureDirectClientInitialized() async {
    if (_directClient == null) {
      _initializeWithDirectApiKey();
    }
  }

  @override
  Future<List<Movie>> getRecommendedMovies() async {
    await _ensureDirectClientInitialized();

    // Fetch both recommended movies and TV shows directly.

    final moviesFuture = _directClient!.getJsonList('movie/popular');
    final tvShowsFuture = _directClient!.getJsonList('tv/popular');

    final results = await Future.wait([moviesFuture, tvShowsFuture]);
    final movies = results[0];
    final tvShows = results[1];

    // Convert to ContentItems.

    final movieItems =
        movies.map((movie) => ContentItem.fromMovieJson(movie)).toList();
    final tvItems = tvShows.map((tv) => ContentItem.fromTVJson(tv)).toList();

    // Combine and sort by vote average.

    final combined = <ContentItem>[];
    combined.addAll(movieItems);
    combined.addAll(tvItems);
    combined.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));

    return combined.map((content) => Movie.fromContentItem(content)).toList();
  }

  @override
  Future<List<Movie>> getNowPlayingMovies() async {
    await _ensureDirectClientInitialized();

    // Fetch both now playing movies and on the air TV shows directly.

    final moviesFuture = _directClient!.getJsonList('movie/now_playing');
    final tvShowsFuture = _directClient!.getJsonList('tv/on_the_air');

    final results = await Future.wait([moviesFuture, tvShowsFuture]);
    final movies = results[0];
    final tvShows = results[1];

    final movieItems =
        movies.map((movie) => ContentItem.fromMovieJson(movie)).toList();
    final tvItems = tvShows.map((tv) => ContentItem.fromTVJson(tv)).toList();

    final combined = <ContentItem>[];
    combined.addAll(movieItems);
    combined.addAll(tvItems);
    combined.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));

    return combined.map((content) => Movie.fromContentItem(content)).toList();
  }

  @override
  Future<List<Movie>> getTopRatedMovies() async {
    await _ensureDirectClientInitialized();

    // Fetch both top rated movies and TV shows directly.

    final moviesFuture = _directClient!.getJsonList('movie/top_rated');
    final tvShowsFuture = _directClient!.getJsonList('tv/top_rated');

    final results = await Future.wait([moviesFuture, tvShowsFuture]);
    final movies = results[0];
    final tvShows = results[1];

    final movieItems =
        movies.map((movie) => ContentItem.fromMovieJson(movie)).toList();
    final tvItems = tvShows.map((tv) => ContentItem.fromTVJson(tv)).toList();

    final combined = <ContentItem>[];
    combined.addAll(movieItems);
    combined.addAll(tvItems);
    combined.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));

    return combined.map((content) => Movie.fromContentItem(content)).toList();
  }

  @override
  Future<List<Movie>> getUpcomingMovies() async {
    await _ensureDirectClientInitialized();

    // Fetch both upcoming movies and airing today TV shows directly.

    final moviesFuture = _directClient!.getJsonList('movie/upcoming');
    final tvShowsFuture = _directClient!.getJsonList('tv/airing_today');

    final results = await Future.wait([moviesFuture, tvShowsFuture]);
    final movies = results[0];
    final tvShows = results[1];

    final movieItems =
        movies.map((movie) => ContentItem.fromMovieJson(movie)).toList();
    final tvItems = tvShows.map((tv) => ContentItem.fromTVJson(tv)).toList();

    final combined = <ContentItem>[];
    combined.addAll(movieItems);
    combined.addAll(tvItems);
    combined.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));

    return combined.map((content) => Movie.fromContentItem(content)).toList();
  }

  @override
  Future<List<Movie>> searchMovies(String query) async {
    await _ensureDirectClientInitialized();
    final results = await _directClient!
        .getJsonList('search/movie?query=${Uri.encodeComponent(query)}');
    return results.map((movie) => Movie.fromJson(movie)).toList();
  }

  @override
  Future<List<Movie>> searchMoviesByActor(String actorName) async {
    await _ensureDirectClientInitialized();
    // First search for the person.

    final personResults = await _directClient!
        .getJsonList('search/person?query=${Uri.encodeComponent(actorName)}');
    if (personResults.isEmpty) return [];

    final personId = personResults[0]['id'];
    final credits =
        await _directClient!.getJson('person/$personId/movie_credits');
    final cast = credits['cast'] as List<dynamic>? ?? [];

    return cast.map((movie) => Movie.fromJson(movie)).toList();
  }

  @override
  Future<List<Movie>> searchMoviesByGenre(String genreName) async {
    await _ensureDirectClientInitialized();
    // First get genre list to find the ID.

    final genreData = await _directClient!.getJson('genre/movie/list');
    final genres = genreData['genres'] as List<dynamic>? ?? [];

    final genre = genres.firstWhere(
      (g) =>
          g['name'].toString().toLowerCase().contains(genreName.toLowerCase()),
      orElse: () => null,
    );

    if (genre == null) return [];

    final genreId = genre['id'];
    final results =
        await _directClient!.getJsonList('discover/movie?with_genres=$genreId');
    return results.map((movie) => Movie.fromJson(movie)).toList();
  }

  @override
  Future<Movie> getMovieDetails(int movieId) async {
    await _ensureDirectClientInitialized();

    // Use direct client instead of going through ContentService.

    try {
      final data = await _directClient!.getJson('movie/$movieId');
      final contentItem = ContentItem.fromMovieJson(data);
      return Movie.fromContentItem(contentItem);
    } catch (e) {
      // Try TV endpoint if movie fails (for TV shows).

      final data = await _directClient!.getJson('tv/$movieId');
      final contentItem = ContentItem.fromTVJson(data);
      return Movie.fromContentItem(contentItem);
    }
  }

  @override
  void dispose() {
    _directClient?.dispose();
    _directClient = null;
    super.dispose();
  }
}
