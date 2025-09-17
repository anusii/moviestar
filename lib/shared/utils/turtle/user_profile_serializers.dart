/// User Profile and API Key Serialization for Turtle format
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:rdflib/rdflib.dart';
import 'package:solidpod/solidpod.dart'
    show tripleMapToTurtle;

import 'package:moviestar/utils/turtle_serializer.dart';

/// Utility class for serializing/deserializing user profiles and API keys to/from Turtle format.
class UserProfileSerializers {
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
      TurtleSerializer.rdfType: [TurtleSerializer.owlNS.withAttr('NamedIndividual'), TurtleSerializer.userType],
      TurtleSerializer.webId: Literal(userWebId, datatype: TurtleSerializer.xsdNS.withAttr('anyURI')),
      TurtleSerializer.rdfsLabel: Literal('|webID=$userWebId|'),
    };

    // Add API key if provided.
    if (apiKey != null && apiKey.isNotEmpty) {
      triples[userResource]![TurtleSerializer.hasApiKey] = TurtleSerializer.moviestarDataNS.withAttr(
        'ApiKey-$apiKey',
      );
    }

    // Add DOB if provided.
    if (dobString != null && dobString.isNotEmpty) {
      triples[userResource]![TurtleSerializer.dob] = Literal(
        dobString,
        datatype: TurtleSerializer.xsdNS.withAttr('date'),
      );
    }

    // Add gender if provided.
    if (genderString != null && genderString.isNotEmpty) {
      triples[userResource]![TurtleSerializer.gender] = Literal(genderString);
    }

    // Add movie lists if provided.
    if (movieListIds != null && movieListIds.isNotEmpty) {
      final movieListRefs = movieListIds
          .map((id) => TurtleSerializer.moviestarDataNS.withAttr('MovieList-$id'))
          .toList();
      triples[userResource]![TurtleSerializer.hasMovieList] = movieListRefs;
    }

    // Use ontology-compliant namespace bindings.
    return tripleMapToTurtle(triples, bindNamespaces: TurtleSerializer.getOntologyNamespaces());
  }

  /// Creates an API key file in TTL format following the ontology structure.
  static String createApiKey(
    String apiKeyId,
    String apiKeyValue, {
    String source = 'TMDB',
  }) {
    final triples = <URIRef, Map<URIRef, dynamic>>{};

    // Create the API key resource.
    final apiKeyResource = TurtleSerializer.moviestarDataNS.withAttr('ApiKey-$apiKeyId');
    triples[apiKeyResource] = {
      TurtleSerializer.rdfType: [TurtleSerializer.owlNS.withAttr('NamedIndividual'), TurtleSerializer.apiKeyType],
      TurtleSerializer.identifier: Literal(apiKeyId),
      TurtleSerializer.keyValue: Literal(apiKeyValue),
      TurtleSerializer.source: Literal(source),
      TurtleSerializer.rdfsLabel: Literal('|filePath=moviestar/data/keys/ApiKey-$apiKeyId.ttl|'),
    };

    // Use ontology-compliant namespace bindings.
    return tripleMapToTurtle(triples, bindNamespaces: TurtleSerializer.getOntologyNamespaces());
  }

  /// Generates a unique ID for resources.
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (1000 + (DateTime.now().microsecond % 9000)).toString();
  }
}