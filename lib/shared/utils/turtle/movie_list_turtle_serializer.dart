/// Movie list-specific Turtle serialization functionality.
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
import 'package:solidpod/solidpod.dart' show tripleMapToTurtle;

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/shared/utils/turtle/turtle_base_serializer.dart';
import 'package:moviestar/shared/utils/turtle/turtle_namespace_manager.dart';
import 'package:moviestar/shared/utils/turtle/turtle_parsing_utils.dart';

/// Handles MovieList ↔ Turtle serialization operations.
class MovieListTurtleSerializer extends TurtleBaseSerializer {
  /// Creates a MovieList in TTL format following the ontology structure.
  static String createMovieList(
    String movieListId,
    String listName, {
    List<Movie> movies = const [],
    String? description,
    Map<String, String>? sharedWith, // Map of WebId -> permissions
    DateTime? sharedDate,
  }) {
    final triples = <URIRef, Map<URIRef, dynamic>>{};

    // Create the MovieList resource.
    final movieListResource = TurtleNamespaceManager.moviestarDataNS
        .withAttr('MovieList-$movieListId');
    triples[movieListResource] = {
      TurtleNamespaceManager.rdfType: [
        TurtleNamespaceManager.owlNS.withAttr('NamedIndividual'),
        TurtleNamespaceManager.movieListType,
      ],
      TurtleNamespaceManager.identifier: Literal(movieListId),
      TurtleNamespaceManager.name:
          Literal(TurtleBaseSerializer.escapeAndSanitizeString(listName)),
      TurtleNamespaceManager.description: Literal(
        TurtleBaseSerializer.escapeAndSanitizeString(description ?? 'List of movies: $listName'),
      ),
      TurtleNamespaceManager.rdfsLabel: Literal(
        '|filePath=moviestar/data/MovieList-$movieListId.ttl|',
      ),
    };

    // Add sharing metadata if provided.
    if (sharedWith != null && sharedWith.isNotEmpty) {
      // Add shared_with as a list of WebIds.
      final sharedWithWebIds =
          sharedWith.keys.map((webId) => Literal(webId)).toList();
      triples[movieListResource]![
              TurtleNamespaceManager.moviestarOntoNS.withAttr('sharedWith')] =
          sharedWithWebIds;

      // Add permissions as JSON string for flexibility.
      final permissionsJson = jsonEncode(sharedWith);
      triples[movieListResource]![TurtleNamespaceManager.moviestarOntoNS
          .withAttr('permissions')] = Literal(permissionsJson);
    }

    // Add shared date if provided.
    if (sharedDate != null) {
      triples[movieListResource]![TurtleNamespaceManager.moviestarOntoNS
          .withAttr('sharedDate')] = Literal(
        sharedDate.toIso8601String(),
        datatype: TurtleNamespaceManager.xsdNS.withAttr('dateTime'),
      );
    }

    // Add movie references (not full movie data) if provided.
    if (movies.isNotEmpty) {
      final movieRefs = movies
          .map((movie) => TurtleNamespaceManager.moviestarDataNS
              .withAttr('movie-${movie.id}'))
          .toList();
      triples[movieListResource]![TurtleNamespaceManager.hasMovie] = movieRefs;

      // Add individual movie reference definitions (not full data).
      for (final movie in movies) {
        final movieResource = TurtleNamespaceManager.moviestarDataNS
            .withAttr('movie-${movie.id}');
        // Use content-type aware file naming
        final contentPrefix =
            movie.contentType == ContentType.tvShow ? 'TVShow' : 'Movie';
        final filePathStr =
            'moviestar/data/movies/$contentPrefix-${movie.id}.ttl';
        final contentType = movie.contentType == ContentType.tvShow
            ? TurtleNamespaceManager.tvShowType
            : TurtleNamespaceManager.movieType;
        triples[movieResource] = {
          TurtleNamespaceManager.rdfType: [
            TurtleNamespaceManager.owlNS.withAttr('NamedIndividual'),
            contentType,
          ],
          TurtleNamespaceManager.filePath: Literal(filePathStr),
          TurtleNamespaceManager.rdfsLabel: Literal('|filePath=$filePathStr|'),
        };
      }
    }

    return tripleMapToTurtle(
      triples,
      bindNamespaces: TurtleNamespaceManager.getOntologyNamespaces(),
    );
  }

  /// Parses a MovieList from TTL content and extracts movies.
  static Map<String, dynamic>? movieListFromTurtle(String ttlContent) {
    try {
      // Parse using proper RDF.
      final triples = TurtleParsingUtils.safeParseTtl(ttlContent);
      if (triples == null) return null;

      String? listId;
      String? listName;
      String? description;
      String? filePath;
      Map<String, String>? sharedWith;
      DateTime? sharedDate;
      final Set<String> movieResourceIds = {};
      final Map<String, ContentType> movieContentTypes = {};

      // Find MovieList resource and extract movie references.
      for (final subject in triples.keys) {
        final predicates = triples[subject]!;

        // Check for MovieList.
        final isMovieList = TurtleParsingUtils.hasRdfType(predicates, [
          'MovieList',
          'https://sii.anu.edu.au/onto/moviestar#MovieList',
        ]);

        if (isMovieList) {
          // Extract MovieList metadata.
          for (final predicate in predicates.keys) {
            final values = predicates[predicate]!;
            if (values.isNotEmpty) {
              final value = values.first.toString();

              if (predicate.contains('identifier')) {
                listId = value;
              } else if (predicate.contains('name')) {
                listName = value;
              } else if (predicate.contains('description')) {
                description = value;
              } else if (predicate.contains('filePath')) {
                filePath = value;
              } else if (predicate.contains('sharedWith')) {
                // Extract shared WebIds.
                final webIds = <String>[];
                for (final webIdRef in values) {
                  webIds.add(webIdRef.toString());
                }
                sharedWith = {for (final webId in webIds) webId: 'read'};
              } else if (predicate.contains('permissions')) {
                // Parse permissions JSON.
                try {
                  final permissionsMap =
                      jsonDecode(value) as Map<String, dynamic>;
                  sharedWith = permissionsMap.map(
                    (key, value) => MapEntry(key, value.toString()),
                  );
                } catch (e) {
                  debugPrint('⚠️ Failed to parse permissions JSON: $e');
                }
              } else if (predicate.contains('sharedDate')) {
                // Parse shared date.
                try {
                  sharedDate = DateTime.parse(value);
                } catch (e) {
                  debugPrint('⚠️ Failed to parse shared date: $e');
                }
              } else if (predicate.contains('hasMovie')) {
                // Extract movie resource references.
                for (final movieRef in values) {
                  final movieRefStr = movieRef.toString();
                  // Extract movie ID from resource URI like "movie-12345".
                  final movieIdMatch =
                      RegExp(r'movie-(\d+)').firstMatch(movieRefStr);
                  if (movieIdMatch != null) {
                    movieResourceIds.add(movieIdMatch.group(1)!);
                  }
                }
              }
            }
          }
        }
        // Check for individual movie resources and their content types
        else {
          final movieIdMatch =
              RegExp(r'movie-(\d+)').firstMatch(subject.toString());
          if (movieIdMatch != null) {
            final movieId = movieIdMatch.group(1)!;
            final isTvShow = TurtleParsingUtils.hasRdfType(predicates, [
              'TVShow',
              'http://schema.org/TVShow',
              '#TVShow',
            ]);
            movieContentTypes[movieId] =
                isTvShow ? ContentType.tvShow : ContentType.movie;
          }
        }
      }

      // Create placeholder Movie objects from the movie references.
      final List<Movie> movies = [];
      for (final movieId in movieResourceIds) {
        try {
          // Create a minimal Movie object with just the ID.
          final movie = Movie(
            id: int.parse(movieId),
            title: 'Loading...', // Use a loading indicator
            overview: '',
            posterUrl: '', // Empty poster URL will trigger loading in UI
            backdropUrl: '',
            releaseDate: DateTime.now(),
            voteAverage: 0.0,
            genreIds: [],
            contentType: movieContentTypes[movieId] ?? ContentType.movie,
          );
          movies.add(movie);
        } catch (e) {
          debugPrint('❌ Failed to parse movie ID $movieId: $e');
        }
      }

      return {
        'id': listId,
        'name': listName ?? 'Unknown List',
        'description': description,
        'filePath': filePath,
        'movies': movies,
        'sharedWith': sharedWith,
        'sharedDate': sharedDate,
      };
    } catch (e) {
      debugPrint('❌ Error parsing MovieList from TTL: $e');
      return null;
    }
  }
}