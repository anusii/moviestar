/// Discover OAuth parameters by intercepting the callback.
///
/// This tool starts a local HTTP server on localhost:44007 to capture
/// the OAuth callback when you manually login to the app.
///
/// Usage:
/// 1. Run this script: dart run integration_test/tools/discover_oauth_params.dart
/// 2. Launch the MovieStar app manually (on emulator or device)
/// 3. Click the Login button in the app
/// 4. Complete the login in the browser
/// 5. This script will capture the callback and display OAuth parameters
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

// ignore_for_file: avoid_print

library;

import 'dart:io';

Future<void> main() async {
  print('=== OAuth Parameter Discovery Tool ===\n');
  print('Starting HTTP server on localhost:44007...');

  try {
    // Start HTTP server on port 44007 (same as app's redirect_uri).
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 44007);
    print('✓ Server started on http://localhost:44007\n');

    print('Instructions:');
    print('1. Launch the MovieStar app');
    print('2. Click the Login button');
    print('3. Complete login in the browser');
    print('4. The OAuth callback will be captured here\n');
    print('Waiting for OAuth callback...\n');

    // Listen for incoming requests.
    await for (final request in server) {
      final uri = request.uri;

      print('═══════════════════════════════════════════════════════');
      print('✓ OAuth Callback Received!');
      print('═══════════════════════════════════════════════════════\n');

      // Print the full callback URL.
      print('Full Callback URL:');
      print('  ${uri.toString()}\n');

      // Extract and display query parameters.
      if (uri.queryParameters.isNotEmpty) {
        print('Query Parameters:');
        uri.queryParameters.forEach((key, value) {
          print('  $key: $value');
        });
        print('');
      }

      // Check for authorization code.
      if (uri.queryParameters.containsKey('code')) {
        print('✓ Authorization Code Found:');
        print('  ${uri.queryParameters['code']}\n');
      }

      // Check for tokens (implicit flow).
      if (uri.fragment.isNotEmpty) {
        print('Fragment Parameters (Implicit Flow):');
        print('  ${uri.fragment}\n');
      }

      // Check for state parameter.
      if (uri.queryParameters.containsKey('state')) {
        print('State Parameter:');
        print('  ${uri.queryParameters['state']}\n');
      }

      // Send response back to browser.
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write('''
<!DOCTYPE html>
<html>
<head>
  <title>Authentication Complete</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      text-align: center;
      padding: 50px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
    }
    .message {
      background: rgba(255, 255, 255, 0.1);
      padding: 30px;
      border-radius: 10px;
      max-width: 500px;
      margin: 0 auto;
    }
    h1 { margin-bottom: 20px; }
    p { font-size: 18px; }
  </style>
</head>
<body>
  <div class="message">
    <h1>✓ OAuth Callback Captured!</h1>
    <p>The callback has been intercepted by the discovery tool.</p>
    <p>You can close this window now.</p>
    <p>Check the terminal for OAuth parameters.</p>
  </div>
</body>
</html>
''');
      await request.response.close();

      // Now analyze what we learned.
      print('═══════════════════════════════════════════════════════');
      print('Analysis:');
      print('═══════════════════════════════════════════════════════\n');

      if (uri.queryParameters.containsKey('code')) {
        print('OAuth Flow Type: Authorization Code Flow');
        print('  - The app uses authorization code exchange');
        print('  - Browser redirects with "code" parameter');
        print('  - App exchanges code for tokens server-side\n');
      } else if (uri.fragment.contains('access_token')) {
        print('OAuth Flow Type: Implicit Flow');
        print('  - Tokens are returned directly in URL fragment');
        print('  - No server-side code exchange needed\n');
      }

      print('Next Steps:');
      print('  1. Note the callback structure above');
      print('  2. The OAuth flow uses redirect_uri: http://localhost:44007');
      print('  3. We need to initiate this flow in pod_auth_automator.dart');
      print('  4. To get the authorization URL, check browser dev tools');
      print('     when you click Login (Network tab → first request)\n');

      print('To capture the full OAuth authorization URL:');
      print('  1. Open browser dev tools (F12)');
      print('  2. Go to Network tab');
      print('  3. Click Login in the app');
      print('  4. Look for the first request to pods.dev.solidcommunity.au');
      print('  5. The URL will contain all OAuth parameters\n');

      // Keep server running for a bit in case there are more requests.
      print('Keeping server running for 30 seconds...');
      await Future.delayed(const Duration(seconds: 30));

      print('\n✓ Discovery complete! Shutting down server...');
      await server.close();
      break;
    }
  } catch (e) {
    print('ERROR: Failed to start server: $e');
    print('\nPossible issues:');
    print('  - Port 44007 may already be in use');
    print('  - Try closing the MovieStar app and running again');
    exit(1);
  }
}
