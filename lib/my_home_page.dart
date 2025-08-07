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
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solidpod/solidpod.dart'
    show getAppNameVersion, logoutPopup, getWebId;
import 'package:version_widget/version_widget.dart';

import 'package:moviestar/features/file/service/page.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/providers/theme_provider.dart';
import 'package:moviestar/screens/coming_soon_screen.dart';
import 'package:moviestar/screens/home_screen.dart';
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
import 'package:moviestar/moviestar.dart';
import 'package:moviestar/utils/initialise_app_folders.dart';
import 'package:moviestar/utils/is_logged_in.dart';
import 'package:moviestar/constants/navigation_constants.dart';
import 'package:moviestar/widgets/movie_nav_tabs.dart';
import 'package:moviestar/widgets/solid_nav_bar.dart';
import 'package:moviestar/widgets/solid_navigation_manager.dart';
import 'package:moviestar/widgets/solid_nav_utils.dart';

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
  String _appVersion = '';
  bool _isVersionLoaded = false;
  String? _webId;
  String? _name;

  /// Service for managing favorite movies.

  late final FavoritesServiceManager _favoritesServiceManager;
  late final FavoritesService _favoritesService;
  late final ApiKeyService _apiKeyService;
  late final MovieService _movieService;

  /// List of screens to display in the navigation rail.

  late List<Widget> _screens;

  /// Navigation tabs configuration.

  late List<SolidNavTab> _navTabs;

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

    // Listen for API key changes.

    _apiKeyService.addListener(_onApiKeyChanged);

    _loadAppInfo();
    _loadUserInfo();
    _buildScreens();
  }

  @override
  void dispose() {
    _apiKeyService.removeListener(_onApiKeyChanged);
    super.dispose();
  }

  /// Loads the app name and version from package_info_plus.

  Future<void> _loadAppInfo() async {
    final appInfo = await getAppNameVersion();
    if (mounted) {
      setState(() {
        _appVersion = appInfo.version;
        _isVersionLoaded = true;
      });
    }
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
      // Handle error gracefully
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

  void _buildScreens() {
    _screens = [
      HomeScreen(favoritesService: _favoritesService),
      ToWatchScreen(
        favoritesService: _favoritesService,
      ),
      WatchedScreen(
        favoritesService: _favoritesService,
      ),
      ComingSoonScreen(favoritesService: _favoritesService),
      const SharedMoviesScreen(),
      const FileService(),
      SettingsScreen(
        favoritesService: _favoritesService,
        apiKeyService: _apiKeyService,
        favoritesServiceManager: _favoritesServiceManager,
      ),
    ];

    // Configure navigation tabs using the MovieStar app configuration.

    _navTabs = createMovieStarNavTabs();

    _initialiseAppData();
  }

  Future<void> _initialiseAppData() async {
    final loggedIn = await isLoggedIn();

    // Refresh user info based on login status
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

  /// Handles the logout action.

  void _handleLogout() {
    logoutPopup(context, const MovieStar());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Create user info for the solid navigation.

    final userInfo = SolidNavUtils.createUserInfo(
      userName: _name ?? '',
      webId: _webId,
      showWebId: false,
    );

    // Create the main content with loading overlay.

    final mainContent = Stack(
      children: [
        _isLoadingFolders
            ? const Center(child: CircularProgressIndicator())
            : _screens[_selectedIndex],
      ],
    );

    // Create responsive AppBar with action buttons.

    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryNarrow = screenWidth < NavigationConstants.veryNarrowScreenThreshold;
    final isNarrow = screenWidth < NavigationConstants.narrowScreenThreshold;
    
    final appBar = AppBar(
      title: Text(_navTabs[_selectedIndex].title),
      backgroundColor: theme.colorScheme.surface,
      actions: [
        // Version widget - hide on very narrow screens.

        if (_isVersionLoaded && !isVeryNarrow)
          MarkdownTooltip(
            message: '''

            **Version:** This is the current version of the MovieStar app. If
            the version is out of date then the text will be red. You can tap on
            the version to view the app's Change Log to determine if it is worth
            updating your version.

            ''',
            child: VersionWidget(
              version: _appVersion,
              changelogUrl:
                  'https://github.com/anusii/moviestar/blob/dev/CHANGELOG.md',
              showDate: !isNarrow, // Hide date on narrow screens.
            ),
          ),

        if (!isVeryNarrow) const SizedBox(width: 8), // Reduced spacing.

        // Essential buttons - always show.

        MarkdownTooltip(
          message: '''

          **Refresh:** Tap here to refresh all movie data and reload the latest
          information from the movie database.

          ''',
          child: IconButton(
            icon: Icon(
              Icons.refresh,
              color: theme.colorScheme.primary,
            ),
            onPressed: _handleRefresh,
          ),
        ),

        // Search button.

        MarkdownTooltip(
          message: '''

          **Search:** Tap here to search for movies by title, genre, or other
          criteria.

          ''',
          child: IconButton(
            icon: Icon(
              Icons.search,
              color: theme.colorScheme.primary,
            ),
            onPressed: _handleSearch,
          ),
        ),

        // Theme toggle - hide on very narrow screens.

        if (!isVeryNarrow)
          Consumer(
            builder: (context, ref, child) {
              final themeMode = ref.watch(themeModeProvider);
              final isDarkMode = themeMode == ThemeMode.dark;
              return MarkdownTooltip(
                message: '''

                **Theme Toggle:** Tap here to switch between light and dark themes.

                ''',
                child: IconButton(
                  icon: Icon(
                    isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () async {
                    await ref.read(themeModeProvider.notifier).toggleTheme();
                  },
                ),
              );
            },
          ),

        // Overflow menu for narrow screens.

        if (isVeryNarrow)
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: theme.colorScheme.primary,
            ),
            onSelected: (value) async {
              switch (value) {
                case 'theme':
                  await ref.read(themeModeProvider.notifier).toggleTheme();
                  break;
                case 'settings':
                  _handleSettings();
                  break;
                case 'logout':
                  _handleLogout();
                  break;
                case 'version':
                  // Show version info in a dialog.

                  if (mounted) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Version Information'),
                        content: Text('Version: $_appVersion'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(
                      ref.watch(themeModeProvider) == ThemeMode.dark
                          ? Icons.light_mode
                          : Icons.dark_mode,
                    ),
                    const SizedBox(width: 8),
                    const Text('Toggle Theme'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              if (_isVersionLoaded)
                const PopupMenuItem(
                  value: 'version',
                  child: Row(
                    children: [
                      Icon(Icons.info),
                      SizedBox(width: 8),
                      Text('Version Info'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          )
        else ...[
          // Settings and logout buttons for wider screens.

          MarkdownTooltip(
            message: '''

            **Settings:** Tap here to view and manage your MovieStar account
            settings.

            ''',
            child: IconButton(
              icon: Icon(
                Icons.settings,
                color: theme.colorScheme.primary,
              ),
              onPressed: _handleSettings,
            ),
          ),

          MarkdownTooltip(
            message: '''

            **Logout:** Tap here to securely log out of your MovieStar account.
            This will clear your current session and return you to the login
            screen.

            ''',
            child: IconButton(
              icon: Icon(
                Icons.logout,
                color: theme.colorScheme.primary,
              ),
              onPressed: _handleLogout,
            ),
          ),
        ],
      ],
    );

    // Use the Solid Navigation Manager with configurable width threshold.

    return SolidNavigationManager.movieStar(
      config: const SolidNavigationConfig(
        wideScreenThreshold: NavigationConstants.wideScreenThreshold,
        autoSwitch: true,
      ),
      tabs: _navTabs,
      selectedIndex: _selectedIndex,
      onTabSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      content: mainContent,
      userInfo: userInfo,
      onLogout: (context) => _handleLogout(),
      appBar: appBar,
      backgroundColor: theme.colorScheme.surface,
    );
  }
}
