/// Utilities for parsing Turtle content and extracting data.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'dart:convert';

import 'package:solidpod/solidpod.dart' show turtleToTripleMap;

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';

/// Utilities for parsing Turtle content and extracting structured data.
class TurtleParsingUtils {
  /// Extracts Movie object from RDF triples.
  static Movie? extractMovieFromTriples(
    Map<String, List<dynamic>> predicates,
  ) {
    try {
      // Try different namespace variations for predicates.

      final idValues = predicates['http://schema.org/identifier'] ??
          predicates['identifier'] ??
          predicates['#identifier'] ??
          [];
      final titleValues = predicates['http://schema.org/name'] ??
          predicates['name'] ??
          predicates['#name'] ??
          [];
      final overviewValues = predicates['http://schema.org/description'] ??
          predicates['description'] ??
          predicates['#description'] ??
          [];
      final posterValues = predicates['http://schema.org/image'] ??
          predicates['image'] ??
          predicates['#image'] ??
          [];
      final backdropValues = predicates['http://schema.org/thumbnailUrl'] ??
          predicates['thumbnailUrl'] ??
          predicates['#thumbnailUrl'] ??
          [];
      final ratingValues = predicates['http://schema.org/aggregateRating'] ??
          predicates['aggregateRating'] ??
          predicates['#aggregateRating'] ??
          [];
      final dateValues = predicates['http://schema.org/datePublished'] ??
          predicates['datePublished'] ??
          predicates['#datePublished'] ??
          [];
      final genreValues = predicates['http://schema.org/genre'] ??
          predicates['genre'] ??
          predicates['#genre'] ??
          [];

      if (idValues.isEmpty || titleValues.isEmpty) {
        return null;
      }

      final id = int.tryParse(idValues.first.toString()) ?? 0;
      final title = titleValues.first.toString();
      final overview =
          overviewValues.isNotEmpty ? overviewValues.first.toString() : '';
      final posterUrl =
          posterValues.isNotEmpty ? posterValues.first.toString() : '';
      final backdropUrl =
          backdropValues.isNotEmpty ? backdropValues.first.toString() : '';
      final voteAverage = double.tryParse(
            ratingValues.isNotEmpty ? ratingValues.first.toString() : '0',
          ) ??
          0.0;
      final releaseDate = dateValues.isNotEmpty
          ? DateTime.tryParse(dateValues.first.toString()) ?? DateTime.now()
          : DateTime.now();
      final genreString =
          genreValues.isNotEmpty ? genreValues.first.toString() : '';
      final genreIds = genreString.isNotEmpty
          ? genreString
              .split(',')
              .map((s) => int.tryParse(s.trim()) ?? 0)
              .toList()
          : <int>[];

      // Determine content type from RDF type in predicates.

      ContentType? contentType;
      final typeValues =
          predicates['http://www.w3.org/1999/02/22-rdf-syntax-ns#type'] ??
              predicates['type'] ??
              predicates['#type'] ??
              [];
      if (typeValues.isNotEmpty) {
        final isTvShow = typeValues.any(
          (type) =>
              type.toString().contains('TVShow') ||
              type == 'http://schema.org/TVShow' ||
              type == '#TVShow',
        );
        contentType = isTvShow ? ContentType.tvShow : ContentType.movie;
      }

      return Movie(
        id: id,
        title: title,
        overview: overview,
        posterUrl: posterUrl,
        backdropUrl: backdropUrl,
        voteAverage: voteAverage,
        releaseDate: releaseDate,
        genreIds: genreIds,
        contentType: contentType,
      );
    } catch (e) {
      return null;
    }
  }

  /// Tries to parse JSON backup data from TTL content.
  static List<Movie>? tryParseMovieJsonBackup(String ttlContent) {
    try {
      // First try to parse from JSON backup for backward compatibility.

      final jsonMatch = RegExp(r'# JSON_DATA: (.+)').firstMatch(ttlContent);
      if (jsonMatch != null) {
        final jsonData = jsonMatch.group(1)!;
        final decoded = jsonDecode(jsonData) as List<dynamic>;
        return decoded.map((movie) => Movie.fromJson(movie)).toList();
      }

      // Try to parse individual movie JSON backup format.

      final movieJsonMatch =
          RegExp(r'# JSON_MOVIE_DATA: (.+)').firstMatch(ttlContent);
      if (movieJsonMatch != null) {
        final movieJsonData = movieJsonMatch.group(1)!;
        final movieData = jsonDecode(movieJsonData) as Map<String, dynamic>;
        return [Movie.fromJson(movieData)];
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Tries to parse user data JSON backup from TTL content.
  static Map<String, dynamic>? tryParseUserDataJsonBackup(String ttlContent) {
    try {
      final movieJsonMatch = RegExp(
        r'# JSON_MOVIE_DATA: (.+)',
      ).firstMatch(ttlContent);
      final userDataJsonMatch = RegExp(
        r'# JSON_USER_DATA: (.+)',
      ).firstMatch(ttlContent);

      if (movieJsonMatch != null && userDataJsonMatch != null) {
        final movieJsonData = movieJsonMatch.group(1)!;
        final userDataJsonData = userDataJsonMatch.group(1)!;

        final movieData = jsonDecode(movieJsonData) as Map<String, dynamic>;
        final userData = jsonDecode(userDataJsonData) as Map<String, dynamic>;

        return {
          'movie': Movie.fromJson(movieData),
          'rating': userData['rating'],
          'comment': userData['comment'],
        };
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Safely parses TTL content to triple map.
  static Map<String, Map<String, List<dynamic>>>? safeParseTtl(
    String ttlContent,
  ) {
    try {
      return turtleToTripleMap(ttlContent);
    } catch (e) {
      return null;
    }
  }

  /// Checks if a subject has a specific RDF type.
  static bool hasRdfType(
    Map<String, List<dynamic>> predicates,
    List<String> typeMatches,
  ) {
    final typeValues =
        predicates['http://www.w3.org/1999/02/22-rdf-syntax-ns#type'] ?? [];
    return typeValues.any(
      (type) => typeMatches.any(
        (match) => type.toString().contains(match) || type.toString() == match,
      ),
    );
  }

  /// Extracts first value from predicate variations.
  static String extractFirstValue(
    Map<String, List<dynamic>> predicates,
    List<String> predicateVariations,
  ) {
    for (final variation in predicateVariations) {
      final values = predicates[variation];
      if (values != null && values.isNotEmpty) {
        return values.first.toString();
      }
    }
    return '';
  }
}
