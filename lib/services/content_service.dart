/// Service for managing both movies and TV shows in the Movie Star application.
///
// Time-stamp: <Friday 2025-01-17 19:45:00 +1000 Assistant>
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
/// Authors: Ashley Tang

library;

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/api_key_service.dart';
import 'package:moviestar/services/content_search_service.dart';
import 'package:moviestar/utils/network_client.dart';

//
class ContentService {
  // Base URL for The Movie Database API.

  static const String _baseUrl = 'https://api.themoviedb.org/3';

  // Network client for making HTTP requests.

  NetworkClient? _client;

  // Service for content search operations.

  ContentSearchService? _searchService;

  // Service for managing the API key.

  final ApiKeyService _apiKeyService;

  // Creates a new ContentService instance.

  ContentService(ApiKeyService apiKeyService) : _apiKeyService = apiKeyService {
    _initializeClient();
  }

  // Initializes the network client with the API key from secure storage.

  Future<void> _initializeClient() async {
    final apiKey = await _apiKeyService.getApiKey();
    _client = NetworkClient(baseUrl: _baseUrl, apiKey: apiKey ?? '');
    _searchService = ContentSearchService(_client!);
  }

  // Updates the API key and recreates the network client.

  Future<void> updateApiKey() async {
    _client?.dispose();
    _client = null;
    _searchService = null;
    await _initializeClient();
  }

  // Ensures the client is initialized before making requests.

  Future<void> _ensureClientInitialized() async {
    if (_client == null) {
      await _initializeClient();
    }
  }

  // MOVIE METHODS

  // Gets a list of popular movies.

  Future<List<ContentItem>> getPopularMovies() async {
    await _ensureClientInitialized();
    final results = await _client!.getJsonList('movie/popular');
    return results.map((movie) => ContentItem.fromMovieJson(movie)).toList();
  }

  // Gets a list of movies currently playing in theaters.

  Future<List<ContentItem>> getNowPlayingMovies() async {
    await _ensureClientInitialized();
    final results = await _client!.getJsonList('movie/now_playing');
    return results.map((movie) => ContentItem.fromMovieJson(movie)).toList();
  }

  // Gets a list of top rated movies.

  Future<List<ContentItem>> getTopRatedMovies() async {
    await _ensureClientInitialized();
    final results = await _client!.getJsonList('movie/top_rated');
    return results.map((movie) => ContentItem.fromMovieJson(movie)).toList();
  }

  // Gets a list of upcoming movies.

  Future<List<ContentItem>> getUpcomingMovies() async {
    await _ensureClientInitialized();
    final results = await _client!.getJsonList('movie/upcoming');
    return results.map((movie) => ContentItem.fromMovieJson(movie)).toList();
  }

  // TV SHOW METHODS

  // Gets a list of popular TV shows.

  Future<List<ContentItem>> getPopularTVShows() async {
    await _ensureClientInitialized();
    final results = await _client!.getJsonList('tv/popular');
    return results.map((tvShow) => ContentItem.fromTVJson(tvShow)).toList();
  }

  // Gets a mixed list of popular movies and TV shows for better content diversity.

  Future<List<ContentItem>> getPopularMixedContent() async {
    await _ensureClientInitialized();

    // Fetch both popular movies and TV shows
    final moviesFuture = getPopularMovies();
    final tvShowsFuture = getPopularTVShows();

    final results = await Future.wait([moviesFuture, tvShowsFuture]);
    final movies = results[0];
    final tvShows = results[1];

    // Combine and shuffle for better variety
    final combined = <ContentItem>[];
    combined.addAll(movies);
    combined.addAll(tvShows);

    // Sort by vote average to maintain quality
    combined.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));

    return combined;
  }

  // Gets a list of TV shows currently airing.

  Future<List<ContentItem>> getOnTheAirTVShows() async {
    await _ensureClientInitialized();
    final results = await _client!.getJsonList('tv/on_the_air');
    return results.map((tvShow) => ContentItem.fromTVJson(tvShow)).toList();
  }

  // Gets a list of top rated TV shows.

  Future<List<ContentItem>> getTopRatedTVShows() async {
    await _ensureClientInitialized();
    final results = await _client!.getJsonList('tv/top_rated');
    return results.map((tvShow) => ContentItem.fromTVJson(tvShow)).toList();
  }

  // Gets a list of TV shows airing today.

  Future<List<ContentItem>> getAiringTodayTVShows() async {
    await _ensureClientInitialized();
    final results = await _client!.getJsonList('tv/airing_today');
    return results.map((tvShow) => ContentItem.fromTVJson(tvShow)).toList();
  }

  // SEARCH METHODS

  // Searches for content (movies and TV shows) matching the given query.

  Future<List<ContentItem>> searchContent(String query) async {
    await _ensureClientInitialized();
    return await _searchService!.searchContent(query);
  }

  // Searches for movies matching the given query.

  Future<List<Movie>> searchMovies(String query) async {
    await _ensureClientInitialized();
    return await _searchService!.searchMovies(query);
  }

  // Searches for content by actor/person name.

  Future<List<ContentItem>> searchContentByActor(String actorName) async {
    await _ensureClientInitialized();
    return await _searchService!.searchContentByActor(actorName);
  }

  // Searches for movies by actor/person name (backward compatibility).

  Future<List<Movie>> searchMoviesByActor(String actorName) async {
    await _ensureClientInitialized();
    return await _searchService!.searchMoviesByActor(actorName);
  }

  // Searches for content by genre name.

  Future<List<ContentItem>> searchContentByGenre(String genreName) async {
    await _ensureClientInitialized();
    return await _searchService!.searchContentByGenre(genreName);
  }

  // Searches for movies by genre name (backward compatibility).

  Future<List<Movie>> searchMoviesByGenre(String genreName) async {
    await _ensureClientInitialized();
    return await _searchService!.searchMoviesByGenre(genreName);
  }

  // Comprehensive search that searches by title, actor, and genre for both movies and TV shows.

  Future<Map<String, List<ContentItem>>> searchContentComprehensive(
    String query,
  ) async {
    await _ensureClientInitialized();
    return await _searchService!.searchContentComprehensive(query);
  }

  // Comprehensive search for movies only (backward compatibility).

  Future<Map<String, List<Movie>>> searchMoviesComprehensive(
    String query,
  ) async {
    await _ensureClientInitialized();
    return await _searchService!.searchMoviesComprehensive(query);
  }

  // DETAIL METHODS

  // Gets detailed information about a specific movie.

  Future<ContentItem> getMovieDetails(int movieId) async {
    await _ensureClientInitialized();
    final data = await _client!.getJson('movie/$movieId');
    return ContentItem.fromMovieJson(data);
  }

  // Gets detailed information about a specific TV show.

  Future<ContentItem> getTVDetails(int tvId) async {
    await _ensureClientInitialized();
    final data = await _client!.getJson('tv/$tvId');
    return ContentItem.fromTVJson(data);
  }

  // Gets detailed information about content (auto-detects type).

  Future<ContentItem> getContentDetails(
    int contentId,
    ContentType contentType,
  ) async {
    if (contentType == ContentType.movie) {
      return getMovieDetails(contentId);
    } else {
      return getTVDetails(contentId);
    }
  }

  // Disposes the network client.

  void dispose() {
    _client?.dispose();
    _client = null;
    _searchService = null;
  }
}
