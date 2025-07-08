/// Main entry point for the Movie Star application.
///
// Time-stamp: <Thursday 2025-07-03 09:41:28 +1000 Graham Williams>
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
/// Authors: Kevin Wang, Graham Williams

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'package:moviestar/features/file/service/page.dart';
import 'package:moviestar/providers/theme_provider.dart';
import 'package:moviestar/screens/coming_soon_screen.dart';
import 'package:moviestar/screens/downloads_screen.dart';
import 'package:moviestar/screens/home_screen.dart';
import 'package:moviestar/screens/settings_screen.dart';
import 'package:moviestar/screens/to_watch_screen.dart';
import 'package:moviestar/screens/watched_screen.dart';
import 'package:moviestar/services/api_key_service.dart';
import 'package:moviestar/services/cache_settings_service.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/services/favorites_service_adapter.dart';
import 'package:moviestar/services/favorites_service_manager.dart';
import 'package:moviestar/services/movie_service.dart';
import 'package:moviestar/theme/app_theme.dart';
import 'package:moviestar/utils/create_solid_login.dart';
import 'package:moviestar/utils/initialise_app_folders.dart';
import 'package:moviestar/utils/is_desktop.dart';
import 'package:moviestar/utils/is_logged_in.dart';
import 'package:moviestar/widgets/floating_theme_toggle.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Initialise cache settings service early.

  await CacheSettingsService.instance.initialize();

  if (isDesktop) {
    WidgetsFlutterBinding.ensureInitialized();

    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      // Setting [alwaysOnTop] here will ensure the app starts on top of other
      // apps on the desktop so that it is visible. We later turn it of as we
      // don't want to force it always on top.

      alwaysOnTop: true,

      // The size is overridden in the first instance by linux/my_application.cc
      // but setting it here then does have effect when Restarting the app.

      // Windows has 1280x720 by default in windows/runner/main.cpp line 29 so
      // best not to override it here since under windows the 950x600 is too
      // small.

      //size: Size(750, 873),

      // The [title] is used for the window manager's window title.

      title: 'Movie Star - Manage and share ratings through private PODs',
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setAlwaysOnTop(false);
    });
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MyApp(),
    ),
  );
}

/// The root widget of the Movie Star application.
class MyApp extends ConsumerWidget {
  /// Creates a new [MyApp] widget.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final prefs = ref.watch(sharedPreferencesProvider);

    return MaterialApp(
      title: 'Movie Star',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: Builder(builder: (context) => createSolidLogin(context, prefs)),
    );
  }
}

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

  /// Service for managing favorite movies.

  late final FavoritesServiceManager _favoritesServiceManager;
  late final FavoritesService _favoritesService;
  late final ApiKeyService _apiKeyService;
  late final MovieService _movieService;

  /// List of screens to display in the bottom navigation bar.

  late final List<Widget> _screens;

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

    _buildScreens();
  }

  @override
  void dispose() {
    _apiKeyService.removeListener(_onApiKeyChanged);
    super.dispose();
  }

  void _onApiKeyChanged() {
    // When API key changes, update the movie service.

    _movieService.updateApiKey();

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
      const DownloadsScreen(),
      const FileService(),
      SettingsScreen(
        favoritesService: _favoritesService,
        apiKeyService: _apiKeyService,
        favoritesServiceManager: _favoritesServiceManager,
      ),
    ];
    _initialiseAppData();
  }

  Future<void> _initialiseAppData() async {
    final loggedIn = await isLoggedIn();
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
            debugPrint('App folders initialised.');
            // Now reload POD data since folders are ready.

            await _favoritesServiceManager.reloadPodDataAfterInit();
          },
        );
        if (mounted && _isLoadingFolders) {
          setState(() {
            _isLoadingFolders = false;
          });
        }
      }
    } else {
      debugPrint('User not logged in. Skipping App folder initialisation.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isLoadingFolders
              ? const Center(child: CircularProgressIndicator())
              : _screens[_selectedIndex],

          // Theme toggle positioned to be visible near debug banner.
          // Hide when on Settings page (index 4) since it has its own theme toggle.
          if (_selectedIndex != 4)
            const FloatingThemeToggle(right: 70, top: 16),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: 'To Watch'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Watched'),
          BottomNavigationBarItem(
            icon: Icon(Icons.upcoming),
            label: 'Coming Soon',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.download),
            label: 'Downloads',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Files'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Settings'),
        ],
      ),
    );
  }
}

/// A placeholder home page widget.

class HomePage extends StatelessWidget {
  /// Creates a new [HomePage] widget.

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movie Star'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              'Welcome to Movie Star',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Your ultimate movie companion',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
