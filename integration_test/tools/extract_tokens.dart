/// Standalone tool to extract POD authentication tokens.
///
/// ⚠️ DEPRECATED: This tool only extracts basic OAuth tokens, which is
/// insufficient for reliable E2E testing. The solidpod package requires
/// complete auth data including RSA keys for DPoP token generation.
///
/// PLEASE USE INSTEAD:
///   flutter run integration_test/tools/extract_complete_auth.dart -d windows
///
/// That tool extracts the COMPLETE auth data structure by performing a
/// real login through the app, ensuring all necessary components (RSA keys,
/// Credential object, Client metadata) are captured.
///
/// ---
///
/// Legacy usage (NOT RECOMMENDED):
///   dart run integration_test/tools/extract_tokens.dart [--headless]
///
/// The tokens will be saved to integration_test/fixtures/auth_tokens.json
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

// ignore_for_file: avoid_print

library;

import 'dart:io';

import '../helpers/pod_auth_automator.dart';

Future<void> main(List<String> args) async {
  final headless = !args.contains('--no-headless');

  print('=== POD Token Extraction Tool ===\n');
  print('⚠️  DEPRECATION WARNING ⚠️');
  print('This tool only extracts basic OAuth tokens, which is INSUFFICIENT');
  print('for reliable E2E testing with the solidpod package.');
  print('');
  print('PLEASE USE THE NEW TOOL INSTEAD:');
  print(
      '  flutter run integration_test/tools/extract_complete_auth.dart -d windows',);
  print('');
  print(
      'The new tool extracts COMPLETE auth data including RSA keys for DPoP.',);
  print(
      'Press Ctrl+C to cancel, or wait 5 seconds to continue with legacy extraction...',);
  print('');

  // Give user time to read and cancel.
  await Future.delayed(const Duration(seconds: 5));

  print('Continuing with legacy token extraction...');
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

    // Save legacy tokens to file (for backwards compatibility).
    final tokensFile = File(
      'integration_test/fixtures/auth_tokens.json',
    );

    // Ensure directory exists.
    await tokensFile.parent.create(recursive: true);

    // Write legacy tokens.
    final prettyTokensJson = PodAuthAutomator.formatTokens(result.tokens!);
    await tokensFile.writeAsString(prettyTokensJson);

    print('✓ Legacy tokens saved to: ${tokensFile.path}');

    // Save complete auth data (NEW - includes RSA keys).
    final completeAuthFile = File(
      'integration_test/fixtures/complete_auth_data.json',
    );

    // Write complete auth data.
    final prettyAuthJson =
        PodAuthAutomator.formatTokens(result.completeAuthData!);
    await completeAuthFile.writeAsString(prettyAuthJson);

    print('✓ Complete auth data saved to: ${completeAuthFile.path}');
    print('  (includes RSA keys for DPoP)\n');
    print('Token summary:');
    print(
      '  - sessionStorage keys: ${(result.tokens!['sessionStorage'] as Map?)?.length ?? 0}',
    );
    print(
      '  - localStorage keys: ${(result.tokens!['localStorage'] as Map?)?.length ?? 0}',
    );
    print(
      '  - Cookies present: ${result.tokens!['cookies'] != null ? "Yes" : "No"}',
    );

    // Check for OpenID Connect auth response.
    final hasAuthResponse =
        result.tokens!['openidconnect_auth_response'] != null;
    print(
      '  - OpenID Connect response: ${hasAuthResponse ? "✓ Found" : "✗ Not found"}',
    );

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
