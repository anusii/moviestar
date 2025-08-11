/// MovieStar Status Bar Configuration.
///
// Time-stamp: <Thursday 2025-08-11 15:45:00 +1000 Tony Chen>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
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
/// Authors: Tony Chen

library;

import 'package:flutter/material.dart';
import 'package:solidui/solidui.dart';

/// MovieStar-specific status bar configuration methods.

class MovieStarStatusBarConfig {
  /// Creates the MovieStar app status bar configuration.
  ///
  /// Returns a status bar configuration specifically designed for the
  /// MovieStar application with server information, login status, and security
  /// key status.

  static SolidStatusBarConfig createStatusBarConfig({
    String? webId,
    required VoidCallback onLoginTap,
    bool isKeySaved = false,
    VoidCallback? onSecurityKeyTap,
    bool showOnNarrowScreens = false,
    bool showSecurityKeyStatus = true,
  }) {
    // Extract server URL from WebID.

    final serverUrl = webId?.split('profile')[0] ?? 'Not connected';

    return SolidStatusBarConfig(
      serverInfo: SolidServerInfo(
        serverUri: serverUrl,
        displayText: serverUrl,
        tooltip: '''

**Server Information**

- Click to open server in browser

- Manages your personal data pod

Your movie data is stored securely in your personal pod.

''',
        isClickable: webId != null,
      ),
      loginStatus: SolidLoginStatus(
        webId: webId,
        onTap: onLoginTap,
        loggedInTooltip: '''

**Currently Logged In**

- WebID: $webId

- Click to log out

- Your data is secure

Your movie preferences and ratings are safely stored in your pod.

''',
        loggedOutTooltip: '''

**Login Required**

- Current status: Not logged in

- Click to log in to your pod

- Access your personal movie data

Connect to your pod to save and sync your movie preferences.

''',
      ),
      securityKeyStatus: showSecurityKeyStatus
          ? SolidSecurityKeyStatus(
              isKeySaved: isKeySaved,
              onTap: onSecurityKeyTap ?? () {
                // TODO: Default behavior: show a placeholder dialog
                // In a real app, this would open the security key manager
              },
              tooltip: '''

**Security Key Manager:** Tap here to manage your security key settings.

- View your current security key status

- Save a new security key

- Remove an existing security key

Your security key is essential for encrypting and protecting your movie data.

''',
            )
          : null,
      showOnNarrowScreens: showOnNarrowScreens,
      customItems: [],
    );
  }

  /// Creates a status bar configuration with additional movie-specific items.

  static SolidStatusBarConfig createStatusBarConfigWithExtras({
    String? webId,
    required VoidCallback onLoginTap,
    bool isKeySaved = false,
    VoidCallback? onSecurityKeyTap,
    List<SolidCustomStatusBarItem> additionalItems = const [],
    bool showOnNarrowScreens = false,
    bool showSecurityKeyStatus = true,
  }) {
    final baseConfig = createStatusBarConfig(
      webId: webId,
      onLoginTap: onLoginTap,
      isKeySaved: isKeySaved,
      onSecurityKeyTap: onSecurityKeyTap,
      showOnNarrowScreens: showOnNarrowScreens,
      showSecurityKeyStatus: showSecurityKeyStatus,
    );

    return SolidStatusBarConfig(
      serverInfo: baseConfig.serverInfo,
      loginStatus: baseConfig.loginStatus,
      securityKeyStatus: baseConfig.securityKeyStatus,
      customItems: additionalItems,
      showOnNarrowScreens: showOnNarrowScreens,
      backgroundColor: baseConfig.backgroundColor,
      narrowLayoutHeight: baseConfig.narrowLayoutHeight,
      mediumLayoutHeight: baseConfig.mediumLayoutHeight,
      wideLayoutHeight: baseConfig.wideLayoutHeight,
      padding: baseConfig.padding,
      itemSpacing: baseConfig.itemSpacing,
    );
  }

  /// Creates a simple server-only status bar configuration.

  static SolidStatusBarConfig createServerOnlyConfig({
    String? webId,
    bool showOnNarrowScreens = false,
  }) {
    final serverUrl = webId?.split('profile')[0] ?? 'Not connected';

    return SolidStatusBarConfig(
      serverInfo: SolidServerInfo(
        serverUri: serverUrl,
        displayText: serverUrl,
        tooltip: '''

**Server Information**

Your MovieStar pod server location.

''',
        isClickable: webId != null,
      ),
      showOnNarrowScreens: showOnNarrowScreens,
    );
  }
}
