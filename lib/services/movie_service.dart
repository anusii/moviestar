/// Service for managing movies in the Movie Star application.
///
// Time-stamp: <Thursday 2025-04-10 11:47:48 +1000 Graham Williams>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
/// Authors: Kevin Wang, Ashley Tang

library;

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/api_key_service.dart';
import 'package:moviestar/services/movie_search_service.dart';
import 'package:moviestar/utils/network_client.dart';

/// A service class that handles movie-related API requests.

class MovieService {
  /// Base URL for The Movie Database API.

  static const String _baseUrl = 'https://api.themoviedb.org/3';

  /// Network client for making HTTP requests.

  NetworkClient? _client;

  /// Service for movie search operations.

  MovieSearchService? _searchService;

  /// Service for managing the API key.

  final ApiKeyService _apiKeyService;

  /// Creates a new MovieService instance.

  MovieService(ApiKeyService apiKeyService) : _apiKeyService = apiKeyService {
    _initializeClient();
  }

  /// Initializes the network client with the API key from secure storage.

  Future<void> _initializeClient() async {
    final apiKey = await _apiKeyService.getApiKey();
    _client = NetworkClient(baseUrl: _baseUrl, apiKey: apiKey ?? '');
    _searchService = MovieSearchService(_client!);
  }

  /// Updates the API key and recreates the network client.

  Future<void> updateApiKey() async {
    _client?.dispose();
    // Reset to null to force recreation.

    _client = null;
    _searchService = null;
    await _initializeClient();
  }

  /// Ensures the client is initialized before making requests.

  Future<void> _ensureClientInitialized() async {
    if (_client == null) {
      await _initializeClient();
    }
  }

  /// Gets a list of popular movies.

  Future<List<Movie>> getPopularMovies() async {
    await _ensureClientInitialized();
    final results = await _client!.getJsonList('movie/popular');
    return results.map((movie) => Movie.fromJson(movie)).toList();
  }

  /// Gets a list of movies currently playing in theaters.

  Future<List<Movie>> getNowPlayingMovies() async {
    await _ensureClientInitialized();
    final results = await _client!.getJsonList('movie/now_playing');
    return results.map((movie) => Movie.fromJson(movie)).toList();
  }

  /// Gets a list of top rated movies.

  Future<List<Movie>> getTopRatedMovies() async {
    await _ensureClientInitialized();
    final results = await _client!.getJsonList('movie/top_rated');
    return results.map((movie) => Movie.fromJson(movie)).toList();
  }

  /// Gets a list of upcoming movies.

  Future<List<Movie>> getUpcomingMovies() async {
    await _ensureClientInitialized();
    final results = await _client!.getJsonList('movie/upcoming');
    return results.map((movie) => Movie.fromJson(movie)).toList();
  }

  /// Searches for movies matching the given query.

  Future<List<Movie>> searchMovies(String query) async {
    await _ensureClientInitialized();
    return await _searchService!.searchMovies(query);
  }

  /// Searches for movies by actor/person name.

  Future<List<Movie>> searchMoviesByActor(String actorName) async {
    await _ensureClientInitialized();
    return await _searchService!.searchMoviesByActor(actorName);
  }

  /// Searches for movies by genre name.

  Future<List<Movie>> searchMoviesByGenre(String genreName) async {
    await _ensureClientInitialized();
    return await _searchService!.searchMoviesByGenre(genreName);
  }

  /// Comprehensive search that searches by title, actor, and genre.

  Future<Map<String, List<Movie>>> searchMoviesComprehensive(
      String query) async {
    await _ensureClientInitialized();
    return await _searchService!.searchMoviesComprehensive(query);
  }

  /// Gets detailed information about a specific movie.

  Future<Movie> getMovieDetails(int movieId) async {
    await _ensureClientInitialized();
    final data = await _client!.getJson('movie/$movieId');
    return Movie.fromJson(data);
  }

  /// Disposes the network client.

  void dispose() {
    _client?.dispose();
    // Reset to null after disposal.

    _client = null;
    _searchService = null;
  }
}
