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
import 'package:gap/gap.dart';

import 'package:moviestar/models/app_error.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/my_home_page.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/providers/view_mode_provider.dart';
import 'package:moviestar/screens/custom_list_detail_screen.dart';
import 'package:moviestar/screens/movie_category_screen.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/services/api_key_validation_service.dart';
import 'package:moviestar/services/cached_movie_service.dart';
import 'package:moviestar/services/content_service.dart';
import 'package:moviestar/services/error_mapper_service.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/services/favorites_service_adapter.dart';
import 'package:moviestar/services/hive_movie_cache_service.dart';
import 'package:moviestar/services/network_connectivity_service.dart';
import 'package:moviestar/widgets/cache_feedback_widget.dart';
import 'package:moviestar/widgets/error_display_widget.dart';
import 'package:moviestar/widgets/movie_card.dart';
import 'package:moviestar/widgets/movie_kanban_board.dart';

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

class _HomeScreenState extends ConsumerState<HomeScreen> {
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
    // Check if any provider has an API key error.

    bool foundApiKeyError = false;
    String? errorMessage;

    final providers = [
      popularMovies,
      nowPlayingMovies,
      topRatedMovies,
      upcomingMovies,
    ];

    for (final provider in providers) {
      if (provider.hasError) {
        final error = provider.error!;
        // Check if this is an API key error.

        if (_isApiKeyError(error)) {
          foundApiKeyError = true;
          errorMessage = error.toString();
          break;
        }
      }
    }

    // Update state if API key error status changed.

    if (foundApiKeyError != _hasApiKeyError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasApiKeyError = foundApiKeyError;
            _apiKeyErrorMessage = errorMessage;
          });
        }
      });
    }
  }

  /// Checks if an error is an API key related error.

  bool _isApiKeyError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('401') ||
        errorString.contains('403') ||
        errorString.contains('unauthorized') ||
        errorString.contains('api key') ||
        errorString.contains('forbidden');
  }

  // Builds the to-watch movies row using FavoritesServiceAdapter stream.

  Widget _buildToWatchMovieRow() {
    final cacheOnlyMode = ref.watch(cacheOnlyModeProvider);

    return StreamBuilder<List<Movie>>(
      stream: widget.favoritesService.toWatchMovies,
      builder: (context, snapshot) {
        // Check if the service is a FavoritesServiceAdapter with caching.

        final isCached = widget.favoritesService is FavoritesServiceAdapter;
        Map<String, dynamic>? cacheStats;

        if (isCached) {
          final adapter = widget.favoritesService as FavoritesServiceAdapter;
          cacheStats = adapter.getCacheStats();
        }

        final toWatchStats = cacheStats?['toWatch'];
        final fromCache = toWatchStats?['valid'] ?? false;
        final cacheAge = toWatchStats?['age'] != null
            ? Duration(minutes: toWatchStats['age'])
            : null;

        final cacheResult = CacheResult(
          data: snapshot.data ?? [],
          fromCache: fromCache,
          cacheAge: cacheAge,
          cachedAt: cacheAge != null ? DateTime.now().subtract(cacheAge) : null,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'To Watch',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) ...[
                          const Gap(8),
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Show cache indicator for user data if cached.
                  if (fromCache && cacheAge != null)
                    _buildCacheAgeBadge(cacheAge),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: _buildToWatchMovieContent(
                snapshot,
                cacheResult,
                cacheOnlyMode,
              ),
            ),
          ],
        );
      },
    );
  }

  // Builds the content for to-watch movies based on stream state.

  Widget _buildToWatchMovieContent(
    AsyncSnapshot<List<Movie>> snapshot,
    CacheResult<List<Movie>> cacheResult,
    bool cacheOnlyMode,
  ) {
    if (snapshot.hasError) {
      return ErrorDisplayWidget.compact(
        message: 'Failed to load To Watch',
        onRetry: () {
          // No specific retry action for user data.
        },
      );
    }

    // Enhanced loading indicator for initial load and connection state.

    if (snapshot.connectionState == ConnectionState.waiting ||
        !snapshot.hasData) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            const Gap(12),
            Text(
              'Loading To Watch movies...',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final movies = cacheResult.data;
    if (movies.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No movies in your to-watch list yet',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Scrollbar(
      controller: _scrollControllers['toWatch'],
      thickness: 6,
      radius: const Radius.circular(3),
      thumbVisibility: true,
      child: ListView.builder(
        controller: _scrollControllers['toWatch'],
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: MovieCard.poster(
              movie: movie,
              fromCache: cacheResult.fromCache,
              cacheAge: cacheResult.cacheAge,
              cacheOnlyMode: cacheOnlyMode,
              favoritesService: widget.favoritesService,
              parentWidget: widget,
              onTap: () {
                // Check if widget is still mounted before navigation.

                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailsScreen(
                        movie: movie,
                        favoritesService: widget.favoritesService,
                        contentType: movie.contentType ?? ContentType.movie,
                      ),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  // Builds the watched movies row using FavoritesServiceAdapter stream.

  Widget _buildWatchedMovieRow() {
    final cacheOnlyMode = ref.watch(cacheOnlyModeProvider);

    return StreamBuilder<List<Movie>>(
      stream: widget.favoritesService.watchedMovies,
      builder: (context, snapshot) {
        // Check if the service is a FavoritesServiceAdapter with caching.

        final isCached = widget.favoritesService is FavoritesServiceAdapter;
        Map<String, dynamic>? cacheStats;

        if (isCached) {
          final adapter = widget.favoritesService as FavoritesServiceAdapter;
          cacheStats = adapter.getCacheStats();
        }

        final watchedStats = cacheStats?['watched'];
        final fromCache = watchedStats?['valid'] ?? false;
        final cacheAge = watchedStats?['age'] != null
            ? Duration(minutes: watchedStats['age'])
            : null;

        final cacheResult = CacheResult(
          data: snapshot.data ?? [],
          fromCache: fromCache,
          cacheAge: cacheAge,
          cachedAt: cacheAge != null ? DateTime.now().subtract(cacheAge) : null,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'Watched',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) ...[
                          const Gap(8),
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Show cache indicator for user data if cached.
                  if (fromCache && cacheAge != null)
                    _buildCacheAgeBadge(cacheAge),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: _buildWatchedMovieContent(
                snapshot,
                cacheResult,
                cacheOnlyMode,
              ),
            ),
          ],
        );
      },
    );
  }

  // Builds the content for watched movies based on stream state.

  Widget _buildWatchedMovieContent(
    AsyncSnapshot<List<Movie>> snapshot,
    CacheResult<List<Movie>> cacheResult,
    bool cacheOnlyMode,
  ) {
    if (snapshot.hasError) {
      return ErrorDisplayWidget.compact(
        message: 'Failed to load Watched',
        onRetry: () {
          // No specific retry action for user data.
        },
      );
    }

    // Enhanced loading indicator for initial load and connection state.

    if (snapshot.connectionState == ConnectionState.waiting ||
        !snapshot.hasData) {
      return Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            const Gap(12),
            Text(
              'Loading Watched movies...',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final movies = cacheResult.data;
    if (movies.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No watched movies yet',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Scrollbar(
      controller: _scrollControllers['watched'],
      thickness: 6,
      radius: const Radius.circular(3),
      thumbVisibility: true,
      child: ListView.builder(
        controller: _scrollControllers['watched'],
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: MovieCard.poster(
              movie: movie,
              fromCache: cacheResult.fromCache,
              cacheAge: cacheResult.cacheAge,
              cacheOnlyMode: cacheOnlyMode,
              favoritesService: widget.favoritesService,
              parentWidget: widget,
              onTap: () {
                // Check if widget is still mounted before navigation
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailsScreen(
                        movie: movie,
                        favoritesService: widget.favoritesService,
                        contentType: movie.contentType ?? ContentType.movie,
                      ),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  // Builds a horizontal scrollable row of movies with cache indicators.

  Widget _buildMovieRow(
    String title,
    AsyncValue<CacheResult<List<Movie>>> moviesAsync,
    String key,
    CacheCategory category,
  ) {
    final cacheOnlyMode = ref.watch(cacheOnlyModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // View More button for sections with many items.

              moviesAsync.when(
                data: (cacheResult) {
                  if (cacheResult.data.length > 10) {
                    return TextButton(
                      onPressed: () => _navigateToMovieCategory(
                        title,
                        cacheResult.data,
                        fromCache: cacheResult.fromCache,
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'View More',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
              ),
              const Gap(8),
              _buildSectionCacheIndicator(moviesAsync, cacheOnlyMode),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: moviesAsync.when(
            data: (cacheResult) => Scrollbar(
              controller: _scrollControllers[key],
              thickness: 6,
              radius: const Radius.circular(3),
              thumbVisibility: true,
              child: ListView.builder(
                controller: _scrollControllers[key],
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: cacheResult.data.length,
                itemBuilder: (context, index) {
                  final movie = cacheResult.data[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: MovieCard.poster(
                      movie: movie,
                      fromCache: cacheResult.fromCache,
                      cacheAge: cacheResult.cacheAge,
                      cacheOnlyMode: cacheOnlyMode,
                      favoritesService: widget.favoritesService,
                      parentWidget: widget,
                      onTap: () {
                        // Check if widget is still mounted before navigation.

                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MovieDetailsScreen(
                                movie: movie,
                                favoritesService: widget.favoritesService,
                                contentType:
                                    movie.contentType ?? ContentType.movie,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            loading: () => Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const Gap(12),
                  Text(
                    'Loading movies...',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            error: (error, stack) => _buildSmartErrorWidgetCompact(
              ref,
              error,
              stack,
              title,
              () {
                // Check if widget is still mounted before invalidating providers.

                if (mounted) {
                  ref.invalidate(popularMoviesWithCacheInfoProvider);
                  ref.invalidate(nowPlayingMoviesWithCacheInfoProvider);
                  ref.invalidate(topRatedMoviesWithCacheInfoProvider);
                  ref.invalidate(upcomingMoviesWithCacheInfoProvider);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // Builds cache indicator for section headers.

  Widget _buildSectionCacheIndicator(
    AsyncValue<CacheResult<List<Movie>>> moviesAsync,
    bool cacheOnlyMode,
  ) {
    return moviesAsync.when(
      data: (cacheResult) {
        if (cacheOnlyMode) {
          return _buildOfflineModeBadge();
        }

        if (cacheResult.fromCache && cacheResult.cacheAge != null) {
          return _buildCacheAgeBadge(cacheResult.cacheAge!);
        }

        if (cacheResult.fromCache) {
          return _buildCacheBadge();
        } else {
          return _buildNetworkBadge();
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // Builds offline mode badge.

  Widget _buildOfflineModeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.offline_pin, size: 12, color: Colors.white),
          Gap(4),
          Text(
            'OFFLINE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Builds cache age badge.

  Widget _buildCacheAgeBadge(Duration cacheAge) {
    final ageText = _formatCacheAge(cacheAge);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.offline_bolt, size: 12, color: Colors.white),
          const Gap(4),
          Text(
            ageText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Builds cache badge for fresh cache data.

  Widget _buildCacheBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.offline_bolt, size: 12, color: Colors.white),
          Gap(4),
          Text(
            'CACHED',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Builds network badge for fresh data.

  Widget _buildNetworkBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi, size: 12, color: Colors.white),
          Gap(4),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Formats cache age into human-readable string.

  String _formatCacheAge(Duration age) {
    if (age.inDays > 0) {
      return '${age.inDays}d old';
    } else if (age.inHours > 0) {
      return '${age.inHours}h old';
    } else if (age.inMinutes > 0) {
      return '${age.inMinutes}m old';
    } else {
      return 'cached';
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

      if (mounted) {
      }
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
    // If there's an API key error, show the error overlay instead of the normal content.

    if (_hasApiKeyError) {
      return _buildApiKeyErrorOverlay();
    }

    switch (viewMode) {
      case HomeViewMode.grid:
        return _buildGridView(
          popularMovies,
          nowPlayingMovies,
          topRatedMovies,
          upcomingMovies,
        );
      case HomeViewMode.kanban:
        return _buildKanbanView(
          popularMovies,
          nowPlayingMovies,
          topRatedMovies,
          upcomingMovies,
        );
      case HomeViewMode.list:
        return _buildListView(
          popularMovies,
          nowPlayingMovies,
          topRatedMovies,
          upcomingMovies,
        );
    }
  }

  // Navigate to a dedicated page for viewing all movies in a category.

  void _navigateToMovieCategory(
    String categoryName,
    List<Movie> movies, {
    bool fromCache = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieCategoryScreen(
          categoryName: categoryName,
          movies: movies,
          favoritesService: widget.favoritesService,
          fromCache: fromCache,
        ),
      ),
    );
  }

  // Build the traditional grid/horizontal scroll view (current implementation).

  Widget _buildGridView(
    AsyncValue<CacheResult<List<Movie>>> popularMovies,
    AsyncValue<CacheResult<List<Movie>>> nowPlayingMovies,
    AsyncValue<CacheResult<List<Movie>>> topRatedMovies,
    AsyncValue<CacheResult<List<Movie>>> upcomingMovies,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToWatchMovieRow(),
          _buildWatchedMovieRow(),
          _buildCustomListRows(),
          _buildMovieRow(
            'Popular on Movie Star',
            popularMovies,
            'popular',
            CacheCategory.popular,
          ),
          _buildMovieRow(
            'Now Playing',
            nowPlayingMovies,
            'nowPlaying',
            CacheCategory.nowPlaying,
          ),
          _buildMovieRow(
            'Top Rated',
            topRatedMovies,
            'topRated',
            CacheCategory.topRated,
          ),
          _buildMovieRow(
            'Upcoming',
            upcomingMovies,
            'upcoming',
            CacheCategory.upcoming,
          ),
        ],
      ),
    );
  }

  // Build the kanban view with AppFlowy Board.

  Widget _buildKanbanView(
    AsyncValue<CacheResult<List<Movie>>> popularMovies,
    AsyncValue<CacheResult<List<Movie>>> nowPlayingMovies,
    AsyncValue<CacheResult<List<Movie>>> topRatedMovies,
    AsyncValue<CacheResult<List<Movie>>> upcomingMovies,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: MovieKanbanBoard(
        favoritesService: widget.favoritesService,
      ),
    );
  }

  // Build a list view of movies.

  Widget _buildListView(
    AsyncValue<CacheResult<List<Movie>>> popularMovies,
    AsyncValue<CacheResult<List<Movie>>> nowPlayingMovies,
    AsyncValue<CacheResult<List<Movie>>> topRatedMovies,
    AsyncValue<CacheResult<List<Movie>>> upcomingMovies,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // To Watch and Watched sections.

          _buildListSection('To Watch', _buildToWatchListItems()),
          _buildListSection('Watched', _buildWatchedListItems()),

          // Custom List sections.

          _buildCustomListListSections(),

          // API Movie sections.

          _buildAsyncListSection('Popular on Movie Star', popularMovies),
          _buildAsyncListSection('Now Playing', nowPlayingMovies),
          _buildAsyncListSection('Top Rated', topRatedMovies),
          _buildAsyncListSection('Upcoming', upcomingMovies),
        ],
      ),
    );
  }

  // Build a list section with title and items.

  Widget _buildListSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              // Add View More button based on section type.

              _buildViewMoreForUserList(title),
            ],
          ),
        ),
        content,
        const Gap(16),
      ],
    );
  }

  // Build View More button for user lists (To Watch/Watched).

  Widget _buildViewMoreForUserList(String title) {
    if (title == 'To Watch') {
      return StreamBuilder<List<Movie>>(
        stream: widget.favoritesService.toWatchMovies,
        builder: (context, snapshot) {
          final movies = snapshot.data ?? [];
          if (movies.length > 5) {
            return TextButton(
              onPressed: () => _navigateToMovieCategory(title, movies),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View More',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 11,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      );
    } else if (title == 'Watched') {
      return StreamBuilder<List<Movie>>(
        stream: widget.favoritesService.watchedMovies,
        builder: (context, snapshot) {
          final movies = snapshot.data ?? [];
          if (movies.length > 5) {
            return TextButton(
              onPressed: () => _navigateToMovieCategory(title, movies),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'View More',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 11,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      );
    }
    return const SizedBox.shrink();
  }

  // Build a list section for async movie data.

  Widget _buildAsyncListSection(
    String title,
    AsyncValue<CacheResult<List<Movie>>> moviesAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              // View More button for sections with many items.

              moviesAsync.when(
                data: (cacheResult) {
                  if (cacheResult.data.length > 5) {
                    return TextButton(
                      onPressed: () => _navigateToMovieCategory(
                        title,
                        cacheResult.data,
                        fromCache: cacheResult.fromCache,
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'View More',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        moviesAsync.when(
          data: (cacheResult) =>
              _buildMovieListItems(cacheResult.data, cacheResult.fromCache),
          loading: () => Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const Gap(12),
                Text(
                  'Loading movies...',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSmartErrorWidget(ref, error, stack),
          ),
        ),
        const Gap(16),
      ],
    );
  }

  // Build list items for To Watch movies.

  Widget _buildToWatchListItems() {
    return StreamBuilder<List<Movie>>(
      stream: widget.favoritesService.toWatchMovies,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const Gap(12),
                Text(
                  'Loading To Watch movies...',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }
        final movies = snapshot.data!;
        if (movies.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No movies in your watchlist'),
          );
        }
        return _buildMovieListItems(movies.take(5).toList(), false);
      },
    );
  }

  // Build list items for Watched movies.

  Widget _buildWatchedListItems() {
    return StreamBuilder<List<Movie>>(
      stream: widget.favoritesService.watchedMovies,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const Gap(12),
                Text(
                  'Loading Watched movies...',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }
        final movies = snapshot.data!;
        if (movies.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No watched movies yet'),
          );
        }
        return _buildMovieListItems(movies.take(5).toList(), false);
      },
    );
  }

  // Build list items for a list of movies.

  Widget _buildMovieListItems(List<Movie> movies, bool fromCache) {
    if (movies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No movies available'),
      );
    }

    return Column(
      children: movies.take(5).map((movie) {
        return MovieCard.listItem(
          movie: movie,
          fromCache: fromCache,
          favoritesService: widget.favoritesService,
          parentWidget: widget,
          onTap: () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MovieDetailsScreen(
                    movie: movie,
                    favoritesService: widget.favoritesService,
                    contentType: movie.contentType ?? ContentType.movie,
                  ),
                ),
              );
            }
          },
        );
      }).toList(),
    );
  }

  // Build custom list rows for grid view.

  Widget _buildCustomListRows() {
    return StreamBuilder<List<CustomList>>(
      stream: widget.favoritesService.customLists,
      builder: (context, snapshot) {
        // Show loading indicator while waiting for custom lists
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading Custom Lists...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        final customLists = snapshot.data ?? [];
        if (customLists.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: customLists.map((customList) {
            return _buildCustomListMovieRow(customList);
          }).toList(),
        );
      },
    );
  }

  // Build a horizontal scrollable row for a custom list.

  Widget _buildCustomListMovieRow(CustomList customList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToCustomListDetail(customList),
                  child: Text(
                    customList.name,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Custom list count badge.

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${customList.movieCount}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              const Gap(8),
              if (customList.movieCount > 5)
                TextButton(
                  onPressed: () => _navigateToCustomListDetail(customList),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View More',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: _buildCustomListContent(customList),
        ),
      ],
    );
  }

  // Build content for a custom list.

  Widget _buildCustomListContent(CustomList customList) {
    // Get movie IDs from the custom list.

    final movieIds = customList.movieIds;
    
    // If using POD storage, try to get movies from POD first
    if (widget.favoritesService is FavoritesServiceAdapter) {
      final adapter = widget.favoritesService as FavoritesServiceAdapter;
      
      if (adapter.isPodStorageEnabled) {
        return FutureBuilder<List<Movie>>(
          future: widget.favoritesService.getMoviesInCustomList(customList.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
            }
            
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final podMovies = snapshot.data!;
              
              return _buildMovieCardsFromMovieObjects(podMovies, customList);
            } else {
              // Fallback to loading from API
              return _buildMovieCardsFromIds(movieIds, customList);
            }
          },
        );
      }
    }

    if (movieIds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No movies in ${customList.name} yet',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return _buildMovieCardsFromIds(movieIds, customList);
  }

  // Build movie cards from movie objects (when we have full data from PODs)
  Widget _buildMovieCardsFromMovieObjects(List<Movie> movies, CustomList customList) {
    return Scrollbar(
      controller: _scrollControllers[customList.id] ?? ScrollController(),
      thickness: 6,
      radius: const Radius.circular(3),
      thumbVisibility: true,
      child: ListView.builder(
        controller: _scrollControllers[customList.id],
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildCustomListMovieCardFromMovie(movie),
          );
        },
      ),
    );
  }

  // Build movie cards from IDs (fallback when POD data not available)
  Widget _buildMovieCardsFromIds(List<int> movieIds, CustomList customList) {
    return Scrollbar(
      controller: _scrollControllers[customList.id] ?? ScrollController(),
      thickness: 6,
      radius: const Radius.circular(3),
      thumbVisibility: true,
      child: ListView.builder(
        controller: _scrollControllers[customList.id],
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: movieIds.length,
        itemBuilder: (context, index) {
          final movieId = movieIds[index];
          final contentType = customList.getContentTypeAt(index);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildCustomListMovieCard(movieId, contentType: contentType),
          );
        },
      ),
    );
  }

  // Build a movie card directly from a Movie object using consistent MovieCard styling
  Widget _buildCustomListMovieCardFromMovie(Movie movie) {
    return MovieCard.poster(
      movie: movie,
      fromCache: true, // Since we got it from PODs
      favoritesService: widget.favoritesService,
      parentWidget: widget,
      onTap: () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MovieDetailsScreen(
                movie: movie,
                favoritesService: widget.favoritesService,
                contentType: movie.contentType ?? ContentType.movie,
              ),
            ),
          );
        }
      },
    );
  }

  // Get content as Movie based on known content type.

  Future<Movie> _getContentAsMovieWithType(
    int contentId,
    String contentType,
    CachedMovieService cachedMovieService,
    ContentService contentService,
  ) async {
    if (contentType == 'tv') {
      final tvShowContent = await contentService.getTVDetails(contentId);
      return Movie.fromContentItem(tvShowContent);
    } else {
      return await cachedMovieService.getMovieDetails(contentId);
    }
  }

  // Build a movie card for a custom list movie (loading movie details on demand).

  Widget _buildCustomListMovieCard(
    int movieId, {
    String contentType = 'movie',
  }) {
    final cachedMovieService = ref.read(cachedMovieServiceProvider);
    final contentService = ref.read(contentServiceProvider);

    return FutureBuilder<Movie>(
      future: _getContentAsMovieWithType(
        movieId,
        contentType,
        cachedMovieService,
        contentService,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            width: 100,
            height: 150,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 24,
                ),
                const Gap(4),
                Text(
                  'Error',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return Container(
            width: 100,
            height: 150,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const Gap(8),
                Text(
                  'Loading...',
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        }

        final movie = snapshot.data!;
        return MovieCard.poster(
          movie: movie,
          fromCache: false,
          favoritesService: widget.favoritesService,
          parentWidget: widget,
          onTap: () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MovieDetailsScreen(
                    movie: movie,
                    favoritesService: widget.favoritesService,
                    contentType: movie.contentType ?? ContentType.movie,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  // Build custom list sections for list view.

  Widget _buildCustomListListSections() {
    return StreamBuilder<List<CustomList>>(
      stream: widget.favoritesService.customLists,
      builder: (context, snapshot) {
        // Show loading indicator while waiting for custom lists
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading Custom Lists...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        final customLists = snapshot.data ?? [];
        if (customLists.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: customLists.map((customList) {
            return _buildCustomListSection(customList);
          }).toList(),
        );
      },
    );
  }

  // Build a list section for a custom list.

  Widget _buildCustomListSection(CustomList customList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToCustomListDetail(customList),
                  child: Text(
                    customList.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              if (customList.movieCount > 5)
                TextButton(
                  onPressed: () => _navigateToCustomListDetail(customList),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View More',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
        _buildCustomListItems(customList),
        const Gap(16),
      ],
    );
  }

  // Build list items for a custom list.

  Widget _buildCustomListItems(CustomList customList) {
    final movieIds = customList.movieIds;

    if (movieIds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('No movies in ${customList.name}'),
      );
    }

    // If using POD storage, try to get movies from POD first (same as grid view)
    if (widget.favoritesService is FavoritesServiceAdapter) {
      final adapter = widget.favoritesService as FavoritesServiceAdapter;
      
      if (adapter.isPodStorageEnabled) {
        return FutureBuilder<List<Movie>>(
          future: widget.favoritesService.getMoviesInCustomList(customList.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
            }
            
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final podMovies = snapshot.data!;
              
              return _buildCustomListItemsFromMovieObjects(podMovies);
            } else {
              // Fallback to loading from API
              return _buildCustomListItemsFromIds(movieIds, customList);
            }
          },
        );
      }
    }

    return _buildCustomListItemsFromIds(movieIds, customList);
  }

  // Build list items from movie objects (when we have full data from PODs)
  Widget _buildCustomListItemsFromMovieObjects(List<Movie> movies) {
    final displayMovies = movies.take(5).toList();
    
    return Column(
      children: displayMovies.map((movie) {
        return _buildCustomListMovieListItemFromMovie(movie);
      }).toList(),
    );
  }

  // Build list items from IDs (fallback when POD data not available)
  Widget _buildCustomListItemsFromIds(List<int> movieIds, CustomList customList) {
    final displayMovieIds = movieIds.take(5).toList();

    return Column(
      children: displayMovieIds.asMap().entries.map((entry) {
        final index = entry.key;
        final movieId = entry.value;
        final contentType = customList.getContentTypeAt(index);
        return _buildCustomListMovieListItem(movieId, contentType: contentType);
      }).toList(),
    );
  }

  // Build a list item directly from a Movie object using consistent MovieCard styling
  Widget _buildCustomListMovieListItemFromMovie(Movie movie) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: MovieCard.listItem(
        movie: movie,
        fromCache: true, // Since we got it from PODs
        favoritesService: widget.favoritesService,
        parentWidget: widget,
        onTap: () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MovieDetailsScreen(
                  movie: movie,
                  favoritesService: widget.favoritesService,
                  contentType: movie.contentType ?? ContentType.movie,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // Build a list item for a custom list movie.

  Widget _buildCustomListMovieListItem(
    int movieId, {
    String contentType = 'movie',
  }) {
    final cachedMovieService = ref.read(cachedMovieServiceProvider);
    final contentService = ref.read(contentServiceProvider);

    return FutureBuilder<Movie>(
      future: _getContentAsMovieWithType(
        movieId,
        contentType,
        cachedMovieService,
        contentService,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const Gap(16),
                  Expanded(
                    child: Text(
                      'Error loading movie',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Text(
                      'Loading movie...',
                      style: TextStyle(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final movie = snapshot.data!;
        return MovieCard.listItem(
          movie: movie,
          fromCache: false,
          favoritesService: widget.favoritesService,
          parentWidget: widget,
          onTap: () {
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MovieDetailsScreen(
                    movie: movie,
                    favoritesService: widget.favoritesService,
                    contentType: movie.contentType ?? ContentType.movie,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  // Navigate to custom list detail screen.

  void _navigateToCustomListDetail(CustomList customList) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomListDetailScreen(
          customList: customList,
          favoritesService: widget.favoritesService,
        ),
      ),
    );
  }

  // Builds a smart error widget that provides user-friendly error messages and actions.
  // Builds a prominent API key error overlay for the entire view.

  Widget _buildApiKeyErrorOverlay() {
    return FutureBuilder<UserFriendlyError>(
      future: _createUserFriendlyError(
        ref,
        _apiKeyErrorMessage ?? 'API key error',
        StackTrace.current,
        () {
          // Retry by refreshing all providers.

          if (mounted) {
            ref.invalidate(popularMoviesWithCacheInfoProvider);
            ref.invalidate(nowPlayingMoviesWithCacheInfoProvider);
            ref.invalidate(topRatedMoviesWithCacheInfoProvider);
            ref.invalidate(upcomingMoviesWithCacheInfoProvider);
            setState(() {
              _hasApiKeyError = false;
              _apiKeyErrorMessage = null;
            });
          }
        },
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userFriendlyError = snapshot.data;
        if (userFriendlyError != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: ErrorDisplayWidget.fromUserFriendlyError(
                error: userFriendlyError,
              ),
            ),
          );
        }

        // Fallback to basic error display.

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.vpn_key_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const Gap(16),
                Text(
                  'API Key Required',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
                const Gap(8),
                Text(
                  'Configure your API key to access movie information.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Gap(24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to Settings tab in the main SolidScaffold instead of creating a new page
                    navigateToSettings();
                  },
                  icon: const Icon(Icons.vpn_key),
                  label: const Text('Configure API Key'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmartErrorWidget(
    WidgetRef ref,
    Object error,
    StackTrace stackTrace,
  ) {
    return FutureBuilder<UserFriendlyError>(
      future: _buildUserFriendlyError(ref, error, stackTrace),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final userFriendlyError = snapshot.data;
        if (userFriendlyError != null) {
          return ErrorDisplayWidget.fromUserFriendlyError(
            error: userFriendlyError,
          );
        }

        // Fallback.

        return ErrorDisplayWidget(
          message: 'Error loading movies: $error',
          onRetry: () => ref.invalidate(popularMoviesWithCacheInfoProvider),
        );
      },
    );
  }

  // Builds a compact smart error widget for movie rows.

  Widget _buildSmartErrorWidgetCompact(
    WidgetRef ref,
    Object error,
    StackTrace stackTrace,
    String title,
    VoidCallback onRetry,
  ) {
    return FutureBuilder<UserFriendlyError>(
      future: _buildUserFriendlyErrorCompact(ref, error, stackTrace, onRetry),
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

        // Fallback.

        return ErrorDisplayWidget.compact(
          message: 'Failed to load $title',
          onRetry: onRetry,
        );
      },
    );
  }

  // Helper method to build user-friendly error for full widget.

  Future<UserFriendlyError> _buildUserFriendlyError(
    WidgetRef ref,
    Object error,
    StackTrace stackTrace,
  ) async {
    return _createUserFriendlyError(
      ref,
      error,
      stackTrace,
      () => ref.invalidate(popularMoviesWithCacheInfoProvider),
    );
  }

  // Helper method to build user-friendly error for compact widget.

  Future<UserFriendlyError> _buildUserFriendlyErrorCompact(
    WidgetRef ref,
    Object error,
    StackTrace stackTrace,
    VoidCallback onRetry,
  ) async {
    return _createUserFriendlyError(ref, error, stackTrace, onRetry);
  }

  // Creates a user-friendly error with smart detection services.

  Future<UserFriendlyError> _createUserFriendlyError(
    WidgetRef ref,
    Object error,
    StackTrace stackTrace,
    VoidCallback onRetry,
  ) async {
    // Create services for smart detection.

    final apiKeyService = ref.read(apiKeyServiceProvider);
    final apiKeyValidationService = ApiKeyValidationService(apiKeyService);
    final networkConnectivityService = NetworkConnectivityService.forTMDB();

    // Create error context with available actions and services.

    final errorContext = ErrorContext(
      onRetry: onRetry,
      onConfigureApiKey: () {
        // Navigate to Settings tab in the main SolidScaffold instead of
        // creating a new page.

        navigateToSettings();
      },
      apiKeyValidationService: apiKeyValidationService,
      networkConnectivityService: networkConnectivityService,
    );

    try {
      // Use smart error mapping.

      return await ErrorMapperService.mapErrorSmart(
        error,
        stackTrace,
        context: errorContext,
      );
    } catch (e) {
      // If smart mapping fails, fall back to traditional mapping.

      return ErrorMapperService.mapError(
        error,
        stackTrace,
        context: errorContext,
      );
    }
  }
}
