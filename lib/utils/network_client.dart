/// A utility class for handling HTTP requests with consistent error handling and configuration.
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
/// Authors: Kevin Wang, Ashley Tang

library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:moviestar/constants/timing_constants.dart';

/// Custom exception for network-related errors.

class NetworkException implements Exception {
  /// The error message.

  final String message;

  /// The HTTP status code, if applicable.

  final int? statusCode;

  /// Creates a new [NetworkException].

  NetworkException(this.message, {this.statusCode});

  @override
  String toString() =>
      'NetworkException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

/// A utility class for handling HTTP requests with consistent error handling and configuration.

class NetworkClient {
  /// The base URL for API requests.

  final String baseUrl;

  /// The API key to be included in requests.

  final String apiKey;

  /// The HTTP client instance.

  final http.Client _client;

  /// The default timeout duration for requests.

  static const Duration _timeout = NetworkTimingConstants.defaultTimeout;

  /// Creates a new [NetworkClient].

  NetworkClient({
    required this.baseUrl,
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Performs a GET request and returns the parsed JSON response.

  Future<Map<String, dynamic>> getJson(String endpoint) async {
    try {
      // Check if endpoint already has query parameters.

      final separator = endpoint.contains('?') ? '&' : '?';
      final url = '$baseUrl/$endpoint${separator}api_key=$apiKey';

      final response = await _client.get(Uri.parse(url)).timeout(_timeout);

      if (response.statusCode != 200) {}

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body) as Map<String, dynamic>;
        return jsonData;
      } else {
        throw NetworkException(
          'Failed to load data from $endpoint',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw NetworkException('Invalid response format: ${e.message}');
    } on Exception catch (e) {
      throw NetworkException('Unexpected error: ${e.toString()}');
    }
  }

  /// Performs a GET request and returns the parsed JSON response as a list.

  Future<List<dynamic>> getJsonList(String endpoint) async {
    final response = await getJson(endpoint);
    if (response.containsKey('results')) {
      return response['results'] as List<dynamic>;
    }
    throw NetworkException('Invalid response format: missing "results" field');
  }

  /// Closes the HTTP client.

  void dispose() {
    _client.close();
  }
}
