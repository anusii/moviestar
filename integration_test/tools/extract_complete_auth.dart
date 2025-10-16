/// Tool to extract complete POD authentication data from secure storage.
///
/// This tool performs a REAL login through the MovieStar app and then
/// extracts the complete authentication data structure from secure storage.
///
/// Usage:
///   flutter run integration_test/tools/extract_complete_auth.dart -d windows
///
/// Instructions:
///   1. The app will launch and show the login screen
///   2. Manually log in with your POD credentials
///   3. Once logged in, press 'e' in the terminal to extract auth data
///   4. The complete auth data will be saved to:
///      integration_test/fixtures/complete_auth_data.json
///
/// This approach ensures we capture the EXACT auth structure that the
/// solidpod package creates and stores, including:
/// - RSA keypair for DPoP token generation
/// - Complete Credential object
/// - Client metadata
/// - Logout URL
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

// ignore_for_file: avoid_print, invalid_use_of_visible_for_testing_member

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moviestar/core/services/cache/settings_service.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/moviestar.dart';
import 'package:moviestar/providers/theme_provider.dart';
import 'package:moviestar/utils/is_logged_in.dart';

/// Storage key used by solidpod package to store complete auth data.
const String _authDataKey = '_solid_auth_data';

/// Output file for complete auth data.
const String _outputPath = 'integration_test/fixtures/complete_auth_data.json';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('=== POD Complete Auth Data Extraction Tool ===\n');
  print('This tool will:');
  print('  1. Launch the MovieStar app');
  print('  2. Wait for you to log in manually');
  print('  3. Extract complete auth data from secure storage');
  print('  4. Save it to $_outputPath');
  print('');

  // Initialize app dependencies.
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await CacheSettingsService.instance.initialize();
  await Hive.initFlutter();
  Hive.registerAdapter(MovieAdapter());
  Hive.registerAdapter(CustomListAdapter());
  Hive.registerAdapter(ContentItemAdapter());
  Hive.registerAdapter(ContentTypeAdapter());

  // Start listening for keyboard input in a separate isolate.
  _startKeyboardListener();

  // Run the app.
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const _AuthExtractionApp(),
    ),
  );
}

/// Custom app widget with extraction UI overlay.
class _AuthExtractionApp extends StatefulWidget {
  const _AuthExtractionApp();

  @override
  State<_AuthExtractionApp> createState() => _AuthExtractionAppState();
}

class _AuthExtractionAppState extends State<_AuthExtractionApp> {
  bool _isLoggedIn = false;
  String _status = 'Checking login status...';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    // Set up periodic checking for login status.
    Future.delayed(const Duration(seconds: 2), _periodicCheck);
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await isLoggedIn();
    if (mounted) {
      setState(() {
        _isLoggedIn = loggedIn;
        _status = loggedIn
            ? 'Logged in! Press EXTRACT button or \'e\' key to extract auth data.'
            : 'Please log in to your POD...';
      });
    }
  }

  void _periodicCheck() {
    if (!mounted) return;
    _checkLoginStatus();
    Future.delayed(const Duration(seconds: 2), _periodicCheck);
  }

  Future<void> _extractAuthData() async {
    setState(() {
      _status = 'Extracting auth data...';
    });

    try {
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock,
        ),
        mOptions: MacOsOptions(synchronizable: false),
      );

      // Read the complete auth data from secure storage.
      final authDataStr = await storage.read(key: _authDataKey);

      if (authDataStr == null || authDataStr.isEmpty) {
        setState(() {
          _status = 'ERROR: No auth data found in secure storage.\n'
              'Make sure you are logged in.';
        });
        return;
      }

      print('\n✓ Auth data found in secure storage!');
      print('  Length: ${authDataStr.length} characters');

      // Parse and pretty-print the data.
      final authData = jsonDecode(authDataStr) as Map<String, dynamic>;
      print('  Contains keys: ${authData.keys.join(', ')}');

      // Save to file.
      final file = File(_outputPath);
      await file.parent.create(recursive: true);
      final prettyJson = const JsonEncoder.withIndent('  ').convert(authData);
      await file.writeAsString(prettyJson);

      print('\n✓ Complete auth data saved to: $_outputPath');
      print('\nAuth data structure:');
      print('  - web_id: ${authData['web_id']}');
      print('  - logout_url: ${authData['logout_url']}');
      print(
        '  - rsa_info: ${(authData['rsa_info'] as String).length} characters',
      );
      print(
        '  - auth_response: ${(authData['auth_response'] as Map).length} keys',
      );

      print('\n✓ Extraction complete!');
      print('You can now close the app and run E2E tests.');
      print('');

      if (mounted) {
        setState(() {
          _status = 'SUCCESS! Auth data saved to $_outputPath\n'
              'You can now close the app.';
        });
      }
    } catch (e, stackTrace) {
      print('\n✗ ERROR: Failed to extract auth data');
      print('Error: $e');
      print('\nStack trace:');
      print(stackTrace);

      if (mounted) {
        setState(() {
          _status = 'ERROR: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Stack(
        children: [
          // The actual MovieStar app.
          const MovieStar(),

          // Overlay with extraction UI.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.black87,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Auth Data Extraction Tool',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: TextStyle(
                        color: _status.startsWith('ERROR')
                            ? Colors.red
                            : _status.startsWith('SUCCESS')
                                ? Colors.green
                                : Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoggedIn && !_status.startsWith('SUCCESS'))
                      ElevatedButton(
                        onPressed: _extractAuthData,
                        child: const Text('EXTRACT AUTH DATA'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Starts a keyboard listener in the background to detect 'e' key press.
void _startKeyboardListener() {
  // Note: This is a simplified version. In a real implementation,
  // you might want to use stdin.listen() but that requires running
  // in console mode which doesn't work well with Flutter GUI apps.
  //
  // The UI button is the primary way to extract, but we keep this
  // as a placeholder for potential future enhancement.
  print('');
  print('INSTRUCTIONS:');
  print('  1. Log in to your POD using the app UI');
  print('  2. Click the EXTRACT button in the app');
  print('  3. Wait for confirmation message');
  print('');
}
