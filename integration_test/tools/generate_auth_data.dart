/// Standalone script to generate complete auth data using browser automation.
///
/// This script runs the POD OAuth automation to generate fresh auth data
/// and saves it to the fixtures directory.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import '../helpers/pod_auth_automator.dart';

Future<void> main() async {
  print('=== POD Auth Data Generation Tool ===\n');
  print('This tool will:');
  print('  1. Run browser automation to authenticate');
  print('  2. Generate complete auth data structure');
  print('  3. Save to integration_test/fixtures/complete_auth_data.json\n');

  try {
    // Run browser automation.
    print('Starting browser automation...');
    final result = await PodAuthAutomator.authenticate(headless: false);

    if (!result.success) {
      print('\n❌ Authentication failed: ${result.error}');
      exit(1);
    }

    print('\n✓ Authentication successful!');

    // Save complete auth data to fixture file.
    final fixtureFile = File(
      'integration_test/fixtures/complete_auth_data.json',
    );

    // Ensure fixtures directory exists.
    await fixtureFile.parent.create(recursive: true);

    // Write complete auth data.
    await fixtureFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(result.completeAuthData),
    );

    print('\n✓ Complete auth data saved to:');
    print('  ${fixtureFile.path}');
    print('\nYou can now run POD integration tests with this auth data.');
  } catch (e, stackTrace) {
    print('\n❌ Error: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}
