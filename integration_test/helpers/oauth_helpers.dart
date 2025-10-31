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
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:puppeteer/puppeteer.dart';

/// Registers an OAuth client dynamically with the Solid POD server.
///
/// Returns the client_id if successful, null otherwise.
Future<String?> registerOAuthClient(Page page) async {
  try {
    // Navigate to the registration endpoint.
    const registrationEndpoint =
        'https://pods.dev.solidcommunity.au/' '.oidc/reg';

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

/// Generates an RSA keypair for DPoP token generation.
///
/// Returns a map containing:
/// - 'rsa': AsymmetricKeyPair object (from pointycastle)
/// - 'pubKeyJwk': Public key in JWK format
/// - 'prvKeyJwk': Private key in JWK format
Future<Map<String, dynamic>> generateRsaKeyPair() async {
  print('Generating RSA keypair for DPoP...');

  // Generate 2048-bit RSA keypair using pointycastle.
  final keyGen = RSAKeyGenerator()
    ..init(
      ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
        FortunaRandom()..seed(KeyParameter(_generateRandomBytes(32))),
      ),
    );

  final keyPair = keyGen.generateKeyPair();
  final publicKey = keyPair.publicKey;
  final privateKey = keyPair.privateKey;

  // Convert to JWK format.
  final publicKeyJwk = _rsaPublicKeyToJwk(publicKey);
  final privateKeyJwk = _rsaPrivateKeyToJwk(privateKey);

  // Add algorithm.
  publicKeyJwk['alg'] = 'RS256';
  privateKeyJwk['alg'] = 'RS256';

  print('✓ RSA keypair generated');

  return {
    'rsa': keyPair,
    'pubKeyJwk': publicKeyJwk,
    'prvKeyJwk': privateKeyJwk,
  };
}

/// Generates random bytes for seeding the random number generator.
Uint8List _generateRandomBytes(int length) {
  final random = Random.secure();
  final bytes = Uint8List(length);
  for (var i = 0; i < length; i++) {
    bytes[i] = random.nextInt(256);
  }
  return bytes;
}

/// Converts an RSA public key to JWK format.
Map<String, dynamic> _rsaPublicKeyToJwk(RSAPublicKey publicKey) {
  return {
    'kty': 'RSA',
    'n': _base64UrlEncode(publicKey.modulus!),
    'e': _base64UrlEncode(publicKey.exponent!),
  };
}

/// Converts an RSA private key to JWK format.
Map<String, dynamic> _rsaPrivateKeyToJwk(RSAPrivateKey privateKey) {
  return {
    'kty': 'RSA',
    'n': _base64UrlEncode(privateKey.modulus!),
    'e': _base64UrlEncode(privateKey.exponent!),
    'd': _base64UrlEncode(privateKey.privateExponent!),
    'p': _base64UrlEncode(privateKey.p!),
    'q': _base64UrlEncode(privateKey.q!),
  };
}

/// Encodes a BigInt to base64url format for JWK.
String _base64UrlEncode(BigInt value) {
  final bytes = _bigIntToBytes(value);
  return base64UrlEncode(bytes).replaceAll('=', '');
}

/// Converts a BigInt to bytes.
Uint8List _bigIntToBytes(BigInt value) {
  final hex = value.toRadixString(16);
  final paddedHex = hex.length.isOdd ? '0$hex' : hex;
  final bytes = Uint8List(paddedHex.length ~/ 2);
  for (var i = 0; i < paddedHex.length; i += 2) {
    bytes[i ~/ 2] = int.parse(paddedHex.substring(i, i + 2), radix: 16);
  }
  return bytes;
}

/// Builds a Credential-compatible JSON structure from OAuth tokens.
///
/// This creates the EXACT structure that solidpod's AuthDataManager expects.
/// Format must match what manual extraction creates.
Future<Map<String, dynamic>> buildCredentialJson({
  required Map<String, dynamic> oauthTokens,
  required String clientId,
  required String issuer,
  required String authorizationCode,
}) async {
  print('Building Credential JSON structure...');

  // Calculate expires_at timestamp (Unix timestamp in seconds)
  final expiresIn = (oauthTokens['expires_in'] as int?) ?? 3600;
  final now = DateTime.now();
  final expiresAt = now.add(Duration(seconds: expiresIn));
  final expiresAtUnix = (expiresAt.millisecondsSinceEpoch / 1000).round();

  // Fetch issuer metadata from well-known endpoint
  print('  Fetching issuer metadata...');
  final issuerMetadata = await _fetchIssuerMetadata(issuer);

  // Build the credential JSON in the format solidpod expects
  final credentialJson = {
    'issuer': issuerMetadata,
    'client_id': clientId,
    'client_secret': null, // Public client (no client secret)
    'token': {
      'expires_at': expiresAtUnix,
      'access_token': oauthTokens['access_token'],
      'expires_in': expiresIn,
      'id_token': oauthTokens['id_token'],
      'refresh_token': oauthTokens['refresh_token'],
      'scope': oauthTokens['scope'] ?? '',
      'token_type': oauthTokens['token_type'] ?? 'DPoP',
    },
    'nonce': null,
  };

  print('✓ Credential JSON built');
  print(
    '  ✓ Token expires at: ${expiresAt.toIso8601String()} (Unix: $expiresAtUnix)',
  );

  return credentialJson;
}

/// Fetches issuer metadata from the OpenID Connect discovery endpoint.
Future<Map<String, dynamic>> _fetchIssuerMetadata(String issuerUrl) async {
  // Return the well-known issuer metadata for Solid POD
  // This should be fetched from ${issuerUrl}.well-known/openid-configuration
  // For now, return a static structure that matches the format
  return {
    'authorization_endpoint': '$issuerUrl.oidc/auth',
    'claims_parameter_supported': true,
    'claims_supported': ['azp', 'sub', 'webid', 'sid', 'auth_time', 'iss'],
    'code_challenge_methods_supported': ['S256'],
    'end_session_endpoint': '$issuerUrl.oidc/session/end',
    'grant_types_supported': [
      'implicit',
      'authorization_code',
      'refresh_token',
      'client_credentials',
    ],
    'issuer': issuerUrl,
    'jwks_uri': '$issuerUrl.oidc/jwks',
    'registration_endpoint': '$issuerUrl.oidc/reg',
    'authorization_response_iss_parameter_supported': true,
    'response_modes_supported': ['form_post', 'fragment', 'query'],
    'response_types_supported': ['code id_token', 'code', 'id_token', 'none'],
    'scopes_supported': ['openid', 'profile', 'offline_access', 'webid'],
    'subject_types_supported': ['public'],
    'token_endpoint_auth_methods_supported': [
      'client_secret_basic',
      'client_secret_jwt',
      'client_secret_post',
      'private_key_jwt',
      'none',
    ],
    'token_endpoint_auth_signing_alg_values_supported': [
      'HS256',
      'RS256',
      'PS256',
      'ES256',
      'EdDSA',
    ],
    'token_endpoint': '$issuerUrl.oidc/token',
    'id_token_signing_alg_values_supported': ['ES256'],
    'pushed_authorization_request_endpoint': '$issuerUrl.oidc/request',
    'request_parameter_supported': false,
    'request_uri_parameter_supported': false,
    'introspection_endpoint': '$issuerUrl.oidc/token/introspection',
    'dpop_signing_alg_values_supported': [
      'RS256',
      'RS384',
      'RS512',
      'PS256',
      'PS384',
      'PS512',
      'ES256',
      'ES256K',
      'ES384',
      'ES512',
      'EdDSA',
    ],
    'revocation_endpoint': '$issuerUrl.oidc/token/revocation',
    'claim_types_supported': ['normal'],
  };
}

/// Builds the complete auth data structure for AuthDataManager.
///
/// This creates the exact format that AuthDataManager stores in secure storage
/// under the '_solid_auth_data' key.
Map<String, dynamic> buildCompleteAuthData({
  required String webId,
  required String logoutUrl,
  required Map<String, dynamic> rsaInfo,
  required Map<String, dynamic> credentialJson,
}) {
  print('Building complete auth data structure...');

  // AuthDataManager expects this format:
  // {
  //   'web_id': String,
  //   'logout_url': String,
  //   'rsa_info': jsonEncode({...}),
  //   'auth_response': Credential.toJson(),
  // }

  // Extract RSA keypair and serialize it.
  final keyPair = rsaInfo['rsa'] as AsymmetricKeyPair;
  final publicKey = keyPair.publicKey as RSAPublicKey;
  final privateKey = keyPair.privateKey as RSAPrivateKey;

  final completeAuthData = {
    'web_id': webId,
    'logout_url': logoutUrl,
    'rsa_info': jsonEncode({
      ...rsaInfo,
      // Override 'rsa' with serialized format compatible with fast_rsa.
      'rsa': {
        'public_key': _serializePublicKey(publicKey),
        'private_key': _serializePrivateKey(privateKey),
      },
    }),
    'auth_response': credentialJson,
  };

  print('✓ Complete auth data structure built');
  print('  - WebID: $webId');
  print('  - Logout URL: $logoutUrl');
  print('  - RSA keys: included');
  print('  - Auth response: included');

  return completeAuthData;
}

/// Serializes an RSA public key to PEM format.
String _serializePublicKey(RSAPublicKey publicKey) {
  final algorithmSeq = ASN1Sequence();
  // OID for rsaEncryption: 1.2.840.113549.1.1.1
  algorithmSeq.add(ASN1ObjectIdentifier([1, 2, 840, 113549, 1, 1, 1]));
  algorithmSeq.add(ASN1Null());

  final publicKeySeq = ASN1Sequence();
  publicKeySeq.add(ASN1Integer(publicKey.modulus!));
  publicKeySeq.add(ASN1Integer(publicKey.exponent!));

  final publicKeyBitString = ASN1BitString(publicKeySeq.encodedBytes);

  final topLevelSeq = ASN1Sequence();
  topLevelSeq.add(algorithmSeq);
  topLevelSeq.add(publicKeyBitString);

  final dataBase64 = base64.encode(topLevelSeq.encodedBytes);
  final chunks = <String>[];
  for (var i = 0; i < dataBase64.length; i += 64) {
    final end = (i + 64 < dataBase64.length) ? i + 64 : dataBase64.length;
    chunks.add(dataBase64.substring(i, end));
  }

  return '-----BEGIN PUBLIC KEY-----\n${chunks.join('\n')}\n-----END PUBLIC KEY-----';
}

/// Serializes an RSA private key to PEM format.
String _serializePrivateKey(RSAPrivateKey privateKey) {
  final version = ASN1Integer(BigInt.zero);
  final modulus = ASN1Integer(privateKey.modulus!);
  final publicExponent = ASN1Integer(privateKey.exponent!);
  final privateExponent = ASN1Integer(privateKey.privateExponent!);
  final p = ASN1Integer(privateKey.p!);
  final q = ASN1Integer(privateKey.q!);

  final dP = privateKey.privateExponent! % (privateKey.p! - BigInt.one);
  final dQ = privateKey.privateExponent! % (privateKey.q! - BigInt.one);
  final iQ = privateKey.q!.modInverse(privateKey.p!);

  final seq = ASN1Sequence();
  seq.add(version);
  seq.add(modulus);
  seq.add(publicExponent);
  seq.add(privateExponent);
  seq.add(p);
  seq.add(q);
  seq.add(ASN1Integer(dP));
  seq.add(ASN1Integer(dQ));
  seq.add(ASN1Integer(iQ));

  final dataBase64 = base64.encode(seq.encodedBytes);
  final chunks = <String>[];
  for (var i = 0; i < dataBase64.length; i += 64) {
    final end = (i + 64 < dataBase64.length) ? i + 64 : dataBase64.length;
    chunks.add(dataBase64.substring(i, end));
  }

  return '-----BEGIN PRIVATE KEY-----\n${chunks.join('\n')}\n-----END PRIVATE KEY-----';
}
