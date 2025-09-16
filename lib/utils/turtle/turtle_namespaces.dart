/// RDF Namespaces and Constants for Turtle Serialization
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:rdflib/rdflib.dart';

/// Central registry for all RDF namespaces and properties used in MovieStar Turtle serialization
class TurtleNamespaces {
  // Primary namespaces
  static final moviestarOntoNS = Namespace(ns: 'http://dacs.anu.edu.au/ontologies/moviestar#');
  static final moviestarDataNS = Namespace(ns: 'http://dacs.anu.edu.au/data/moviestar#');
  static final movieNS = Namespace(ns: 'http://schema.org/');
  static final xsdNS = Namespace(ns: 'http://www.w3.org/2001/XMLSchema#');
  static final rdfsNS = Namespace(ns: 'http://www.w3.org/2000/01/rdf-schema#');
  static final owlNS = Namespace(ns: 'http://www.w3.org/2002/07/owl#');
  static final localNS = Namespace(ns: '#');

  // Type definitions
  static final movieType = movieNS.withAttr('Movie');
  static final tvShowType = movieNS.withAttr('TVShow');
  static final movieListType = moviestarOntoNS.withAttr('MovieList');
  static final userType = moviestarOntoNS.withAttr('User');
  static final ratingType = localNS.withAttr('Rating');
  static final commentType = localNS.withAttr('Comment');
  static final apiKeyType = moviestarOntoNS.withAttr('ApiKey');

  // User properties
  static final hasMovieList = moviestarOntoNS.withAttr('hasMovieList');
  static final hasApiKey = moviestarOntoNS.withAttr('hasApiKey');
  static final dob = moviestarOntoNS.withAttr('DOB');
  static final gender = moviestarOntoNS.withAttr('gender');
  static final webId = moviestarOntoNS.withAttr('webID');

  // MovieList properties
  static final hasMovie = moviestarOntoNS.withAttr('hasMovie');
  static final filePath = moviestarOntoNS.withAttr('filePath');

  // Movie properties (Schema.org)
  static final identifier = movieNS.withAttr('identifier');
  static final name = movieNS.withAttr('name');
  static final description = movieNS.withAttr('description');
  static final image = movieNS.withAttr('image');
  static final thumbnailUrl = movieNS.withAttr('thumbnailUrl');
  static final aggregateRating = movieNS.withAttr('aggregateRating');
  static final datePublished = movieNS.withAttr('datePublished');
  static final genre = movieNS.withAttr('genre');
  static final contentRating = movieNS.withAttr(
    'contentRating',
  );
  static final comment = movieNS.withAttr('comment');
  static final keyValue = moviestarOntoNS.withAttr('keyValue');
  static final source = moviestarOntoNS.withAttr('source');

  // List properties
  static final nameProperty = localNS.withAttr('name');
  static final moviesProperty = localNS.withAttr('movies');

  // Rating properties
  static final movieId = localNS.withAttr('movieId');
  static final value = localNS.withAttr('value');

  // Comment properties
  static final text = localNS.withAttr('text');

  // Standard RDF properties
  static final rdfType = URIRef(
    'http://www.w3.org/1999/02/22-rdf-syntax-ns#type',
  );

  // RDFS properties
  static final rdfsLabel = rdfsNS.withAttr('label');

  /// Returns map of all ontology namespaces for Turtle generation
  static Map<String, Namespace> getOntologyNamespaces() {
    return {
      'moviestar': moviestarOntoNS,
      'moviestar-data': moviestarDataNS,
      'sdo': movieNS,
      'xsd': xsdNS,
      'rdfs': rdfsNS,
      'owl': owlNS,
    };
  }
}