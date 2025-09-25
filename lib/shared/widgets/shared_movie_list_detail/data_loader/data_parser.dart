/// Data parsing operations for shared movie list data loading.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'dart:convert';

/// Static helper class for data parsing operations.

class DataParser {
  /// Extract title from enhanced movie data.

  static String? extractTitleFromEnhancedData(
    Map<String, dynamic> enhancedData,
  ) {
    // Check if we have a title field in the enhanced data.

    final title = enhancedData['title'] as String?;
    if (title != null && title.isNotEmpty) {
      return title;
    }
    return null;
  }

  /// Parses individual movie file content to extract title, rating and comments.

  static Future<Map<String, dynamic>?> parseIndividualMovieData(
    String ttlContent,
  ) async {
    try {
      double? rating;
      String? comments;
      String? title;

      // Try to parse JSON backup data first (more reliable).

      final movieJsonMatch = RegExp(
        r'# JSON_MOVIE_DATA: (.+)',
      ).firstMatch(ttlContent);

      Map<String, dynamic>? movieMetadata;
      if (movieJsonMatch != null) {
        final movieJsonData = movieJsonMatch.group(1)!;
        movieMetadata = jsonDecode(movieJsonData) as Map<String, dynamic>;
        title = movieMetadata['title'] as String?;
      }

      final userJsonMatch = RegExp(
        r'# JSON_USER_DATA: (.+)',
      ).firstMatch(ttlContent);

      if (userJsonMatch != null) {
        final userJsonData = userJsonMatch.group(1)!;
        final userData = jsonDecode(userJsonData) as Map<String, dynamic>;
        rating = userData['rating'] as double?;
        comments = userData['comment'] as String?;
      }

      // If no JSON backup, try TTL parsing (fallback).

      if (title == null || rating == null || comments == null) {
        final lines = ttlContent.split('\n');
        for (final line in lines) {
          final trimmedLine = line.trim();

          // Extract title.

          if (title == null &&
              (trimmedLine.contains('schema:name') ||
                  trimmedLine.contains('sdo:name') ||
                  trimmedLine.contains(':name'))) {
            final match = RegExp(r'"([^"]*)"').firstMatch(trimmedLine);
            if (match != null) {
              title = match.group(1);
            }
          }

          // Extract rating.

          if (rating == null && trimmedLine.contains('schema:ratingValue')) {
            final match = RegExp(r'"?([0-9.]+)"?').firstMatch(trimmedLine);
            if (match != null) {
              rating = double.tryParse(match.group(1)!);
            }
          }

          // Extract comments.

          if (comments == null && trimmedLine.contains('schema:reviewBody')) {
            final match = RegExp(r'"([^"]*)"').firstMatch(trimmedLine);
            if (match != null) {
              comments = match.group(1);
            }
          }
        }
      }

      // Build comprehensive result with TMDB metadata if available.

      final result = <String, dynamic>{};

      if (title != null) result['title'] = title;
      if (rating != null) result['rating'] = rating;
      if (comments != null && comments.isNotEmpty) {
        result['comments'] = comments;
      }

      // Include TMDB metadata from JSON backup if available.

      if (movieMetadata != null) {
        // Add poster and backdrop URLs.

        if (movieMetadata['poster_path'] != null) {
          result['posterUrl'] =
              'https://image.tmdb.org/t/p/w500${movieMetadata['poster_path']}';
        }
        if (movieMetadata['backdrop_path'] != null) {
          result['backdropUrl'] =
              'https://image.tmdb.org/t/p/w1280${movieMetadata['backdrop_path']}';
        }

        // Add other TMDB fields.

        if (movieMetadata['overview'] != null) {
          result['overview'] = movieMetadata['overview'];
        }
        if (movieMetadata['release_date'] != null) {
          result['releaseDate'] = movieMetadata['release_date'];
        }
        if (movieMetadata['first_air_date'] != null) {
          result['releaseDate'] =
              movieMetadata['first_air_date']; // For TV shows
        }
        if (movieMetadata['vote_average'] != null) {
          result['voteAverage'] = movieMetadata['vote_average'];
        }
        if (movieMetadata['genre_ids'] != null) {
          result['genreIds'] = movieMetadata['genre_ids'];
        }
      }

      if (result.isNotEmpty) {
        return result;
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
