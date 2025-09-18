/// View mode builders for home screen (grid, kanban, list views).
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
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/view_mode_provider.dart';
import 'package:moviestar/screens/movie_category_screen.dart';
import 'package:moviestar/shared/widgets/home/cache_badges.dart';
import 'package:moviestar/shared/widgets/home/custom_list_builder.dart';
import 'package:moviestar/shared/widgets/home/error_handler.dart';
import 'package:moviestar/shared/widgets/home/movie_list_items.dart';
import 'package:moviestar/shared/widgets/home/movie_sections.dart';
import 'package:moviestar/shared/widgets/home/to_watch_section.dart';
import 'package:moviestar/shared/widgets/home/watched_section.dart';
import 'package:moviestar/widgets/movie_kanban_board.dart';

/// Widget that builds different view modes for the home screen.
class HomeViewModes extends ConsumerWidget {
  final HomeViewMode viewMode;
  final FavoritesService favoritesService;
  final StatefulWidget parentWidget;
  final Function(Route<dynamic>) onNavigate;
  final Map<String, ScrollController> scrollControllers;
  final AsyncValue<CacheResult<List<Movie>>> popularMovies;
  final AsyncValue<CacheResult<List<Movie>>> nowPlayingMovies;
  final AsyncValue<CacheResult<List<Movie>>> topRatedMovies;
  final AsyncValue<CacheResult<List<Movie>>> upcomingMovies;

  const HomeViewModes({
    super.key,
    required this.viewMode,
    required this.favoritesService,
    required this.parentWidget,
    required this.onNavigate,
    required this.scrollControllers,
    required this.popularMovies,
    required this.nowPlayingMovies,
    required this.topRatedMovies,
    required this.upcomingMovies,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (viewMode) {
      case HomeViewMode.grid:
        return _buildGridView(context, ref);
      case HomeViewMode.kanban:
        return _buildKanbanView(context, ref);
      case HomeViewMode.list:
        return _buildListView(context, ref);
    }
  }

  Widget _buildGridView(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeToWatchSection(
            favoritesService: favoritesService,
            parentWidget: parentWidget,
            onNavigate: onNavigate,
            scrollController: scrollControllers['toWatch']!,
            buildCacheAgeBadge: HomeCacheBadges.buildCacheAgeBadge,
            buildMovieListItems: (movies, fromCache) => HomeMovieListItems(
              movies: movies,
              fromCache: fromCache,
              favoritesService: favoritesService,
              parentWidget: parentWidget,
              onNavigate: onNavigate,
            ),
          ),
          HomeWatchedSection(
            favoritesService: favoritesService,
            parentWidget: parentWidget,
            onNavigate: onNavigate,
            scrollController: scrollControllers['watched']!,
            buildCacheAgeBadge: HomeCacheBadges.buildCacheAgeBadge,
            buildMovieListItems: (movies, fromCache) => HomeMovieListItems(
              movies: movies,
              fromCache: fromCache,
              favoritesService: favoritesService,
              parentWidget: parentWidget,
              onNavigate: onNavigate,
            ),
          ),
          HomeCustomListBuilder(
            favoritesService: favoritesService,
            parentWidget: parentWidget,
            onNavigate: onNavigate,
            scrollControllers: scrollControllers,
          ),
          HomeMovieSections(
            favoritesService: favoritesService,
            parentWidget: parentWidget,
            onNavigate: onNavigate,
            scrollControllers: scrollControllers,
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanView(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: MovieKanbanBoard(
        favoritesService: favoritesService,
      ),
    );
  }

  Widget _buildListView(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildListSection(
            context,
            'To Watch',
            HomeToWatchSection(
              favoritesService: favoritesService,
              parentWidget: parentWidget,
              onNavigate: onNavigate,
              scrollController: scrollControllers['toWatch']!,
              buildCacheAgeBadge: HomeCacheBadges.buildCacheAgeBadge,
              buildMovieListItems: (movies, fromCache) => HomeMovieListItems(
                movies: movies,
                fromCache: fromCache,
                favoritesService: favoritesService,
                parentWidget: parentWidget,
                onNavigate: onNavigate,
              ),
              showAsListItems: true,
            ),
          ),
          _buildListSection(
            context,
            'Watched',
            HomeWatchedSection(
              favoritesService: favoritesService,
              parentWidget: parentWidget,
              onNavigate: onNavigate,
              scrollController: scrollControllers['watched']!,
              buildCacheAgeBadge: HomeCacheBadges.buildCacheAgeBadge,
              buildMovieListItems: (movies, fromCache) => HomeMovieListItems(
                movies: movies,
                fromCache: fromCache,
                favoritesService: favoritesService,
                parentWidget: parentWidget,
                onNavigate: onNavigate,
              ),
              showAsListItems: true,
            ),
          ),
          HomeCustomListBuilder(
            favoritesService: favoritesService,
            parentWidget: parentWidget,
            onNavigate: onNavigate,
            scrollControllers: scrollControllers,
            showAsListSections: true,
          ),
          _buildAsyncListSection(
            context,
            ref,
            'Popular on Movie Star',
            popularMovies,
          ),
          _buildAsyncListSection(context, ref, 'Now Playing', nowPlayingMovies),
          _buildAsyncListSection(context, ref, 'Top Rated', topRatedMovies),
          _buildAsyncListSection(context, ref, 'Upcoming', upcomingMovies),
        ],
      ),
    );
  }

  Widget _buildListSection(BuildContext context, String title, Widget content) {
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
              _buildViewMoreForUserList(context, title),
            ],
          ),
        ),
        content,
        const Gap(16),
      ],
    );
  }

  Widget _buildViewMoreForUserList(BuildContext context, String title) {
    if (title == 'To Watch') {
      return StreamBuilder<List<Movie>>(
        stream: favoritesService.toWatchMovies,
        builder: (context, snapshot) {
          final movies = snapshot.data ?? [];
          if (movies.length > 5) {
            return TextButton(
              onPressed: () => _navigateToMovieCategory(context, title, movies),
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
        stream: favoritesService.watchedMovies,
        builder: (context, snapshot) {
          final movies = snapshot.data ?? [];
          if (movies.length > 5) {
            return TextButton(
              onPressed: () => _navigateToMovieCategory(context, title, movies),
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

  Widget _buildAsyncListSection(
    BuildContext context,
    WidgetRef ref,
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
              moviesAsync.when(
                data: (cacheResult) {
                  if (cacheResult.data.length > 5) {
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
            ],
          ),
        ),
        moviesAsync.when(
          data: (cacheResult) => HomeMovieListItems(
            movies: cacheResult.data,
            fromCache: cacheResult.fromCache,
            favoritesService: favoritesService,
            parentWidget: parentWidget,
            onNavigate: onNavigate,
          ),
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
          error: (error, stack) => Padding(
            padding: const EdgeInsets.all(16),
            child: HomeErrorHandler.buildSmartErrorWidget(ref, error, stack),
          ),
        ),
        const Gap(16),
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
