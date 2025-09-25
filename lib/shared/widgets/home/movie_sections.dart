/// Movie sections widget for home screen displaying trending/popular movies.
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
import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/screens/movie_category_screen.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/shared/widgets/home/cache_badges.dart';
import 'package:moviestar/shared/widgets/home/movie_filtering_helper.dart';
import 'package:moviestar/widgets/movie_card.dart';

/// Widget that displays recommended, now playing, top rated, and upcoming movie sections.

class HomeMovieSections extends ConsumerWidget {
  final FavoritesService favoritesService;
  final StatefulWidget parentWidget;
  final Function(Route<dynamic>) onNavigate;
  final Map<String, ScrollController> scrollControllers;

  const HomeMovieSections({
    super.key,
    required this.favoritesService,
    required this.parentWidget,
    required this.onNavigate,
    required this.scrollControllers,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendedMovies = ref.watch(recommendedMoviesWithCacheInfoProvider);
    final nowPlayingMovies = ref.watch(nowPlayingMoviesWithCacheInfoProvider);
    final topRatedMovies = ref.watch(topRatedMoviesWithCacheInfoProvider);
    final upcomingMovies = ref.watch(upcomingMoviesWithCacheInfoProvider);

    return Column(
      children: [
        _buildFilteredRecommendedMovieRow(
          context,
          ref,
          'Recommended on Movie Star',
          recommendedMovies,
          'popular',
          CacheCategory.recommended,
        ),
        _buildMovieRow(
          context,
          ref,
          'Now Playing',
          nowPlayingMovies,
          'nowPlaying',
          CacheCategory.nowPlaying,
        ),
        _buildMovieRow(
          context,
          ref,
          'Top Rated',
          topRatedMovies,
          'topRated',
          CacheCategory.topRated,
        ),
        _buildMovieRow(
          context,
          ref,
          'Upcoming',
          upcomingMovies,
          'upcoming',
          CacheCategory.upcoming,
        ),
      ],
    );
  }

  /// Filters recommended movies to exclude those already in user lists (TO WATCH, WATCHED, or custom lists).

  Widget _buildFilteredRecommendedMovieRow(
    BuildContext context,
    WidgetRef ref,
    String title,
    AsyncValue<CacheResult<List<Movie>>> recommendedMovies,
    String key,
    CacheCategory category,
  ) {
    return recommendedMovies.when(
      data: (cacheResult) {
        return FutureBuilder<List<Movie>>(
          future: MovieFilteringHelper.filterMoviesByUserLists(
            favoritesService,
            cacheResult.data,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Show original data while filtering to avoid empty scrollbar issues.

              return _buildMovieRow(
                context,
                ref,
                title,
                AsyncValue.data(cacheResult),
                key,
                category,
              );
            }

            if (snapshot.hasError) {
              return _buildMovieRow(
                context,
                ref,
                title,
                AsyncValue.error(snapshot.error!, StackTrace.current),
                key,
                category,
              );
            }

            final filteredCacheResult = CacheResult<List<Movie>>(
              data: snapshot.data ?? [],
              fromCache: cacheResult.fromCache,
              cacheAge: cacheResult.cacheAge,
            );

            return _buildMovieRow(
              context,
              ref,
              title,
              AsyncValue.data(filteredCacheResult),
              key,
              category,
            );
          },
        );
      },
      loading: () =>
          _buildMovieRow(context, ref, title, recommendedMovies, key, category),
      error: (error, stackTrace) =>
          _buildMovieRow(context, ref, title, recommendedMovies, key, category),
    );
  }

  Widget _buildMovieRow(
    BuildContext context,
    WidgetRef ref,
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
              moviesAsync.when(
                data: (cacheResult) {
                  if (cacheResult.data.length > 10) {
                    return TextButton(
                      onPressed: () => _navigateToMovieCategory(
                        context,
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
              HomeCacheBadges.buildSectionCacheIndicator(
                moviesAsync,
                cacheOnlyMode,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: moviesAsync.when(
            data: (cacheResult) => Scrollbar(
              controller: scrollControllers[key],
              thickness: 6,
              radius: const Radius.circular(3),
              thumbVisibility: true,
              child: ListView.builder(
                controller: scrollControllers[key],
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
                      favoritesService: favoritesService,
                      parentWidget: parentWidget,
                      onTap: () {
                        onNavigate(
                          MaterialPageRoute(
                            builder: (context) => MovieDetailsScreen(
                              movie: movie,
                              favoritesService: favoritesService,
                              contentType:
                                  movie.contentType ?? ContentType.movie,
                            ),
                          ),
                        );
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
            ),
            error: (error, stack) => Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const Gap(8),
                  Text(
                    'Failed to load $title',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.invalidate(recommendedMoviesWithCacheInfoProvider);
                      ref.invalidate(nowPlayingMoviesWithCacheInfoProvider);
                      ref.invalidate(topRatedMoviesWithCacheInfoProvider);
                      ref.invalidate(upcomingMoviesWithCacheInfoProvider);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToMovieCategory(
    BuildContext context,
    String categoryName,
    List<Movie> movies, {
    bool fromCache = false,
  }) {
    onNavigate(
      MaterialPageRoute(
        builder: (context) => MovieCategoryScreen(
          categoryName: categoryName,
          movies: movies,
          favoritesService: favoritesService,
          fromCache: fromCache,
        ),
      ),
    );
  }
}
