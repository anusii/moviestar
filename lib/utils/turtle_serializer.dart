/// Utility for converting Movie objects to/from Turtle (TTL) format using solidpod RDF functions.
///
// Time-stamp: <Thursday 2025-04-10 11:47:48 +1000 Graham Williams>
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

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:rdflib/rdflib.dart';
import 'package:solidpod/src/solid/utils/rdf.dart'
    show tripleMapToTurtle, turtleToTripleMap;

import 'package:moviestar/models/movie.dart';

/// Utility class for serializing/deserializing movies to/from Turtle format using proper RDF.

class TurtleSerializer {
  // Define namespaces based on the ontology design.

  static final moviestarOntoNS =
      Namespace(ns: 'https://sii.anu.edu.au/onto/moviestar#');
  static final moviestarDataNS =
      Namespace(ns: 'https://sii.anu.edu.au/data/moviestar/');
  static final movieNS = Namespace(ns: 'http://schema.org/');
  static final xsdNS = Namespace(ns: 'http://www.w3.org/2001/XMLSchema#');
  static final rdfsNS = Namespace(ns: 'http://www.w3.org/2000/01/rdf-schema#');
  static final owlNS = Namespace(ns: 'http://www.w3.org/2002/07/owl#');
  static final localNS = Namespace(ns: '#');

  // Define common predicates as URIRefs.

  static final movieType = movieNS.withAttr('Movie');
  static final movieListType = moviestarOntoNS.withAttr('MovieList');
  static final userType = moviestarOntoNS.withAttr('User');
  static final ratingType = localNS.withAttr('Rating');
  static final commentType = localNS.withAttr('Comment');
  static final apiKeyType = moviestarOntoNS.withAttr('ApiKey');

  // User predicates.

  static final hasMovieList = moviestarOntoNS.withAttr('hasMovieList');
  static final hasApiKey = moviestarOntoNS.withAttr('hasApiKey');
  static final dob = moviestarOntoNS.withAttr('DOB');
  static final gender = moviestarOntoNS.withAttr('gender');
  static final webId = moviestarOntoNS.withAttr('webID');

  // MovieList predicates.

  static final hasMovie = moviestarOntoNS.withAttr('hasMovie');
  static final filePath = moviestarOntoNS.withAttr('filePath');

  // Movie predicates (using schema.org/sdo: prefix to match ontology).

  static final identifier = movieNS.withAttr('identifier');
  static final name = movieNS.withAttr('name');
  static final description = movieNS.withAttr('description');
  static final image = movieNS.withAttr('image');
  static final thumbnailUrl = movieNS.withAttr('thumbnailUrl');
  static final aggregateRating = movieNS.withAttr('aggregateRating');
  static final datePublished = movieNS.withAttr('datePublished');
  static final genre = movieNS.withAttr('genre');
  static final contentRating =
      movieNS.withAttr('contentRating'); // Changed to sdo: prefix
  static final comment = movieNS.withAttr('comment'); // Changed to sdo: prefix
  static final keyValue = moviestarOntoNS.withAttr('keyValue');
  static final source = moviestarOntoNS.withAttr('source');

  // List predicates.

  static final nameProperty = localNS.withAttr('name');
  static final moviesProperty = localNS.withAttr('movies');

  // Rating predicates.

  static final movieId = localNS.withAttr('movieId');
  static final value = localNS.withAttr('value');

  // Comment predicates.

  static final text = localNS.withAttr('text');

  // RDF type predicate.

  static final rdfType = URIRef(
    'http://www.w3.org/1999/02/22-rdf-syntax-ns#type',
  );

  // RDFS label predicate.

  static final rdfsLabel = rdfsNS.withAttr('label');

  // Static namespace bindings to match ontology structure exactly.
  // Only define custom namespaces - let the RDF library handle standard prefixes (owl, xsd, rdfs).

  static Map<String, Namespace> _getOntologyNamespaces() {
    return {
      'moviestar-onto': moviestarOntoNS,
      'moviestar-data': moviestarDataNS,
      'sdo': movieNS,
    };
  }

  /// Converts a list of movies to TTL format using proper RDF triples.

  static String moviesToTurtle(List<Movie> movies, String listName) {
    final triples = <URIRef, Map<URIRef, dynamic>>{};

    // Create the list resource.

    final listResource = localNS.withAttr(listName);
    triples[listResource] = {
      rdfType: movieListType,
      nameProperty: Literal(_escapeString(listName)),
    };

    // Add movie references to the list only if there are movies.

    if (movies.isNotEmpty) {
      final movieList =
          movies.map((m) => localNS.withAttr('movie${m.id}')).toList();
      triples[listResource]![moviesProperty] = movieList;

      // Add individual movie definitions.

      for (final movie in movies) {
        final movieResource = localNS.withAttr('movie${movie.id}');
        triples[movieResource] = {
          rdfType: movieType,
          identifier: Literal('${movie.id}', datatype: XSD.int),
          name: Literal(_escapeString(movie.title)),
          description: Literal(_escapeString(movie.overview)),
          image: Literal(_escapeString(movie.posterUrl)),
          thumbnailUrl: Literal(_escapeString(movie.backdropUrl)),
          aggregateRating: Literal(
            '${movie.voteAverage}',
            datatype: XSD.double,
          ),
          datePublished: Literal(
            movie.releaseDate.toIso8601String(),
            datatype: XSD.dateTime,
          ),
          genre: Literal(movie.genreIds.join(',')),
        };
      }
    }

    // Define namespace bindings - only bind our custom namespaces.

    final bindNamespaces = {'': localNS, 'schema': movieNS};

    return tripleMapToTurtle(triples, bindNamespaces: bindNamespaces);
  }

  /// Converts ratings map to TTL format using proper RDF triples.

  static String ratingsToTurtle(Map<String, double> ratings) {
    final triples = <URIRef, Map<URIRef, dynamic>>{};

    // Create the ratings list resource.

    final ratingsResource = localNS.withAttr('ratings');
    triples[ratingsResource] = {
      rdfType: movieListType,
      nameProperty: Literal('User Ratings'),
    };

    // Add individual rating definitions.

    for (final entry in ratings.entries) {
      final ratingResource = localNS.withAttr('rating${entry.key}');
      triples[ratingResource] = {
        rdfType: ratingType,
        movieId: Literal(entry.key, datatype: XSD.int),
        value: Literal('${entry.value}', datatype: XSD.double),
      };
    }

    // Define namespace bindings - only bind our custom namespaces.

    final bindNamespaces = {'': localNS};

    return tripleMapToTurtle(triples, bindNamespaces: bindNamespaces);
  }

  /// Converts movie comments to TTL format using proper RDF triples.

  static String commentsToTurtle(Map<String, String> comments) {
    final triples = <URIRef, Map<URIRef, dynamic>>{};

    // Create the comments list resource.

    final commentsResource = localNS.withAttr('comments');
    triples[commentsResource] = {
      rdfType: movieListType,
      nameProperty: Literal('User Comments'),
    };

    // Add individual comment definitions.

    for (final entry in comments.entries) {
      final commentResource = localNS.withAttr('comment${entry.key}');
      triples[commentResource] = {
        rdfType: commentType,
        movieId: Literal(entry.key, datatype: XSD.int),
        text: Literal(_escapeString(entry.value)),
      };
    }

    // Define namespace bindings - only bind our custom namespaces.

    final bindNamespaces = {'': localNS};

    return tripleMapToTurtle(triples, bindNamespaces: bindNamespaces);
  }

  /// Converts a single movie with user's personal rating and comment to TTL format.
  /// This creates a unified file containing both movie metadata and user's personal data.

  static String movieWithUserDataToTurtle(
      Movie movie, double? rating, String? comment) {
    final triples = <URIRef, Map<URIRef, dynamic>>{};

    // Create the movie resource with all movie metadata.

    final movieResource = localNS.withAttr('movie${movie.id}');
    triples[movieResource] = {
      rdfType: movieType,
      identifier: Literal('${movie.id}', datatype: XSD.int),
      name: Literal(_escapeString(movie.title)),
      description: Literal(_escapeString(movie.overview)),
      image: Literal(_escapeString(movie.posterUrl)),
      thumbnailUrl: Literal(_escapeString(movie.backdropUrl)),
      aggregateRating: Literal('${movie.voteAverage}', datatype: XSD.double),
      datePublished:
          Literal(movie.releaseDate.toIso8601String(), datatype: XSD.dateTime),
      genre: Literal(movie.genreIds.join(',')),
    };

    // Add user's personal rating if it exists.

    if (rating != null) {
      final userRatingResource = localNS.withAttr('userRating${movie.id}');
      triples[userRatingResource] = {
        rdfType: ratingType,
        movieId: Literal('${movie.id}', datatype: XSD.int),
        value: Literal('$rating', datatype: XSD.double),
      };

      // Link the movie to the user rating.

      triples[movieResource]![localNS.withAttr('hasUserRating')] =
          userRatingResource;
    }

    // Add user's personal comment if it exists.

    if (comment != null && comment.isNotEmpty) {
      final userCommentResource = localNS.withAttr('userComment${movie.id}');
      triples[userCommentResource] = {
        rdfType: commentType,
        movieId: Literal('${movie.id}', datatype: XSD.int),
        text: Literal(_escapeString(comment)),
      };

      // Link the movie to the user comment.

      triples[movieResource]![localNS.withAttr('hasUserComment')] =
          userCommentResource;
    }

    // Define namespace bindings.

    final bindNamespaces = {'': localNS, 'schema': movieNS};

    // Add JSON backup for compatibility.

    final movieJson = jsonEncode(movie.toJson());
    final userDataJson = jsonEncode({
      'rating': rating,
      'comment': comment,
    });

    final ttlContent =
        tripleMapToTurtle(triples, bindNamespaces: bindNamespaces);
    final withJsonBackup =
        '$ttlContent\n\n# JSON_MOVIE_DATA: $movieJson\n# JSON_USER_DATA: $userDataJson';

    return withJsonBackup;
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

      // Parse using proper RDF if no JSON backup.

      final triples = turtleToTripleMap(ttlContent);
      final movies = <Movie>[];

      // Find movie resources (subjects that have movie:Movie type).

      for (final subject in triples.keys) {
        final predicates = triples[subject]!;

        // Check if this is a movie resource - look for various type URIs.

        final typeValues =
            predicates['http://www.w3.org/1999/02/22-rdf-syntax-ns#type'] ?? [];

        final isMovie = typeValues.any(
          (type) =>
              type.toString().contains('Movie') ||
              type == 'http://schema.org/Movie' ||
              type == '#Movie',
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
            final rating = double.tryParse(valueValues.first.toString()) ?? 0.0;
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
            final comment = textValues.first.toString();
            comments[movieId] = comment;
          }
        }
      }

      return comments;
    } catch (e) {
      return {};
    }
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

  /// Extract Movie object from RDF triples.

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

  /// Creates a user profile in TTL format following the ontology structure.

  static String createUserProfile(
    String userWebId, {
    String? apiKey,
    String? dobString,
    String? genderString,
    List<String>? movieListIds,
  }) {
    final triples = <URIRef, Map<URIRef, dynamic>>{};

    // Create the user resource.

    final userResource = URIRef(userWebId);
    triples[userResource] = {
      rdfType: [owlNS.withAttr('NamedIndividual'), userType],
      webId: Literal(userWebId, datatype: xsdNS.withAttr('anyURI')),
      rdfsLabel: Literal('|webID=$userWebId|'),
    };

    // Add API key if provided.

    if (apiKey != null && apiKey.isNotEmpty) {
      triples[userResource]![hasApiKey] =
          moviestarDataNS.withAttr('ApiKey-$apiKey');
    }

    // Add DOB if provided.

    if (dobString != null && dobString.isNotEmpty) {
      triples[userResource]![dob] =
          Literal(dobString, datatype: xsdNS.withAttr('date'));
    }

    // Add gender if provided.

    if (genderString != null && genderString.isNotEmpty) {
      triples[userResource]![gender] = Literal(genderString);
    }

    // Add movie lists if provided.

    if (movieListIds != null && movieListIds.isNotEmpty) {
      final movieListRefs = movieListIds
          .map((id) => moviestarDataNS.withAttr('MovieList-$id'))
          .toList();
      triples[userResource]![hasMovieList] = movieListRefs;
    }

    // Use ontology-compliant namespace bindings.
    return tripleMapToTurtle(triples, bindNamespaces: _getOntologyNamespaces());
  }

  /// Creates a MovieList in TTL format following the ontology structure.

  static String createMovieList(
    String movieListId,
    String listName, {
    List<Movie>? movies,
    String? description,
    Map<String, String>? sharedWith, // Map of WebId -> permissions
    DateTime? sharedDate,
  }) {
    final triples = <URIRef, Map<URIRef, dynamic>>{};

    // Create the MovieList resource.

    final movieListResource =
        moviestarDataNS.withAttr('MovieList-$movieListId');
    triples[movieListResource] = {
      rdfType: [owlNS.withAttr('NamedIndividual'), movieListType],
      TurtleSerializer.identifier: Literal(movieListId),
      TurtleSerializer.name: Literal(_escapeAndSanitizeString(listName)),
      TurtleSerializer.description: Literal(
          _escapeAndSanitizeString(description ?? 'List of movies: $listName')),
      rdfsLabel:
          Literal('|filePath=moviestar/data/MovieList-$movieListId.ttl|'),
    };

    // Add sharing metadata if provided.

    if (sharedWith != null && sharedWith.isNotEmpty) {
      // Add shared_with as a list of WebIds.

      final sharedWithWebIds =
          sharedWith.keys.map((webId) => Literal(webId)).toList();
      triples[movieListResource]![moviestarOntoNS.withAttr('sharedWith')] =
          sharedWithWebIds;

      // Add permissions as JSON string for flexibility.

      final permissionsJson = jsonEncode(sharedWith);
      triples[movieListResource]![moviestarOntoNS.withAttr('permissions')] =
          Literal(permissionsJson);
    }

    // Add shared date if provided.

    if (sharedDate != null) {
      triples[movieListResource]![moviestarOntoNS.withAttr('sharedDate')] =
          Literal(sharedDate.toIso8601String(),
              datatype: xsdNS.withAttr('dateTime'));
    }

    // Add movie references (not full movie data) if provided.

    if (movies != null && movies.isNotEmpty) {
      final movieRefs = movies
          .map((movie) => moviestarDataNS.withAttr('movie-${movie.id}'))
          .toList();
      triples[movieListResource]![hasMovie] = movieRefs;

      // Add individual movie reference definitions (not full data).
      // According to ontology, MovieList only contains references with filePath.

      for (final movie in movies) {
        final movieResource = moviestarDataNS.withAttr('movie-${movie.id}');
        triples[movieResource] = {
          rdfType: [owlNS.withAttr('NamedIndividual'), movieType],
          filePath: Literal('moviestar/data/movies/Movie-${movie.id}.ttl'),
          rdfsLabel:
              Literal('|filePath=moviestar/data/movies/Movie-${movie.id}.ttl|'),
        };
      }
    }

    // Use ontology-compliant namespace bindings.

    return tripleMapToTurtle(triples, bindNamespaces: _getOntologyNamespaces());
  }

  /// Updates a single movie with user's personal rating and comment following the ontology structure.

  static String movieWithUserDataToTurtleOntology(
      Movie movie, double? rating, String? comment) {
    final triples = <URIRef, Map<URIRef, dynamic>>{};

    // Create the movie resource with all movie metadata.

    final movieResource = moviestarDataNS.withAttr('movie-${movie.id}');
    triples[movieResource] = {
      rdfType: [owlNS.withAttr('NamedIndividual'), movieType],
      identifier:
          Literal('${movie.id}', datatype: xsdNS.withAttr('positiveInteger')),
      name: Literal(_escapeAndSanitizeString(movie.title)),
      description: Literal(_escapeAndSanitizeString(movie.overview)),
      image: Literal(_escapeAndSanitizeString(movie.posterUrl),
          datatype: xsdNS.withAttr('anyURI')),
      thumbnailUrl: Literal(_escapeAndSanitizeString(movie.backdropUrl),
          datatype: xsdNS.withAttr('anyURI')),
      aggregateRating:
          Literal('${movie.voteAverage}', datatype: xsdNS.withAttr('double')),
      datePublished: Literal(movie.releaseDate.toIso8601String(),
          datatype: xsdNS.withAttr('date')),
      genre: Literal(movie.genreIds.join(',')),
      rdfsLabel: Literal('|name=${_escapeAndSanitizeString(movie.title)}|'),
    };

    // Add user's personal rating if it exists.

    if (rating != null) {
      triples[movieResource]![contentRating] =
          Literal('$rating', datatype: xsdNS.withAttr('double'));
    }

    // Add user's personal comment if it exists.

    if (comment != null && comment.isNotEmpty) {
      triples[movieResource]![TurtleSerializer.comment] =
          Literal(_escapeAndSanitizeString(comment));
    }

    // Add JSON backup for compatibility.
    final movieJson = jsonEncode(movie.toJson());
    final userDataJson = jsonEncode({
      'rating': rating,
      'comment': comment,
    });

    // Use ontology-compliant namespace bindings.
    final ttlContent =
        tripleMapToTurtle(triples, bindNamespaces: _getOntologyNamespaces());
    final withJsonBackup =
        '$ttlContent\n\n# JSON_MOVIE_DATA: $movieJson\n# JSON_USER_DATA: $userDataJson';

    return withJsonBackup;
  }

  /// Creates an API key file in TTL format following the ontology structure.

  static String createApiKey(
    String apiKeyId,
    String apiKeyValue, {
    String source = 'TMDB',
  }) {
    final triples = <URIRef, Map<URIRef, dynamic>>{};

    // Create the API key resource.

    final apiKeyResource = moviestarDataNS.withAttr('ApiKey-$apiKeyId');
    triples[apiKeyResource] = {
      rdfType: [owlNS.withAttr('NamedIndividual'), apiKeyType],
      identifier: Literal(apiKeyId),
      keyValue: Literal(apiKeyValue),
      TurtleSerializer.source: Literal(source),
      rdfsLabel: Literal('|filePath=moviestar/data/keys/ApiKey-$apiKeyId.ttl|'),
    };

    // Use ontology-compliant namespace bindings.

    return tripleMapToTurtle(triples, bindNamespaces: _getOntologyNamespaces());
  }

  /// Generates a unique ID for resources.

  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (1000 + (DateTime.now().microsecond % 9000)).toString();
  }

  /// Parses a MovieList from TTL content and extracts movies.
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

      // Find MovieList resource and extract movie references.

      for (final subject in triples.keys) {
        final predicates = triples[subject]!;
        final typeValues =
            predicates['http://www.w3.org/1999/02/22-rdf-syntax-ns#type'] ?? [];

        // Check for MovieList.

        final isMovieList = typeValues.any((type) =>
            type.toString().contains('MovieList') ||
            type == 'https://sii.anu.edu.au/onto/moviestar#MovieList');

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
                  sharedWith = permissionsMap
                      .map((key, value) => MapEntry(key, value.toString()));
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
      }

      // Create placeholder Movie objects from the movie references.
      // In the new ontology structure, MovieLists only contain references.
      // The actual movie data is in separate files.

      final List<Movie> movies = [];
      for (final movieId in movieResourceIds) {
        try {
          // Create a minimal Movie object with just the ID.
          // The full movie data should be loaded separately when needed.

          final movie = Movie(
            id: int.parse(movieId),
            title: 'Movie $movieId',
            overview: '',
            posterUrl: '',
            backdropUrl: '',
            releaseDate: DateTime.now(),
            voteAverage: 0.0,
            genreIds: [],
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

  /// Escapes special characters in strings for TTL format.

  static String _escapeString(String input) {
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  /// Parses a single movie with user data from TTL content.
  /// Returns a map containing the movie, rating, and comment.

  static Map<String, dynamic>? movieWithUserDataFromTurtle(String ttlContent) {
    try {
      // First try to parse from JSON backup for compatibility.

      final movieJsonMatch =
          RegExp(r'# JSON_MOVIE_DATA: (.+)').firstMatch(ttlContent);
      final userDataJsonMatch =
          RegExp(r'# JSON_USER_DATA: (.+)').firstMatch(ttlContent);

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
            predicates['http://www.w3.org/1999/02/22-rdf-syntax-ns#type'] ?? [];

        // Check for movie.

        final isMovie = typeValues.any(
          (type) =>
              type.toString().contains('Movie') ||
              type == 'http://schema.org/Movie' ||
              type == '#Movie',
        );

        if (isMovie && movie == null) {
          movie = _extractMovieFromTriples(predicates);

          // Also check for rating and comment in the same movie resource (new ontology format).

          if (rating == null) {
            final contentRatingKey = predicates.keys.firstWhere(
              (key) => key.toString().contains('contentRating'),
              orElse: () => '',
            );
            if (contentRatingKey.isNotEmpty &&
                predicates[contentRatingKey]!.isNotEmpty) {
              final rawValue = predicates[contentRatingKey]!.first.toString();
              rating = double.tryParse(rawValue);
            }
          }

          if (comment == null) {
            final commentKey = predicates.keys.firstWhere(
              (key) => key.toString().contains('comment'),
              orElse: () => '',
            );
            if (commentKey.isNotEmpty && predicates[commentKey]!.isNotEmpty) {
              comment = predicates[commentKey]!.first.toString();
            }
          }
        }

        // Check for rating (old format compatibility).

        final isRating = typeValues.any(
          (type) => type.toString().contains('Rating') || type == '#Rating',
        );

        if (isRating && rating == null) {
          final valueKey = predicates.keys.firstWhere(
            (key) => key.toString().contains('value'),
            orElse: () => '',
          );
          if (valueKey.isNotEmpty && predicates[valueKey]!.isNotEmpty) {
            final rawValue = predicates[valueKey]!.first.toString();
            rating = double.tryParse(rawValue);
          }
        }

        // Check for comment (old format compatibility).

        final isComment = typeValues.any(
          (type) => type.toString().contains('Comment') || type == '#Comment',
        );

        if (isComment && comment == null) {
          final textKey = predicates.keys.firstWhere(
            (key) => key.toString().contains('text'),
            orElse: () => '',
          );
          if (textKey.isNotEmpty && predicates[textKey]!.isNotEmpty) {
            comment = predicates[textKey]!.first.toString();
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
      // Don't log parsing errors - they're often due to expected empty/missing files.

      return null;
    }
  }

  // Escapes special characters in strings for TTL format.

  static String _escapeAndSanitizeString(String input) {
    return _escapeString(input);
  }
}
