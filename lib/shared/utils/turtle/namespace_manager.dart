/// Namespace management for Turtle serialization.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:rdflib/rdflib.dart';

/// Manages all RDF/TTL namespaces and predicates used in MovieStar ontology.

class TurtleNamespaceManager {
  // Define namespaces based on the ontology design.

  static final moviestarOntoNS = Namespace(
    ns: 'https://sii.anu.edu.au/onto/moviestar#',
  );
  static final moviestarDataNS = Namespace(
    ns: 'https://sii.anu.edu.au/data/moviestar/',
  );
  static final movieNS = Namespace(ns: 'http://schema.org/');
  static final xsdNS = Namespace(ns: 'http://www.w3.org/2001/XMLSchema#');
  static final rdfsNS = Namespace(ns: 'http://www.w3.org/2000/01/rdf-schema#');
  static final owlNS = Namespace(ns: 'http://www.w3.org/2002/07/owl#');
  static final localNS = Namespace(ns: '#');

  // Define common predicates as URIRefs.

  static final movieType = movieNS.withAttr('Movie');
  static final tvShowType = movieNS.withAttr('TVShow');
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
  static final contentRating = movieNS.withAttr('contentRating');
  static final comment = movieNS.withAttr('comment');
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

  /// Static namespace bindings to match ontology structure exactly.
  /// Only define custom namespaces - let the RDF library handle standard prefixes.

  static Map<String, Namespace> getOntologyNamespaces() {
    return {
      'moviestar-onto': moviestarOntoNS,
      'moviestar-data': moviestarDataNS,
      'sdo': movieNS,
    };
  }

  /// Get basic namespace bindings for simple operations.

  static Map<String, Namespace> getBasicNamespaces() {
    return {
      '': localNS,
      'schema': movieNS,
    };
  }
}
