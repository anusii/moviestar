/// User profile-specific Turtle serialization functionality.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:rdflib/rdflib.dart';
import 'package:solidpod/solidpod.dart' show tripleMapToTurtle;

import 'package:moviestar/shared/utils/turtle/turtle_base_serializer.dart';
import 'package:moviestar/shared/utils/turtle/turtle_namespace_manager.dart';

/// Handles User profile ↔ Turtle serialization operations.
class UserProfileTurtleSerializer extends TurtleBaseSerializer {
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
      TurtleNamespaceManager.rdfType: [
        TurtleNamespaceManager.owlNS.withAttr('NamedIndividual'),
        TurtleNamespaceManager.userType,
      ],
      TurtleNamespaceManager.webId: Literal(
        userWebId,
        datatype: TurtleNamespaceManager.xsdNS.withAttr('anyURI'),
      ),
      TurtleNamespaceManager.rdfsLabel: Literal('|webID=$userWebId|'),
    };

    // Add API key if provided.
    if (apiKey != null && apiKey.isNotEmpty) {
      triples[userResource]![TurtleNamespaceManager.hasApiKey] =
          TurtleNamespaceManager.moviestarDataNS.withAttr('ApiKey-$apiKey');
    }

    // Add DOB if provided.
    if (dobString != null && dobString.isNotEmpty) {
      triples[userResource]![TurtleNamespaceManager.dob] = Literal(
        dobString,
        datatype: TurtleNamespaceManager.xsdNS.withAttr('date'),
      );
    }

    // Add gender if provided.
    if (genderString != null && genderString.isNotEmpty) {
      triples[userResource]![TurtleNamespaceManager.gender] =
          Literal(genderString);
    }

    // Add movie lists if provided.
    if (movieListIds != null && movieListIds.isNotEmpty) {
      final movieListRefs = movieListIds
          .map((id) =>
              TurtleNamespaceManager.moviestarDataNS.withAttr('MovieList-$id'))
          .toList();
      triples[userResource]![TurtleNamespaceManager.hasMovieList] =
          movieListRefs;
    }

    return tripleMapToTurtle(
      triples,
      bindNamespaces: TurtleNamespaceManager.getOntologyNamespaces(),
    );
  }
}