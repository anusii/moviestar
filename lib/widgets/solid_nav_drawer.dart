/// Solid Navigation Drawer.
///
// Time-stamp: <Tuesday 2025-08-06 16:30:00 +1000 Tony Chen>
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

import 'package:moviestar/constants/navigation_constants.dart';
import 'package:moviestar/widgets/solid_nav_bar.dart';

/// User information configuration for the navigation drawer.

class SolidNavUserInfo {
  /// The user's display name.

  final String userName;

  /// The user's WebID (optional).

  final String? webId;

  /// Whether to show the WebID in the drawer.

  final bool showWebId;

  /// Custom user avatar widget (optional).

  final Widget? avatar;

  /// Custom user avatar icon (used if avatar widget is null).

  final IconData? avatarIcon;

  /// Custom avatar size.

  final double? avatarSize;

  const SolidNavUserInfo({
    required this.userName,
    this.webId,
    this.showWebId = false,
    this.avatar,
    this.avatarIcon,
    this.avatarSize,
  });
}

/// A solid navigation drawer component.
///
/// This widget provides a collapsible navigation drawer that displays
/// when the screen is narrow, replacing the navigation rail.

class SolidNavDrawer extends StatelessWidget {
  /// User information to display in the drawer header.

  final SolidNavUserInfo? userInfo;

  /// List of navigation tabs to display.

  final List<SolidNavTab> tabs;

  /// Currently selected tab index.

  final int selectedIndex;

  /// Callback when a tab is selected.

  final void Function(int) onTabSelected;

  /// Optional logout callback.

  final void Function(BuildContext)? onLogout;

  /// Optional custom logout icon.

  final IconData? logoutIcon;

  /// Optional custom logout text.

  final String? logoutText;

  /// Whether to show the logout option.

  final bool showLogout;

  /// Optional additional menu items to display after the main tabs.

  final List<Widget>? additionalMenuItems;

  /// Optional custom drawer shape.

  final ShapeBorder? drawerShape;

  const SolidNavDrawer({
    super.key,
    this.userInfo,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.onLogout,
    this.logoutIcon,
    this.logoutText,
    this.showLogout = true,
    this.additionalMenuItems,
    this.drawerShape,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      shape: drawerShape ??
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
          ),
      child: ListView(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        children: <Widget>[
          // User info header (if provided).

          if (userInfo != null) _buildUserInfoHeader(context, theme),

          // Navigation items.

          Container(
            padding: const EdgeInsets.all(NavigationConstants.navDrawerPadding),
            child: Column(
              children: [
                // Main navigation tabs.

                ...tabs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tab = entry.value;

                  return ListTile(
                    leading: Icon(
                      tab.icon,
                      color: index == selectedIndex
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    title: Text(
                      tab.title,
                      style: TextStyle(
                        fontWeight: index == selectedIndex
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: index == selectedIndex
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    selected: index == selectedIndex,
                    selectedTileColor:
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                    onTap: () {
                      onTabSelected(index);
                      Navigator.of(context).pop(); // Close drawer.
                    },
                  );
                }).toList(),

                // Additional menu items (if provided).

                if (additionalMenuItems != null) ...additionalMenuItems!,

                // Divider and logout option.

                if (showLogout && onLogout != null) ...[
                  Divider(
                    height: NavigationConstants.navDividerHeight,
                    color: theme.dividerColor,
                  ),
                  ListTile(
                    leading: Icon(
                      logoutIcon ?? Icons.logout,
                      color: _canLogout()
                          ? theme.colorScheme.error
                          : theme.disabledColor,
                    ),
                    title: Text(
                      logoutText ?? 'Logout',
                      style: TextStyle(
                        color: _canLogout()
                            ? theme.colorScheme.error
                            : theme.disabledColor,
                      ),
                    ),
                    onTap: _canLogout()
                        ? () {
                            Navigator.of(context).pop(); // Close drawer first.
                            onLogout!(context);
                          }
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoHeader(BuildContext context, ThemeData theme) {
    final user = userInfo!;

    return Container(
      padding: EdgeInsets.only(
        top: NavigationConstants.userHeaderTopPadding +
            MediaQuery.of(context).padding.top,
        bottom: NavigationConstants.userHeaderBottomPadding,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
      ),
      child: Column(
        children: [
          // User avatar.

          user.avatar ??
              Icon(
                user.avatarIcon ?? Icons.account_circle,
                size: user.avatarSize ?? NavigationConstants.userAvatarSize,
                color: theme.colorScheme.onPrimaryContainer,
              ),

          SizedBox(height: NavigationConstants.userInfoSpacing),

          // User name.

          Text(
            user.userName.isNotEmpty ? user.userName : 'Not logged in',
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontSize: NavigationConstants.userNameFontSize,
              fontWeight: FontWeight.w600,
            ),
          ),

          // WebID (if enabled and available).

          if (user.showWebId &&
              user.webId != null &&
              user.webId!.isNotEmpty) ...[
            SizedBox(height: NavigationConstants.webIdSpacing),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: NavigationConstants.webIdHorizontalPadding,
              ),
              child: Text(
                _getSimplifiedUrl(user.webId!),
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer
                      .withValues(alpha: 0.8),
                  fontSize: NavigationConstants.webIdFontSize,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Determines if logout functionality is available.

  bool _canLogout() {
    if (userInfo == null) return false;
    return userInfo!.webId != null && userInfo!.webId!.isNotEmpty;
  }

  /// Simplifies the WebID URL for display purposes.

  String _getSimplifiedUrl(String webId) {
    const suffix = 'profile/card#me';
    String url = webId;
    if (url.endsWith(suffix)) {
      url = url.substring(0, url.length - suffix.length);
    }

    // Remove protocol for cleaner display

    if (url.startsWith('https://')) {
      url = url.substring(8);
    } else if (url.startsWith('http://')) {
      url = url.substring(7);
    }
    return url;
  }
}
