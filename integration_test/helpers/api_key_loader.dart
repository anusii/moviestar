/// Helper to load TMDB API key from fixtures.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'dart:convert';
import 'dart:io';

/// Loads the TMDB API key from the fixtures file.
///
/// Returns the API key string, or throws an exception if the file
/// doesn't exist or is invalid.
Future<String> loadTmdbApiKey() async {
  final file = File('integration_test/fixtures/tmdb_api_key.json');

  if (!await file.exists()) {
    throw Exception(
      'TMDB API key file not found. Please create integration_test/fixtures/tmdb_api_key.json '
      'from the template file tmdb_api_key.json.template',
    );
  }

  final contents = await file.readAsString();
  final json = jsonDecode(contents) as Map<String, dynamic>;

  final apiKey = json['apiKey'] as String?;
  if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_TMDB_API_KEY_HERE') {
    throw Exception(
      'Invalid TMDB API key in integration_test/fixtures/tmdb_api_key.json. '
      'Please add your real TMDB API key.',
    );
  }

  return apiKey;
}
