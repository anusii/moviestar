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
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solidpod/solidpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:moviestar/my_home_page.dart';
import 'package:moviestar/screens/settings_screen.dart';
import 'package:moviestar/services/api_key_service.dart';
import 'package:moviestar/services/favorites_service.dart';

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
  @override
  void initState() {
    super.initState();

    // Delay the check to ensure the widget is fully built AND POD is authenticated
    // API key checking is now handled in MyHomePage instead
    // Wait longer to allow POD authentication and API key fetching to complete
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Future.delayed(const Duration(seconds: 3), () {
    //     if (mounted && !_hasCheckedApiKey) {
    //       _checkApiKey();
    //     }
    //   });
    // });
  }

  void _showApiKeyDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // User must take action
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(
              maxWidth: 500,
              minHeight: 300,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon section
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.key,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  '🎬 API Key Required',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Content
                Text(
                  'To unlock the full Movie Star experience, you need to configure your MovieDB API key.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'This allows the app to fetch the latest movie data, ratings, and information.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: Text(
                          'Later',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _navigateToSettings();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        icon: const Icon(Icons.settings, size: 20),
                        label: const Text(
                          'Set Up API Key',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Help text
                TextButton(
                  onPressed: () => _showApiKeyHelpDialog(),
                  child: Text(
                    '💡 How to get a MovieDB API key?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToSettings() async {
    if (!mounted) return;

    try {
      // Create a basic favorites service - won't be used for API key setting
      final favoritesService = FavoritesService(widget.prefs);
      final apiKeyService = ApiKeyService();

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Material(
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Settings'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              body: SettingsScreen(
                favoritesService: favoritesService,
                apiKeyService: apiKeyService,
                fromApiKeyPrompt: true,
              ),
            ),
          ),
        ),
      );

      // After returning from settings, don't immediately recheck
      // The API key should already be set if the user saved it
      if (mounted) {
        // Give time for the providers to update
        await Future.delayed(const Duration(seconds: 1));

        // Only recheck if we really need to (e.g., user might have cancelled)
        final apiKeyService =
            ApiKeyService(context: context, child: widget.child);
        final apiKey = await apiKeyService.getApiKey();

        if (apiKey == null || apiKey.trim().isEmpty) {
          // User didn't set the API key - could show dialog again in future
          debugPrint('User dismissed API key setup');
        }
      }
    } catch (e) {
      debugPrint('Error navigating to settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening settings: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showApiKeyHelpDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.help_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'How to get a MovieDB API Key',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Follow these simple steps to get your free API key:',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                _buildStep('1', 'Visit The Movie Database website', Icons.web),
                _buildStep(
                  '2',
                  'Create a free account or sign in',
                  Icons.person_add,
                ),
                _buildStep('3', 'Go to Settings → API section', Icons.settings),
                _buildStep(
                  '4',
                  'Request an API key (free for personal use)',
                  Icons.key,
                ),
                _buildStep(
                  '5',
                  'Copy your API key and paste it in Movie Star',
                  Icons.copy,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyApiUrl(),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy Website URL'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openTmdbWebsite(),
                        icon: const Icon(Icons.open_in_browser, size: 18),
                        label: const Text('Open Website'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep(String number, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyApiUrl() async {
    const url = 'https://www.themoviedb.org/settings/api';
    await Clipboard.setData(const ClipboardData(text: url));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Website URL copied to clipboard!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openTmdbWebsite() async {
    const url = 'https://www.themoviedb.org/settings/api';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error opening URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not open website. URL copied to clipboard instead.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        _copyApiUrl(); // Fallback to copying URL
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Define provider for server URL.

final serverURLProvider = StateProvider<String>((ref) => '');
