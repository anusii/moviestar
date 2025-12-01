/// Shared authentication setup helpers for integration tests.
///
/// Provides common credential injection and cleanup patterns used
/// across authenticated E2E tests.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'credential_injector.dart';

/// Auto-regenerate credentials flag - centralized constant.
///
/// Control via dart-define flag for batch test compatibility:
/// - Default: true (auto-regenerate enabled for individual tests)
/// - Batch mode: `flutter test integration_test/ --dart-define=AUTO_REGENERATE=false`

const autoRegenerateCredentials = bool.fromEnvironment(
  'AUTO_REGENERATE',
  defaultValue: true,
);

/// Helper class for authenticated test setup and teardown.
///
/// Use in setUpAll/tearDownAll to inject and clean up POD credentials.
///
/// Example usage:
/// ```dart
/// group('My Authenticated Tests', () {
///   setUpAll(() async {
///     await AuthTestSetup.setUpAuth();
///   });
///
///   tearDownAll(() async {
///     await AuthTestSetup.tearDownAuth();
///   });
///
///   testWidgets('my test', (tester) async {
///     // Test code here - credentials are already injected
///   });
/// });
/// ```

class AuthTestSetup {
  /// Set up authentication by injecting credentials.
  ///
  /// Injects full authentication with automatic token regeneration
  /// if [autoRegenerateCredentials] is true and tokens are expired.
  ///
  /// Throws if credential injection fails.

  static Future<void> setUpAuth({
    bool? autoRegenerate,
  }) async {
    await CredentialInjector.injectFullAuth(
      autoRegenerateOnFailure: autoRegenerate ?? autoRegenerateCredentials,
    );

    // Verify injection was successful.

    final injected = await CredentialInjector.verifyInjection();
    expect(
      injected,
      isTrue,
      reason: 'Credential injection failed - WebID not found',
    );
  }

  /// Clean up authentication by clearing credentials and closing Hive.

  static Future<void> tearDownAuth() async {
    await CredentialInjector.clearCredentials();
    await Hive.close();
  }
}
