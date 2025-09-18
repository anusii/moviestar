/// MovieStar SolidScaffold Configuration.
///
// Time-stamp: <Wednesday 2025-08-27 11:42:58 +1000 Graham Williams>
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
import 'package:solidui/solidui.dart';

import 'package:moviestar/core/services/api/api_key_service.dart';
import 'package:moviestar/core/services/favorites/favorites_service.dart';
import 'package:moviestar/core/services/favorites/favorites_service_manager.dart';
import 'package:moviestar/providers/view_mode_provider.dart';
import 'package:moviestar/screens/coming_soon_screen.dart';
import 'package:moviestar/screens/files_screen.dart';
import 'package:moviestar/screens/home_screen.dart';
import 'package:moviestar/screens/my_lists_screen.dart';
import 'package:moviestar/screens/my_movies_screen.dart';
import 'package:moviestar/screens/shared_movies_screen.dart';
import 'package:moviestar/screens/to_watch_screen.dart';
import 'package:moviestar/screens/watched_screen.dart';

/// MovieStar-specific SolidScaffold configuration.
///
/// Provides centralised configuration for all SolidScaffold components
/// including navigation menu, app bar actions, and overflow items.
/// This ensures consistent UI patterns throughout the application.

class SolidScaffoldConfig {
  /// Creates the MovieStar app navigation menu items.
  ///
  /// Returns a list of menu items configured specifically for the
  /// MovieStar application with proper titles, icons, tooltips, and child
  /// widgets.
  ///
  /// [favoritesService] The service for managing favourite movies.
  /// [apiKeyService] The service for managing API keys.
  /// [favoritesServiceManager] The manager for favourites service.

  static List<SolidMenuItem> createMenuItems({
    required FavoritesService favoritesService,
    required ApiKeyService apiKeyService,
    required FavoritesServiceManager favoritesServiceManager,
  }) {
    return [
      SolidMenuItem(
        title: 'Home',
        icon: Icons.home,
        child: HomeScreen(favoritesService: favoritesService),
        tooltip: '''

**Home:** Tap here to view your movie dashboard and discover new films.

''',
      ),
      SolidMenuItem(
        title: 'To Watch',
        icon: Icons.favorite,
        child: ToWatchScreen(favoritesService: favoritesService),
        tooltip: '''

**To Watch:** Tap here to view your watchlist of movies you want to see.

''',
      ),
      SolidMenuItem(
        title: 'Watched',
        icon: Icons.history,
        child: WatchedScreen(favoritesService: favoritesService),
        tooltip: '''

**Watched:** Tap here to view movies you have already watched and rated.

''',
      ),
      SolidMenuItem(
        title: 'Coming Soon',
        icon: Icons.upcoming,
        child: ComingSoonScreen(favoritesService: favoritesService),
        tooltip: '''

**Coming Soon:** Tap here to discover upcoming movie releases.

''',
      ),
      SolidMenuItem(
        title: 'My Movies',
        icon: Icons.star,
        child: MyMoviesScreen(favoritesService: favoritesService),
        tooltip: '''

**My Movies:** Tap here to view movies you have rated and reviewed.

''',
      ),
      SolidMenuItem(
        title: 'My Lists',
        icon: Icons.playlist_play,
        child: MyListsScreen(favoritesService: favoritesService),
        tooltip: '''

**My Lists:** Tap here to view and manage your custom movie lists.

''',
      ),
      SolidMenuItem(
        title: 'Shared',
        icon: Icons.movie_outlined,
        child: const SharedMoviesScreen(),
        tooltip: '''

**Shared Movies:** Tap here to view movies shared from your POD.

''',
      ),
      SolidMenuItem(
        title: 'Files',
        icon: Icons.folder,
        child: const FilesScreen(),
        tooltip: '''

**File Management:** Tap here to access file management features for your POD.

You can browse POD storage, upload files, download files, and manage
your movie data files.

''',
      ),
    ];
  }

  /// Creates the MovieStar app bar actions.
  ///
  /// Returns a list of action buttons configured for the MovieStar application.
  /// Requires a WidgetRef to access view mode state and callback functions for
  /// handling actions.

  static List<SolidAppBarAction> createAppBarActions({
    required WidgetRef ref,
    required VoidCallback onViewModeToggle,
    required VoidCallback onRefresh,
    required VoidCallback onSearch,
  }) {
    return [
      SolidAppBarAction(
        icon: _getViewModeIcon(ref.watch(viewModeProvider)),
        onPressed: onViewModeToggle,
        tooltip:
            'View Mode: Tap here to cycle between different view modes (Grid, Kanban, List).',
      ),
      SolidAppBarAction(
        icon: Icons.refresh,
        onPressed: onRefresh,
        tooltip:
            'Refresh: Tap here to refresh all movie data and reload the latest information from the movie database.',
      ),
      SolidAppBarAction(
        icon: Icons.search,
        onPressed: onSearch,
        tooltip:
            'Search: Tap here to search for movies by title, genre, or other criteria.',
      ),
    ];
  }

  /// Creates the MovieStar app bar overflow items.
  ///
  /// Returns a list of overflow menu items configured for the MovieStar
  /// application.

  static List<SolidOverflowMenuItem> createOverflowItems({
    required VoidCallback onLogout,
    required VoidCallback onSettings,
  }) {
    return [
      SolidOverflowMenuItem(
        id: 'logout',
        icon: Icons.logout,
        label: 'Logout',
        onSelected: onLogout,
      ),
      SolidOverflowMenuItem(
        id: 'settings',
        icon: Icons.settings,
        label: 'Settings',
        onSelected: onSettings,
      ),
    ];
  }

  /// Gets the appropriate icon for the current view mode.

  static IconData _getViewModeIcon(HomeViewMode viewMode) {
    switch (viewMode) {
      case HomeViewMode.grid:
        return Icons.grid_view;
      case HomeViewMode.kanban:
        return Icons.view_kanban;
      case HomeViewMode.list:
        return Icons.view_list;
    }
  }
}
