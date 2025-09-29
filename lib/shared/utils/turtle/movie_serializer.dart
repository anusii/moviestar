/// Movie-specific Turtle serialization functionality.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'dart:convert';

import 'package:rdflib/rdflib.dart';
import 'package:solidpod/solidpod.dart' show tripleMapToTurtle;

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/shared/utils/turtle/base_serializer.dart';
import 'package:moviestar/shared/utils/turtle/namespace_manager.dart';
import 'package:moviestar/shared/utils/turtle/parsing_utils.dart';

/// Handles Movie ↔ Turtle serialization operations.

class MovieTurtleSerializer extends TurtleBaseSerializer {
  /// Converts a list of movies to TTL format using proper RDF triples.

  static String moviesToTurtle(List<Movie> movies, String listName) {
    final triples = <URIRef, Map<URIRef, dynamic>>{};

    // Create the list resource.

    final listResource = TurtleNamespaceManager.localNS.withAttr(listName);
    triples[listResource] = {
      TurtleNamespaceManager.rdfType: TurtleNamespaceManager.movieListType,
      TurtleNamespaceManager.nameProperty:
          Literal(TurtleBaseSerializer.escapeString(listName)),
    };

    // Add movie references to the list only if there are movies.

    if (movies.isNotEmpty) {
      final movieList = movies
          .map((m) => TurtleNamespaceManager.localNS.withAttr('movie${m.id}'))
          .toList();
      triples[listResource]![TurtleNamespaceManager.moviesProperty] = movieList;

      // Add individual movie definitions.

      for (final movie in movies) {
        final movieResource =
            TurtleNamespaceManager.localNS.withAttr('movie${movie.id}');
        final contentType = movie.contentType == ContentType.tvShow
            ? TurtleNamespaceManager.tvShowType
            : TurtleNamespaceManager.movieType;
        triples[movieResource] = {
          TurtleNamespaceManager.rdfType: contentType,
          TurtleNamespaceManager.identifier:
              Literal('${movie.id}', datatype: XSD.int),
          TurtleNamespaceManager.name:
              Literal(TurtleBaseSerializer.escapeString(movie.title)),
          TurtleNamespaceManager.description:
              Literal(TurtleBaseSerializer.escapeString(movie.overview)),
          TurtleNamespaceManager.image:
              Literal(TurtleBaseSerializer.escapeString(movie.posterUrl)),
          TurtleNamespaceManager.thumbnailUrl:
              Literal(TurtleBaseSerializer.escapeString(movie.backdropUrl)),
          TurtleNamespaceManager.aggregateRating: Literal(
            '${movie.voteAverage}',
            datatype: XSD.double,
          ),
          TurtleNamespaceManager.datePublished: Literal(
            movie.releaseDate.toIso8601String(),
            datatype: XSD.dateTime,
          ),
          TurtleNamespaceManager.genre: Literal(movie.genreIds.join(',')),
        };
      }
    }

    return tripleMapToTurtle(
      triples,
      bindNamespaces: TurtleNamespaceManager.getBasicNamespaces(),
    );
  }

  /// Converts a single movie with user's personal rating and comment to TTL format.

  static String movieWithUserDataToTurtle(
    Movie movie,
    double? rating,
    String? comment,
  ) {
    final triples = <URIRef, Map<URIRef, dynamic>>{};

    // Create the movie resource with all movie metadata.

    final movieResource =
        TurtleNamespaceManager.localNS.withAttr('movie${movie.id}');
    triples[movieResource] = {
      TurtleNamespaceManager.rdfType: TurtleNamespaceManager.movieType,
      TurtleNamespaceManager.identifier:
          Literal('${movie.id}', datatype: XSD.int),
      TurtleNamespaceManager.name:
          Literal(TurtleBaseSerializer.escapeString(movie.title)),
      TurtleNamespaceManager.description:
          Literal(TurtleBaseSerializer.escapeString(movie.overview)),
      TurtleNamespaceManager.image:
          Literal(TurtleBaseSerializer.escapeString(movie.posterUrl)),
      TurtleNamespaceManager.thumbnailUrl:
          Literal(TurtleBaseSerializer.escapeString(movie.backdropUrl)),
      TurtleNamespaceManager.aggregateRating:
          Literal('${movie.voteAverage}', datatype: XSD.double),
      TurtleNamespaceManager.datePublished: Literal(
        movie.releaseDate.toIso8601String(),
        datatype: XSD.dateTime,
      ),
      TurtleNamespaceManager.genre: Literal(movie.genreIds.join(',')),
    };

    // Add user's personal rating if it exists.

    if (rating != null) {
      final userRatingResource =
          TurtleNamespaceManager.localNS.withAttr('userRating${movie.id}');
      triples[userRatingResource] = {
        TurtleNamespaceManager.rdfType: TurtleNamespaceManager.ratingType,
        TurtleNamespaceManager.movieId:
            Literal('${movie.id}', datatype: XSD.int),
        TurtleNamespaceManager.value: Literal('$rating', datatype: XSD.double),
      };

      // Link the movie to the user rating.

      triples[movieResource]![TurtleNamespaceManager.localNS
          .withAttr('hasUserRating')] = userRatingResource;
    }

    // Add user's personal comment if it exists.

    if (comment != null && comment.isNotEmpty) {
      final userCommentResource =
          TurtleNamespaceManager.localNS.withAttr('userComment${movie.id}');
      triples[userCommentResource] = {
        TurtleNamespaceManager.rdfType: TurtleNamespaceManager.commentType,
        TurtleNamespaceManager.movieId:
            Literal('${movie.id}', datatype: XSD.int),
        TurtleNamespaceManager.text:
            Literal(TurtleBaseSerializer.escapeString(comment)),
      };

      // Link the movie to the user comment.

      triples[movieResource]![TurtleNamespaceManager.localNS
          .withAttr('hasUserComment')] = userCommentResource;
    }

    // Add JSON backup for compatibility.

    final movieJson = jsonEncode(movie.toJson());
    final userDataJson = jsonEncode({'rating': rating, 'comment': comment});

    final ttlContent = tripleMapToTurtle(
      triples,
      bindNamespaces: TurtleNamespaceManager.getBasicNamespaces(),
    );
    final withJsonBackup =
        '$ttlContent\n\n# JSON_MOVIE_DATA: $movieJson\n# JSON_USER_DATA: $userDataJson';

    return withJsonBackup;
  }

  /// Movie with user data using ontology structure.

  static String movieWithUserDataToTurtleOntology(
    Movie movie,
    double? rating,
    String? comment,
  ) {
    final triples = <URIRef, Map<URIRef, dynamic>>{};

    // Create the movie resource with all movie metadata.

    final movieResource =
        TurtleNamespaceManager.moviestarDataNS.withAttr('movie-${movie.id}');
    triples[movieResource] = {
      TurtleNamespaceManager.rdfType: [
        TurtleNamespaceManager.owlNS.withAttr('NamedIndividual'),
        movie.contentType == ContentType.tvShow
            ? TurtleNamespaceManager.tvShowType
            : TurtleNamespaceManager.movieType,
      ],
      TurtleNamespaceManager.identifier: Literal(
        '${movie.id}',
        datatype: TurtleNamespaceManager.xsdNS.withAttr('positiveInteger'),
      ),
      TurtleNamespaceManager.name:
          Literal(TurtleBaseSerializer.escapeAndSanitizeString(movie.title)),
      TurtleNamespaceManager.description:
          Literal(TurtleBaseSerializer.escapeAndSanitizeString(movie.overview)),
      TurtleNamespaceManager.image: Literal(
        TurtleBaseSerializer.escapeAndSanitizeString(movie.posterUrl),
        datatype: TurtleNamespaceManager.xsdNS.withAttr('anyURI'),
      ),
      TurtleNamespaceManager.thumbnailUrl: Literal(
        TurtleBaseSerializer.escapeAndSanitizeString(movie.backdropUrl),
        datatype: TurtleNamespaceManager.xsdNS.withAttr('anyURI'),
      ),
      TurtleNamespaceManager.aggregateRating: Literal(
        '${movie.voteAverage}',
        datatype: TurtleNamespaceManager.xsdNS.withAttr('double'),
      ),
      TurtleNamespaceManager.datePublished: Literal(
        movie.releaseDate.toIso8601String(),
        datatype: TurtleNamespaceManager.xsdNS.withAttr('date'),
      ),
      TurtleNamespaceManager.genre: Literal(movie.genreIds.join(',')),
      TurtleNamespaceManager.rdfsLabel: Literal(
        '|name=${TurtleBaseSerializer.escapeAndSanitizeString(movie.title)}|',
      ),
    };

    // Add user's personal rating if it exists.

    if (rating != null) {
      triples[movieResource]![TurtleNamespaceManager.contentRating] = Literal(
        '$rating',
        datatype: TurtleNamespaceManager.xsdNS.withAttr('double'),
      );
    }

    // Add user's personal comment if it exists.

    if (comment != null && comment.isNotEmpty) {
      triples[movieResource]![TurtleNamespaceManager.comment] = Literal(
        TurtleBaseSerializer.escapeAndSanitizeString(comment),
      );
    }

    // Add JSON backup for compatibility.

    final movieJson = jsonEncode(movie.toJson());
    final userDataJson = jsonEncode({'rating': rating, 'comment': comment});

    final ttlContent = tripleMapToTurtle(
      triples,
      bindNamespaces: TurtleNamespaceManager.getOntologyNamespaces(),
    );
    final withJsonBackup =
        '$ttlContent\n\n# JSON_MOVIE_DATA: $movieJson\n# JSON_USER_DATA: $userDataJson';

    return withJsonBackup;
  }

  /// Enhanced serialization with JSON backup for compatibility.

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

  /// Parses movies from TTL content using proper RDF parsing.

  static List<Movie> moviesFromTurtle(String ttlContent) {
    try {
      // First try to parse from JSON backup for backward compatibility.

      final jsonMovies = TurtleParsingUtils.tryParseMovieJsonBackup(ttlContent);
      if (jsonMovies != null) {
        return jsonMovies;
      }

      // Parse using proper RDF if no JSON backup.

      final triples = TurtleParsingUtils.safeParseTtl(ttlContent);
      if (triples == null) return [];

      final movies = <Movie>[];

      // Find movie resources (subjects that have movie:Movie type).

      for (final subject in triples.keys) {
        final predicates = triples[subject]!;

        // Check if this is a movie or TV show resource.

        final isMovie = TurtleParsingUtils.hasRdfType(predicates, [
          'Movie',
          'TVShow',
          'http://schema.org/Movie',
          'http://schema.org/TVSeries',
          '#Movie',
          '#TVShow',
        ]);

        if (isMovie) {
          final movie = TurtleParsingUtils.extractMovieFromTriples(predicates);
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

  /// Parses a single movie with user data from TTL content.

  static Map<String, dynamic>? movieWithUserDataFromTurtle(String ttlContent) {
    try {
      // First try to parse from JSON backup for compatibility.

      final userData =
          TurtleParsingUtils.tryParseUserDataJsonBackup(ttlContent);
      if (userData != null) {
        return userData;
      }

      // Parse using proper RDF if no JSON backup.

      final triples = TurtleParsingUtils.safeParseTtl(ttlContent);
      if (triples == null) return null;

      Movie? movie;
      double? rating;
      String? comment;

      // Find movie, rating, and comment resources.

      for (final subject in triples.keys) {
        final predicates = triples[subject]!;

        // Check for movie or TV show.

        final isMovie = TurtleParsingUtils.hasRdfType(predicates, [
          'Movie',
          'TVShow',
          'http://schema.org/Movie',
          'http://schema.org/TVSeries',
          '#Movie',
          '#TVShow',
        ]);

        if (isMovie && movie == null) {
          movie = TurtleParsingUtils.extractMovieFromTriples(predicates);

          // Also check for rating and comment in the same movie resource (new ontology format).

          rating ??= double.tryParse(
            TurtleParsingUtils.extractFirstValue(
              predicates,
              ['contentRating', 'http://schema.org/contentRating'],
            ),
          );

          if (comment == null) {
            final commentValue = TurtleParsingUtils.extractFirstValue(
              predicates,
              ['comment', 'http://schema.org/comment'],
            );
            if (commentValue.isNotEmpty) {
              comment = commentValue;
            }
          }
        }

        // Check for rating (old format compatibility).

        final isRating = TurtleParsingUtils.hasRdfType(
          predicates,
          ['Rating', '#Rating'],
        );

        if (isRating && rating == null) {
          rating = double.tryParse(
            TurtleParsingUtils.extractFirstValue(predicates, ['#value']),
          );
        }

        // Check for comment (old format compatibility).

        final isComment = TurtleParsingUtils.hasRdfType(
          predicates,
          ['Comment', '#Comment'],
        );

        if (isComment && comment == null) {
          final commentValue =
              TurtleParsingUtils.extractFirstValue(predicates, ['#text']);
          if (commentValue.isNotEmpty) {
            comment = commentValue;
          }
        }
      }

      if (movie != null) {
        return {'movie': movie, 'rating': rating, 'comment': comment};
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
