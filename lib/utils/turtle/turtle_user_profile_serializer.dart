/// User profile and API key Turtle serialization functionality
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:rdflib/rdflib.dart';

import 'package:moviestar/utils/turtle/turtle_namespaces.dart';
import 'package:moviestar/utils/turtle/turtle_utils.dart';

/// Handles conversion of user profiles and API keys to Turtle format
class TurtleUserProfileSerializer {
  /// Creates a user profile in Turtle format
  static String createUserProfile(
    String webId,
    String name,
    String dob,
    String gender,
  ) {
    final graph = Graph();
    final namespaces = TurtleNamespaces.getOntologyNamespaces();

    // Add namespaces
    for (final entry in namespaces.entries) {
      graph.addPrefixToCtx(entry.key, entry.value.uriRef!);
    }

    // Create user resource
    final userUri = URIRef(webId);
    print(
        '🐛 [TurtleUserProfileSerializer] Adding user triple: $userUri rdf:type ${TurtleNamespaces.userType}');
    graph.addTripleToGroups(
        userUri, TurtleNamespaces.rdfType, TurtleNamespaces.userType);

    // Add user properties
    graph.addTripleToGroups(
      userUri,
      TurtleNamespaces.name,
      Literal(TurtleUtils.escapeString(name),
          datatype: TurtleNamespaces.xsdNS.withAttr('string')),
    );

    if (dob.isNotEmpty) {
      graph.addTripleToGroups(
        userUri,
        TurtleNamespaces.dob,
        Literal(dob, datatype: TurtleNamespaces.xsdNS.withAttr('date')),
      );
    }

    if (gender.isNotEmpty) {
      graph.addTripleToGroups(
        userUri,
        TurtleNamespaces.gender,
        Literal(TurtleUtils.escapeString(gender),
            datatype: TurtleNamespaces.xsdNS.withAttr('string')),
      );
    }

    graph.addTripleToGroups(
      userUri,
      TurtleNamespaces.webId,
      Literal(TurtleUtils.escapeString(webId),
          datatype: TurtleNamespaces.xsdNS.withAttr('string')),
    );

    print('🐛 [TurtleUserProfileSerializer] About to serialize graph');

    // Try to serialize using the graph
    try {
      graph.serialize(format: 'turtle');
      print(
          '🐛 [TurtleUserProfileSerializer] Graph serialize called, serializedString length: ${graph.serializedString.length}');
      print(
          '🐛 [TurtleUserProfileSerializer] Graph serializedString content: "${graph.serializedString}"');

      if (graph.serializedString.isNotEmpty) {
        return graph.serializedString;
      }
    } catch (e) {
      print('🐛 [TurtleUserProfileSerializer] Graph serialize error: $e');
    }

    // Fallback: create manual TTL for user profile
    print(
        '🐛 [TurtleUserProfileSerializer] Using fallback manual TTL generation');
    final buffer = StringBuffer();

    // Add namespaces
    buffer.writeln(
        '@prefix ms: <http://dacs.anu.edu.au/ontologies/moviestar#> .');
    buffer.writeln(
        '@prefix moviestar-data: <http://dacs.anu.edu.au/data/moviestar#> .');
    buffer.writeln(
        '@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .');
    buffer.writeln('@prefix foaf: <http://xmlns.com/foaf/0.1/> .');
    buffer.writeln('@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .');
    buffer.writeln();

    // Add user profile
    buffer.writeln('<$webId> rdf:type ms:User ;');
    buffer.writeln('    foaf:name "User" ;');
    buffer.writeln('    ms:webId "$webId" .');
    buffer.writeln();

    final fallbackTtl = buffer.toString();
    print(
        '🐛 [TurtleUserProfileSerializer] Generated fallback TTL (${fallbackTtl.length} chars)');
    return fallbackTtl;
  }

  /// Creates a movie list resource in Turtle format
  static String createMovieList(
    String listId,
    String listName,
    String description,
  ) {
    final graph = Graph();
    final namespaces = TurtleNamespaces.getOntologyNamespaces();

    // Add namespaces
    for (final entry in namespaces.entries) {
      graph.addPrefixToCtx(entry.key, entry.value.uriRef!);
    }

    // Create movie list resource
    final listUri = TurtleNamespaces.moviestarDataNS.withAttr(
      'MovieList-$listId',
    );

    // Create movie list
    graph.addTripleToGroups(
        listUri, TurtleNamespaces.rdfType, TurtleNamespaces.movieListType);
    graph.addTripleToGroups(
      listUri,
      TurtleNamespaces.name,
      Literal(TurtleUtils.escapeString(listName),
          datatype: TurtleNamespaces.xsdNS.withAttr('string')),
    );
    if (description.isNotEmpty) {
      graph.addTripleToGroups(
        listUri,
        TurtleNamespaces.description,
        Literal(TurtleUtils.escapeString(description),
            datatype: TurtleNamespaces.xsdNS.withAttr('string')),
      );
    }

    // Try to serialize using the graph
    try {
      graph.serialize(format: 'turtle');
      print(
          '🐛 [TurtleUserProfileSerializer] Movie list graph serialize called, serializedString length: ${graph.serializedString.length}');

      if (graph.serializedString.isNotEmpty) {
        return graph.serializedString;
      }
    } catch (e) {
      print(
          '🐛 [TurtleUserProfileSerializer] Movie list graph serialize error: $e');
    }

    // Fallback: create manual TTL for movie list
    print(
        '🐛 [TurtleUserProfileSerializer] Using fallback manual TTL for movie list $listId');
    final buffer = StringBuffer();

    // Add namespaces
    buffer.writeln(
        '@prefix ms: <http://dacs.anu.edu.au/ontologies/moviestar#> .');
    buffer.writeln(
        '@prefix moviestar-data: <http://dacs.anu.edu.au/data/moviestar#> .');
    buffer.writeln(
        '@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .');
    buffer.writeln();

    // Add movie list reference
    buffer.writeln('moviestar-data:MovieList-$listId rdf:type ms:MovieList ;');
    buffer.writeln('    ms:name "$listName" ;');
    if (description.isNotEmpty) {
      buffer.writeln('    ms:description "$description" ;');
    }
    buffer.writeln('    ms:listId "$listId" .');
    buffer.writeln();

    final fallbackTtl = buffer.toString();
    print(
        '🐛 [TurtleUserProfileSerializer] Generated fallback movie list TTL (${fallbackTtl.length} chars)');
    return fallbackTtl;
  }

  /// Creates an API key resource in Turtle format
  static String createApiKey(
    String apiKeyId,
    String apiKeyValue,
    String source,
  ) {
    final graph = Graph();
    final namespaces = TurtleNamespaces.getOntologyNamespaces();

    // Add namespaces
    for (final entry in namespaces.entries) {
      graph.addPrefixToCtx(entry.key, entry.value.uriRef!);
    }

    // Create API key resource
    final apiKeyUri = TurtleNamespaces.moviestarDataNS.withAttr(
      'ApiKey-$apiKeyId',
    );

    // Create API key
    graph.addTripleToGroups(
        apiKeyUri, TurtleNamespaces.rdfType, TurtleNamespaces.apiKeyType);
    graph.addTripleToGroups(
      apiKeyUri,
      TurtleNamespaces.keyValue,
      Literal(TurtleUtils.escapeString(apiKeyValue),
          datatype: TurtleNamespaces.xsdNS.withAttr('string')),
    );
    graph.addTripleToGroups(
      apiKeyUri,
      TurtleNamespaces.source,
      Literal(TurtleUtils.escapeString(source),
          datatype: TurtleNamespaces.xsdNS.withAttr('string')),
    );

    // Try to serialize using the graph
    try {
      graph.serialize(format: 'turtle');
      if (graph.serializedString.isNotEmpty) {
        return graph.serializedString;
      }
    } catch (e) {
      print(
          '🐛 [TurtleUserProfileSerializer] API key graph serialize error: $e');
    }

    // Fallback: create manual TTL for API key
    final buffer = StringBuffer();

    // Add namespaces
    buffer.writeln(
        '@prefix ms: <http://dacs.anu.edu.au/ontologies/moviestar#> .');
    buffer.writeln(
        '@prefix moviestar-data: <http://dacs.anu.edu.au/data/moviestar#> .');
    buffer.writeln(
        '@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .');
    buffer.writeln();

    // Add API key
    buffer.writeln('moviestar-data:ApiKey-$apiKeyId rdf:type ms:ApiKey ;');
    buffer.writeln('    ms:keyValue "$apiKeyValue" ;');
    buffer.writeln('    ms:source "$source" .');
    buffer.writeln();

    return buffer.toString();
  }

  /// Creates movie list with user data in ontology format
  static String movieWithUserDataToTurtleOntology(
    List<Map<String, dynamic>> movies,
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
        listUri, TurtleNamespaces.rdfType, TurtleNamespaces.movieListType);
    graph.addTripleToGroups(
      listUri,
      TurtleNamespaces.rdfsLabel,
      Literal(TurtleUtils.escapeString(listName),
          datatype: TurtleNamespaces.xsdNS.withAttr('string')),
    );

    // Add movies from map data
    for (final movieData in movies) {
      final movieId = movieData['id']?.toString() ?? '';
      if (movieId.isEmpty) continue;

      final movieUri =
          TurtleNamespaces.moviestarDataNS.withAttr('movie_$movieId');

      // Link movie to list
      graph.addTripleToGroups(listUri, TurtleNamespaces.hasMovie, movieUri);

      // Add movie type
      graph.addTripleToGroups(
          movieUri, TurtleNamespaces.rdfType, TurtleNamespaces.movieType);

      // Add movie properties from map
      if (movieData['title'] != null) {
        graph.addTripleToGroups(
          movieUri,
          TurtleNamespaces.name,
          Literal(
            TurtleUtils.escapeString(movieData['title'].toString()),
            datatype: TurtleNamespaces.xsdNS.withAttr('string'),
          ),
        );
      }

      if (movieData['overview'] != null) {
        graph.addTripleToGroups(
          movieUri,
          TurtleNamespaces.description,
          Literal(
            TurtleUtils.escapeString(movieData['overview'].toString()),
            datatype: TurtleNamespaces.xsdNS.withAttr('string'),
          ),
        );
      }

      // Add user data if exists
      final rating = ratings[movieId];
      if (rating != null) {
        final ratingUri =
            TurtleNamespaces.moviestarDataNS.withAttr('rating_$movieId');
        graph.addTripleToGroups(
            ratingUri, TurtleNamespaces.rdfType, TurtleNamespaces.ratingType);
        graph.addTripleToGroups(
            movieUri, TurtleNamespaces.aggregateRating, ratingUri);
        graph.addTripleToGroups(
          ratingUri,
          TurtleNamespaces.value,
          Literal(rating.toString(),
              datatype: TurtleNamespaces.xsdNS.withAttr('decimal')),
        );
      }

      final comment = comments[movieId];
      if (comment != null) {
        final commentUri =
            TurtleNamespaces.moviestarDataNS.withAttr('comment_$movieId');
        graph.addTripleToGroups(
            commentUri, TurtleNamespaces.rdfType, TurtleNamespaces.commentType);
        graph.addTripleToGroups(movieUri, TurtleNamespaces.comment, commentUri);
        graph.addTripleToGroups(
          commentUri,
          TurtleNamespaces.text,
          Literal(TurtleUtils.escapeString(comment),
              datatype: TurtleNamespaces.xsdNS.withAttr('string')),
        );
      }
    }

    graph.serialize(format: 'turtle');
    return graph.serializedString;
  }

  /// Extracts movie list data from Turtle content
  static Map<String, dynamic>? movieListFromTurtle(String ttlContent) {
    try {
      final graph = Graph();
      graph.parseTurtle(ttlContent);
      print(
          '🐛 [movieListFromTurtle] Graph parsed, looking for movie lists...');

      // Try to find movie lists with current namespace
      var listUris = graph.subjects(
        pre: TurtleNamespaces.rdfType,
        obj: TurtleNamespaces.movieListType,
      );
      print(
          '🐛 [movieListFromTurtle] Found ${listUris.length} lists with movieListType');

      // Fallback: try with rdfs:label instead of custom movieListType for backward compatibility
      if (listUris.isEmpty) {
        // Look for any subject that has rdfs:label property (common in older format)
        final labelProp = TurtleNamespaces.rdfsNS.withAttr('label');
        listUris = graph.subjects(pre: labelProp);
        print(
            '🐛 [movieListFromTurtle] Fallback: found ${listUris.length} subjects with rdfs:label');
      }

      if (listUris.isEmpty) {
        print('🐛 [movieListFromTurtle] No list URIs found, returning null');
        return null;
      }

      final listUri = listUris.first;

      // Get list name - try multiple property names for backward compatibility
      var nameTriples = graph.objects(
        sub: listUri,
        pre: TurtleNamespaces.nameProperty,
      );

      // Fallback to rdfs:label if name property not found
      if (nameTriples.isEmpty) {
        final labelProp = TurtleNamespaces.rdfsNS.withAttr('label');
        nameTriples = graph.objects(sub: listUri, pre: labelProp);
      }

      // Fallback to rdfs:comment if still not found
      if (nameTriples.isEmpty) {
        final commentProp = TurtleNamespaces.rdfsNS.withAttr('comment');
        nameTriples = graph.objects(sub: listUri, pre: commentProp);
      }

      final listName = nameTriples.isNotEmpty
          ? nameTriples.first.toString().replaceAll('"', '')
          : 'Unnamed List';

      // Get movies - try multiple property names for backward compatibility
      var movieUris = <URIRef>[];

      // First try: look for movies using hasMovie property
      final movieTriples = graph.objects(
        sub: listUri,
        pre: TurtleNamespaces.hasMovie,
      );
      print(
          '🐛 [movieListFromTurtle] Found ${movieTriples.length} movies with hasMovie property');

      if (movieTriples.isNotEmpty) {
        // Convert objects to URIRef list
        movieUris = movieTriples.whereType<URIRef>().toList();
        print(
            '🐛 [movieListFromTurtle] Using hasMovie results: ${movieUris.length} movies');
      } else {
        // Fallback: find all objects that are movies based on their type
        final movieUriSet = graph.subjects(
          pre: TurtleNamespaces.rdfType,
          obj: TurtleNamespaces.movieType,
        );
        movieUris = movieUriSet.toList();
        print(
            '🐛 [movieListFromTurtle] Fallback: found ${movieUris.length} movies by type');
      }

      print(
          '🐛 [movieListFromTurtle] Total movies to process: ${movieUris.length}');

      final movies = <Map<String, dynamic>>[];
      final ratings = <String, double>{};
      final comments = <String, String>{};

      for (final movieUri in movieUris) {
        print(
            '🐛 [movieListFromTurtle] Processing movie URI: ${movieUri.value}');

        // Extract movie data
        final movieData = _extractMovieDataFromGraph(graph, movieUri);
        print('🐛 [movieListFromTurtle] Extracted movie data: $movieData');

        if (movieData != null) {
          // Check if this is a placeholder that needs file loading
          if (movieData['isPlaceholder'] == true && movieData['filePath'] != null) {
            print('🐛 [movieListFromTurtle] Movie ${movieData['id']} is a placeholder, needs file loading from: ${movieData['filePath']}');
            // Mark the movie as needing file resolution but add it to the list
            // The calling code will need to resolve filePath references
            movieData['needsFileResolution'] = true;
          }

          movies.add(movieData);
          print(
              '🐛 [movieListFromTurtle] Added movie: ${movieData['title']} (ID: ${movieData['id']})');

          final movieId = movieData['id']?.toString() ?? '';

          // Extract rating if exists
          final rating = _extractRatingFromGraph(graph, movieUri);
          if (rating != null) {
            ratings[movieId] = rating;
          }

          // Extract comment if exists
          final comment = _extractCommentFromGraph(graph, movieUri);
          if (comment != null) {
            comments[movieId] = comment;
          }
        } else {
          print(
              '🐛 [movieListFromTurtle] Failed to extract data for movie URI: ${movieUri.value}');
        }
      }

      return {
        'name': listName,
        'movies': movies,
        'ratings': ratings,
        'comments': comments,
      };
    } catch (e) {
      print('🐛 [movieListFromTurtle] Error parsing TTL: $e');
      return null;
    }
  }

  /// Extracts movie data from graph
  static Map<String, dynamic>? _extractMovieDataFromGraph(
      Graph graph, URIRef movieUri) {
    try {
      print(
          '🐛 [_extractMovieDataFromGraph] Extracting data for URI: ${movieUri.value}');
      final movieData = <String, dynamic>{};

      // Extract ID from URI - handle both Movie and TVShow formats with underscore and hyphen
      final uriString = movieUri.value;
      var idMatch = RegExp(r'(Movie|TVShow)[_-](\d+)', caseSensitive: false).firstMatch(uriString);
      if (idMatch != null) {
        movieData['id'] = int.tryParse(idMatch.group(2)!) ?? 0;
        print(
            '🐛 [_extractMovieDataFromGraph] Extracted ID: ${movieData['id']} from ${idMatch.group(1)} format');
      } else {
        print(
            '🐛 [_extractMovieDataFromGraph] Failed to extract ID from URI: $uriString');
      }

      // Extract title - try both schema.org name and moviestar ontology name
      var nameTriples =
          graph.objects(sub: movieUri, pre: TurtleNamespaces.name);

      // If not found with schema.org name, try moviestar ontology name
      if (nameTriples.isEmpty) {
        nameTriples = graph.objects(sub: movieUri, pre: TurtleNamespaces.moviestarOntoNS.withAttr('name'));
      }
      print(
          '🐛 [_extractMovieDataFromGraph] Name triples found: ${nameTriples.length}');
      if (nameTriples.isNotEmpty) {
        var titleValue = nameTriples.first.toString().replaceAll('"', '');

        // Check if title contains file path reference (e.g., "filePath=moviestar/data/movies/Movie-803796.ttl")
        final filePathMatch =
            RegExp(r'filePath=([^|]+)').firstMatch(titleValue);
        if (filePathMatch != null) {
          // This is a file path reference, create placeholder title
          final filePath = filePathMatch.group(1)!;
          final fileNameMatch = RegExp(r'([^/]+)\.ttl$').firstMatch(filePath);
          if (fileNameMatch != null) {
            final fileName = fileNameMatch.group(1)!;
            // Extract movie ID from filename (e.g., "Movie-803796" -> "803796", "TVShow-223911" -> "223911")
            final fileIdMatch = RegExp(r'(Movie|TVShow)[_-](\d+)', caseSensitive: false).firstMatch(fileName);
            if (fileIdMatch != null) {
              final contentType = fileIdMatch.group(1)!;
              final movieId = fileIdMatch.group(2)!;
              movieData['title'] =
                  '$contentType $movieId'; // Placeholder title
              movieData['isPlaceholder'] =
                  true; // Mark as placeholder for later loading
              movieData['filePath'] =
                  filePath; // Store file path for later loading
              print(
                  '🐛 [_extractMovieDataFromGraph] Detected file path reference: $filePath, using placeholder title: ${movieData['title']}');
            }
          }
        } else {
          movieData['title'] = titleValue;
          print(
              '🐛 [_extractMovieDataFromGraph] Extracted title: ${movieData['title']}');
        }
      } else {
        // Fallback: try rdfs:label for title
        final labelProp = TurtleNamespaces.rdfsNS.withAttr('label');
        final labelTriples = graph.objects(sub: movieUri, pre: labelProp);
        print(
            '🐛 [_extractMovieDataFromGraph] Label triples found: ${labelTriples.length}');
        if (labelTriples.isNotEmpty) {
          var titleValue = labelTriples.first.toString().replaceAll('"', '');

          // Check if label contains file path reference
          final filePathMatch =
              RegExp(r'filePath=([^|]+)').firstMatch(titleValue);
          if (filePathMatch != null) {
            // This is a file path reference, create placeholder title
            final filePath = filePathMatch.group(1)!;
            final fileNameMatch = RegExp(r'([^/]+)\.ttl$').firstMatch(filePath);
            if (fileNameMatch != null) {
              final fileName = fileNameMatch.group(1)!;
              // Extract movie ID from filename
              final fileIdMatch =
                  RegExp(r'(Movie|TVShow)[_-](\d+)', caseSensitive: false).firstMatch(fileName);
              if (fileIdMatch != null) {
                final contentType = fileIdMatch.group(1)!;
                final movieId = fileIdMatch.group(2)!;
                movieData['title'] =
                    '$contentType $movieId'; // Placeholder title
                movieData['isPlaceholder'] =
                    true; // Mark as placeholder for later loading
                movieData['filePath'] =
                    filePath; // Store file path for later loading
                print(
                    '🐛 [_extractMovieDataFromGraph] Detected file path reference in label: $filePath, using placeholder title: ${movieData['title']}');
              }
            }
          } else {
            movieData['title'] = titleValue;
            print(
                '🐛 [_extractMovieDataFromGraph] Extracted title from label: ${movieData['title']}');
          }
        }
      }

      // Extract overview
      final descTriples =
          graph.objects(sub: movieUri, pre: TurtleNamespaces.description);
      print(
          '🐛 [_extractMovieDataFromGraph] Description triples found: ${descTriples.length}');
      if (descTriples.isNotEmpty) {
        movieData['overview'] =
            descTriples.first.toString().replaceAll('"', '');
        print(
            '🐛 [_extractMovieDataFromGraph] Extracted overview: ${movieData['overview']}');
      } else {
        // Fallback: try rdfs:comment for overview
        final commentProp = TurtleNamespaces.rdfsNS.withAttr('comment');
        final commentTriples = graph.objects(sub: movieUri, pre: commentProp);
        print(
            '🐛 [_extractMovieDataFromGraph] Comment triples found: ${commentTriples.length}');
        if (commentTriples.isNotEmpty) {
          movieData['overview'] =
              commentTriples.first.toString().replaceAll('"', '');
          print(
              '🐛 [_extractMovieDataFromGraph] Extracted overview from comment: ${movieData['overview']}');
        }
      }

      print('🐛 [_extractMovieDataFromGraph] Final movie data: $movieData');
      return movieData.isNotEmpty ? movieData : null;
    } catch (e) {
      print('🐛 [_extractMovieDataFromGraph] Error: $e');
      return null;
    }
  }

  /// Extracts rating from graph for a movie
  static double? _extractRatingFromGraph(Graph graph, URIRef movieUri) {
    try {
      final ratingTriples =
          graph.objects(sub: movieUri, pre: TurtleNamespaces.aggregateRating);
      if (ratingTriples.isEmpty) return null;

      final ratingUri = ratingTriples.first as URIRef;
      final valueTriples =
          graph.objects(sub: ratingUri, pre: TurtleNamespaces.value);

      if (valueTriples.isNotEmpty) {
        return double.tryParse(
            valueTriples.first.toString().replaceAll('"', ''));
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Extracts comment from graph for a movie
  static String? _extractCommentFromGraph(Graph graph, URIRef movieUri) {
    try {
      final commentTriples =
          graph.objects(sub: movieUri, pre: TurtleNamespaces.comment);
      if (commentTriples.isEmpty) return null;

      final commentUri = commentTriples.first as URIRef;
      final textTriples =
          graph.objects(sub: commentUri, pre: TurtleNamespaces.text);

      if (textTriples.isNotEmpty) {
        return textTriples.first.toString().replaceAll('"', '');
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
