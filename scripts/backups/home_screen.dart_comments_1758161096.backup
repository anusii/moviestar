/// Moviestar - Manage and share ratings through private PODs
///
// Time-stamp: <Sunday 2025-08-10 11:10:15 +1000 Graham Williams>
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
/// Authors: Kevin Wang, Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/core/services/cache/hive_movie_cache_service.dart';
import 'package:moviestar/core/services/favorites/favorites_service.dart';
import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/providers/view_mode_provider.dart';
import 'package:moviestar/shared/widgets/home/home_api_error_overlay.dart';
import 'package:moviestar/shared/widgets/home/home_error_handler.dart';
import 'package:moviestar/shared/widgets/home/home_view_modes.dart';
import 'package:moviestar/widgets/cache_feedback_widget.dart';

/// Main home screen of the Movie Star application, displaying featured and
/// trending movies.

class HomeScreen extends ConsumerStatefulWidget {
  /// Service for managing favorite movies.

  final FavoritesService favoritesService;

  /// Creates a new [HomeScreen] widget.

  const HomeScreen({super.key, required this.favoritesService});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

// State class for the home screen.

class _HomeScreenState extends ConsumerState<HomeScreen> with ScreenStateMixin {
  // Map of scroll controllers for different movie categories.

  final Map<String, ScrollController> _scrollControllers = {};

  // Track if initial load feedback has been shown.

  bool _hasShownInitialFeedback = false;

  // Track API key error state per view to show single error message.

  bool _hasApiKeyError = false;
  String? _apiKeyErrorMessage;

  @override
  void initState() {
    super.initState();
    _scrollControllers['toWatch'] = ScrollController();
    _scrollControllers['watched'] = ScrollController();
    _scrollControllers['popular'] = ScrollController();
    _scrollControllers['nowPlaying'] = ScrollController();
    _scrollControllers['topRated'] = ScrollController();
    _scrollControllers['upcoming'] = ScrollController();

    // Listen to custom list changes to create scroll controllers.

    widget.favoritesService.customLists.listen((customLists) {
      for (final customList in customLists) {
        if (!_scrollControllers.containsKey(customList.id)) {
          _scrollControllers[customList.id] = ScrollController();
        }
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Checks all movie providers for API key errors and updates state.
  void _checkForApiKeyErrors(
    AsyncValue<CacheResult<List<Movie>>> popularMovies,
    AsyncValue<CacheResult<List<Movie>>> nowPlayingMovies,
    AsyncValue<CacheResult<List<Movie>>> topRatedMovies,
    AsyncValue<CacheResult<List<Movie>>> upcomingMovies,
  ) {
    final errorState = HomeErrorHandler.checkForApiKeyErrors(
      popularMovies,
      nowPlayingMovies,
      topRatedMovies,
      upcomingMovies,
    );

    if (errorState.hasError != _hasApiKeyError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          safeSetState(() {
            _hasApiKeyError = errorState.hasError;
            _apiKeyErrorMessage = errorState.errorMessage;
          });
        }
      });
    }
  }

  // Forces refresh of all movie data.

  Future<void> _forceRefresh() async {
    // Check if widget is still mounted before starting refresh.

    if (!mounted) return;

    // Invalidate all providers to force refresh.

    ref.invalidate(popularMoviesWithCacheInfoProvider);
    ref.invalidate(nowPlayingMoviesWithCacheInfoProvider);
    ref.invalidate(topRatedMoviesWithCacheInfoProvider);
    ref.invalidate(upcomingMoviesWithCacheInfoProvider);
    ref.invalidate(cacheStatsProvider);

    // Force refresh through the cached service.

    try {
      final cachedService = ref.read(configuredCachedMovieServiceProvider);
      await cachedService.forceRefreshAll();
    } catch (e) {
      // Handle error gracefully without causing setState after dispose.

      if (mounted) {}
    }
  }

  // Shows cache performance feedback after initial load.

  void _showCachePerformanceFeedback() {
    if (_hasShownInitialFeedback) return;

    // Check if widget is still mounted before proceeding.

    if (!mounted) return;

    final popularMovies = ref.read(popularMoviesWithCacheInfoProvider);
    final nowPlayingMovies = ref.read(nowPlayingMoviesWithCacheInfoProvider);
    final topRatedMovies = ref.read(topRatedMoviesWithCacheInfoProvider);
    final upcomingMovies = ref.read(upcomingMoviesWithCacheInfoProvider);

    // Check if all categories have loaded.

    final allLoaded = [
      popularMovies,
      nowPlayingMovies,
      topRatedMovies,
      upcomingMovies,
    ].every((async) => async.hasValue);

    if (!allLoaded) return;

    // Extract cache results.

    final results = <String, bool>{};
    popularMovies.whenOrNull(
      data: (result) => results['Popular'] = result.fromCache,
    );
    nowPlayingMovies.whenOrNull(
      data: (result) => results['Now Playing'] = result.fromCache,
    );
    topRatedMovies.whenOrNull(
      data: (result) => results['Top Rated'] = result.fromCache,
    );
    upcomingMovies.whenOrNull(
      data: (result) => results['Upcoming'] = result.fromCache,
    );

    if (results.length == 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Check if widget is still mounted before showing feedback.

        if (mounted) {
          CacheFeedbackWidget.showCacheStatsSummary(
            context,
            categoryResults: results,
            totalTime: const Duration(milliseconds: 500),
          );
        }
      });
      _hasShownInitialFeedback = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final popularMovies = ref.watch(popularMoviesWithCacheInfoProvider);
    final nowPlayingMovies = ref.watch(nowPlayingMoviesWithCacheInfoProvider);
    final topRatedMovies = ref.watch(topRatedMoviesWithCacheInfoProvider);
    final upcomingMovies = ref.watch(upcomingMoviesWithCacheInfoProvider);
    final currentViewMode = ref.watch(viewModeProvider);

    // Check for API key errors across all providers.

    _checkForApiKeyErrors(
      popularMovies,
      nowPlayingMovies,
      topRatedMovies,
      upcomingMovies,
    );

    // Show performance feedback after initial load.

    _showCachePerformanceFeedback();

    return RefreshIndicator(
      onRefresh: _forceRefresh,
      child: _buildContentForViewMode(
        currentViewMode,
        popularMovies,
        nowPlayingMovies,
        topRatedMovies,
        upcomingMovies,
      ),
    );
  }

  // Build content based on the selected view mode.
  Widget _buildContentForViewMode(
    HomeViewMode viewMode,
    AsyncValue<CacheResult<List<Movie>>> popularMovies,
    AsyncValue<CacheResult<List<Movie>>> nowPlayingMovies,
    AsyncValue<CacheResult<List<Movie>>> topRatedMovies,
    AsyncValue<CacheResult<List<Movie>>> upcomingMovies,
  ) {
    if (_hasApiKeyError) {
      return HomeApiErrorOverlay(
        hasApiKeyError: _hasApiKeyError,
        apiKeyErrorMessage: _apiKeyErrorMessage,
        onRetry: () {
          safeSetState(() {
            _hasApiKeyError = false;
            _apiKeyErrorMessage = null;
          });
        },
      );
    }

    return HomeViewModes(
      viewMode: viewMode,
      favoritesService: widget.favoritesService,
      parentWidget: widget,
      onNavigate: safeNavigateTo,
      scrollControllers: _scrollControllers,
      popularMovies: popularMovies,
      nowPlayingMovies: nowPlayingMovies,
      topRatedMovies: topRatedMovies,
      upcomingMovies: upcomingMovies,
    );
  }
}
