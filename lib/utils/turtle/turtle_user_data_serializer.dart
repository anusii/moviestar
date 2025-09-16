/// User data (ratings, comments) Turtle serialization functionality
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/foundation.dart';
import 'package:rdflib/rdflib.dart';

import 'package:moviestar/utils/turtle/turtle_namespaces.dart';
import 'package:moviestar/utils/turtle/turtle_utils.dart';

/// Handles conversion of user ratings and comments to/from Turtle format
class TurtleUserDataSerializer {
  /// Converts movie ratings to Turtle format
  static String ratingsToTurtle(Map<String, double> ratings) {
    final graph = Graph();
    final namespaces = TurtleNamespaces.getOntologyNamespaces();

    // Add namespaces
    for (final entry in namespaces.entries) {
      graph.addPrefixToCtx(entry.key, entry.value.uriRef!);
    }

    // Add ratings
    for (final entry in ratings.entries) {
      final movieId = entry.key;
      final rating = entry.value;
      final ratingUri = TurtleNamespaces.moviestarDataNS.withAttr('rating_$movieId');

      graph.addTripleToGroups(ratingUri, TurtleNamespaces.rdfType, TurtleNamespaces.ratingType);
      graph.addTripleToGroups(
        ratingUri,
        TurtleNamespaces.movieId,
        Literal(movieId, datatype: TurtleNamespaces.xsdNS.withAttr('string')),
      );
      graph.addTripleToGroups(
        ratingUri,
        TurtleNamespaces.value,
        Literal(rating.toString(), datatype: TurtleNamespaces.xsdNS.withAttr('decimal')),
      );
    }

    graph.serialize(format: 'turtle');
    return graph.serializedString;
  }

  /// Converts movie comments to Turtle format
  static String commentsToTurtle(Map<String, String> comments) {
    final graph = Graph();
    final namespaces = TurtleNamespaces.getOntologyNamespaces();

    // Add namespaces
    for (final entry in namespaces.entries) {
      graph.addPrefixToCtx(entry.key, entry.value.uriRef!);
    }

    // Add comments
    for (final entry in comments.entries) {
      final movieId = entry.key;
      final comment = entry.value;
      final commentUri = TurtleNamespaces.moviestarDataNS.withAttr('comment_$movieId');

      graph.addTripleToGroups(commentUri, TurtleNamespaces.rdfType, TurtleNamespaces.commentType);
      graph.addTripleToGroups(
        commentUri,
        TurtleNamespaces.movieId,
        Literal(movieId, datatype: TurtleNamespaces.xsdNS.withAttr('string')),
      );
      graph.addTripleToGroups(
        commentUri,
        TurtleNamespaces.text,
        Literal(TurtleUtils.escapeString(comment), datatype: TurtleNamespaces.xsdNS.withAttr('string')),
      );
    }

    graph.serialize(format: 'turtle');
    return graph.serializedString;
  }

  /// Extracts ratings from Turtle content
  static Map<String, double> ratingsFromTurtle(String ttlContent) {
    try {
      final graph = Graph();
      graph.parseTurtle(ttlContent);

      final ratings = <String, double>{};
      final ratingUris = graph.subjects(
        pre: TurtleNamespaces.rdfType,
        obj: TurtleNamespaces.ratingType,
      );

      for (final ratingUri in ratingUris) {
        final movieIdTriples = graph.objects(
          sub: ratingUri,
          pre: TurtleNamespaces.movieId,
        );
        final valueTriples = graph.objects(
          sub: ratingUri,
          pre: TurtleNamespaces.value,
        );

        if (movieIdTriples.isNotEmpty && valueTriples.isNotEmpty) {
          final movieId = movieIdTriples.first.toString().replaceAll('"', '');
          final ratingValue = double.tryParse(
            valueTriples.first.toString().replaceAll('"', ''),
          );

          if (ratingValue != null) {
            ratings[movieId] = ratingValue;
          }
        }
      }

      return ratings;
    } catch (e) {
      debugPrint('Error parsing ratings from Turtle: $e');
      return {};
    }
  }

  /// Extracts comments from Turtle content
  static Map<String, String> commentsFromTurtle(String ttlContent) {
    try {
      final graph = Graph();
      graph.parseTurtle(ttlContent);

      final comments = <String, String>{};
      final commentUris = graph.subjects(
        pre: TurtleNamespaces.rdfType,
        obj: TurtleNamespaces.commentType,
      );

      for (final commentUri in commentUris) {
        final movieIdTriples = graph.objects(
          sub: commentUri,
          pre: TurtleNamespaces.movieId,
        );
        final textTriples = graph.objects(
          sub: commentUri,
          pre: TurtleNamespaces.text,
        );

        if (movieIdTriples.isNotEmpty && textTriples.isNotEmpty) {
          final movieId = movieIdTriples.first.toString().replaceAll('"', '');
          final commentText = textTriples.first.toString().replaceAll('"', '');

          comments[movieId] = commentText;
        }
      }

      return comments;
    } catch (e) {
      debugPrint('Error parsing comments from Turtle: $e');
      return {};
    }
  }

  /// Converts ratings to Turtle with JSON embedding
  static String ratingsToTurtleWithJson(Map<String, double> ratings) {
    final graph = Graph();
    final namespaces = TurtleNamespaces.getOntologyNamespaces();

    // Add namespaces
    for (final entry in namespaces.entries) {
      graph.addPrefixToCtx(entry.key, entry.value.uriRef!);
    }

    // Convert ratings to JSON and embed
    final ratingsJson = ratings.map((k, v) => MapEntry(k, v));
    final ratingsUri = TurtleNamespaces.moviestarDataNS.withAttr('ratings');

    graph.addTripleToGroups(
      ratingsUri,
      TurtleNamespaces.keyValue,
      Literal(ratingsJson.toString(), datatype: TurtleNamespaces.xsdNS.withAttr('string')),
    );

    graph.serialize(format: 'turtle');
    return graph.serializedString;
  }

  /// Converts comments to Turtle with JSON embedding
  static String commentsToTurtleWithJson(Map<String, String> comments) {
    final graph = Graph();
    final namespaces = TurtleNamespaces.getOntologyNamespaces();

    // Add namespaces
    for (final entry in namespaces.entries) {
      graph.addPrefixToCtx(entry.key, entry.value.uriRef!);
    }

    // Convert comments to JSON and embed
    final commentsUri = TurtleNamespaces.moviestarDataNS.withAttr('comments');

    graph.addTripleToGroups(
      commentsUri,
      TurtleNamespaces.keyValue,
      Literal(comments.toString(), datatype: TurtleNamespaces.xsdNS.withAttr('string')),
    );

    graph.serialize(format: 'turtle');
    return graph.serializedString;
  }
}