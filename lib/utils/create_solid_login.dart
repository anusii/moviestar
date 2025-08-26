/// Create Solid Login Widget.
//
// Time-stamp: <Wednesday 2025-07-23 16:57:13 +1000 Graham Williams>
//
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solidpod/solidpod.dart';

import 'package:moviestar/my_home_page.dart';
import 'package:moviestar/screens/settings_screen.dart';
import 'package:moviestar/services/api_key_service.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/utils/is_logged_in.dart';

/// Creates a Solid login widget for authentication.
///
/// This is a simplified version that provides a standard Solid authentication
/// interface for applications that need to connect to Solid PODs.
///
/// Parameters:
///   context: BuildContext for widget creation
///   prefs: SharedPreferences for accessing user preferences
///
/// Returns:
///   A Widget configured for Solid authentication.

Widget createSolidLogin(BuildContext context, SharedPreferences prefs) {
  debugPrint('🔍 Setting up Solid login widget');

  return Consumer(
    builder: (context, ref, child) {
      final serverUrl = ref.watch(serverURLProvider);

      return _buildNormalLogin(serverUrl, prefs);
    },
  );
}

/// Build the normal login widget.

Widget _buildNormalLogin(String serverUrl, SharedPreferences prefs) {
  return Builder(
    builder: (context) {
      // Wrap SolidLogin in a container with custom image.

      return Column(
        children: [
          Expanded(
            child: Theme(
              data: Theme.of(context).brightness == Brightness.dark
                  ? ThemeData.dark()
                  : ThemeData.light(),
              child: SolidLogin(
                required: false,
                title: 'Movie Star',
                appDirectory: 'moviestar',
                webID: serverUrl.isNotEmpty
                    ? serverUrl
                    : 'https://pods.dev.solidcommunity.au',
                image: const AssetImage('assets/images/app_image.jpg'),
                logo: const AssetImage('assets/images/app_icon.png'),
                link:
                    'https://github.com/yourusername/moviestar/blob/main/README.md',

                // Use a wrapper widget to check for API key after login.
                child: ApiKeyCheckWrapper(
                  prefs: prefs,
                  child: MyHomePage(
                    title: 'Movie Star Home Page',
                    prefs: prefs,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// A wrapper widget that checks if the API key is set and shows a dialog if not
class ApiKeyCheckWrapper extends StatefulWidget {
  final Widget child;
  final SharedPreferences prefs;

  const ApiKeyCheckWrapper({
    super.key,
    required this.child,
    required this.prefs,
  });

  @override
  State<ApiKeyCheckWrapper> createState() => _ApiKeyCheckWrapperState();
}

class _ApiKeyCheckWrapperState extends State<ApiKeyCheckWrapper> {
  late final ApiKeyService _apiKeyService;
  bool _hasCheckedApiKey = false;
  // Add static flag to prevent showing dialog multiple times in the same session.

  static bool _hasShownApiKeyDialogThisSession = false;

  @override
  void initState() {
    super.initState();
    _apiKeyService = ApiKeyService();

    // Delay the check to ensure the widget is fully built AND POD is authenticated
    // Wait a bit longer to allow POD authentication and API key fetching to complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _checkApiKey();
        }
      });
    });
  }

  Future<void> _checkApiKey() async {
    if (_hasCheckedApiKey || _hasShownApiKeyDialogThisSession) return;

    _hasCheckedApiKey = true;

    // Only check for API key if user is logged in (required for POD access).

    final loggedIn = await isLoggedIn();
    if (!loggedIn) return; // Don't show dialog if not logged in.

    // Set context for POD operations
    if (mounted) {
      _apiKeyService.updateContext(context, widget);
    } else {
      return;
    }

    final apiKey = await _apiKeyService.getApiKey();

    if (mounted && (apiKey == null || apiKey.isEmpty)) {
      _hasShownApiKeyDialogThisSession = true;
      // Show dialog asking user to set up API key.

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: Text(
            'API Key Required',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To use MovieStar, you need to set up a MovieDB API key.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Gap(12),
              Text(
                'You can get your free API key from The Movie Database (TMDB) website.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to settings screen
                _navigateToSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Set Up Now'),
            ),
          ],
        ),
      );
    }
  }

  void _navigateToSettings() {
    // We can't directly access _MyHomePageState as it's private.
    // Instead, navigate to a new SettingsScreen.

    final navigator = Navigator.of(context);
    // Get API key service to pass to settings screen.

    final apiKeyService = ApiKeyService();
    // Use a delay to ensure the dialog is fully closed.

    Future.delayed(const Duration(milliseconds: 100), () {
      navigator.push(
        MaterialPageRoute(
          builder: (context) => SettingsScreen(
            favoritesService: FavoritesService(widget.prefs),
            apiKeyService: apiKeyService,
            fromApiKeyPrompt: true,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Define provider for server URL.

final serverURLProvider = StateProvider<String>((ref) => '');
