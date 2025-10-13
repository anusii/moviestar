/// Helper for injecting test credentials into the app for E2E testing.
///
/// This allows E2E tests to run authenticated without manual login.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

// ignore_for_file: avoid_print

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solidpod/solidpod.dart';

import 'pod_auth_automator.dart';

/// Credentials loaded from test fixture file.
class TestCredentials {
  final String email;
  final String password;
  final String securityKey;
  final String webId;
  final String podUrl;
  final String issuer;

  TestCredentials({
    required this.email,
    required this.password,
    required this.securityKey,
    required this.webId,
    required this.podUrl,
    required this.issuer,
  });

  factory TestCredentials.fromJson(Map<String, dynamic> json) {
    return TestCredentials(
      email: json['email'] as String,
      password: json['password'] as String,
      securityKey: json['securityKey'] as String,
      webId: json['webId'] as String,
      podUrl: json['podUrl'] as String,
      issuer: json['issuer'] as String,
    );
  }
}

/// Injects test credentials for authenticated E2E testing.
class CredentialInjector {
  static const _credentialsPath =
      'integration_test/fixtures/test_credentials.json';
  static const _authTokensPath = 'integration_test/fixtures/auth_tokens.json';
  static const _completeAuthDataPath =
      'integration_test/fixtures/complete_auth_data.json';

  /// Storage key used by solidpod package to store complete auth data.
  static const _authDataSecureStorageKey = '_solid_auth_data';

  /// Loads test credentials from fixture file.
  static Future<TestCredentials> loadCredentials() async {
    try {
      // Try loading from file system first (for local development).
      final file = File(_credentialsPath);
      if (await file.exists()) {
        final contents = await file.readAsString();
        final json = jsonDecode(contents) as Map<String, dynamic>;
        return TestCredentials.fromJson(json);
      }
    } catch (e) {
      // If file system fails, try loading from assets.
      try {
        final contents = await rootBundle.loadString(_credentialsPath);
        final json = jsonDecode(contents) as Map<String, dynamic>;
        return TestCredentials.fromJson(json);
      } catch (e) {
        throw Exception(
          'Failed to load test credentials from $_credentialsPath: $e',
        );
      }
    }

    throw Exception('Test credentials file not found: $_credentialsPath');
  }

  /// Injects credentials into secure storage to simulate authenticated state.
  ///
  /// NOTE: This is a simplified approach. The solidpod package uses OAuth tokens
  /// which are obtained through browser authentication. For full E2E testing,
  /// you may need to:
  /// 1. Perform actual login flow once to get tokens
  /// 2. Extract and store those tokens
  /// 3. Inject stored tokens for subsequent test runs
  ///
  /// This method provides the basic WebID injection. Additional token injection
  /// may be needed depending on the solidpod package's internal storage structure.
  static Future<void> injectCredentials(TestCredentials credentials) async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
      mOptions: MacOsOptions(synchronizable: false),
    );

    // Store WebID (this is what the app checks first).
    await storage.write(key: 'webId', value: credentials.webId);

    // Store POD URL.
    await storage.write(key: 'podUrl', value: credentials.podUrl);

    // Store issuer.
    await storage.write(key: 'issuer', value: credentials.issuer);

    // Note: The solidpod package may use different keys for storing
    // OAuth tokens. You may need to inspect the package's implementation
    // or perform actual login and extract the keys it uses.
  }

  /// Loads OAuth tokens from auth_tokens.json file.
  ///
  /// These tokens are extracted using the token extraction tool:
  /// `dart run integration_test/tools/extract_tokens.dart`
  static Future<Map<String, dynamic>> loadAuthTokens() async {
    try {
      final file = File(_authTokensPath);
      if (!await file.exists()) {
        throw Exception(
          'Auth tokens file not found. Run: dart run integration_test/tools/extract_tokens.dart',
        );
      }

      final contents = await file.readAsString();
      return jsonDecode(contents) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load auth tokens from $_authTokensPath: $e');
    }
  }

  /// Injects real OAuth tokens from browser automation into storage.
  ///
  /// This uses tokens extracted by running the token extraction tool,
  /// which performs automated browser login to obtain real OAuth tokens.
  static Future<void> injectAuthTokens(Map<String, dynamic> tokens) async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
      mOptions: MacOsOptions(synchronizable: false),
    );

    print('Injecting OAuth tokens into secure storage...');

    // Inject core authentication data.
    final webId = tokens['webid'] as String?;
    if (webId != null && webId.isNotEmpty) {
      await storage.write(key: 'webId', value: webId);
      print('  ✓ webId: $webId');
    }

    final accessToken = tokens['access_token'] as String?;
    if (accessToken != null && accessToken.isNotEmpty) {
      await storage.write(key: 'accessToken', value: accessToken);
      print('  ✓ accessToken: ${accessToken.substring(0, 20)}...');
    }

    final idToken = tokens['id_token'] as String?;
    if (idToken != null && idToken.isNotEmpty) {
      await storage.write(key: 'idToken', value: idToken);
      print('  ✓ idToken: ${idToken.substring(0, 20)}...');
    }

    final refreshToken = tokens['refresh_token'] as String?;
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await storage.write(key: 'refreshToken', value: refreshToken);
      print('  ✓ refreshToken: ${refreshToken.substring(0, 20)}...');
    }

    final tokenType = tokens['token_type'] as String? ?? 'Bearer';
    await storage.write(key: 'tokenType', value: tokenType);

    final issuer = tokens['issuer'] as String?;
    if (issuer != null && issuer.isNotEmpty) {
      await storage.write(key: 'issuer', value: issuer);
      print('  ✓ issuer: $issuer');
    }

    // Calculate and store token expiry.
    final expiresIn = tokens['expires_in'] as int? ?? 3600;
    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    await storage.write(key: 'expiresAt', value: expiresAt.toIso8601String());
    print('  ✓ Token expires at: ${expiresAt.toIso8601String()}');

    // Store client_id for token refresh (if needed).
    final clientId = tokens['client_id'] as String?;
    if (clientId != null && clientId.isNotEmpty) {
      await storage.write(key: 'clientId', value: clientId);
    }

    // Extract POD URL from webId (everything before /profile/).
    if (webId != null && webId.contains('/profile/')) {
      final podUrl = webId.substring(0, webId.indexOf('/profile/'));
      await storage.write(key: 'podUrl', value: podUrl);
      print('  ✓ podUrl: $podUrl');
    }

    // Legacy support: handle old format with sessionStorage/localStorage.
    final sessionStorage = tokens['sessionStorage'] as Map<String, dynamic>?;
    if (sessionStorage != null) {
      final authResponse = sessionStorage['openidconnect_auth_response_info'];
      if (authResponse != null) {
        await storage.write(
          key: 'openidconnect_auth_response_info',
          value: authResponse.toString(),
        );
      }
    }

    print('✓ All OAuth tokens injected successfully');
  }

  /// Loads complete auth data from complete_auth_data.json file.
  ///
  /// This auth data is extracted using the complete auth extraction tool:
  /// `flutter run integration_test/tools/extract_complete_auth.dart -d windows`
  ///
  /// The complete auth data includes the full structure that solidpod's
  /// AuthDataManager expects, including RSA keys for DPoP token generation.
  static Future<Map<String, dynamic>> loadCompleteAuthData() async {
    try {
      final file = File(_completeAuthDataPath);
      if (!await file.exists()) {
        throw Exception(
          'Complete auth data file not found. Run: flutter run integration_test/tools/extract_complete_auth.dart -d windows',
        );
      }

      final contents = await file.readAsString();
      return jsonDecode(contents) as Map<String, dynamic>;
    } catch (e) {
      throw Exception(
        'Failed to load complete auth data from $_completeAuthDataPath: $e',
      );
    }
  }

  /// Injects complete auth data directly into secure storage.
  ///
  /// This method injects the COMPLETE auth data structure that was extracted
  /// from a real login session. This includes:
  /// - RSA keypair for DPoP token generation
  /// - Complete Credential object
  /// - Client metadata
  /// - Logout URL
  ///
  /// This is stored under the '_solid_auth_data' key that solidpod's
  /// AuthDataManager expects.
  static Future<void> injectCompleteAuthData(
    Map<String, dynamic> authData,
  ) async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
      mOptions: MacOsOptions(synchronizable: false),
    );

    print('Injecting complete auth data into secure storage...');

    // The auth data is already in the correct format from extraction.
    // We just need to serialize it and store it under the correct key.
    final authDataJson = jsonEncode(authData);

    await storage.write(
      key: _authDataSecureStorageKey,
      value: authDataJson,
    );

    print('  ✓ Stored complete auth data under $_authDataSecureStorageKey');
    print('  ✓ WebID: ${authData['web_id']}');
    print('  ✓ Contains RSA keys: ${authData.containsKey('rsa_info')}');
    print(
      '  ✓ Contains auth response: ${authData.containsKey('auth_response')}',
    );

    print('✓ Complete auth data injected successfully');
  }

  /// Full authentication injection using complete auth data.
  ///
  /// This is the NEW recommended approach for E2E testing with real POD auth.
  /// It injects the complete auth data structure including RSA keys for DPoP.
  ///
  /// To extract complete auth data:
  /// 1. Run: flutter run integration_test/tools/extract_complete_auth.dart -d windows
  /// 2. Log in through the app UI
  /// 3. Click EXTRACT button to save auth data
  /// 4. Run your E2E tests
  ///
  /// If [autoRegenerateOnFailure] is true, will fall back to the old
  /// token-based approach using browser automation if complete auth data
  /// is not available.
  static Future<void> injectFullAuth({
    bool autoRegenerateOnFailure = false,
  }) async {
    print('Loading complete auth data...');

    Map<String, dynamic> authData;
    try {
      // Try loading complete auth data first (NEW approach).
      authData = await loadCompleteAuthData();
      print('✓ Complete auth data loaded');

      // Inject the complete auth data structure.
      await injectCompleteAuthData(authData);

      print('✓ Full authentication injected successfully');
      return;
    } catch (e) {
      print('⚠ Complete auth data not found: $e');

      if (autoRegenerateOnFailure) {
        print('  Auto-regenerating with browser automation...');

        // Regenerate auth data (this saves both complete auth data and tokens)
        await _regenerateTokens();

        // Now try loading and injecting the complete auth data
        try {
          authData = await loadCompleteAuthData();
          await injectCompleteAuthData(authData);
          print(
              '✓ Complete auth data auto-regenerated and injected successfully');
          return;
        } catch (e) {
          // If complete auth data still fails, fall back to legacy tokens
          print('⚠ Failed to load complete auth data after regeneration: $e');
          print('  Falling back to legacy token injection...');

          final tokens = await loadAuthTokens();
          await injectAuthTokens(tokens);

          print('⚠ WARNING: Using legacy token injection. This may not work.');
          print('   POD operations may fail due to missing RSA keys.');
          return;
        }
      } else {
        rethrow;
      }
    }
  }

  /// Automatically regenerates auth data using browser automation.
  ///
  /// This performs automated login via Puppeteer and saves BOTH:
  /// - Complete auth data (with RSA keys) to complete_auth_data.json
  /// - Legacy tokens to auth_tokens.json (for backwards compatibility)
  static Future<Map<String, dynamic>> _regenerateTokens() async {
    print('🔄 Regenerating auth data using browser automation...');

    // Load test credentials
    final credentials = await loadCredentials();

    // Perform automated browser login
    print('  Authenticating with POD provider...');
    final result = await PodAuthAutomator.authenticate(
      email: credentials.email,
      password: credentials.password,
      securityKey: credentials.securityKey,
      headless: true,
    );

    if (!result.success || result.completeAuthData == null) {
      throw Exception(
        'Failed to regenerate auth data: ${result.error}',
      );
    }

    // Save complete auth data to file (NEW - includes RSA keys)
    print('  Saving complete auth data to $_completeAuthDataPath...');
    final completeAuthFile = File(_completeAuthDataPath);
    await completeAuthFile.parent.create(recursive: true);
    await completeAuthFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(result.completeAuthData),
    );

    // Also save legacy tokens for backwards compatibility
    print('  Saving legacy tokens to $_authTokensPath...');
    final tokensFile = File(_authTokensPath);
    await tokensFile.parent.create(recursive: true);
    await tokensFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(result.tokens),
    );

    print('✓ Complete auth data regenerated and saved successfully');
    return result.tokens!; // Return tokens for backwards compatibility
  }

  /// Performs programmatic login using test credentials.
  ///
  /// This is a more robust approach that performs actual authentication
  /// to obtain valid OAuth tokens.
  ///
  /// WARNING: This requires browser automation or headless browser support.
  /// Not yet implemented - see issue #283 for browser automation approach.
  static Future<void> performLogin(TestCredentials credentials) async {
    // TODO: Implement programmatic login with browser automation.
    // This would involve:
    // 1. Starting the OAuth flow
    // 2. Automating browser interactions (email, password, consent, security key)
    // 3. Capturing the redirect and extracting tokens
    // 4. The solidpod package should store these tokens automatically
    throw UnimplementedError(
      'Programmatic login requires browser automation - see issue #283',
    );
  }

  /// Clears injected credentials (for test cleanup).
  static Future<void> clearCredentials() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
      mOptions: MacOsOptions(synchronizable: false),
    );

    // Clear complete auth data (solidpod package's storage key).
    await storage.delete(key: _authDataSecureStorageKey);

    // Clear OAuth tokens (legacy).
    await storage.delete(key: 'webId');
    await storage.delete(key: 'accessToken');
    await storage.delete(key: 'idToken');
    await storage.delete(key: 'refreshToken');
    await storage.delete(key: 'tokenType');
    await storage.delete(key: 'expiresAt');
    await storage.delete(key: 'clientId');

    // Clear basic credentials.
    await storage.delete(key: 'podUrl');
    await storage.delete(key: 'issuer');

    // Clear OpenID Connect auth response.
    await storage.delete(key: 'openidconnect_auth_response_info');

    // Clear cookies.
    await storage.delete(key: 'cookies');

    // Note: We don't have a list of all session/local storage keys,
    // so those will remain until the app is restarted or storage is fully cleared.

    print('✓ Cleared all injected credentials and tokens');
  }

  /// Verifies that credentials are properly injected.
  static Future<bool> verifyInjection() async {
    try {
      final webId = await getWebId();
      return webId != null && webId.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
