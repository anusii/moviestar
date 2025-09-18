/// Rating and Comment Serialization for Turtle format.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:rdflib/rdflib.dart';
import 'package:solidpod/solidpod.dart'
    show tripleMapToTurtle, turtleToTripleMap;

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/utils/turtle/turtle_utils.dart';
import 'package:moviestar/utils/turtle_serializer.dart';

/// Utility class for serializing/deserializing ratings and comments to/from Turtle format.
class RatingCommentSerializers {
  /// Converts ratings map to TTL format using proper RDF triples.
  static String ratingsToTurtle(Map<String, double> ratings) {
    final triples = <URIRef, Map<URIRef, dynamic>>{};

    // Create the ratings list resource.
    final ratingsResource = TurtleSerializer.localNS.withAttr('ratings');
    triples[ratingsResource] = {
      TurtleSerializer.rdfType: TurtleSerializer.movieListType,
      TurtleSerializer.nameProperty: Literal('User Ratings'),
    };

    // Add individual rating definitions.
    for (final entry in ratings.entries) {
      final ratingResource =
          TurtleSerializer.localNS.withAttr('rating${entry.key}');
      triples[ratingResource] = {
        TurtleSerializer.rdfType: TurtleSerializer.ratingType,
        TurtleSerializer.movieId: Literal(entry.key, datatype: XSD.int),
        TurtleSerializer.value: Literal('${entry.value}', datatype: XSD.double),
      };
    }

    // Define namespace bindings - only bind our custom namespaces.
    final bindNamespaces = {'': TurtleSerializer.localNS};

    return tripleMapToTurtle(triples, bindNamespaces: bindNamespaces);
  }

  /// Converts movie comments to TTL format using proper RDF triples.
  static String commentsToTurtle(Map<String, String> comments) {
    final triples = <URIRef, Map<URIRef, dynamic>>{};

    // Create the comments list resource.
    final commentsResource = TurtleSerializer.localNS.withAttr('comments');
    triples[commentsResource] = {
      TurtleSerializer.rdfType: TurtleSerializer.movieListType,
      TurtleSerializer.nameProperty: Literal('User Comments'),
    };

    // Add individual comment definitions.
    for (final entry in comments.entries) {
      final commentResource =
          TurtleSerializer.localNS.withAttr('comment${entry.key}');
      triples[commentResource] = {
        TurtleSerializer.rdfType: TurtleSerializer.commentType,
        TurtleSerializer.movieId: Literal(entry.key, datatype: XSD.int),
        TurtleSerializer.text: Literal(TurtleUtils.escapeString(entry.value)),
      };
    }

    // Define namespace bindings - only bind our custom namespaces.
    final bindNamespaces = {'': TurtleSerializer.localNS};

    return tripleMapToTurtle(triples, bindNamespaces: bindNamespaces);
  }

  /// Parses ratings from TTL content using proper RDF parsing.
  static Map<String, double> ratingsFromTurtle(String ttlContent) {
    try {
      // First try JSON backup for backward compatibility.
      final jsonMatch = RegExp(r'# JSON_DATA: (.+)').firstMatch(ttlContent);
      if (jsonMatch != null) {
        final jsonData = jsonMatch.group(1)!;
        final decoded = jsonDecode(jsonData) as Map<String, dynamic>;
        return decoded.map((key, value) => MapEntry(key, value.toDouble()));
      }

      // Parse using proper RDF.
      final triples = turtleToTripleMap(ttlContent);
      final ratings = <String, double>{};

      // Find rating resources.
      for (final subject in triples.keys) {
        final predicates = triples[subject]!;

        // Check if this is a rating resource.
        final typeValues =
            predicates['http://www.w3.org/1999/02/22-rdf-syntax-ns#type'] ?? [];
        final isRating = typeValues.any(
          (type) => type.toString().contains('Rating') || type == '#Rating',
        );

        if (isRating) {
          final movieIdValues = predicates['#movieId'] ?? [];
          final valueValues = predicates['#value'] ?? [];

          if (movieIdValues.isNotEmpty && valueValues.isNotEmpty) {
            final movieId = movieIdValues.first.toString();
            final ratingValue =
                double.tryParse(valueValues.first.toString()) ?? 0.0;
            ratings[movieId] = ratingValue;
          }
        }
      }

      return ratings;
    } catch (e) {
      // Fallback to empty map if parsing fails.
      return {};
    }
  }

  /// Parses comments from TTL content using proper RDF parsing.
  static Map<String, String> commentsFromTurtle(String ttlContent) {
    try {
      // First try JSON backup for backward compatibility.
      final jsonMatch = RegExp(r'# JSON_DATA: (.+)').firstMatch(ttlContent);
      if (jsonMatch != null) {
        final jsonData = jsonMatch.group(1)!;
        final decoded = jsonDecode(jsonData) as Map<String, dynamic>;
        return decoded.map((key, value) => MapEntry(key, value.toString()));
      }

      // Parse using proper RDF.
      final triples = turtleToTripleMap(ttlContent);
      final comments = <String, String>{};

      // Find comment resources.
      for (final subject in triples.keys) {
        final predicates = triples[subject]!;

        // Check if this is a comment resource.
        final typeValues =
            predicates['http://www.w3.org/1999/02/22-rdf-syntax-ns#type'] ?? [];
        final isComment = typeValues.any(
          (type) => type.toString().contains('Comment') || type == '#Comment',
        );

        if (isComment) {
          final movieIdValues = predicates['#movieId'] ?? [];
          final textValues = predicates['#text'] ?? [];

          if (movieIdValues.isNotEmpty && textValues.isNotEmpty) {
            final movieId = movieIdValues.first.toString();
            final commentText = textValues.first.toString();
            comments[movieId] = commentText;
          }
        }
      }

      return comments;
    } catch (e) {
      // Fallback to empty map if parsing fails.
      return {};
    }
  }

  /// Enhanced ratings serialization with JSON backup.
  static String ratingsToTurtleWithJson(Map<String, double> ratings) {
    final buffer = StringBuffer();

    // Add proper TTL structure.
    buffer.writeln(ratingsToTurtle(ratings));

    // Add JSON backup as comment.
    buffer.writeln();
    buffer.writeln('# JSON_DATA: ${jsonEncode(ratings)}');

    return buffer.toString();
  }

  /// Enhanced comments serialization with JSON backup.
  static String commentsToTurtleWithJson(Map<String, String> comments) {
    final buffer = StringBuffer();

    // Add proper TTL structure.
    buffer.writeln(commentsToTurtle(comments));

    // Add JSON backup as comment.
    buffer.writeln();
    buffer.writeln('# JSON_DATA: ${jsonEncode(comments)}');

    return buffer.toString();
  }

  /// Updates a single movie with user's personal rating and comment following the ontology structure.
  static String movieWithUserDataToTurtle(
    Movie movie,
    double? rating,
    String? comment,
  ) {
    final triples = <URIRef, Map<URIRef, dynamic>>{};

    // Create the movie resource with full details
    final movieResource = TurtleSerializer.localNS.withAttr('movie${movie.id}');
    triples[movieResource] = {
      TurtleSerializer.rdfType: TurtleSerializer.movieType,
      TurtleSerializer.identifier: Literal('${movie.id}', datatype: XSD.int),
      TurtleSerializer.name: Literal(TurtleUtils.escapeString(movie.title)),
      TurtleSerializer.description:
          Literal(TurtleUtils.escapeString(movie.overview)),
      TurtleSerializer.image:
          Literal(TurtleUtils.escapeString(movie.posterUrl)),
      TurtleSerializer.thumbnailUrl:
          Literal(TurtleUtils.escapeString(movie.backdropUrl)),
      TurtleSerializer.aggregateRating:
          Literal('${movie.voteAverage}', datatype: XSD.double),
      TurtleSerializer.datePublished: Literal(
        movie.releaseDate.toIso8601String(),
        datatype: XSD.dateTime,
      ),
      TurtleSerializer.genre: Literal(movie.genreIds.join(',')),
    };

    // Add user rating if provided
    if (rating != null) {
      final userRatingResource =
          TurtleSerializer.localNS.withAttr('userRating${movie.id}');
      triples[userRatingResource] = {
        TurtleSerializer.rdfType: TurtleSerializer.ratingType,
        TurtleSerializer.movieId: Literal('${movie.id}', datatype: XSD.int),
        TurtleSerializer.value: Literal('$rating', datatype: XSD.double),
      };

      // Link the movie to the user rating
      triples[movieResource]![TurtleSerializer.comment] = userRatingResource;
    }

    // Add user comment if provided
    if (comment != null && comment.isNotEmpty) {
      final userCommentResource =
          TurtleSerializer.localNS.withAttr('userComment${movie.id}');
      triples[userCommentResource] = {
        TurtleSerializer.rdfType: TurtleSerializer.commentType,
        TurtleSerializer.movieId: Literal('${movie.id}', datatype: XSD.int),
        TurtleSerializer.text: Literal(TurtleUtils.escapeString(comment)),
      };

      // Link the movie to the user comment
      triples[movieResource]![TurtleSerializer.comment] = userCommentResource;
    }

    // Use a minimal namespace binding for user data files
    final bindNamespaces = {
      '': TurtleSerializer.localNS,
      'schema': TurtleSerializer.movieNS,
    };

    return tripleMapToTurtle(triples, bindNamespaces: bindNamespaces);
  }

  /// Parses a single movie with user data from TTL content.
  /// Returns a map containing the movie, rating, and comment.
  static Map<String, dynamic>? movieWithUserDataFromTurtle(String ttlContent) {
    try {
      // First try to parse from JSON backup for compatibility.
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

      // Parse using proper RDF if no JSON backup.
      final triples = turtleToTripleMap(ttlContent);
      Movie? movie;
      double? rating;
      String? comment;

      // Find movie, rating, and comment resources.
      for (final subject in triples.keys) {
        final predicates = triples[subject]!;
        final typeValues =
            predicates['http://www.w3.org/1999/02/22-rdf-syntax-ns#type'] ??
                predicates['type'] ??
                predicates['#type'] ??
                [];

        final isMovie = typeValues.any(
          (type) =>
              type.toString().contains('Movie') ||
              type == 'http://schema.org/Movie' ||
              type == '#Movie',
        );
        final isRating = typeValues.any(
          (type) => type.toString().contains('Rating') || type == '#Rating',
        );
        final isComment = typeValues.any(
          (type) => type.toString().contains('Comment') || type == '#Comment',
        );

        if (isMovie) {
          // Extract movie data from predicates - use the shared method
          final movieFromTriples = _extractMovieFromTriples(predicates);
          if (movieFromTriples != null) {
            movie = movieFromTriples;
          }
        } else if (isRating) {
          final valueValues = predicates['#value'] ?? [];
          if (valueValues.isNotEmpty) {
            rating = double.tryParse(valueValues.first.toString());
          }
        } else if (isComment) {
          final textValues = predicates['#text'] ?? [];
          if (textValues.isNotEmpty) {
            comment = textValues.first.toString();
          }
        }
      }

      if (movie != null) {
        return {
          'movie': movie,
          'rating': rating,
          'comment': comment,
        };
      }

      return null;
    } catch (e) {
      debugPrint('Error parsing movie with user data: $e');
      return null;
    }
  }

  /// Extract Movie object from RDF triples (shared helper method).
  static Movie? _extractMovieFromTriples(
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

      return Movie(
        id: id,
        title: title,
        overview: overview,
        posterUrl: posterUrl,
        backdropUrl: backdropUrl,
        voteAverage: voteAverage,
        releaseDate: releaseDate,
        genreIds: genreIds,
      );
    } catch (e) {
      return null;
    }
  }
}
