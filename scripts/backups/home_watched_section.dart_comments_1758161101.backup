/// Watched Section for Home Screen
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:moviestar/core/services/cache/hive_movie_cache_service.dart';
import 'package:moviestar/core/services/favorites/favorites_service.dart';
import 'package:moviestar/core/services/favorites/favorites_service_adapter.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/widgets/error_display_widget.dart';
import 'package:moviestar/widgets/movie_card.dart';

/// A widget that displays the Watched section for the home screen.
/// This section shows movies from the user's watched list.
class HomeWatchedSection extends ConsumerWidget {
  /// Service for managing favorite movies.
  final FavoritesService favoritesService;

  /// Parent widget for navigation context.
  final StatefulWidget parentWidget;

  /// Callback for safe navigation.
  final void Function(Route<dynamic> route) onNavigate;

  /// Scroll controller for the watched section.
  final ScrollController scrollController;

  /// Callback to build cache age badge.
  final Widget Function(Duration cacheAge) buildCacheAgeBadge;

  /// Callback to build movie list items for list view.
  final Widget Function(List<Movie> movies, bool fromCache) buildMovieListItems;

  /// Whether to show as list items (for list view) or movie row (for grid view).
  final bool showAsListItems;

  /// Creates a new [HomeWatchedSection] widget.
  const HomeWatchedSection({
    super.key,
    required this.favoritesService,
    required this.parentWidget,
    required this.onNavigate,
    required this.scrollController,
    required this.buildCacheAgeBadge,
    required this.buildMovieListItems,
    this.showAsListItems = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (showAsListItems) {
      return _buildWatchedListItems(context, ref);
    } else {
      return _buildWatchedMovieRow(context, ref);
    }
  }

  /// Builds the watched movies row for grid view.
  Widget _buildWatchedMovieRow(BuildContext context, WidgetRef ref) {
    final cacheOnlyMode = ref.watch(cacheOnlyModeProvider);

    return StreamBuilder<List<Movie>>(
      stream: favoritesService.watchedMovies,
      builder: (context, snapshot) {
        // Check if the service is a FavoritesServiceAdapter with caching.
        final isCached = favoritesService is FavoritesServiceAdapter;
        Map<String, dynamic>? cacheStats;

        if (isCached) {
          final adapter = favoritesService as FavoritesServiceAdapter;
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
                            color: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.color,
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
                                Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Show cache indicator for user data if cached.
                  if (fromCache && cacheAge != null)
                    buildCacheAgeBadge(cacheAge),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: _buildWatchedMovieContent(
                context,
                ref,
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

  /// Builds the content for watched movies based on stream state.
  Widget _buildWatchedMovieContent(
    BuildContext context,
    WidgetRef ref,
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
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.7),
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
            'No movies in your watched list yet',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Scrollbar(
      controller: scrollController,
      thickness: 6,
      radius: const Radius.circular(3),
      thumbVisibility: true,
      child: ListView.builder(
        controller: scrollController,
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
              favoritesService: favoritesService,
              parentWidget: parentWidget,
              onTap: () {
                // Navigate to movie details using the provided callback
                onNavigate(
                  MaterialPageRoute(
                    builder: (context) => MovieDetailsScreen(
                      movie: movie,
                      favoritesService: favoritesService,
                      contentType: movie.contentType ?? ContentType.movie,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Builds the watched list items for list view.
  Widget _buildWatchedListItems(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Movie>>(
      stream: favoritesService.watchedMovies,
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
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.7),
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
            child: Text('No movies in your watched list'),
          );
        }
        return buildMovieListItems(movies.take(5).toList(), false);
      },
    );
  }
}
