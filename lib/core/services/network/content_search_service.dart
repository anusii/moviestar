/// Service for searching both movies and TV shows by title, actor, and genre.
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
import 'package:moviestar/utils/network_client.dart';

/// A service class that handles content search operations for both movies and TV shows.

class ContentSearchService {
  final NetworkClient _client;

  /// Creates a new ContentSearchService instance.

  ContentSearchService(this._client);

  /// Searches for content (movies and TV shows) matching the given query.

  Future<List<ContentItem>> searchContent(String query) async {
    print(
        '🔍 [ContentSearchService] searchContent called with query: "$query"',);
    final allContent = <ContentItem>[];

    try {
      print('🔍 [ContentSearchService] Searching movies...');
      // Search movies.
      final movieResults = await _client.getJsonList(
        'search/movie?query=${Uri.encodeComponent(query)}',
      );
      print(
          '🔍 [ContentSearchService] Movie search returned ${movieResults.length} results',);
      allContent.addAll(
        movieResults.map((movie) => ContentItem.fromMovieJson(movie)),
      );

      print('🔍 [ContentSearchService] Searching TV shows...');
      // Search TV shows.
      final tvResults = await _client.getJsonList(
        'search/tv?query=${Uri.encodeComponent(query)}',
      );
      print(
          '🔍 [ContentSearchService] TV search returned ${tvResults.length} results',);
      allContent.addAll(tvResults.map((tv) => ContentItem.fromTVJson(tv)));

      // Sort by vote average for better results.
      allContent.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));

      print(
          '🔍 [ContentSearchService] searchContent completed with ${allContent.length} total results',);
      return allContent;
    } catch (e) {
      print('🔍 [ContentSearchService] searchContent failed: $e');
      rethrow;
    }
  }

  /// Searches for movies matching the given query (backward compatibility).

  Future<List<Movie>> searchMovies(String query) async {
    final results = await _client.getJsonList(
      'search/movie?query=${Uri.encodeComponent(query)}',
    );
    return results.map((movie) => Movie.fromJson(movie)).toList();
  }

  /// Searches for content by actor/person name.

  Future<List<ContentItem>> searchContentByActor(String actorName) async {
    // First search for people.

    final personResults = await _client.getJsonList(
      'search/person?query=${Uri.encodeComponent(actorName)}',
    );

    if (personResults.isEmpty) return [];

    final allContent = <ContentItem>[];
    final seenContentIds = <String>{};

    // Determine if this is a specific search (contains space) or generic.

    final isSpecificSearch = actorName.contains(' ');

    // Sort people by popularity (descending) and known_for_department.

    final sortedPeople = List<Map<String, dynamic>>.from(personResults);
    sortedPeople.sort((a, b) {
      final popularityA = (a['popularity'] as num?)?.toDouble() ?? 0.0;
      final popularityB = (b['popularity'] as num?)?.toDouble() ?? 0.0;

      // Prioritise actors over other professions.

      final knownForA = a['known_for_department'] as String? ?? '';
      final knownForB = b['known_for_department'] as String? ?? '';
      final isActorA = knownForA.toLowerCase() == 'acting';
      final isActorB = knownForB.toLowerCase() == 'acting';

      if (isActorA && !isActorB) return -1;
      if (!isActorA && isActorB) return 1;

      return popularityB.compareTo(popularityA);
    });

    // For generic searches, process more people to find famous actors.

    final maxPeopleToProcess = isSpecificSearch ? 5 : 10;
    final peopleToProcess = sortedPeople.take(maxPeopleToProcess);

    for (final person in peopleToProcess) {
      try {
        final personId = person['id'];
        final popularity = (person['popularity'] as num?)?.toDouble() ?? 0.0;

        // Skip people who are too unknown.

        final minPopularity = isSpecificSearch ? 0.1 : 0.5;
        if (popularity < minPopularity) {
          continue;
        }

        // Get movie credits.

        try {
          final movieCredits =
              await _client.getJson('person/$personId/movie_credits');
          final movieCast = movieCredits['cast'] as List<dynamic>? ?? [];

          for (final movieData in movieCast) {
            final contentKey = 'movie_${movieData['id']}';
            if (!seenContentIds.contains(contentKey)) {
              try {
                final contentItem = ContentItem.fromMovieJson(movieData);
                allContent.add(contentItem);
                seenContentIds.add(contentKey);
              } catch (e) {
                continue;
              }
            }
          }
        } catch (e) {
          // Continue even if movie credits fail.
        }

        // Get TV credits.

        try {
          final tvCredits =
              await _client.getJson('person/$personId/tv_credits');
          final tvCast = tvCredits['cast'] as List<dynamic>? ?? [];

          for (final tvData in tvCast) {
            final contentKey = 'tv_${tvData['id']}';
            if (!seenContentIds.contains(contentKey)) {
              try {
                final contentItem = ContentItem.fromTVJson(tvData);
                allContent.add(contentItem);
                seenContentIds.add(contentKey);
              } catch (e) {
                continue;
              }
            }
          }
        } catch (e) {
          // Continue even if TV credits fail.
        }

        // If we have a very specific search and found a highly popular match, prioritise that.

        if (isSpecificSearch && popularity > 10.0) {
          break;
        }
      } catch (e) {
        continue;
      }
    }

    // Sort by popularity/rating for better results ordering.

    allContent.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));

    return allContent;
  }

  /// Searches for movies by actor/person name (backward compatibility).

  Future<List<Movie>> searchMoviesByActor(String actorName) async {
    // Use the existing actor search from content, but filter to movies only.

    final contentResults = await searchContentByActor(actorName);
    return contentResults
        .where((content) => content.contentType == ContentType.movie)
        .map((content) => Movie.fromContentItem(content))
        .toList();
  }

  /// Searches for content by genre name.

  Future<List<ContentItem>> searchContentByGenre(String genreName) async {
    final allContent = <ContentItem>[];

    // Get movie genre list.

    try {
      final movieGenreResponse = await _client.getJson('genre/movie/list');
      final movieGenres = movieGenreResponse['genres'] as List<dynamic>;

      // Find matching movie genre.

      final matchingMovieGenre = movieGenres.firstWhere(
        (genre) => (genre['name'] as String).toLowerCase().contains(
              genreName.toLowerCase(),
            ),
        orElse: () => null,
      );

      if (matchingMovieGenre != null) {
        // Search movies by genre ID.

        final movieGenreId = matchingMovieGenre['id'];
        final movieResults = await _client.getJsonList(
          'discover/movie?with_genres=$movieGenreId',
        );

        allContent.addAll(
          movieResults.map((movie) => ContentItem.fromMovieJson(movie)),
        );
      }
    } catch (e) {
      // Continue even if movie genre search fails.
    }

    // Get TV genre list.

    try {
      final tvGenreResponse = await _client.getJson('genre/tv/list');
      final tvGenres = tvGenreResponse['genres'] as List<dynamic>;

      // Find matching TV genre.

      final matchingTVGenre = tvGenres.firstWhere(
        (genre) => (genre['name'] as String).toLowerCase().contains(
              genreName.toLowerCase(),
            ),
        orElse: () => null,
      );

      if (matchingTVGenre != null) {
        // Search TV shows by genre ID.

        final tvGenreId = matchingTVGenre['id'];
        final tvResults = await _client.getJsonList(
          'discover/tv?with_genres=$tvGenreId',
        );

        allContent.addAll(tvResults.map((tv) => ContentItem.fromTVJson(tv)));
      }
    } catch (e) {
      // Continue even if TV genre search fails.
    }

    return allContent;
  }

  /// Searches for movies by genre name (backward compatibility).

  Future<List<Movie>> searchMoviesByGenre(String genreName) async {
    // Get genre list first.

    final genreResponse = await _client.getJson('genre/movie/list');
    final genres = genreResponse['genres'] as List<dynamic>;

    // Find matching genre.

    final matchingGenre = genres.firstWhere(
      (genre) => (genre['name'] as String).toLowerCase().contains(
            genreName.toLowerCase(),
          ),
      orElse: () => null,
    );

    if (matchingGenre == null) return [];

    // Search movies by genre ID.

    final genreId = matchingGenre['id'];
    final results = await _client.getJsonList(
      'discover/movie?with_genres=$genreId',
    );

    return results.map((movie) => Movie.fromJson(movie)).toList();
  }

  /// Comprehensive search that searches by title, actor, director, and genre for both movies and TV shows.

  Future<Map<String, List<ContentItem>>> searchContentComprehensive(
    String query,
  ) async {
    print(
        '🔍 [ContentSearchService] searchContentComprehensive called with query: "$query"',);
    final results = <String, List<ContentItem>>{};

    try {
      print('🔍 [ContentSearchService] Searching by title...');
      // Search by title.
      results['title'] = await searchContent(query);
      print(
          '🔍 [ContentSearchService] Title search completed: ${results['title']!.length} results',);
    } catch (e) {
      print('🔍 [ContentSearchService] Title search failed: $e');
      results['title'] = [];
    }

    try {
      print('🔍 [ContentSearchService] Searching by actor...');
      // Search by actor.
      results['actor'] = await searchContentByActor(query);
      print(
          '🔍 [ContentSearchService] Actor search completed: ${results['actor']!.length} results',);
    } catch (e) {
      print('🔍 [ContentSearchService] Actor search failed: $e');
      results['actor'] = [];
    }

    try {
      print('🔍 [ContentSearchService] Searching by genre...');
      // Search by genre.
      results['genre'] = await searchContentByGenre(query);
      print(
          '🔍 [ContentSearchService] Genre search completed: ${results['genre']!.length} results',);
    } catch (e) {
      print('🔍 [ContentSearchService] Genre search failed: $e');
      results['genre'] = [];
    }

    print(
        '🔍 [ContentSearchService] Comprehensive search completed with ${results.values.fold(0, (sum, list) => sum + list.length)} total results',);
    return results;
  }

  /// Comprehensive search for movies only (backward compatibility).

  Future<Map<String, List<Movie>>> searchMoviesComprehensive(
    String query,
  ) async {
    final results = <String, List<Movie>>{};

    try {
      // Search by title.

      results['title'] = await searchMovies(query);
    } catch (e) {
      results['title'] = [];
    }

    try {
      // Search by actor.

      results['actor'] = await searchMoviesByActor(query);
    } catch (e) {
      results['actor'] = [];
    }

    try {
      // Search by genre.

      results['genre'] = await searchMoviesByGenre(query);
    } catch (e) {
      results['genre'] = [];
    }

    return results;
  }
}
