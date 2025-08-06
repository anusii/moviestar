/// Navigation Drawer.
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solidpod/solidpod.dart' show logoutPopup;

import 'package:moviestar/moviestar.dart';
import 'package:moviestar/widgets/solid_nav_bar.dart';

/// A navigation drawer for the application.
///
/// This widget provides a collapsible navigation drawer that displays
/// when the screen is narrow, replacing the navigation rail.

class MovieNavDrawer extends ConsumerWidget {
  const MovieNavDrawer({
    super.key,
    required this.webId,
    required this.userName,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final String webId;
  final String userName;
  final List<SolidNavTab> tabs;
  final int selectedIndex;
  final void Function(int) onTabSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: ListView(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        children: <Widget>[
          // User info header.

          Container(
            padding: EdgeInsets.only(
              top: 24 + MediaQuery.of(context).padding.top,
              bottom: 24,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.account_circle,
                  size: 64,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 12),
                Text(
                  userName.isNotEmpty ? userName : 'Not logged in',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (webId.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _getSimplifiedUrl(webId),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Navigation items.

          Container(
            padding: const EdgeInsets.all(15),
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
                    selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    onTap: () {
                      onTabSelected(index);
                      Navigator.of(context).pop(); // Close drawer.
                    },
                  );
                }).toList(),

                // Divider.

                Divider(
                  height: 32,
                  color: theme.dividerColor,
                ),

                // Logout option.

                ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: webId.isEmpty 
                        ? theme.disabledColor 
                        : theme.colorScheme.error,
                  ),
                  title: Text(
                    'Logout',
                    style: TextStyle(
                      color: webId.isEmpty 
                          ? theme.disabledColor 
                          : theme.colorScheme.error,
                    ),
                  ),
                  onTap: webId.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).pop(); // Close drawer first.
                          logoutPopup(context, const MovieStar());
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
