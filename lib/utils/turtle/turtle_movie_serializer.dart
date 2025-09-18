/// Movie-specific Turtle serialization functionality
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/foundation.dart';

import 'package:rdflib/rdflib.dart';

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/utils/turtle/turtle_namespaces.dart';
import 'package:moviestar/utils/turtle/turtle_utils.dart';

/// Handles conversion of Movie objects to/from Turtle (TTL) format
class TurtleMovieSerializer {
  /// Converts a list of movies to Turtle format with specified list name
  static String moviesToTurtle(List<Movie> movies, String listName) {
    final graph = Graph();
    final namespaces = TurtleNamespaces.getOntologyNamespaces();

    // Add all namespace declarations to graph
    for (final entry in namespaces.entries) {
      graph.addPrefixToCtx(entry.key, entry.value.uriRef!);
    }

    // Create the movie list resource
    final listUri = TurtleNamespaces.moviestarDataNS.withAttr(listName);
    graph.addTripleToGroups(
      listUri,
      TurtleNamespaces.rdfType,
      TurtleNamespaces.movieListType,
    );
    graph.addTripleToGroups(
      listUri,
      TurtleNamespaces.nameProperty,
      Literal(listName, datatype: TurtleNamespaces.xsdNS.withAttr('string')),
    );

    // Add each movie
    for (final movie in movies) {
      _addMovieToGraph(graph, movie, listUri);
    }

    // Try to serialize using the graph
    try {
      graph.serialize(format: 'turtle');
      if (graph.serializedString.isNotEmpty) {
        return graph.serializedString;
      }
    } catch (e) {
      debugPrint('🐛 [TurtleMovieSerializer] Graph serialize error: $e');
    }

    // Fallback: create manual TTL with movies
    debugPrint(
      '🐛 [TurtleMovieSerializer] Using fallback manual TTL generation for $listName with ${movies.length} movies',
    );
    final buffer = StringBuffer();

    // Add namespaces
    buffer.writeln(
      '@prefix ms: <http://dacs.anu.edu.au/ontologies/moviestar#> .',
    );
    buffer.writeln(
      '@prefix moviestar-data: <http://dacs.anu.edu.au/data/moviestar#> .',
    );
    buffer.writeln(
      '@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .',
    );
    buffer.writeln('@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .');
    buffer.writeln();

    // Create movie list
    final listId = TurtleUtils.escapeString(listName.replaceAll(' ', ''));
    buffer.writeln('moviestar-data:$listId rdf:type ms:MovieList ;');
    buffer.writeln('    ms:name "${TurtleUtils.escapeString(listName)}" .');
    buffer.writeln();

    // Add each movie
    for (final movie in movies) {
      final movieUri =
          'moviestar-data:${movie.contentType == ContentType.tvShow ? 'TVShow' : 'Movie'}-${movie.id}';
      buffer.writeln(
        '$movieUri rdf:type ms:${movie.contentType == ContentType.tvShow ? 'TVShow' : 'Movie'} ;',
      );
      buffer
          .writeln('    ms:name "${TurtleUtils.escapeString(movie.title)}" ;');
      buffer.writeln(
        '    ms:description "${TurtleUtils.escapeString(movie.overview)}" ;',
      );
      buffer.writeln('    ms:movieId "${movie.id}" ;');
      buffer.writeln(
        '    ms:posterUrl "${TurtleUtils.escapeString(movie.posterUrl)}" ;',
      );
      buffer.writeln(
        '    ms:backdropUrl "${TurtleUtils.escapeString(movie.backdropUrl)}" ;',
      );
      buffer.writeln(
        '    ms:releaseDate "${movie.releaseDate.toIso8601String()}" ;',
      );
      buffer.writeln('    ms:voteAverage "${movie.voteAverage}" ;');
      buffer.writeln(
        '    ms:contentType "${movie.contentType == ContentType.tvShow ? 'tvShow' : 'movie'}" .',
      );
      buffer.writeln();

      // Link movie to list
      buffer.writeln('moviestar-data:$listId ms:hasMovie $movieUri .');
      buffer.writeln();
    }

    final fallbackTtl = buffer.toString();
    debugPrint(
      '🐛 [TurtleMovieSerializer] Generated fallback TTL (${fallbackTtl.length} chars)',
    );
    return fallbackTtl;
  }

  /// Converts movies with user data (ratings, comments) to Turtle format
  static String movieWithUserDataToTurtle(
    List<Movie> movies,
    String listName,
    Map<String, double> ratings,
    Map<String, String> comments,
  ) {
    final graph = Graph();
    final namespaces = TurtleNamespaces.getOntologyNamespaces();

    // Add namespaces
    for (final entry in namespaces.entries) {
      graph.addPrefixToCtx(entry.key, entry.value.uriRef!);
    }

    // Create movie list
    final listUri = TurtleNamespaces.moviestarDataNS.withAttr(listName);
    graph.addTripleToGroups(
      listUri,
      TurtleNamespaces.rdfType,
      TurtleNamespaces.movieListType,
    );
    graph.addTripleToGroups(
      listUri,
      TurtleNamespaces.nameProperty,
      Literal(listName, datatype: TurtleNamespaces.xsdNS.withAttr('string')),
    );

    // Add movies with user data
    for (final movie in movies) {
      final movieUri = _addMovieToGraph(graph, movie, listUri);

      // Add rating if exists
      final rating = ratings[movie.id.toString()];
      if (rating != null) {
        _addRatingToGraph(graph, movieUri, rating);
      }

      // Add comment if exists
      final comment = comments[movie.id.toString()];
      if (comment != null) {
        _addCommentToGraph(graph, movieUri, comment);
      }
    }

    // Try to serialize using the graph
    try {
      graph.serialize(format: 'turtle');
      if (graph.serializedString.isNotEmpty) {
        return graph.serializedString;
      }
    } catch (e) {
      debugPrint(
        '🐛 [TurtleMovieSerializer] movieWithUserDataToTurtle graph serialize error: $e',
      );
    }

    // Fallback: create manual TTL with movies and user data
    debugPrint(
      '🐛 [TurtleMovieSerializer] Using fallback manual TTL for movieWithUserDataToTurtle: $listName with ${movies.length} movies',
    );
    final buffer = StringBuffer();

    // Add namespaces
    buffer.writeln(
      '@prefix ms: <http://dacs.anu.edu.au/ontologies/moviestar#> .',
    );
    buffer.writeln(
      '@prefix moviestar-data: <http://dacs.anu.edu.au/data/moviestar#> .',
    );
    buffer.writeln(
      '@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .',
    );
    buffer.writeln('@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .');
    buffer.writeln();

    // Create movie list
    final listId = TurtleUtils.escapeString(listName.replaceAll(' ', ''));
    buffer.writeln('moviestar-data:$listId rdf:type ms:MovieList ;');
    buffer.writeln('    ms:name "${TurtleUtils.escapeString(listName)}" .');
    buffer.writeln();

    // Add each movie with user data
    for (final movie in movies) {
      final movieUri =
          'moviestar-data:${movie.contentType == ContentType.tvShow ? 'TVShow' : 'Movie'}-${movie.id}';
      buffer.writeln(
        '$movieUri rdf:type ms:${movie.contentType == ContentType.tvShow ? 'TVShow' : 'Movie'} ;',
      );
      buffer
          .writeln('    ms:name "${TurtleUtils.escapeString(movie.title)}" ;');
      buffer.writeln(
        '    ms:description "${TurtleUtils.escapeString(movie.overview)}" ;',
      );
      buffer.writeln('    ms:movieId "${movie.id}" ;');
      buffer.writeln(
        '    ms:posterUrl "${TurtleUtils.escapeString(movie.posterUrl)}" ;',
      );
      buffer.writeln(
        '    ms:backdropUrl "${TurtleUtils.escapeString(movie.backdropUrl)}" ;',
      );
      buffer.writeln(
        '    ms:releaseDate "${movie.releaseDate.toIso8601String()}" ;',
      );
      buffer.writeln('    ms:voteAverage "${movie.voteAverage}" ;');
      buffer.writeln(
        '    ms:contentType "${movie.contentType == ContentType.tvShow ? 'tvShow' : 'movie'}" .',
      );

      // Add user data if available
      final rating = ratings[movie.id.toString()];
      if (rating != null) {
        buffer.writeln('$movieUri ms:userRating "$rating" .');
      }

      final comment = comments[movie.id.toString()];
      if (comment != null) {
        buffer.writeln(
          '$movieUri ms:userComment "${TurtleUtils.escapeString(comment)}" .',
        );
      }

      buffer.writeln();

      // Link movie to list
      buffer.writeln('moviestar-data:$listId ms:hasMovie $movieUri .');
      buffer.writeln();
    }

    final fallbackTtl = buffer.toString();
    debugPrint(
      '🐛 [TurtleMovieSerializer] Generated fallback user data TTL (${fallbackTtl.length} chars)',
    );
    return fallbackTtl;
  }

  /// Converts movies from Turtle format back to Movie objects
  static List<Movie> moviesFromTurtle(String ttlContent) {
    try {
      final graph = Graph();
      graph.parseTurtle(ttlContent);

      final movies = <Movie>[];
      final movieUris = graph.subjects(
        pre: TurtleNamespaces.rdfType,
        obj: TurtleNamespaces.movieType,
      );

      for (final movieUri in movieUris) {
        final movie = _extractMovieFromObjects(graph, movieUri);
        if (movie != null) {
          movies.add(movie);
        }
      }

      return movies;
    } catch (e) {
      debugPrint('Error parsing movies from Turtle: $e');
      return [];
    }
  }

  /// Adds a movie to the RDF graph and returns the movie URI
  static URIRef _addMovieToGraph(Graph graph, Movie movie, URIRef listUri) {
    final movieUri =
        TurtleNamespaces.moviestarDataNS.withAttr('movie_${movie.id}');

    // Link movie to list
    graph.addTripleToGroups(listUri, TurtleNamespaces.hasMovie, movieUri);

    // Add movie type
    graph.addTripleToGroups(
      movieUri,
      TurtleNamespaces.rdfType,
      TurtleNamespaces.movieType,
    );

    // Add movie properties
    graph.addTripleToGroups(
      movieUri,
      TurtleNamespaces.identifier,
      Literal(
        movie.id.toString(),
        datatype: TurtleNamespaces.xsdNS.withAttr('integer'),
      ),
    );

    graph.addTripleToGroups(
      movieUri,
      TurtleNamespaces.name,
      Literal(
        TurtleUtils.escapeString(movie.title),
        datatype: TurtleNamespaces.xsdNS.withAttr('string'),
      ),
    );

    if (movie.overview.isNotEmpty) {
      graph.addTripleToGroups(
        movieUri,
        TurtleNamespaces.description,
        Literal(
          TurtleUtils.escapeString(movie.overview),
          datatype: TurtleNamespaces.xsdNS.withAttr('string'),
        ),
      );
    }

    if (movie.posterUrl.isNotEmpty) {
      graph.addTripleToGroups(
        movieUri,
        TurtleNamespaces.image,
        URIRef(movie.posterUrl),
      );
      graph.addTripleToGroups(
        movieUri,
        TurtleNamespaces.thumbnailUrl,
        URIRef(movie.posterUrl),
      );
    }

    if (movie.voteAverage > 0) {
      graph.addTripleToGroups(
        movieUri,
        TurtleNamespaces.aggregateRating,
        Literal(
          movie.voteAverage.toString(),
          datatype: TurtleNamespaces.xsdNS.withAttr('decimal'),
        ),
      );
    }

    graph.addTripleToGroups(
      movieUri,
      TurtleNamespaces.datePublished,
      Literal(
        movie.releaseDate.toIso8601String(),
        datatype: TurtleNamespaces.xsdNS.withAttr('date'),
      ),
    );

    return movieUri;
  }

  /// Adds a rating to the graph for a movie
  static void _addRatingToGraph(Graph graph, URIRef movieUri, double rating) {
    final ratingUri = URIRef('${movieUri.value}_rating');
    graph.addTripleToGroups(
      ratingUri,
      TurtleNamespaces.rdfType,
      TurtleNamespaces.ratingType,
    );
    graph.addTripleToGroups(
      movieUri,
      TurtleNamespaces.aggregateRating,
      ratingUri,
    );
    graph.addTripleToGroups(
      ratingUri,
      TurtleNamespaces.value,
      Literal(
        rating.toString(),
        datatype: TurtleNamespaces.xsdNS.withAttr('decimal'),
      ),
    );
  }

  /// Adds a comment to the graph for a movie
  static void _addCommentToGraph(Graph graph, URIRef movieUri, String comment) {
    final commentUri = URIRef('${movieUri.value}_comment');
    graph.addTripleToGroups(
      commentUri,
      TurtleNamespaces.rdfType,
      TurtleNamespaces.commentType,
    );
    graph.addTripleToGroups(movieUri, TurtleNamespaces.comment, commentUri);
    graph.addTripleToGroups(
      commentUri,
      TurtleNamespaces.text,
      Literal(
        TurtleUtils.escapeString(comment),
        datatype: TurtleNamespaces.xsdNS.withAttr('string'),
      ),
    );
  }

  /// Extracts a Movie object from RDF graph triples
  static Movie? _extractMovieFromObjects(Graph graph, URIRef movieUri) {
    try {
      // Get movie ID
      final idObjects =
          graph.objects(sub: movieUri, pre: TurtleNamespaces.identifier);
      if (idObjects.isEmpty) return null;
      final id = int.tryParse(idObjects.first.toString()) ?? 0;

      // Get movie title
      final nameObjects =
          graph.objects(sub: movieUri, pre: TurtleNamespaces.name);
      if (nameObjects.isEmpty) return null;
      final title = nameObjects.first.toString().replaceAll('"', '');

      // Get optional fields
      final overviewObjects =
          graph.objects(sub: movieUri, pre: TurtleNamespaces.description);
      final overview = overviewObjects.isNotEmpty
          ? overviewObjects.first.toString().replaceAll('"', '')
          : '';

      final posterObjects =
          graph.objects(sub: movieUri, pre: TurtleNamespaces.image);
      final posterUrl =
          posterObjects.isNotEmpty ? posterObjects.first.toString() : '';

      final ratingObjects =
          graph.objects(sub: movieUri, pre: TurtleNamespaces.aggregateRating);
      final voteAverage = ratingObjects.isNotEmpty
          ? double.tryParse(ratingObjects.first.toString()) ?? 0.0
          : 0.0;

      final dateObjects =
          graph.objects(sub: movieUri, pre: TurtleNamespaces.datePublished);
      final dateStr = dateObjects.isNotEmpty
          ? dateObjects.first.toString().replaceAll('"', '')
          : '';
      final releaseDate = dateStr.isNotEmpty
          ? DateTime.tryParse(dateStr) ?? DateTime.now()
          : DateTime.now();

      return Movie(
        id: id,
        title: title,
        overview: overview,
        posterUrl: posterUrl,
        backdropUrl: '', // Not stored in turtle format
        releaseDate: releaseDate,
        voteAverage: voteAverage,
        genreIds: [], // Not stored in turtle format
      );
    } catch (e) {
      debugPrint('Error extracting movie from triples: $e');
      return null;
    }
  }
}
