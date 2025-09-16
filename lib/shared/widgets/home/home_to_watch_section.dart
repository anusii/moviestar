/// To Watch Section for Home Screen
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

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/core/services/favorites/favorites_service.dart';
import 'package:moviestar/core/services/favorites/favorites_service_adapter.dart';
import 'package:moviestar/core/services/cache/cached_movie_service.dart';
import 'package:moviestar/core/services/cache/hive_movie_cache_service.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/widgets/error_display_widget.dart';
import 'package:moviestar/widgets/movie_card.dart';

/// A widget that displays the To Watch section for the home screen.
/// This section shows movies from the user's to-watch list.
class HomeToWatchSection extends ConsumerWidget {
  /// Service for managing favorite movies.
  final FavoritesService favoritesService;

  /// Parent widget for navigation context.
  final StatefulWidget parentWidget;

  /// Callback for safe navigation.
  final void Function(Route<dynamic> route) onNavigate;

  /// Scroll controller for the to-watch section.
  final ScrollController scrollController;

  /// Callback to build cache age badge.
  final Widget Function(Duration cacheAge) buildCacheAgeBadge;

  /// Callback to build movie list items for list view.
  final Widget Function(List<Movie> movies, bool fromCache) buildMovieListItems;

  /// Whether to show as list items (for list view) or movie row (for grid view).
  final bool showAsListItems;

  /// Creates a new [HomeToWatchSection] widget.
  const HomeToWatchSection({
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
      return _buildToWatchListItems(context, ref);
    } else {
      return _buildToWatchMovieRow(context, ref);
    }
  }

  /// Builds the to-watch movies row for grid view.
  Widget _buildToWatchMovieRow(BuildContext context, WidgetRef ref) {
    final cacheOnlyMode = ref.watch(cacheOnlyModeProvider);

    return StreamBuilder<List<Movie>>(
      stream: favoritesService.toWatchMovies,
      builder: (context, snapshot) {
        // Check if the service is a FavoritesServiceAdapter with caching.
        final isCached = favoritesService is FavoritesServiceAdapter;
        Map<String, dynamic>? cacheStats;

        if (isCached) {
          final adapter = favoritesService as FavoritesServiceAdapter;
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
                            color: Theme.of(context).textTheme.headlineMedium?.color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (snapshot.connectionState == ConnectionState.waiting) ...[
                          const Gap(8),
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Show cache indicator for user data if cached.
                  if (fromCache && cacheAge != null) buildCacheAgeBadge(cacheAge),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: _buildToWatchMovieContent(
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

  /// Builds the content for to-watch movies based on stream state.
  Widget _buildToWatchMovieContent(
    BuildContext context,
    WidgetRef ref,
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
    if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
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
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
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

  /// Builds the to-watch list items for list view.
  Widget _buildToWatchListItems(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Movie>>(
      stream: favoritesService.toWatchMovies,
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
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
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
        return buildMovieListItems(movies.take(5).toList(), false);
      },
    );
  }
}