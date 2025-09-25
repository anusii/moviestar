/// Rating and comment-specific Turtle serialization functionality.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'dart:convert';

import 'package:rdflib/rdflib.dart';
import 'package:solidpod/solidpod.dart' show tripleMapToTurtle;

import 'package:moviestar/shared/utils/turtle/base_serializer.dart';
import 'package:moviestar/shared/utils/turtle/namespace_manager.dart';
import 'package:moviestar/shared/utils/turtle/parsing_utils.dart';

/// Handles Rating and Comment ↔ Turtle serialization operations.

class RatingCommentTurtleSerializer extends TurtleBaseSerializer {
  /// Converts ratings map to TTL format using proper RDF triples.

  static String ratingsToTurtle(Map<String, double> ratings) {
    final triples = <URIRef, Map<URIRef, dynamic>>{};

    // Create the ratings list resource.

    final ratingsResource = TurtleNamespaceManager.localNS.withAttr('ratings');
    triples[ratingsResource] = {
      TurtleNamespaceManager.rdfType: TurtleNamespaceManager.movieListType,
      TurtleNamespaceManager.nameProperty: Literal('User Ratings'),
    };

    // Add individual rating definitions.

    for (final entry in ratings.entries) {
      final ratingResource =
          TurtleNamespaceManager.localNS.withAttr('rating${entry.key}');
      triples[ratingResource] = {
        TurtleNamespaceManager.rdfType: TurtleNamespaceManager.ratingType,
        TurtleNamespaceManager.movieId: Literal(entry.key, datatype: XSD.int),
        TurtleNamespaceManager.value:
            Literal('${entry.value}', datatype: XSD.double),
      };
    }

    return tripleMapToTurtle(
      triples,
      bindNamespaces: TurtleNamespaceManager.getBasicNamespaces(),
    );
  }

  /// Converts movie comments to TTL format using proper RDF triples.

  static String commentsToTurtle(Map<String, String> comments) {
    final triples = <URIRef, Map<URIRef, dynamic>>{};

    // Create the comments list resource.

    final commentsResource =
        TurtleNamespaceManager.localNS.withAttr('comments');
    triples[commentsResource] = {
      TurtleNamespaceManager.rdfType: TurtleNamespaceManager.movieListType,
      TurtleNamespaceManager.nameProperty: Literal('User Comments'),
    };

    // Add individual comment definitions.

    for (final entry in comments.entries) {
      final commentResource =
          TurtleNamespaceManager.localNS.withAttr('comment${entry.key}');
      triples[commentResource] = {
        TurtleNamespaceManager.rdfType: TurtleNamespaceManager.commentType,
        TurtleNamespaceManager.movieId: Literal(entry.key, datatype: XSD.int),
        TurtleNamespaceManager.text:
            Literal(TurtleBaseSerializer.escapeString(entry.value)),
      };
    }

    return tripleMapToTurtle(
      triples,
      bindNamespaces: TurtleNamespaceManager.getBasicNamespaces(),
    );
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

      final triples = TurtleParsingUtils.safeParseTtl(ttlContent);
      if (triples == null) return {};

      final ratings = <String, double>{};

      // Find rating resources.

      for (final subject in triples.keys) {
        final predicates = triples[subject]!;

        // Check if this is a rating resource.

        final isRating = TurtleParsingUtils.hasRdfType(
          predicates,
          ['Rating', '#Rating'],
        );

        if (isRating) {
          final movieId = TurtleParsingUtils.extractFirstValue(
            predicates,
            ['#movieId'],
          );
          final ratingValue = TurtleParsingUtils.extractFirstValue(
            predicates,
            ['#value'],
          );

          if (movieId.isNotEmpty && ratingValue.isNotEmpty) {
            final rating = double.tryParse(ratingValue) ?? 0.0;
            ratings[movieId] = rating;
          }
        }
      }

      return ratings;
    } catch (e) {
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
        return decoded.cast<String, String>();
      }

      // Parse using proper RDF.

      final triples = TurtleParsingUtils.safeParseTtl(ttlContent);
      if (triples == null) return {};

      final comments = <String, String>{};

      // Find comment resources.

      for (final subject in triples.keys) {
        final predicates = triples[subject]!;

        // Check if this is a comment resource.

        final isComment = TurtleParsingUtils.hasRdfType(
          predicates,
          ['Comment', '#Comment'],
        );

        if (isComment) {
          final movieId = TurtleParsingUtils.extractFirstValue(
            predicates,
            ['#movieId'],
          );
          final commentText = TurtleParsingUtils.extractFirstValue(
            predicates,
            ['#text'],
          );

          if (movieId.isNotEmpty && commentText.isNotEmpty) {
            comments[movieId] = commentText;
          }
        }
      }

      return comments;
    } catch (e) {
      return {};
    }
  }
}
