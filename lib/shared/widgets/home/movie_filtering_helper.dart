/// Helper class for filtering movies to exclude those in user lists.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/core/services/cache/hive_movie_cache_service.dart';
import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/models/movie.dart';

/// Helper class for filtering movies based on user lists.

class MovieFilteringHelper {
  /// Filters a list of movies to exclude those already in user lists.

  static Future<List<Movie>> filterMoviesByUserLists(
    FavoritesService favoritesService,
    List<Movie> movies,
  ) async {
    final filteredMovies = <Movie>[];

    for (final movie in movies) {
      // Check if movie is in TO WATCH list

      final isInToWatch = await favoritesService.isInToWatch(movie);
      if (isInToWatch) continue;

      // Check if movie is in WATCHED list

      final isInWatched = await favoritesService.isInWatched(movie);
      if (isInWatched) continue;

      // Check if movie is in any custom lists.

      final customLists =
          await favoritesService.getCustomListsContainingMovie(movie.id);
      if (customLists.isNotEmpty) continue;

      // If movie is not in any user list, add it to filtered results.

      filteredMovies.add(movie);
    }

    return filteredMovies;
  }

  /// Builds a filtered async list section widget for list view mode.

  static Widget buildFilteredAsyncListSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    AsyncValue<CacheResult<List<Movie>>> moviesAsync,
    FavoritesService favoritesService,
    Widget Function(
      BuildContext context,
      WidgetRef ref,
      String title,
      AsyncValue<CacheResult<List<Movie>>> moviesAsync,
    ) buildAsyncListSection,
  ) {
    return moviesAsync.when(
      data: (cacheResult) {
        return FutureBuilder<List<Movie>>(
          future: filterMoviesByUserLists(favoritesService, cacheResult.data),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Show original data while filtering to avoid empty scrollbar issues.

              return buildAsyncListSection(
                context,
                ref,
                title,
                AsyncValue.data(cacheResult),
              );
            }

            final filteredCacheResult = CacheResult<List<Movie>>(
              data: snapshot.data ?? cacheResult.data,
              fromCache: cacheResult.fromCache,
              cacheAge: cacheResult.cacheAge,
            );

            return buildAsyncListSection(
              context,
              ref,
              title,
              AsyncValue.data(filteredCacheResult),
            );
          },
        );
      },
      loading: () => buildAsyncListSection(context, ref, title, moviesAsync),
      error: (error, stackTrace) =>
          buildAsyncListSection(context, ref, title, moviesAsync),
    );
  }
}
