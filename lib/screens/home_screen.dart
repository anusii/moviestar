/// Moviestar - Manage and share ratings through private PODs
///
// Time-stamp: <Tuesday 2025-07-15 07:12:49 +1000 Graham Williams>
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

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/providers/theme_provider.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/screens/search_screen.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/services/favorites_service_adapter.dart';
import 'package:moviestar/services/hive_movie_cache_service.dart';
import 'package:moviestar/widgets/cache_feedback_widget.dart';
import 'package:moviestar/widgets/error_display_widget.dart';
import 'package:moviestar/widgets/movie_card.dart';

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

  @override
  void initState() {
    super.initState();
    _scrollControllers['toWatch'] = ScrollController();
    _scrollControllers['watched'] = ScrollController();
    _scrollControllers['popular'] = ScrollController();
    _scrollControllers['nowPlaying'] = ScrollController();
    _scrollControllers['topRated'] = ScrollController();
    _scrollControllers['upcoming'] = ScrollController();
  }

  @override
  void dispose() {
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
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
        final cacheAge =
            toWatchStats?['age'] != null
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
                            color:
                                Theme.of(
                                  context,
                                ).textTheme.headlineMedium?.color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) ...[
                          const SizedBox(width: 8),
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
            const SizedBox(height: 12),
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
                      builder:
                          (context) => MovieDetailsScreen(
                            movie: movie,
                            favoritesService: widget.favoritesService,
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
        final cacheAge =
            watchedStats?['age'] != null
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
                            color:
                                Theme.of(
                                  context,
                                ).textTheme.headlineMedium?.color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) ...[
                          const SizedBox(width: 8),
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
            const SizedBox(height: 12),
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
                      builder:
                          (context) => MovieDetailsScreen(
                            movie: movie,
                            favoritesService: widget.favoritesService,
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
              _buildSectionCacheIndicator(moviesAsync, cacheOnlyMode),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: moviesAsync.when(
            data:
                (cacheResult) => Scrollbar(
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
                                  builder:
                                      (context) => MovieDetailsScreen(
                                        movie: movie,
                                        favoritesService:
                                            widget.favoritesService,
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
            loading:
                () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),
            error:
                (error, stack) => ErrorDisplayWidget.compact(
                  message: 'Failed to load $title',
                  onRetry: () {
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
          SizedBox(width: 4),
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
          const SizedBox(width: 4),
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
          SizedBox(width: 4),
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
          SizedBox(width: 4),
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
        debugPrint('Error during force refresh: $e');
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
    final cacheOnlyMode = ref.watch(cacheOnlyModeProvider);

    // Show performance feedback after initial load.

    _showCachePerformanceFeedback();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Row(
          children: [
            const Text(
              'MOVIE STAR',
              style: TextStyle(
                color: Colors.red,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (cacheOnlyMode) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'OFFLINE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          Padding(
            // Space for debug banner.
            padding: const EdgeInsets.only(right: 60.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _forceRefresh,
                  tooltip: 'Refresh data',
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // Check if widget is still mounted before navigation.

                    if (mounted) {
                      final movieService = ref.read(movieServiceProvider);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => SearchScreen(
                                favoritesService: widget.favoritesService,
                                movieService: movieService,
                              ),
                        ),
                      );
                    }
                  },
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final themeMode = ref.watch(themeModeProvider);
                    final isDarkMode = themeMode == ThemeMode.dark;
                    return IconButton(
                      icon: Icon(
                        isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      ),
                      onPressed: () async {
                        await ref
                            .read(themeModeProvider.notifier)
                            .toggleTheme();
                      },
                      tooltip:
                          isDarkMode
                              ? 'Switch to light mode'
                              : 'Switch to dark mode',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _forceRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildToWatchMovieRow(),
              _buildWatchedMovieRow(),
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
        ),
      ),
    );
  }
}
