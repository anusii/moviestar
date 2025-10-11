/// OAuth helper functions for POD authentication.
///
/// This module provides OAuth-specific utilities including:
/// - Dynamic client registration
/// - Token exchange
/// - PKCE code generation and verification
/// - JWT token parsing
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

// ignore_for_file: avoid_print

library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:puppeteer/puppeteer.dart';

/// Registers an OAuth client dynamically with the Solid POD server.
///
/// Returns the client_id if successful, null otherwise.
Future<String?> registerOAuthClient(Page page) async {
  try {
    // Navigate to the registration endpoint.
    const registrationEndpoint = 'https://pods.dev.solidcommunity.au/.oidc/reg';

    // Prepare registration request.
    final registrationData = {
      'client_name': 'MovieStar E2E Test Client',
      'redirect_uris': ['http://localhost:44007/'],
      'response_types': ['code'], // Authorization code flow only
      'grant_types': ['authorization_code'],
      'scope': 'openid profile',
      'application_type': 'web',
      'token_endpoint_auth_method': 'none', // Public client (no client secret)
    };

    // Use fetch API to register client.
    final result = await page.evaluate(
      '''
        async (endpoint, data) => {
          try {
            const response = await fetch(endpoint, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
              },
              body: JSON.stringify(data),
            });

            if (!response.ok) {
              return { success: false, error: await response.text() };
            }

            const json = await response.json();
            return { success: true, data: json };
          } catch (err) {
            return { success: false, error: err.toString() };
          }
        }
      ''',
      args: [registrationEndpoint, registrationData],
    );

    if (result is Map && result['success'] == true) {
      final data = result['data'] as Map;
      return data['client_id']?.toString();
    } else {
      print('Client registration failed: ${result['error']}');
      return null;
    }
  } catch (e) {
    print('Error registering OAuth client: $e');
    return null;
  }
}

/// Exchanges authorization code for OAuth tokens.
///
/// Returns a map with success status and tokens/error.
Future<Map<String, dynamic>> exchangeCodeForTokens(
  Page page,
  String authorizationCode,
  String clientId,
  String codeVerifier,
) async {
  try {
    const tokenEndpoint = 'https://pods.dev.solidcommunity.au/.oidc/token';
    const redirectUri = 'http://localhost:44007/';

    // Prepare token request body.
    final tokenRequest = {
      'grant_type': 'authorization_code',
      'code': authorizationCode,
      'client_id': clientId,
      'code_verifier': codeVerifier,
      'redirect_uri': redirectUri,
    };

    // Use fetch API to exchange code for tokens.
    final result = await page.evaluate(
      '''
        async (endpoint, data) => {
          try {
            // Convert data to URL-encoded form
            const formBody = Object.keys(data)
              .map(key => encodeURIComponent(key) + '=' + encodeURIComponent(data[key]))
              .join('&');

            const response = await fetch(endpoint, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
              },
              body: formBody,
            });

            if (!response.ok) {
              const errorText = await response.text();
              return {
                success: false,
                error: 'HTTP ' + response.status + ': ' + errorText
              };
            }

            const json = await response.json();
            return { success: true, tokens: json };
          } catch (err) {
            return { success: false, error: err.toString() };
          }
        }
      ''',
      args: [tokenEndpoint, tokenRequest],
    );

    if (result is Map && result['success'] == true) {
      return {
        'success': true,
        'tokens': result['tokens'] as Map,
      };
    } else {
      return {
        'success': false,
        'error': result['error']?.toString() ?? 'Unknown error',
      };
    }
  } catch (e) {
    print('Error exchanging code for tokens: $e');
    return {
      'success': false,
      'error': e.toString(),
    };
  }
}

/// Extracts WebID from ID token JWT.
///
/// ID tokens are JWTs with 3 parts: header.payload.signature
/// The payload contains the webid claim (or sub claim as fallback).
String? extractWebIdFromIdToken(String idToken) {
  try {
    // Split JWT into parts.
    final parts = idToken.split('.');
    if (parts.length != 3) {
      print('Invalid ID token format');
      return null;
    }

    // Decode payload (base64url).
    final payload = parts[1];

    // Add padding if needed for base64 decoding.
    var normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
    while (normalized.length % 4 != 0) {
      normalized += '=';
    }

    // Decode base64.
    final decoded = utf8.decode(base64.decode(normalized));
    final json = jsonDecode(decoded) as Map<String, dynamic>;

    print('ID token payload: ${json.keys.toList()}');

    // Extract webid claim (or sub as fallback).
    final webId = json['webid'] as String? ?? json['sub'] as String?;
    return webId;
  } catch (e) {
    print('Error extracting WebID from ID token: $e');
    return null;
  }
}

/// Builds the OAuth authorization URL with proper parameters including PKCE.
String buildAuthorizationUrl(String clientId, String codeChallenge) {
  const authEndpoint = 'https://pods.dev.solidcommunity.au/.oidc/auth';
  const redirectUri = 'http://localhost:44007/';
  const responseType = 'code'; // Authorization code flow
  const scope = 'openid profile';

  // Generate a random state for CSRF protection.
  final state = DateTime.now().millisecondsSinceEpoch.toString();

  // Build the URL with proper encoding including PKCE parameters.
  final params = {
    'response_type': responseType,
    'client_id': clientId,
    'redirect_uri': redirectUri,
    'scope': scope,
    'state': state,
    'code_challenge': codeChallenge,
    'code_challenge_method': 'S256', // SHA-256
    'prompt': 'consent', // Force consent screen
  };

  final queryString = params.entries
      .map(
        (e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
      )
      .join('&');

  return '$authEndpoint?$queryString';
}

/// Generates a random code verifier for PKCE.
String generateCodeVerifier() {
  final random = Random.secure();
  final values = List<int>.generate(32, (i) => random.nextInt(256));
  return base64UrlEncode(values).replaceAll('=', '');
}

/// Generates a code challenge from the code verifier using SHA-256.
String generateCodeChallenge(String verifier) {
  final bytes = utf8.encode(verifier);
  final digest = sha256.convert(bytes);
  return base64UrlEncode(digest.bytes).replaceAll('=', '');
}
