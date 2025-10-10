/// Standalone tool to extract POD authentication tokens.
///
/// Run this script to perform automated POD login and save authentication
/// tokens for use in E2E tests.
///
/// Usage:
///   dart run integration_test/tools/extract_tokens.dart [--headless]
///
/// The tokens will be saved to integration_test/fixtures/auth_tokens.json
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'dart:convert';
import 'dart:io';

import '../helpers/pod_auth_automator.dart';

Future<void> main(List<String> args) async {
  final headless = !args.contains('--no-headless');

  print('=== POD Token Extraction Tool ===\n');
  print('This will perform automated POD login and extract auth tokens.');
  print('Headless mode: ${headless ? "ON" : "OFF"}');
  print('');

  try {
    // Perform authentication.
    print('Starting authentication...\n');
    final result = await PodAuthAutomator.authenticate(headless: headless);

    if (!result.success) {
      print('ERROR: Authentication failed!');
      print('Reason: ${result.error}');
      exit(1);
    }

    print('\n✓ Authentication successful!\n');

    // Save tokens to file.
    final tokensFile = File(
      'integration_test/fixtures/auth_tokens.json',
    );

    // Ensure directory exists.
    await tokensFile.parent.create(recursive: true);

    // Write tokens.
    final prettyJson = PodAuthAutomator.formatTokens(result.tokens!);
    await tokensFile.writeAsString(prettyJson);

    print('✓ Tokens saved to: ${tokensFile.path}\n');
    print('Token summary:');
    print('  - sessionStorage keys: ${(result.tokens!['sessionStorage'] as Map?)?.length ?? 0}');
    print('  - localStorage keys: ${(result.tokens!['localStorage'] as Map?)?.length ?? 0}');
    print('  - Cookies present: ${result.tokens!['cookies'] != null ? "Yes" : "No"}');

    // Check for OpenID Connect auth response.
    final hasAuthResponse = result.tokens!['openidconnect_auth_response'] != null;
    print('  - OpenID Connect response: ${hasAuthResponse ? "✓ Found" : "✗ Not found"}');

    if (!hasAuthResponse) {
      print('\n⚠ Warning: OpenID Connect auth response not found.');
      print('  This may mean authentication did not complete properly.');
      print('  Try running again with --no-headless to see what happened.');
    }

    print('\n✓ Token extraction complete!');
    print('');
    print('Next steps:');
    print('  1. Review the tokens in ${tokensFile.path}');
    print('  2. Run E2E tests: flutter test integration_test/');
    print('  3. The tokens will be automatically injected during test setup');
    print('');
  } catch (e, stackTrace) {
    print('\nERROR: Token extraction failed!');
    print('Error: $e');
    print('\nStack trace:');
    print(stackTrace);
    exit(1);
  }
}
