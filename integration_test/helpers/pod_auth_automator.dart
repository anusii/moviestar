/// Automated POD OAuth login using Puppeteer for E2E testing.
///
/// This script automates the Solid POD OAuth flow to obtain authentication
/// tokens without manual user interaction.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:puppeteer/puppeteer.dart';

import '../test_constants.dart';

/// Result of POD authentication automation.
class AuthResult {
  final bool success;
  final Map<String, dynamic>? tokens;
  final String? error;

  AuthResult({required this.success, this.tokens, this.error});
}

/// Automates Solid POD OAuth login flow using Puppeteer.
class PodAuthAutomator {
  /// Timeout for page loads and element waits (30 seconds).
  static const _timeout = Duration(seconds: 30);

  /// Automates full POD OAuth login and returns authentication tokens.
  ///
  /// This performs the complete OAuth flow:
  /// 1. Perform dynamic client registration (if needed)
  /// 2. Navigate to OAuth authorization endpoint
  /// 3. Enter email and password
  /// 4. Handle consent screen
  /// 5. Wait for callback redirect to localhost
  /// 6. Extract auth tokens from callback or browser storage
  ///
  /// Returns [AuthResult] with success status and tokens/error.
  static Future<AuthResult> authenticate({
    String? email,
    String? password,
    String? securityKey,
    bool headless = true,
  }) async {
    // Use test constants if not provided.
    final authEmail = email ?? TestConstants.testEmail;
    final authPassword = password ?? TestConstants.testPassword;
    final authSecurityKey = securityKey ?? TestConstants.testSecurityKey;

    Browser? browser;
    try {
      // Launch browser.
      browser = await puppeteer.launch(
        headless: headless,
        args: [
          '--no-sandbox',
          '--disable-setuid-sandbox',
          '--disable-dev-shm-usage',
        ],
      );

      final page = await browser.newPage();

      // Set a reasonable viewport.
      await page.setViewport(DeviceViewport(width: 1280, height: 720));

      // Set up OAuth callback interception early (before navigating).
      String? capturedCode;
      String? capturedState;

      await page.setRequestInterception(true);
      bool interceptorActive = true;

      page.onRequest.listen((request) async {
        if (!interceptorActive) return;

        final url = request.url;

        // Check if this is the callback to localhost.
        if (url.startsWith('http://localhost:44007')) {
          print('✓ Intercepted OAuth callback:');
          print('  Full URL: $url');

          // Parse the URL to extract code or error.
          final uri = Uri.parse(url);
          capturedCode = uri.queryParameters['code'];
          capturedState = uri.queryParameters['state'];

          // Check for error in callback.
          if (uri.queryParameters.containsKey('error')) {
            print('  ERROR in callback:');
            print('    error: ${uri.queryParameters['error']}');
            print('    error_description: ${uri.queryParameters['error_description']}');
          }

          // Abort the request since we don't have a server listening.
          try {
            await request.abort();
          } catch (e) {
            // Ignore abort errors
          }
        } else {
          // Allow other requests to proceed.
          try {
            await request.continueRequest();
          } catch (e) {
            // Ignore continue errors (request may have been handled)
          }
        }
      });

      // Perform dynamic client registration to get client_id.
      print('Registering OAuth client...');
      final clientId = await _registerOAuthClient(page);
      if (clientId == null) {
        return AuthResult(
          success: false,
          error: 'Failed to register OAuth client',
        );
      }
      print('✓ Client registered: $clientId');

      // Generate PKCE parameters.
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);
      print('✓ Generated PKCE challenge');

      // Construct OAuth authorization URL with PKCE.
      final authUrl = _buildAuthorizationUrl(clientId, codeChallenge);
      print('Navigating to OAuth authorization endpoint...');
      print('URL: ${authUrl.substring(0, 100)}...');

      await page.goto(
        authUrl,
        wait: Until.networkIdle,
        timeout: _timeout,
      );

      // Wait for login form to appear.
      print('Waiting for login form...');
      try {
        // Wait for email input field.
        await page.waitForSelector(
          'input[type="text"], input[name="email"]',
          timeout: _timeout,
        );
      } catch (e) {
        return AuthResult(
          success: false,
          error: 'Login form not found: $e',
        );
      }

      // Fill in email.
      print('Entering email...');
      await page.type(
        'input[type="text"], input[name="email"]',
        authEmail,
      );

      // Fill in password.
      print('Entering password...');
      await page.type(
        'input[type="password"], input[name="password"]',
        authPassword,
      );

      // Click login button.
      print('Clicking login button...');
      try {
        // Wait for and click the "Log in" button.
        await page.click('button[type="submit"]');
      } catch (e) {
        return AuthResult(
          success: false,
          error: 'Login button not found: $e',
        );
      }

      // Wait for navigation after login.
      print('Waiting for navigation after login...');
      await page.waitForNavigation(timeout: _timeout);

      // Add a small delay to let the page load.
      await Future.delayed(const Duration(seconds: 2));

      print('Current URL after login: ${page.url}');

      // Handle consent screen if present.
      print('Checking for consent screen...');
      if (page.url!.contains('/consent')) {
        print('Consent screen detected!');
        final hasConsent = await _handleConsentScreen(page);
        if (hasConsent) {
          print('Consent granted, waiting for navigation...');
          try {
            await page.waitForNavigation(timeout: _timeout);
          } catch (e) {
            print('Warning: Navigation timeout after consent: $e');
          }
        }
      } else {
        print('No consent screen found, proceeding...');
      }

      // Handle security key input if present.
      print('Checking for security key prompt...');
      final hasSecurityKey = await _handleSecurityKey(page, authSecurityKey);
      if (hasSecurityKey) {
        print('Security key entered, waiting for callback...');
      }

      // Wait for OAuth callback (capturedCode will be set by the request listener).
      print('Waiting for OAuth callback...');
      final startTime = DateTime.now();
      while (capturedCode == null) {
        await Future.delayed(const Duration(milliseconds: 500));

        // Check timeout.
        if (DateTime.now().difference(startTime) > _timeout) {
          return AuthResult(
            success: false,
            error: 'Timeout waiting for OAuth callback',
          );
        }
      }

      print('✓ OAuth callback received!');

      // Validate authorization code.
      final authorizationCode = capturedCode; // capturedCode is guaranteed non-null here
      if (authorizationCode == null || authorizationCode.isEmpty) {
        return AuthResult(
          success: false,
          error: 'No authorization code in callback',
        );
      }

      print('✓ Authorization code: ${authorizationCode.substring(0, 20)}...');

      // Disable request interceptor.
      interceptorActive = false;
      // Give it a moment to stop processing any pending requests
      await Future.delayed(const Duration(milliseconds: 500));
      await page.setRequestInterception(false);

      // Exchange authorization code for OAuth tokens.
      print('Exchanging authorization code for tokens...');
      final tokenResponse = await _exchangeCodeForTokens(
        page,
        authorizationCode,
        clientId,
        codeVerifier,
      );

      if (!tokenResponse['success']) {
        return AuthResult(
          success: false,
          error: 'Token exchange failed: ${tokenResponse['error']}',
        );
      }

      print('✓ Token exchange successful!');

      // Extract tokens from response.
      final oauthTokens = tokenResponse['tokens'] as Map<String, dynamic>;

      // Decode ID token to extract WebID.
      final idToken = oauthTokens['id_token'] as String?;
      String? webId;
      if (idToken != null) {
        webId = _extractWebIdFromIdToken(idToken);
        if (webId != null) {
          print('✓ Extracted WebID: $webId');
        }
      }

      // Build final tokens map.
      final tokens = <String, dynamic>{
        'access_token': oauthTokens['access_token'],
        'refresh_token': oauthTokens['refresh_token'],
        'id_token': oauthTokens['id_token'],
        'token_type': oauthTokens['token_type'] ?? 'Bearer',
        'expires_in': oauthTokens['expires_in'] ?? 3600,
        'webid': webId,
        'issuer': 'https://pods.dev.solidcommunity.au',
        'client_id': clientId,
        'authorization_code': authorizationCode, // Keep for reference
        'code_verifier': codeVerifier, // Keep for reference
      };

      if (capturedState != null) {
        tokens['state'] = capturedState;
      }

      if (tokens.isEmpty) {
        return AuthResult(
          success: false,
          error: 'No authentication tokens found in browser storage',
        );
      }

      print('Authentication successful!');
      return AuthResult(success: true, tokens: tokens);
    } catch (e, stackTrace) {
      print('Authentication failed: $e');
      print('Stack trace: $stackTrace');
      return AuthResult(
        success: false,
        error: 'Authentication failed: $e',
      );
    } finally {
      await browser?.close();
    }
  }

  /// Handles OAuth consent screen if present.
  static Future<bool> _handleConsentScreen(Page page) async {
    try {
      // Wait a moment for the consent screen to render.
      await Future.delayed(const Duration(seconds: 2));

      print('Looking for consent buttons...');

      // Try to find and click the "Yes" button.
      try {
        // Look for button with text "Yes" (case-insensitive).
        final buttons = await page.$$('button');
        print('Found ${buttons.length} buttons on page');

        for (final button in buttons) {
          final text = await page.evaluate('el => el.textContent', args: [button]);
          final textStr = text.toString().trim().toLowerCase();

          print('Button text: "$textStr"');

          if (textStr == 'yes' || textStr == 'allow' || textStr == 'authorize' || textStr == 'consent') {
            print('✓ Found consent button with text: "$text", clicking...');
            await button.click();
            return true;
          }
        }
      } catch (e) {
        print('Error finding consent button: $e');
      }

      // Alternative: try looking for input type=submit with "Yes" value.
      try {
        final submitInputs = await page.$$('input[type="submit"]');
        for (final input in submitInputs) {
          final value = await page.evaluate('el => el.value', args: [input]);
          final valueStr = value.toString().trim().toLowerCase();

          if (valueStr == 'yes' || valueStr == 'allow' || valueStr == 'authorize') {
            print('✓ Found consent input with value: "$value", clicking...');
            await input.click();
            return true;
          }
        }
      } catch (e) {
        print('Error checking submit inputs: $e');
      }

      // Last resort: try the first submit button.
      try {
        final submitButtons = await page.$$('button[type="submit"]');
        if (submitButtons.isNotEmpty) {
          print('Trying first submit button as fallback...');
          await submitButtons.first.click();
          return true;
        }
      } catch (e) {
        print('Error clicking submit button: $e');
      }

      print('No consent button found');
      return false;
    } catch (e) {
      print('Error handling consent screen: $e');
      return false;
    }
  }

  /// Handles security key input if present.
  static Future<bool> _handleSecurityKey(Page page, String securityKey) async {
    try {
      // Look for security key input.
      final securityKeySelectors = [
        'input[type="text"][placeholder*="key"]',
        'input[type="text"][placeholder*="security"]',
        'input[name="securityKey"]',
        'input[id="securityKey"]',
      ];

      for (final selector in securityKeySelectors) {
        try {
          await page.waitForSelector(selector, timeout: Duration(seconds: 2));
          await page.type(selector, securityKey);

          // Click submit button.
          await page.click('button[type="submit"]');
          return true;
        } catch (_) {
          // Try next selector.
        }
      }

      return false;
    } catch (e) {
      print('No security key prompt found or error handling it: $e');
      return false;
    }
  }

  /// Extracts authentication tokens from browser storage.
  static Future<Map<String, dynamic>> _extractAuthTokens(Page page) async {
    try {
      // Extract data from sessionStorage and localStorage.
      final storageData = await page.evaluate('''
        function() {
          var result = {
            sessionStorage: {},
            localStorage: {},
            cookies: document.cookie
          };

          // Get sessionStorage.
          for (var i = 0; i < sessionStorage.length; i++) {
            var key = sessionStorage.key(i);
            result.sessionStorage[key] = sessionStorage.getItem(key);
          }

          // Get localStorage.
          for (var i = 0; i < localStorage.length; i++) {
            var key = localStorage.key(i);
            result.localStorage[key] = localStorage.getItem(key);
          }

          return result;
        }
      ''');

      // Parse the result.
      final tokens = <String, dynamic>{};

      if (storageData is Map) {
        // Extract relevant auth data.
        final sessionStorage = storageData['sessionStorage'] as Map?;
        final localStorage = storageData['localStorage'] as Map?;
        final cookies = storageData['cookies'] as String?;

        if (sessionStorage != null) {
          tokens['sessionStorage'] = Map<String, dynamic>.from(sessionStorage);
        }

        if (localStorage != null) {
          tokens['localStorage'] = Map<String, dynamic>.from(localStorage);
        }

        if (cookies != null && cookies.isNotEmpty) {
          tokens['cookies'] = cookies;
        }

        // Extract OpenID Connect specific data.
        if (sessionStorage != null) {
          final authResponse = sessionStorage['openidconnect_auth_response_info'];
          if (authResponse != null) {
            tokens['openidconnect_auth_response'] = authResponse.toString();
          }
        }
      }

      return tokens;
    } catch (e) {
      print('Error extracting auth tokens: $e');
      return {};
    }
  }

  /// Pretty print tokens for debugging.
  static String formatTokens(Map<String, dynamic> tokens) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(tokens);
  }

  /// Exchanges authorization code for OAuth tokens.
  ///
  /// Returns a map with success status and tokens/error.
  static Future<Map<String, dynamic>> _exchangeCodeForTokens(
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
      final result = await page.evaluate('''
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
      ''', args: [tokenEndpoint, tokenRequest]);

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
  static String? _extractWebIdFromIdToken(String idToken) {
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

  /// Registers an OAuth client dynamically with the Solid POD server.
  ///
  /// Returns the client_id if successful, null otherwise.
  static Future<String?> _registerOAuthClient(Page page) async {
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
      final result = await page.evaluate('''
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
      ''', args: [registrationEndpoint, registrationData]);

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

  /// Builds the OAuth authorization URL with proper parameters including PKCE.
  static String _buildAuthorizationUrl(String clientId, String codeChallenge) {
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
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$authEndpoint?$queryString';
  }

  /// Generates a random code verifier for PKCE.
  static String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64UrlEncode(values).replaceAll('=', '');
  }

  /// Generates a code challenge from the code verifier using SHA-256.
  static String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }
}
