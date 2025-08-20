/// Moviestar - Manage and share ratings through private PODs.
///
// Time-stamp: <Wednesday 2025-07-23 16:53:30 +1000 Graham Williams>
///
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
/// Authors: Kevin Wang, Graham Williams, Ashley Tang, Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solidpod/solidpod.dart'
    show getAppNameVersion, logoutPopup, getWebId;
import 'package:solidui/solidui.dart';

import 'package:moviestar/features/file/service/page.dart';
import 'package:moviestar/moviestar.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/providers/theme_provider.dart';
import 'package:moviestar/providers/view_mode_provider.dart';
import 'package:moviestar/screens/coming_soon_screen.dart';
import 'package:moviestar/screens/home_screen.dart';
import 'package:moviestar/screens/my_lists_screen.dart';
import 'package:moviestar/screens/my_movies_screen.dart';
import 'package:moviestar/screens/search_screen.dart';
import 'package:moviestar/screens/settings_screen.dart';
import 'package:moviestar/screens/shared_movies_screen.dart';
import 'package:moviestar/screens/to_watch_screen.dart';
import 'package:moviestar/screens/watched_screen.dart';
import 'package:moviestar/services/api_key_service.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/services/favorites_service_adapter.dart';
import 'package:moviestar/services/favorites_service_manager.dart';
import 'package:moviestar/services/movie_service.dart';
import 'package:moviestar/utils/initialise_app_folders.dart';
import 'package:moviestar/utils/is_logged_in.dart';
import 'package:moviestar/widgets/moviestar_nav_config.dart';
import 'package:moviestar/widgets/security_key_manager_dialog.dart';

class MyHomePage extends ConsumerStatefulWidget {
  final SharedPreferences prefs;

  const MyHomePage({super.key, required this.title, required this.prefs});

  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

/// State class for the main screen.

class _MyHomePageState extends ConsumerState<MyHomePage> {
  /// Index of the currently selected screen.

  int _selectedIndex = 0;
  bool _isLoadingFolders = false;
  String? _webId;
  String? _name;
  bool _isKeySaved = false;

  /// Service for managing favorite movies.

  late final FavoritesServiceManager _favoritesServiceManager;
  late final FavoritesService _favoritesService;
  late final ApiKeyService _apiKeyService;
  late final MovieService _movieService;
  late final SolidSecurityKeyService _securityKeyService;

  // Flag to prevent security key status update loops
  bool _isUpdatingSecurityKeyStatus = false;

  /// List of screens to display in the navigation rail.

  late List<Widget> _screens;

  /// Navigation menu items configuration.

  late List<SolidMenuItem> _menuItems;

  @override
  void initState() {
    super.initState();
    _favoritesServiceManager = FavoritesServiceManager(
      widget.prefs,
      context,
      widget,
    );
    _favoritesService = FavoritesServiceAdapter(_favoritesServiceManager);
    _apiKeyService = ApiKeyService();
    _movieService = MovieService(_apiKeyService);
    _securityKeyService = SolidSecurityKeyService();

    // Listen for API key changes.

    _apiKeyService.addListener(_onApiKeyChanged);

    // Listen for security key changes.

    _securityKeyService.addListener(_onSecurityKeyChanged);

    _loadAppInfo();
    _loadUserInfo();
    _loadSecurityKeyStatus();
    _buildScreens();
  }

  @override
  void dispose() {
    _apiKeyService.removeListener(_onApiKeyChanged);
    _securityKeyService.removeListener(_onSecurityKeyChanged);
    super.dispose();
  }

  /// Loads the app name and version from package_info_plus.

  Future<void> _loadAppInfo() async {
    await getAppNameVersion();

    // Version loaded successfully.
  }

  /// Loads user information from the POD.

  Future<void> _loadUserInfo() async {
    try {
      final webId = await getWebId();
      if (mounted && webId != null && webId.isNotEmpty) {
        final name = _extractNameFromWebId(webId);
        setState(() {
          _webId = webId;
          _name = name;
        });
      } else if (mounted) {
        setState(() {
          _webId = null;
          _name = 'Not logged in';
        });
      }
    } catch (e) {
      // Handle error gracefully.

      if (mounted) {
        setState(() {
          _webId = null;
          _name = 'Not logged in';
        });
      }
    }
  }

  /// Extracts a user-friendly name from the WebID.

  String _extractNameFromWebId(String webId) {
    try {
      // Extract domain from WebID for a simple display name
      final uri = Uri.parse(webId);
      final domain = uri.host;

      // Try to extract a meaningful part
      if (domain.contains('.')) {
        final parts = domain.split('.');
        if (parts.isNotEmpty) {
          return parts.first.toLowerCase();
        }
      }

      return domain;
    } catch (e) {
      return 'User';
    }
  }

  void _onApiKeyChanged() {
    // When API key changes, update the movie service.

    _movieService.updateApiKey();

    // Invalidate all movie providers to force refresh with new API key.

    ref.invalidate(popularMoviesWithCacheInfoProvider);
    ref.invalidate(nowPlayingMoviesWithCacheInfoProvider);
    ref.invalidate(topRatedMoviesWithCacheInfoProvider);
    ref.invalidate(upcomingMoviesWithCacheInfoProvider);
    ref.invalidate(configuredCachedMovieServiceProvider);

    // Rebuild screens to ensure they have the latest data.

    setState(() {
      _buildScreens();
    });

    // If we're on the home screen, make sure it reloads.

    if (_selectedIndex == 0) {
      // Force refresh by rebuilding.

      setState(() {});
    }
  }

  /// Handles security key changes.

  void _onSecurityKeyChanged() {
    if (_isUpdatingSecurityKeyStatus) {
      debugPrint('Security key update already in progress, skipping');
      return;
    }

    debugPrint('Security key status changed, updating UI state');

    _updateSecurityKeyStatusFromService();
  }

  /// Updates security key status from service without triggering reload.

  Future<void> _updateSecurityKeyStatusFromService() async {
    if (_isUpdatingSecurityKeyStatus) return;

    _isUpdatingSecurityKeyStatus = true;
    try {
      final isKeySaved = await _securityKeyService.isKeySaved();
      if (mounted) {
        setState(() {
          _isKeySaved = isKeySaved;
        });
      }
    } catch (e) {
      debugPrint('Error updating security key status: $e');
    } finally {
      _isUpdatingSecurityKeyStatus = false;
    }
  }

  /// Loads the current security key status.

  Future<void> _loadSecurityKeyStatus() async {
    if (_isUpdatingSecurityKeyStatus) return;

    _isUpdatingSecurityKeyStatus = true;
    try {
      bool hasValidKey = false;

      // Check basic KeyManager status.

      final hasKeyInMemory = await _securityKeyService.isKeySaved();

      if (hasKeyInMemory) {
        hasValidKey = true;
      }

      if (mounted) {
        setState(() {
          _isKeySaved = hasValidKey;
        });
      }

      await _securityKeyService.fetchKeySavedStatus((bool hasKey) {
        if (mounted && hasKey != _isKeySaved) {
          setState(() {
            _isKeySaved = hasKey;
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading security key status: $e');
      if (mounted) {
        setState(() {
          _isKeySaved = false;
        });
      }
    } finally {
      _isUpdatingSecurityKeyStatus = false;
    }
  }

  void _buildScreens() {
    _screens = [
      HomeScreen(favoritesService: _favoritesService),
      ToWatchScreen(favoritesService: _favoritesService),
      WatchedScreen(favoritesService: _favoritesService),
      ComingSoonScreen(favoritesService: _favoritesService),
      MyMoviesScreen(favoritesService: _favoritesService),
      MyListsScreen(favoritesService: _favoritesService),
      const SharedMoviesScreen(),
      const FileService(),
      SettingsScreen(
        favoritesService: _favoritesService,
        apiKeyService: _apiKeyService,
        favoritesServiceManager: _favoritesServiceManager,
      ),
    ];

    // Configure navigation menu items using the MovieStar app configuration.

    _menuItems = MovieStarNavConfig.createMenuItems();

    _initialiseAppData();
  }

  Future<void> _initialiseAppData() async {
    final loggedIn = await isLoggedIn();

    // Refresh user info based on login status.

    await _loadUserInfo();

    if (loggedIn) {
      if (mounted) {
        setState(() {
          _isLoadingFolders = true;
        });
        await initialiseAppFolders(
          context: context,
          onProgress: (inProgress) {
            if (mounted && !inProgress) {
              setState(() {
                _isLoadingFolders = false;
              });
            }
          },
          onComplete: () async {
            if (mounted) {
              setState(() {
                _isLoadingFolders = false;
              });
            }

            // Now reload POD data since folders are ready.

            await _favoritesServiceManager.reloadPodDataAfterInit();

            // Refresh UI streams to ensure latest data is displayed.

            await _favoritesServiceManager.refreshUIStreams();
          },
        );
        if (mounted && _isLoadingFolders) {
          setState(() {
            _isLoadingFolders = false;
          });
        }
      }
    }
  }

  /// Handles the refresh action.

  void _handleRefresh() {
    // Invalidate all movie providers to force refresh.

    ref.invalidate(popularMoviesWithCacheInfoProvider);
    ref.invalidate(nowPlayingMoviesWithCacheInfoProvider);
    ref.invalidate(topRatedMoviesWithCacheInfoProvider);
    ref.invalidate(upcomingMoviesWithCacheInfoProvider);
    ref.invalidate(configuredCachedMovieServiceProvider);
  }

  /// Handles the search action.

  void _handleSearch() {
    if (mounted) {
      final movieService = ref.read(movieServiceProvider);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchScreen(
            favoritesService: _favoritesService,
            movieService: movieService,
          ),
        ),
      );
    }
  }

  /// Handles the settings action.

  void _handleSettings() {
    setState(() {
      _selectedIndex = 6; // Settings screen index.
    });
  }

  /// Handles the view mode toggle action.

  void _handleViewModeToggle() {
    ref.read(viewModeProvider.notifier).cycleViewMode();
  }

  /// Handles the logout action.

  void _handleLogout() {
    logoutPopup(context, const MovieStar());
  }

  /// Handles the security key management action.

  void _handleSecurityKeyManagement() {
    showDialog(
      context: context,
      barrierColor: Theme.of(context).colorScheme.onSurface,
      builder: (BuildContext context) => SecurityKeyManagerDialog(
        onKeyStatusChanged: (bool hasKey) {
          _updateSecurityKeyStatusFromService();
        },
      ),
    );
  }

  /// Gets the appropriate icon for the current view mode.

  IconData _getViewModeIcon(HomeViewMode viewMode) {
    switch (viewMode) {
      case HomeViewMode.grid:
        return Icons.grid_view;
      case HomeViewMode.kanban:
        return Icons.view_kanban;
      case HomeViewMode.list:
        return Icons.view_list;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Create user info for the solid navigation.

    final userInfo = SolidNavUserInfo(
      userName: _name ?? 'Not logged in',
      webId: _webId,
      showWebId: false, // Doesn't show WebID by default.
      avatarIcon: Icons.account_circle,
    );

    // Create the main content with loading overlay.

    final mainContent = Stack(
      children: [
        _isLoadingFolders
            ? const Center(child: CircularProgressIndicator())
            : _screens[_selectedIndex],
      ],
    );

    return SolidScaffold(
      menu: _menuItems,
      appBar: SolidAppBarConfig(
        title: _menuItems[_selectedIndex].title,
        versionConfig: const SolidVersionConfig(
          version: '0.0.9+6',
          changelogUrl: 'https://github.com/anusii/moviestar/blob/dev/CHANGELOG'
              '.md',
          showDate: true,
          tooltip: '''
**Version Information**

Current version: 0.0.9+6

Click to view the changelog and see what's new in this version.
The version is automatically checked for updates.

''',
        ),
        actions: [
          SolidAppBarAction(
            icon: _getViewModeIcon(ref.watch(viewModeProvider)),
            onPressed: _handleViewModeToggle,
            tooltip:
                'View Mode: Tap here to cycle between different view modes (Grid, Kanban, List).',
          ),
          SolidAppBarAction(
            icon: Icons.refresh,
            onPressed: _handleRefresh,
            tooltip:
                'Refresh: Tap here to refresh all movie data and reload the latest information from the movie database.',
          ),
          SolidAppBarAction(
            icon: Icons.search,
            onPressed: _handleSearch,
            tooltip:
                'Search: Tap here to search for movies by title, genre, or other criteria.',
          ),
        ],
        overflowItems: [
          SolidOverflowMenuItem(
            id: 'settings',
            icon: Icons.settings,
            label: 'Settings',
            onSelected: _handleSettings,
          ),
          SolidOverflowMenuItem(
            id: 'logout',
            icon: Icons.logout,
            label: 'Logout',
            onSelected: _handleLogout,
          ),
        ],
      ),
      statusBar: SolidStatusBarConfig(
        serverInfo: SolidServerInfo(
          serverUri: _webId?.split('profile')[0] ?? 'Not connected',
          displayText: _webId?.split('profile')[0] ?? 'Not connected',
          tooltip:
              'Server Information - Click to open server in browser. Manages your personal data pod. Your movie data is stored securely in your personal pod.',
          isClickable: _webId != null,
        ),
        loginStatus: SolidLoginStatus(
          webId: _webId,
          onTap: _handleLogout,
          loggedInTooltip:
              'Currently Logged In - WebID: $_webId - Click to log out - Your data is secure. Your movie preferences and ratings are safely stored in your pod.',
          loggedOutTooltip:
              'Login Required - Current status: Not logged in - Click to log in to your pod - Access your personal movie data. Connect to your pod to save and sync your movie preferences.',
        ),
        securityKeyStatus: SolidSecurityKeyStatus(
          isKeySaved: _isKeySaved,
          onTap: _handleSecurityKeyManagement,
          tooltip:
              'Security Key Manager: Tap here to manage your security key settings. View your current security key status, save a new security key, or remove an existing security key. Your security key is essential for encrypting and protecting your movie data.',
        ),
        showOnNarrowScreens: false,
      ),
      userInfo: userInfo,
      onLogout: (context) => _handleLogout(),
      narrowScreenThreshold: NavigationConstants.narrowScreenThreshold,
      backgroundColor: theme.colorScheme.surface,
      selectedIndex: _selectedIndex,
      onMenuSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      themeToggle: SolidThemeToggleConfig(
        enabled: true,
        currentThemeMode: ref.watch(themeModeProvider),
        onToggleTheme: () async {
          await ref.read(themeModeProvider.notifier).toggleTheme();
        },
        showInAppBarActions: true,
        hideOnVeryNarrowScreen: true,
        tooltip: '''
**Theme Toggle**

Switch between light and dark modes for optimal viewing experience.

🌙 **Dark Mode**: Better for low-light viewing

☀️ **Light Mode**: Better for bright environments

''',
      ),
      child: mainContent,
    );
  }
}
