/// HomeScreen Orchestrator Service - Central coordinator for HomeScreen components and view modes.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/core/services/cache/hive_movie_cache_service.dart';
import 'package:moviestar/core/services/favorites/favorites_service.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/shared/widgets/home/home_cache_indicator_system.dart';
import 'package:moviestar/shared/widgets/home/home_custom_list_manager.dart';
import 'package:moviestar/shared/widgets/home/home_error_handling_system.dart';
import 'package:moviestar/shared/widgets/home/home_movie_row_builder.dart';
import 'package:moviestar/shared/widgets/home/home_screen_view_mode_handler.dart';
import 'package:moviestar/widgets/error_display_widget.dart';

/// Service class that orchestrates HomeScreen components and handles complex view mode integration.
class HomeScreenOrchestrator {
  final FavoritesService favoritesService;
  final WidgetRef ref;
  final BuildContext context;
  final bool Function() isMounted;
  final void Function(Route<dynamic>) safeNavigateTo;
  final VoidCallback onStateUpdate;
  final StatefulWidget parentWidget;

  // Component instances
  late final HomeMovieRowBuilder movieRowBuilder;
  late final HomeCustomListManager customListManager;
  late final HomeErrorHandlingSystem errorHandlingSystem;
  late final HomeCacheIndicatorSystem cacheIndicatorSystem;

  // Component keys for state management
  final GlobalKey errorHandlingKey;
  final GlobalKey cacheIndicatorKey;

  // Scroll controllers for movie categories
  final Map<String, ScrollController> scrollControllers;

  HomeScreenOrchestrator({
    required this.favoritesService,
    required this.ref,
    required this.context,
    required this.isMounted,
    required this.safeNavigateTo,
    required this.onStateUpdate,
    required this.parentWidget,
    required this.errorHandlingKey,
    required this.cacheIndicatorKey,
    required this.scrollControllers,
  }) {
    _initializeComponents();
  }

  /// Initializes all component instances with proper dependency injection.
  void _initializeComponents() {
    // Initialize movie row builder
    movieRowBuilder = HomeMovieRowBuilder(
      favoritesService: favoritesService,
      scrollControllers: scrollControllers,
      isMounted: isMounted,
      safeNavigateTo: safeNavigateTo,
      buildSmartErrorWidgetCompact: _buildSmartErrorWidgetCompact,
      buildSmartErrorWidgetCompactWithRetry:
          _buildSmartErrorWidgetCompactWithRetry,
      buildSmartErrorWidget: _buildSmartErrorWidget,
      onInvalidateProviders: invalidateProviders,
      parentWidget: parentWidget,
    );

    // Initialize custom list manager
    customListManager = HomeCustomListManager(
      favoritesService: favoritesService,
      scrollControllers: scrollControllers,
      isMounted: isMounted,
      safeNavigateTo: safeNavigateTo,
      buildSmartErrorWidgetCompact: _buildSmartErrorWidgetCompact,
      buildSmartErrorWidgetCompactWithRetry:
          _buildSmartErrorWidgetCompactWithRetry,
      buildMovieRow: movieRowBuilder.buildMovieRow,
      parentWidget: parentWidget,
    );
  }

  /// Invalidates all movie providers for refresh.
  void invalidateProviders() {
    ref.invalidate(popularMoviesWithCacheInfoProvider);
    ref.invalidate(nowPlayingMoviesWithCacheInfoProvider);
    ref.invalidate(topRatedMoviesWithCacheInfoProvider);
    ref.invalidate(upcomingMoviesWithCacheInfoProvider);
  }

  /// Builds the main HomeScreen content with integrated view mode handling.
  Widget buildContent({
    required AsyncValue<CacheResult<List<Movie>>> popularMovies,
    required AsyncValue<CacheResult<List<Movie>>> nowPlayingMovies,
    required AsyncValue<CacheResult<List<Movie>>> topRatedMovies,
    required AsyncValue<CacheResult<List<Movie>>> upcomingMovies,
  }) {
    return Stack(
      children: [
        // Error handling system component
        HomeErrorHandlingSystem(
          key: errorHandlingKey,
          ref: ref,
          mounted: isMounted(),
          onStateUpdate: onStateUpdate,
        ),

        // Cache indicator system component
        HomeCacheIndicatorSystem(
          key: cacheIndicatorKey,
          ref: ref,
          mounted: isMounted(),
          popularMovies: popularMovies,
          nowPlayingMovies: nowPlayingMovies,
          topRatedMovies: topRatedMovies,
          upcomingMovies: upcomingMovies,
          onForceRefresh: invalidateProviders,
        ),

        RefreshIndicator(
          onRefresh: _forceRefresh,
          child: HomeScreenViewModeHandler(
            popularMovies: popularMovies,
            nowPlayingMovies: nowPlayingMovies,
            topRatedMovies: topRatedMovies,
            upcomingMovies: upcomingMovies,
            favoritesService: favoritesService,
            buildToWatchMovieRow: _buildToWatchMovieRow,
            buildWatchedMovieRow: _buildWatchedMovieRow,
            buildCustomListRows: _buildCustomListRows,
            buildMovieRow: _buildMovieRow,
            buildCustomListListSections: _buildCustomListListSections,
            buildAsyncListSection: _buildAsyncListSection,
            buildListSection: _buildListSection,
            buildToWatchListItems: _buildToWatchListItems,
            buildWatchedListItems: _buildWatchedListItems,
            hasApiKeyError: false,
            buildApiKeyErrorOverlay: _buildApiKeyErrorOverlay,
          ),
        ),
      ],
    );
  }

  /// Forces refresh of all movie data.
  Future<void> _forceRefresh() async {
    invalidateProviders();
  }

  // Callback methods for HomeScreenViewModeHandler

  Widget _buildToWatchMovieRow() =>
      customListManager.buildToWatchMovieRow(context, ref);

  Widget _buildWatchedMovieRow() =>
      customListManager.buildWatchedMovieRow(context, ref);

  Widget _buildCustomListRows() => customListManager.buildCustomListRows(
        context,
        (customList) => const SizedBox.shrink(),
      );

  Widget _buildMovieRow(
    String title,
    AsyncValue<CacheResult<List<Movie>>> moviesAsync,
    String key,
    CacheCategory category,
  ) =>
      movieRowBuilder.buildMovieRow(
        context,
        ref,
        title,
        moviesAsync,
        key,
        category,
        ref.watch(cacheOnlyModeProvider),
      );

  Widget _buildCustomListListSections() =>
      customListManager.buildCustomListListSections(context, ref);

  Widget _buildAsyncListSection(
    String title,
    AsyncValue<CacheResult<List<Movie>>> moviesAsync,
  ) =>
      customListManager.buildAsyncListSection(context, ref, title, moviesAsync);

  Widget _buildListSection(String title, Widget content) =>
      movieRowBuilder.buildListSection(context, title, content);

  Widget _buildToWatchListItems() =>
      customListManager.buildToWatchListItems(context);

  Widget _buildWatchedListItems() =>
      customListManager.buildWatchedListItems(context);

  Widget _buildApiKeyErrorOverlay() => const SizedBox.shrink();

  // Error handling delegation methods

  Widget _buildSmartErrorWidget(
    WidgetRef ref,
    Object error,
    StackTrace stackTrace,
  ) {
    return FutureBuilder(
      future: ErrorHandlingHelper.createUserFriendlyError(
        ref,
        error,
        stackTrace,
        invalidateProviders,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final userFriendlyError = snapshot.data;
        if (userFriendlyError != null) {
          return ErrorDisplayWidget.fromUserFriendlyError(
            error: userFriendlyError,
          );
        }
        return ErrorDisplayWidget(
          message: 'Error loading movies: $error',
          onRetry: invalidateProviders,
        );
      },
    );
  }

  Widget _buildSmartErrorWidgetCompact(
    WidgetRef ref,
    Object error,
    StackTrace stackTrace,
    String title,
    VoidCallback onRetry,
  ) {
    return FutureBuilder(
      future: ErrorHandlingHelper.createUserFriendlyError(
        ref,
        error,
        stackTrace,
        onRetry,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ErrorDisplayWidget.compact(
            message: 'Loading error details...',
          );
        }
        final userFriendlyError = snapshot.data;
        if (userFriendlyError != null) {
          return ErrorDisplayWidget.compactFromUserFriendlyError(
            error: userFriendlyError,
          );
        }
        return ErrorDisplayWidget.compact(
          message: 'Failed to load $title',
          onRetry: onRetry,
        );
      },
    );
  }

  Widget _buildSmartErrorWidgetCompactWithRetry(
    WidgetRef ref,
    Object error,
    StackTrace stackTrace,
    String title,
    VoidCallback onRetry,
  ) {
    return _buildSmartErrorWidgetCompact(
      ref,
      error,
      stackTrace,
      title,
      onRetry,
    );
  }

  /// Disposes of scroll controllers when orchestrator is no longer needed.
  void dispose() {
    for (var controller in scrollControllers.values) {
      controller.dispose();
    }
  }
}
