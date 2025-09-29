/// Service for managing movies in the Movie Star application.
///
// Time-stamp: <Thursday 2025-04-10 11:47:48 +1000 Graham Williams>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Kevin Wang, Ashley Tang.

library;

import 'package:moviestar/core/services/api/content_service.dart';
import 'package:moviestar/core/services/api/key_service.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/utils/network_client.dart';

/// A service class that handles movie-related API requests.

class MovieService {
  /// Base URL for The Movie Database API.

  static const String _baseUrl = 'https://api.themoviedb.org/3';

  /// Network client for making HTTP requests.

  NetworkClient? _client;

  /// Content service for handling both movies and TV shows.

  ContentService? _contentService;

  /// Service for managing the API key.

  final ApiKeyService? _apiKeyService;

  /// Creates a new MovieService instance.

  MovieService(ApiKeyService? apiKeyService) : _apiKeyService = apiKeyService {
    _initializeClient();
  }

  /// Initializes the network client with the API key from secure storage.

  Future<void> _initializeClient() async {
    if (_apiKeyService == null) {
      _client = NetworkClient(baseUrl: _baseUrl, apiKey: '');
      _contentService = ContentService(null);
      return;
    }
    final apiKey = await _apiKeyService.getApiKey();
    _client = NetworkClient(baseUrl: _baseUrl, apiKey: apiKey ?? '');
    _contentService = ContentService(_apiKeyService);
  }

  /// Updates the API key and recreates the network client.

  Future<void> updateApiKey() async {
    if (_apiKeyService == null) return;
    _client?.dispose();
    _contentService?.dispose();
    // Reset to null to force recreation.

    _client = null;
    _contentService = null;
    await _initializeClient();
  }

  /// Ensures the client is initialized before making requests.

  Future<void> _ensureClientInitialized() async {
    if (_client == null) {
      await _initializeClient();
    }
  }

  /// Gets a list of recommended movies and TV shows (mixed content for better variety).

  Future<List<Movie>> getRecommendedMovies() async {
    await _ensureClientInitialized();
    final contentItems = await _contentService!.getRecommendedMixedContent();
    return contentItems
        .map((content) => Movie.fromContentItem(content))
        .toList();
  }

  /// Gets a list of movies currently playing in theaters and TV shows on the air.

  Future<List<Movie>> getNowPlayingMovies() async {
    await _ensureClientInitialized();
    final contentItems = await _contentService!.getNowPlayingMixedContent();
    return contentItems
        .map((content) => Movie.fromContentItem(content))
        .toList();
  }

  /// Gets a list of top rated movies and TV shows.

  Future<List<Movie>> getTopRatedMovies() async {
    await _ensureClientInitialized();
    final contentItems = await _contentService!.getTopRatedMixedContent();
    return contentItems
        .map((content) => Movie.fromContentItem(content))
        .toList();
  }

  /// Gets a list of upcoming movies and TV shows airing today.

  Future<List<Movie>> getUpcomingMovies() async {
    await _ensureClientInitialized();
    final contentItems = await _contentService!.getUpcomingMixedContent();
    return contentItems
        .map((content) => Movie.fromContentItem(content))
        .toList();
  }

  /// Searches for movies matching the given query.

  Future<List<Movie>> searchMovies(String query) async {
    await _ensureClientInitialized();
    return await _contentService!.searchMovies(query);
  }

  /// Searches for movies by actor/person name.

  Future<List<Movie>> searchMoviesByActor(String actorName) async {
    await _ensureClientInitialized();
    return await _contentService!.searchMoviesByActor(actorName);
  }

  /// Searches for movies by genre name.

  Future<List<Movie>> searchMoviesByGenre(String genreName) async {
    await _ensureClientInitialized();
    return await _contentService!.searchMoviesByGenre(genreName);
  }

  /// Comprehensive search that searches by title, actor, and genre.

  Future<Map<String, List<Movie>>> searchMoviesComprehensive(
    String query,
  ) async {
    await _ensureClientInitialized();
    return await _contentService!.searchMoviesComprehensive(query);
  }

  /// Gets detailed information about a specific movie.

  Future<Movie> getMovieDetails(int movieId) async {
    await _ensureClientInitialized();
    final contentItem = await _contentService!.getMovieDetails(movieId);
    return Movie.fromContentItem(contentItem);
  }

  /// Disposes the network client.

  void dispose() {
    _client?.dispose();
    _contentService?.dispose();
    // Reset to null after disposal.

    _client = null;
    _contentService = null;
  }
}
