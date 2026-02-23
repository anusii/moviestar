/// Utilities for parsing Turtle content and extracting data.
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
/// Authors: Ashley Tang, Kevin Wang

library;

import 'dart:convert';

import 'package:solidpod/solidpod.dart' show turtleToTripleMap;

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';

/// Utilities for parsing Turtle content and extracting structured data.

class TurtleParsingUtils {
  /// Extracts Movie object from RDF triples.

  static Movie? extractMovieFromTriples(
    Map<String, dynamic> predicates,
  ) {
    try {
      // Helper to convert dynamic value to list.

      List<dynamic> toList(dynamic value) {
        if (value == null) return [];
        if (value is List) return value;
        return [value];
      }

      // Try different namespace variations for predicates.

      final idValues = toList(
        predicates['http://schema.org/identifier'] ??
            predicates['identifier'] ??
            predicates['#identifier'],
      );
      final titleValues = toList(
        predicates['http://schema.org/name'] ??
            predicates['name'] ??
            predicates['#name'],
      );
      final overviewValues = toList(
        predicates['http://schema.org/description'] ??
            predicates['description'] ??
            predicates['#description'],
      );
      final posterValues = toList(
        predicates['http://schema.org/image'] ??
            predicates['image'] ??
            predicates['#image'],
      );
      final backdropValues = toList(
        predicates['http://schema.org/thumbnailUrl'] ??
            predicates['thumbnailUrl'] ??
            predicates['#thumbnailUrl'],
      );
      final ratingValues = toList(
        predicates['http://schema.org/aggregateRating'] ??
            predicates['aggregateRating'] ??
            predicates['#aggregateRating'],
      );
      final dateValues = toList(
        predicates['http://schema.org/datePublished'] ??
            predicates['datePublished'] ??
            predicates['#datePublished'],
      );
      final genreValues = toList(
        predicates['http://schema.org/genre'] ??
            predicates['genre'] ??
            predicates['#genre'],
      );

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
      final typeValues = toList(
        predicates['http://www.w3.org/1999/02/22-rdf-syntax-ns#type'] ??
            predicates['type'] ??
            predicates['#type'],
      );
      if (typeValues.isNotEmpty) {
        final isTvShow = typeValues.any(
          (type) =>
              type.toString().contains('TVShow') ||
              type == 'http://schema.org/TVSeries' ||
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

  static Map<String, Map<String, dynamic>>? safeParseTtl(
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
    Map<String, dynamic> predicates,
    List<String> typeMatches,
  ) {
    final rawValue =
        predicates['http://www.w3.org/1999/02/22-rdf-syntax-ns#type'];
    final List<dynamic> typeValues =
        rawValue == null ? [] : (rawValue is List ? rawValue : [rawValue]);
    return typeValues.any(
      (type) => typeMatches.any(
        (match) => type.toString().contains(match) || type.toString() == match,
      ),
    );
  }

  /// Extracts first value from predicate variations.

  static String extractFirstValue(
    Map<String, dynamic> predicates,
    List<String> predicateVariations,
  ) {
    for (final variation in predicateVariations) {
      final rawValue = predicates[variation];
      if (rawValue != null) {
        if (rawValue is List && rawValue.isNotEmpty) {
          return rawValue.first.toString();
        } else if (rawValue is! List) {
          return rawValue.toString();
        }
      }
    }
    return '';
  }
}
