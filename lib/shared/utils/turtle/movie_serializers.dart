/// Movie and List Serialization for Turtle format
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

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/utils/turtle_serializer.dart';

/// Utility class for serializing/deserializing movies and movie lists to/from Turtle format.
class MovieSerializers {
  /// Converts a list of movies to TTL format using proper RDF triples.
  static String moviesToTurtle(List<Movie> movies, String listName) {
    final triples = <URIRef, Map<URIRef, dynamic>>{};

    // Create the list resource.
    final listResource = TurtleSerializer.localNS.withAttr(listName);
    triples[listResource] = {
      TurtleSerializer.rdfType: TurtleSerializer.movieListType,
      TurtleSerializer.nameProperty:
          Literal(TurtleSerializer.escapeString(listName)),
    };

    // Add movie references to the list only if there are movies.
    if (movies.isNotEmpty) {
      final movieList = movies
          .map((m) => TurtleSerializer.localNS.withAttr('movie${m.id}'))
          .toList();
      triples[listResource]![TurtleSerializer.moviesProperty] = movieList;

      // Add individual movie definitions.
      for (final movie in movies) {
        final movieResource =
            TurtleSerializer.localNS.withAttr('movie${movie.id}');
        final contentType = movie.contentType == ContentType.tvShow
            ? TurtleSerializer.tvShowType
            : TurtleSerializer.movieType;
        triples[movieResource] = {
          TurtleSerializer.rdfType: contentType,
          TurtleSerializer.identifier:
              Literal('${movie.id}', datatype: XSD.int),
          TurtleSerializer.name:
              Literal(TurtleSerializer.escapeString(movie.title)),
          TurtleSerializer.description:
              Literal(TurtleSerializer.escapeString(movie.overview)),
          TurtleSerializer.image:
              Literal(TurtleSerializer.escapeString(movie.posterUrl)),
          TurtleSerializer.thumbnailUrl:
              Literal(TurtleSerializer.escapeString(movie.backdropUrl)),
          TurtleSerializer.aggregateRating: Literal(
            '${movie.voteAverage}',
            datatype: XSD.double,
          ),
          TurtleSerializer.datePublished: Literal(
            movie.releaseDate.toIso8601String(),
            datatype: XSD.dateTime,
          ),
          TurtleSerializer.genre: Literal(movie.genreIds.join(',')),
        };
      }
    }

    // Define namespace bindings - only bind our custom namespaces.
    final bindNamespaces = {
      '': TurtleSerializer.localNS,
      'schema': TurtleSerializer.movieNS,
    };

    return tripleMapToTurtle(triples, bindNamespaces: bindNamespaces);
  }

  /// Parses movies from TTL content using proper RDF parsing.
  static List<Movie> moviesFromTurtle(String ttlContent) {
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

      // Parse using proper RDF if no JSON backup.
      final triples = turtleToTripleMap(ttlContent);
      final movies = <Movie>[];

      // Find movie resources (subjects that have movie:Movie type).
      for (final subject in triples.keys) {
        final predicates = triples[subject]!;

        // Check if this is a movie or TV show resource - look for various type URIs.
        final typeValues =
            predicates['http://www.w3.org/1999/02/22-rdf-syntax-ns#type'] ?? [];

        final isMovie = typeValues.any(
          (type) =>
              type.toString().contains('Movie') ||
              type.toString().contains('TVShow') ||
              type == 'http://schema.org/Movie' ||
              type == 'http://schema.org/TVShow' ||
              type == '#Movie' ||
              type == '#TVShow',
        );

        if (isMovie) {
          // Extract movie data from predicates.
          final movie = _extractMovieFromTriples(predicates);
          if (movie != null) {
            movies.add(movie);
          }
        }
      }

      return movies;
    } catch (e) {
      // Fallback to empty list if parsing fails.
      return [];
    }
  }

  /// Extracts a Movie from RDF triple predicates.
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

      // Determine content type from RDF type in predicates
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

  /// Enhanced movies serialization with JSON backup.
  static String moviesToTurtleWithJson(List<Movie> movies, String listName) {
    final buffer = StringBuffer();

    // Add the proper TTL structure.
    buffer.writeln(moviesToTurtle(movies, listName));

    // Add JSON backup as comment for easy parsing and backward compatibility.
    buffer.writeln();
    buffer.writeln(
      '# JSON_DATA: ${jsonEncode(movies.map((m) => m.toJson()).toList())}',
    );

    return buffer.toString();
  }

  /// Creates a movie list in TTL format following the ontology structure.
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
    final movieListResource = TurtleSerializer.moviestarDataNS.withAttr(
      'MovieList-$movieListId',
    );
    triples[movieListResource] = {
      TurtleSerializer.rdfType: [
        TurtleSerializer.owlNS.withAttr('NamedIndividual'),
        TurtleSerializer.movieListType,
      ],
      TurtleSerializer.identifier: Literal(movieListId),
      TurtleSerializer.name:
          Literal(TurtleSerializer.escapeAndSanitizeString(listName)),
      TurtleSerializer.description: Literal(
        TurtleSerializer.escapeAndSanitizeString(
            description ?? 'List of movies: $listName',),
      ),
      TurtleSerializer.rdfsLabel: Literal(
        '|filePath=moviestar/data/MovieList-$movieListId.ttl|',
      ),
    };

    // Add sharing metadata if provided.
    if (sharedWith != null && sharedWith.isNotEmpty) {
      // Add shared_with as a list of WebIds.
      final sharedWithWebIds =
          sharedWith.keys.map((webId) => Literal(webId)).toList();
      triples[movieListResource]![TurtleSerializer.moviestarOntoNS
          .withAttr('sharedWith')] = sharedWithWebIds;

      // Add permissions as JSON string for flexibility.
      final permissionsJson = jsonEncode(sharedWith);
      triples[movieListResource]![TurtleSerializer.moviestarOntoNS.withAttr(
        'permissions',
      )] = Literal(permissionsJson);
    }

    // Add shared date if provided.
    if (sharedDate != null) {
      triples[movieListResource]![TurtleSerializer.moviestarOntoNS.withAttr(
        'sharedDate',
      )] = Literal(
        sharedDate.toIso8601String(),
        datatype: TurtleSerializer.xsdNS.withAttr('dateTime'),
      );
    }

    // Add movie references (not full movie data) if provided.
    if (movies.isNotEmpty) {
      final movieRefs = movies
          .map((movie) =>
              TurtleSerializer.moviestarDataNS.withAttr('movie-${movie.id}'),)
          .toList();
      triples[movieListResource]![TurtleSerializer.hasMovie] = movieRefs;

      // Add individual movie reference definitions (not full data).
      // According to ontology, MovieList only contains references with filePath.
      for (final movie in movies) {
        final movieResource =
            TurtleSerializer.moviestarDataNS.withAttr('movie-${movie.id}');
        // Use content-type aware file naming
        final contentPrefix =
            movie.contentType == ContentType.tvShow ? 'TVShow' : 'Movie';
        final filePathStr =
            'moviestar/data/movies/$contentPrefix-${movie.id}.ttl';
        final contentType = movie.contentType == ContentType.tvShow
            ? TurtleSerializer.tvShowType
            : TurtleSerializer.movieType;
        triples[movieResource] = {
          TurtleSerializer.rdfType: [
            TurtleSerializer.owlNS.withAttr('NamedIndividual'),
            contentType,
          ],
          TurtleSerializer.filePath: Literal(filePathStr),
          TurtleSerializer.rdfsLabel: Literal(
            '|filePath=$filePathStr|',
          ),
        };
      }
    }

    // Use ontology-compliant namespace bindings.
    return tripleMapToTurtle(triples,
        bindNamespaces: TurtleSerializer.getOntologyNamespaces(),);
  }

  /// Parses movie list from TTL content.
  /// Returns a map containing movieList metadata and movies list.
  static Map<String, dynamic>? movieListFromTurtle(String ttlContent) {
    try {
      // Parse using proper RDF.
      final triples = turtleToTripleMap(ttlContent);

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
        final typeValues =
            predicates['http://www.w3.org/1999/02/22-rdf-syntax-ns#type'] ?? [];

        // Check for MovieList.
        final isMovieList = typeValues.any(
          (type) =>
              type.toString().contains('MovieList') ||
              type == 'https://sii.anu.edu.au/onto/moviestar#MovieList',
        );

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
                // This will be populated with permissions from the permissions field.
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
                  // Extract movie ID from resource URI like "movie-12345" (lowercase).
                  final movieIdMatch = RegExp(
                    r'movie-(\d+)',
                  ).firstMatch(movieRefStr);
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
            // Determine content type from RDF type
            final isTvShow = typeValues.any(
              (type) =>
                  type.toString().contains('TVShow') ||
                  type == 'http://schema.org/TVShow',
            );
            movieContentTypes[movieId] =
                isTvShow ? ContentType.tvShow : ContentType.movie;
          }
        }
      }

      if (listId == null && listName == null) {
        return null;
      }

      return {
        'listId': listId,
        'listName': listName ?? 'Untitled List',
        'description': description,
        'filePath': filePath,
        'sharedWith': sharedWith ?? {},
        'sharedDate': sharedDate,
        'movieIds': movieResourceIds.toList(),
        'movieContentTypes': movieContentTypes,
      };
    } catch (e) {
      debugPrint('Error parsing MovieList TTL: $e');
      return null;
    }
  }
}
