/// Create Solid Login Widget.
//
// Time-stamp: <Wednesday 2026-02-04 08:25:19 +1100 Graham Williams>
//
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License");.
///
/// License: https://opensource.org/license/gpl-3-0.
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Ashley Tang.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solidui/solidui.dart';

import 'package:moviestar/my_home_page.dart';

/// Creates a Solid login widget for authentication.
///
/// This is a simplified version that provides a standard Solid authentication.
/// interface for applications that need to connect to Solid PODs.
///
/// Parameters:.
///   context: BuildContext for widget creation.
///   prefs: SharedPreferences for accessing user preferences.
///
/// Returns:.
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
                title: 'MovieStar\nPrivate Ratings and Recommender',
                appDirectory: 'moviestar',
                webID: serverUrl.isNotEmpty
                    ? serverUrl
                    : 'https://pods.solidcommunity.au',
                image: const AssetImage('assets/images/app_image.jpg'),
                logo: const AssetImage('assets/images/app_icon.png'),
                link: 'https://github.com/anusii/moviestar/blob/dev/README.md',

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

/// A wrapper widget that checks if the API key is set and shows a dialog if not.

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

    // Delay the check to ensure the widget is fully built AND POD is authenticated.
    // API key checking is now handled in MyHomePage instead.
    // Wait longer to allow POD authentication and API key fetching to complete.
    // WidgetsBinding.instance.addPostFrameCallback((_) {.
    //   Future.delayed(const Duration(seconds: 3), () {.
    //     if (mounted && !_hasCheckedApiKey) {.
    //       _checkApiKey();.
    //     }.
    //   });.
    // });.
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Notifier for server URL state.

class ServerURLNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setServerURL(String url) {
    state = url;
  }
}

// Define provider for server URL.

final serverURLProvider = NotifierProvider<ServerURLNotifier, String>(
  ServerURLNotifier.new,
);
