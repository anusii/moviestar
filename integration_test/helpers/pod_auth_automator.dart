/// Automated POD OAuth login using Puppeteer for E2E testing.
///
/// This script automates the Solid POD OAuth flow to obtain authentication
/// tokens without manual user interaction.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

// ignore_for_file: avoid_print

library;

import 'dart:convert';

import 'package:puppeteer/puppeteer.dart';

import 'browser_automation_helpers.dart';
import 'oauth_helpers.dart';

/// Result of POD authentication automation.
class AuthResult {
  final bool success;
  final Map<String, dynamic>? tokens;
  final Map<String, dynamic>? completeAuthData;
  final String? error;

  AuthResult({
    required this.success,
    this.tokens,
    this.completeAuthData,
    this.error,
  });
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
    required String email,
    required String password,
    required String securityKey,
    bool headless = true,
  }) async {

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
      await page.setViewport(const DeviceViewport(width: 1280, height: 720));

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
            print(
              '    error_description: ${uri.queryParameters['error_description']}',
            );
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
      final clientId = await registerOAuthClient(page);
      if (clientId == null) {
        return AuthResult(
          success: false,
          error: 'Failed to register OAuth client',
        );
      }
      print('✓ Client registered: $clientId');

      // Generate PKCE parameters.
      final codeVerifier = generateCodeVerifier();
      final codeChallenge = generateCodeChallenge(codeVerifier);
      print('✓ Generated PKCE challenge');

      // Construct OAuth authorization URL with PKCE.
      final authUrl = buildAuthorizationUrl(clientId, codeChallenge);
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

        // Add delay to let the login screen fully render (cosmetic).
        await Future.delayed(const Duration(seconds: 1));
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
        email,
      );

      // Fill in password.
      print('Entering password...');
      await page.type(
        'input[type="password"], input[name="password"]',
        password,
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
        final hasConsent = await handleConsentScreen(page);
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
      final hasSecurityKey = await handleSecurityKey(page, securityKey);
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
      final authorizationCode =
          capturedCode; // capturedCode is guaranteed non-null here
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
      final tokenResponse = await exchangeCodeForTokens(
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
        webId = extractWebIdFromIdToken(idToken);
        if (webId != null) {
          print('✓ Extracted WebID: $webId');
        }
      }

      // Generate RSA keypair for DPoP token generation.
      print('\nGenerating complete auth data structure...');
      final rsaInfo = await generateRsaKeyPair();

      // Build logout URL.
      const issuer = 'https://pods.dev.solidcommunity.au';
      const logoutUrl = '$issuer/logout';

      // Build Credential JSON structure (async - fetches issuer metadata).
      final credentialJson = await buildCredentialJson(
        oauthTokens: oauthTokens,
        clientId: clientId,
        issuer: issuer,
        authorizationCode: authorizationCode,
      );

      // Build complete auth data in AuthDataManager format.
      final completeAuthData = buildCompleteAuthData(
        webId: webId ?? 'unknown',
        logoutUrl: logoutUrl,
        rsaInfo: rsaInfo,
        credentialJson: credentialJson,
      );

      // Build legacy tokens map for backwards compatibility.
      final tokens = <String, dynamic>{
        'access_token': oauthTokens['access_token'],
        'refresh_token': oauthTokens['refresh_token'],
        'id_token': oauthTokens['id_token'],
        'token_type': oauthTokens['token_type'] ?? 'Bearer',
        'expires_in': oauthTokens['expires_in'] ?? 3600,
        'webid': webId,
        'issuer': issuer,
        'client_id': clientId,
        'authorization_code': authorizationCode, // Keep for reference
        'code_verifier': codeVerifier, // Keep for reference
      };

      if (capturedState != null) {
        tokens['state'] = capturedState;
      }

      print('\n✓ Authentication successful!');
      print('  - Basic tokens: ✓');
      print('  - Complete auth data: ✓ (includes RSA keys for DPoP)');

      return AuthResult(
        success: true,
        tokens: tokens,
        completeAuthData: completeAuthData,
      );
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

  /// Pretty print tokens for debugging.
  static String formatTokens(Map<String, dynamic> tokens) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(tokens);
  }
}
