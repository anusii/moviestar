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

  /// Full authentication injection using extracted OAuth tokens.
  ///
  /// This is the recommended approach for E2E testing with real POD auth.
  /// Run the token extraction tool first to generate auth_tokens.json.
  ///
  /// If [autoRegenerateOnFailure] is true, will automatically regenerate
  /// tokens using browser automation if the stored tokens are invalid.
  static Future<void> injectFullAuth({
    bool autoRegenerateOnFailure = false,
  }) async {
    print('Loading OAuth tokens...');

    Map<String, dynamic> tokens;
    try {
      tokens = await loadAuthTokens();
    } catch (e) {
      if (autoRegenerateOnFailure) {
        print('⚠ Auth tokens file not found, regenerating...');
        tokens = await _regenerateTokens();
      } else {
        rethrow;
      }
    }

    print('Injecting tokens into secure storage...');
    await injectAuthTokens(tokens);

    print('✓ Full authentication injected successfully');
  }

  /// Automatically regenerates OAuth tokens using browser automation.
  ///
  /// This performs automated login via Puppeteer and saves the tokens
  /// to auth_tokens.json for future use.
  static Future<Map<String, dynamic>> _regenerateTokens() async {
    print('🔄 Regenerating OAuth tokens using browser automation...');

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

    if (!result.success || result.tokens == null) {
      throw Exception(
        'Failed to regenerate OAuth tokens: ${result.error}',
      );
    }

    // Save tokens to file for future use
    print('  Saving tokens to $_authTokensPath...');
    final file = File(_authTokensPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(result.tokens),
    );

    print('✓ OAuth tokens regenerated and saved successfully');
    return result.tokens!;
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

    // Clear OAuth tokens.
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
