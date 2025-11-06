/// Moviestar - Manage and share ratings through private PODs.
///
// Time-stamp: <Tuesday 2025-10-28 15:59:19 +1100 Graham Williams>
///
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
/// Authors: Kevin Wang, Graham Williams, Ashley Tang, Tony Chen.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solidpod/solidpod.dart';
import 'package:solidui/solidui.dart';

import 'package:moviestar/core/services/api/key_service.dart';
import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/core/services/favorites/service_adapter.dart';
import 'package:moviestar/core/services/favorites/service_manager.dart';
import 'package:moviestar/moviestar.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart'
    hide directApiKeyProvider;
import 'package:moviestar/providers/cached_movie_service_provider/provider_definitions.dart'
    show directApiKeyProvider;
import 'package:moviestar/providers/view_mode_provider.dart';
import 'package:moviestar/screens/enhanced_search_screen.dart';
import 'package:moviestar/screens/settings_screen.dart';
import 'package:moviestar/utils/create_solid_login.dart';
import 'package:moviestar/utils/initialise_app_folders.dart';
import 'package:moviestar/utils/is_logged_in.dart';
import 'package:moviestar/utils/show_api_key_dialog.dart';
import 'package:moviestar/widgets/solid_scaffold_config.dart';

class MyHomePage extends ConsumerStatefulWidget {
  final SharedPreferences prefs;

  const MyHomePage({super.key, required this.title, required this.prefs});

  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

/// State class for the main screen.

class _MyHomePageState extends ConsumerState<MyHomePage> {
  bool _isLoadingFolders = false;
  String? _webId;
  String? _name;

  /// Service for managing favorite movies.

  late final FavoritesServiceManager _favoritesServiceManager;
  late final FavoritesService _favoritesService;

  /// Navigation menu items configuration.

  late List<SolidMenuItem> _menuItems;

  /// Current selected tab index.

  int _selectedTabIndex = 0;

  /// Flag to show Settings screen instead of menu content.

  bool _showSettings = false;

  /// API key service reference for cleanup.

  late final ApiKeyService _apiKeyService;

  @override
  void initState() {
    super.initState();
    _favoritesServiceManager = FavoritesServiceManager(
      widget.prefs,
      context,
      widget,
    );
    _favoritesService = FavoritesServiceAdapter(_favoritesServiceManager);

    // Create API key service directly with context.

    _apiKeyService = ApiKeyService(context, widget);

    // Listen for API key changes.

    _apiKeyService.addListener(_onApiKeyChanged);

    _loadUserInfo();
    _buildScreens();
  }

  @override
  void dispose() {
    _apiKeyService.removeListener(_onApiKeyChanged);

    // Clear global navigation callback.

    super.dispose();
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
      // Extract domain from WebID for a simple display name.

      final uri = Uri.parse(webId);
      final domain = uri.host;

      // Try to extract a meaningful part.

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

  Future<void> _onApiKeyChanged() async {
    if (!mounted) return;

    // When API key changes, update the movie service.

    final movieService = ref.read(movieServiceProvider);
    await movieService.updateApiKey();

    // Clear cache to force fresh data with new API key.

    try {
      final cachedService = ref.read(configuredCachedMovieServiceProvider);
      await cachedService.clearAllCache();
    } catch (e) {
      // Log but don't fail - provider invalidation will still work.
    }

    // Invalidate all movie providers to force refresh with new API key.

    ref.invalidate(recommendedMoviesWithCacheInfoProvider);
    ref.invalidate(nowPlayingMoviesWithCacheInfoProvider);
    ref.invalidate(topRatedMoviesWithCacheInfoProvider);
    ref.invalidate(upcomingMoviesWithCacheInfoProvider);
    ref.invalidate(configuredCachedMovieServiceProvider);

    // Rebuild screens to ensure they have the latest data.

    if (mounted) {
      setState(() {
        _buildScreens();
      });

      // Force refresh by rebuilding.

      setState(() {});
    }
  }

  void _buildScreens() {
    _menuItems = SolidScaffoldConfig.createMenuItems(
      favoritesService: _favoritesService,
      apiKeyService: _apiKeyService,
      favoritesServiceManager: _favoritesServiceManager,
    );

    _initialiseAppData();
  }

  Future<void> _initialiseAppData() async {
    final loggedIn = await isLoggedIn();

    // Refresh user info based on login status.

    await _loadUserInfo();

    if (loggedIn) {
      // Check if API key is present and show dialog immediately if missing.

      bool hasApiKey = false;
      try {
        final apiKey = await _apiKeyService.getApiKey();
        hasApiKey = apiKey != null && apiKey.trim().isNotEmpty;

        if (!hasApiKey) {
          // Show API key dialog immediately but continue with POD initialization.

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (mounted) {
              final apiKeySet = await showApiKeyDialog(
                context,
                _apiKeyService,
                ref: ref,
                onApiKeySet: () {
                  // Reinitialize after API key is set.

                  reinitializeAfterApiKey();
                },
              );
              if (!apiKeySet) {
                // If user dismissed without setting API key, they can still use POD features.
              }
            }
          });
        }
      } catch (e) {
        // Failed to initialize API services.
      }

      // Always initialize POD folders regardless of API key status.

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

            // Automatically enable POD storage for authenticated users if not already enabled.

            if (!_favoritesServiceManager.isPodStorageEnabled) {
              try {
                final enabled =
                    await _favoritesServiceManager.enablePodStorage();
                if (!enabled) {}
              } catch (e) {
                // Failed to enable POD storage.
              }
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

    ref.invalidate(recommendedMoviesWithCacheInfoProvider);
    ref.invalidate(nowPlayingMoviesWithCacheInfoProvider);
    ref.invalidate(topRatedMoviesWithCacheInfoProvider);
    ref.invalidate(upcomingMoviesWithCacheInfoProvider);
    ref.invalidate(configuredCachedMovieServiceProvider);
  }

  /// Handles the search action.

  void _handleSearch() async {
    if (mounted) {
      try {
        // Get the content service with proper API key.

        final contentService =
            await ref.read(directContentServiceProvider.future);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EnhancedSearchScreen(
                favoritesService: _favoritesService,
                contentService: contentService,
              ),
            ),
          );
        }
      } catch (e) {
        // Show error or fallback.

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Search is not available at the moment'),
            ),
          );
        }
      }
    }
  }

  /// Handles the view mode toggle action.

  void _handleViewModeToggle() {
    ref.read(viewModeProvider.notifier).cycleViewMode();
  }

  /// Handles the logout action.

  void _handleLogout() {
    logoutPopup(context, const MovieStar());
  }

  /// Handles the login action.

  void _handleLogin() {
    // Navigate to login page using createSolidLogin.

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Login to Movie Star'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: createSolidLogin(context, widget.prefs),
        ),
      ),
    );
  }

  /// Handles the settings action.

  void _handleSettings() {
    // Show Settings by replacing the body content.

    if (mounted) {
      setState(() {
        _showSettings = true;
      });
    }
  }

  /// Reinitializes the app after API key is set.

  Future<void> reinitializeAfterApiKey() async {
    if (!mounted) return;

    // Invalidate all providers immediately to trigger API key refresh.

    ref.invalidate(directApiKeyProvider);
    ref.invalidate(apiKeyProvider);

    // Allow time for core providers to refresh.

    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) return;

    // Clear cache to force fresh data with new API key.

    try {
      final cachedService = ref.read(configuredCachedMovieServiceProvider);
      await cachedService.clearAllCache();
    } catch (e) {
      // Log but don't fail - provider invalidation will still work.
    }

    // Invalidate all movie providers for immediate refresh.

    ref.invalidate(movieServiceProvider);
    ref.invalidate(contentServiceProvider);
    ref.invalidate(recommendedMoviesWithCacheInfoProvider);
    ref.invalidate(nowPlayingMoviesWithCacheInfoProvider);
    ref.invalidate(topRatedMoviesWithCacheInfoProvider);
    ref.invalidate(upcomingMoviesWithCacheInfoProvider);
    ref.invalidate(configuredCachedMovieServiceProvider);

    // Re-initialize app data.

    await _initialiseAppData();
  }

  /// Handles menu tab selection.

  void _onTabSelected(int index) {
    if (mounted) {
      setState(() {
        _selectedTabIndex = index;
        _showSettings = false; // Hide Settings when navigating to other tabs
      });
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

    final solidScaffold = SolidScaffold(
      menu: _menuItems,
      selectedIndex: _selectedTabIndex,
      onMenuSelected: _onTabSelected,
      appBar: SolidAppBarConfig(
        title: 'MovieStar',
        versionConfig: mounted
            ? const SolidVersionConfig(
                changelogUrl:
                    'https://github.com/anusii/moviestar/blob/dev/CHANGELOG.md',
                showDate: true,
              )
            : null,
        actions: SolidScaffoldConfig.createAppBarActions(
          ref: ref,
          onViewModeToggle: _handleViewModeToggle,
          onRefresh: _handleRefresh,
          onSearch: _handleSearch,
        ),
        overflowItems: SolidScaffoldConfig.createOverflowItems(
          onLogout: _handleLogout,
          onSettings: _handleSettings,
        ),
      ),
      aboutConfig: SolidAboutConfig(
        applicationName: 'MovieStar',
        applicationIcon: const Icon(
          Icons.movie,
          size: 64,
        ),
        applicationLegalese: '''
        © ${DateTime.now().year} Software Innovation Institute, ANU
        ''',
        text: '''

        MovieStar is a movie discovery and management application built with
        Flutter, which helps you discover, track, and manage your favourite
        movies using the power of Solid PODs for decentralised data storage.

        Licensed under the GNU General Public License v3.0

        This is free software: you are free to change and redistribute it.
        There is NO WARRANTY, to the extent permitted by law.

        Visit [https://github.com/anusii/moviestar](https://github.com/anusii/moviestar)
        for more information.

        ''',
      ),
      statusBar: SolidStatusBarConfig(
        serverInfo: SolidServerInfo(
          serverUri: _webId?.split('profile')[0] ?? 'Not connected',
          displayText: _webId?.split('profile')[0] ?? 'Not connected',
          isClickable: _webId != null,
        ),
        loginStatus: SolidLoginStatus(
          webId: _webId,
          onTap: _handleLogout,
        ),
        onLogin: _handleLogin,
        securityKeyStatus: SolidSecurityKeyStatus(
          isKeySaved: true,
          onTap: () => {
            // Handle security key tap - could show key management dialog.
            //print('Security key status tapped').
          },
        ),
        showOnNarrowScreens: false,
      ),
      userInfo: userInfo,
      onLogout: (context) => _handleLogout(),
      backgroundColor: theme.colorScheme.surface,
      themeToggle: const SolidThemeToggleConfig(
        enabled: true,
        showInAppBarActions: true,
      ),
    );

    // Return appropriate widget with proper loading overlay.

    if (_showSettings) {
      return _buildSettingsOverlay(solidScaffold);
    }

    // Individual components handle their own loading states.
    // Removed full-screen loading overlay to prevent sudden loading indicator.

    return solidScaffold;
  }

  /// Builds the Settings screen as an overlay on top of the SolidScaffold.

  Widget _buildSettingsOverlay(Widget solidScaffold) {
    return Stack(
      children: [
        solidScaffold,
        Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _showSettings = false;
                  });
                }
              },
            ),
          ),
          body: SettingsScreen(
            favoritesService: _favoritesService,
            apiKeyService: _apiKeyService,
            favoritesServiceManager: _favoritesServiceManager,
          ),
        ),
      ],
    );
  }
}
