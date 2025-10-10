/// Extract OAuth tokens from FlutterSecureStorage after manual login.
///
/// This tool creates a simple integration test that reads authentication tokens
/// from the app's secure storage and saves them to auth_tokens.json.
///
/// Usage:
/// 1. First, manually login to the app using the emulator/device
/// 2. Keep the app open and authenticated
/// 3. Run this tool: flutter test integration_test/tools/extract_tokens_from_storage.dart
///
/// The tool will extract all auth-related data and save it to:
/// integration_test/fixtures/auth_tokens.json
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

// ignore_for_file: avoid_print

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moviestar/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Extract OAuth tokens from FlutterSecureStorage',
      (WidgetTester tester) async {
    // Start the app to initialize storage.
    app.main();
    await tester.pumpAndSettle();

    print('Extracting tokens from FlutterSecureStorage...');

    // Initialize secure storage with same options as the app.
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
    );

    // Read all keys from secure storage.
    final allKeys = await storage.readAll();

    if (allKeys.isEmpty) {
      print('ERROR: No data found in FlutterSecureStorage!');
      print('Please ensure you have logged in to the app first.');
      exit(1);
    }

    print('Found ${allKeys.length} keys in secure storage');

    // Build tokens structure similar to browser storage.
    final tokens = <String, dynamic>{
      'sessionStorage': <String, dynamic>{},
      'localStorage': <String, dynamic>{},
      'cookies': '',
      'secureStorage': <String, dynamic>{},
    };

    // Process all keys and organize them.
    for (final entry in allKeys.entries) {
      final key = entry.key;
      final value = entry.value;

      print('Found key: $key');

      // Store all keys in secureStorage section.
      tokens['secureStorage'][key] = value;

      // Special handling for OpenID Connect auth response.
      if (key == 'openidconnect_auth_response_info') {
        tokens['sessionStorage'][key] = value;
      }

      // Handle session storage keys (if prefixed).
      if (key.startsWith('session_')) {
        final actualKey = key.substring(8); // Remove 'session_' prefix
        tokens['sessionStorage'][actualKey] = value;
      }

      // Handle local storage keys (if prefixed).
      if (key.startsWith('local_')) {
        final actualKey = key.substring(6); // Remove 'local_' prefix
        tokens['localStorage'][actualKey] = value;
      }
    }

    // Check if we have OAuth tokens.
    final hasOAuthTokens = tokens['secureStorage'].isNotEmpty ||
        tokens['sessionStorage'].isNotEmpty;

    if (!hasOAuthTokens) {
      print('WARNING: No OAuth tokens found in secure storage!');
      print('The app may not be logged in, or tokens are stored differently.');
    }

    // Save to auth_tokens.json.
    final outputFile = File('integration_test/fixtures/auth_tokens.json');

    // Ensure directory exists.
    await outputFile.parent.create(recursive: true);

    // Write formatted JSON.
    const encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(tokens);
    await outputFile.writeAsString(jsonString);

    print('\n✓ Tokens extracted successfully!');
    print('Saved to: ${outputFile.path}');
    print('\nToken summary:');
    print('- Secure storage keys: ${tokens['secureStorage'].length}');
    print('- Session storage keys: ${tokens['sessionStorage'].length}');
    print('- Local storage keys: ${tokens['localStorage'].length}');

    // Print all keys for debugging.
    print('\nAll keys found:');
    for (final key in allKeys.keys) {
      print('  - $key');
    }

    expect(hasOAuthTokens, isTrue,
        reason: 'Expected to find OAuth tokens in secure storage',);
  });
}
