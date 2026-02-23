/// API key-specific Turtle serialization functionality.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Ashley Tang, Kevin Wang

library;

import 'package:rdflib/rdflib.dart';
import 'package:solidpod/solidpod.dart' show tripleMapToTurtle;

import 'package:moviestar/shared/utils/turtle/base_serializer.dart';
import 'package:moviestar/shared/utils/turtle/namespace_manager.dart';

/// Handles API key ↔ Turtle serialization operations.

class ApiKeyTurtleSerializer extends TurtleBaseSerializer {
  /// Creates an API key file in TTL format following the ontology structure.

  static String createApiKey(
    String apiKeyId,
    String apiKeyValue, {
    String source = 'TMDB',
  }) {
    final triples = <URIRef, Map<URIRef, dynamic>>{};

    // Create the API key resource.

    final apiKeyResource =
        TurtleNamespaceManager.moviestarDataNS.withAttr('ApiKey-$apiKeyId');
    triples[apiKeyResource] = {
      TurtleNamespaceManager.rdfType: [
        TurtleNamespaceManager.owlNS.withAttr('NamedIndividual'),
        TurtleNamespaceManager.apiKeyType,
      ],
      TurtleNamespaceManager.identifier: Literal(apiKeyId),
      TurtleNamespaceManager.keyValue: Literal(apiKeyValue),
      TurtleNamespaceManager.source: Literal(source),
      TurtleNamespaceManager.rdfsLabel:
          Literal('|filePath=moviestar/data/keys/ApiKey-$apiKeyId.ttl|'),
    };

    return tripleMapToTurtle(
      triples,
      bindNamespaces: TurtleNamespaceManager.getOntologyNamespaces(),
    );
  }
}
