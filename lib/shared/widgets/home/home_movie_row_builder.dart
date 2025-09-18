/// HomeScreen Movie Row Builder Component - Movie rendering and navigation logic.
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
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/screens/movie_category_screen.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/shared/widgets/home/home_cache_indicator_system.dart';
import 'package:moviestar/widgets/movie_card.dart';

/// Component that handles movie row building, list sections, and navigation logic.
class HomeMovieRowBuilder extends StatelessWidget {
  final FavoritesService favoritesService;
  final Map<String, ScrollController> scrollControllers;
  final bool Function() isMounted;
  final void Function(Route<dynamic>) safeNavigateTo;
  final Widget Function(WidgetRef, Object, StackTrace, String, VoidCallback)
      buildSmartErrorWidgetCompact;
  final Widget Function(WidgetRef, Object, StackTrace, String, VoidCallback)
      buildSmartErrorWidgetCompactWithRetry;
  final Widget Function(WidgetRef, Object, StackTrace) buildSmartErrorWidget;
  final VoidCallback onInvalidateProviders;
  final StatefulWidget parentWidget;

  const HomeMovieRowBuilder({
    super.key,
    required this.favoritesService,
    required this.scrollControllers,
    required this.isMounted,
    required this.safeNavigateTo,
    required this.buildSmartErrorWidgetCompact,
    required this.buildSmartErrorWidgetCompactWithRetry,
    required this.buildSmartErrorWidget,
    required this.onInvalidateProviders,
    required this.parentWidget,
  });

  /// Build a movie row with horizontal scrolling.
  Widget buildMovieRow(
    BuildContext context,
    WidgetRef ref,
    String title,
    AsyncValue<CacheResult<List<Movie>>> moviesAsync,
    String key,
    CacheCategory category,
    bool cacheOnlyMode,
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
              _buildSectionCacheIndicator(moviesAsync, cacheOnlyMode),
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
                        // Check if widget is still mounted before navigation.
                        if (isMounted()) {
                          safeNavigateTo(
                            MaterialPageRoute(
                              builder: (context) => MovieDetailsScreen(
                                movie: movie,
                                favoritesService: favoritesService,
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
            error: (error, stack) => buildSmartErrorWidgetCompactWithRetry(
              ref,
              error,
              stack,
              title,
              () {
                // Check if widget is still mounted before invalidating providers.
                if (isMounted()) {
                  onInvalidateProviders();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Build a list section with title and items.
  Widget buildListSection(
    BuildContext context,
    String title,
    Widget content,
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
              // Add View More button based on section type.
              buildViewMoreForUserList(context, title),
            ],
          ),
        ),
        content,
        const Gap(16),
      ],
    );
  }

  /// Build View More button for user lists (To Watch/Watched).
  Widget buildViewMoreForUserList(BuildContext context, String title) {
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

  /// Build list items for a list of movies.
  Widget buildMovieListItems(
    BuildContext context,
    List<Movie> movies,
    bool fromCache,
  ) {
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
          favoritesService: favoritesService,
          parentWidget: parentWidget,
          onTap: () {
            if (isMounted()) {
              safeNavigateTo(
                MaterialPageRoute(
                  builder: (context) => MovieDetailsScreen(
                    movie: movie,
                    favoritesService: favoritesService,
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

  /// Build cache indicator for section headers using the helper.
  Widget _buildSectionCacheIndicator(
    AsyncValue<CacheResult<List<Movie>>> moviesAsync,
    bool cacheOnlyMode,
  ) {
    return CacheIndicatorHelper.buildSectionCacheIndicator(
      moviesAsync,
      cacheOnlyMode,
    );
  }

  /// Navigate to movie category screen.
  void _navigateToMovieCategory(
    BuildContext context,
    String categoryName,
    List<Movie> movies, {
    bool fromCache = false,
  }) {
    safeNavigateTo(
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

  @override
  Widget build(BuildContext context) {
    // This component doesn't render anything visible - it's purely functional
    // It provides methods for building movie rows and lists
    return const SizedBox.shrink();
  }
}
