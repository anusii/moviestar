/// Movie Kanban Board Widget - Custom Implementation
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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/models/movie.dart';

import 'package:moviestar/providers/cached_movie_service_provider.dart';

import 'package:moviestar/screens/movie_category_screen.dart';

import 'package:moviestar/screens/movie_details_screen.dart';

import 'package:moviestar/services/favorites_service.dart';

import 'package:moviestar/widgets/movie_card.dart';

/// A movie item wrapper for kanban board usage.

class MovieItem {
  final Movie movie;
  final bool fromCache;
  final Duration? cacheAge;

  const MovieItem({
    required this.movie,
    this.fromCache = false,
    this.cacheAge,
  });

  String get id => movie.id.toString();
}

/// Custom Kanban board widget for displaying movies in columns.

class MovieKanbanBoard extends ConsumerStatefulWidget {
  final FavoritesService favoritesService;

  const MovieKanbanBoard({
    super.key,
    required this.favoritesService,
  });

  @override
  ConsumerState<MovieKanbanBoard> createState() => _MovieKanbanBoardState();
}

class _MovieKanbanBoardState extends ConsumerState<MovieKanbanBoard> {
  final int _maxItemsPerColumn = 8;

  @override
  void initState() {
    super.initState();
  }

  /// Build a movie item widget for the kanban board.

  Widget _buildMovieItem(Movie movie, String category,
      {bool fromCache = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: MovieCard.poster(
        movie: movie,
        fromCache: fromCache,
        width: 100,
        height: 150,
        favoritesService: widget.favoritesService,
        onTap: () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MovieDetailsScreen(
                  movie: movie,
                  favoritesService: widget.favoritesService,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  /// Build a kanban column.

  Widget _buildKanbanColumn({
    required String title,
    required List<Movie> movies,
    required String categoryId,
    required bool fromCache,
  }) {
    final displayMovies = movies.take(_maxItemsPerColumn).toList();
    final hasMore = movies.length > _maxItemsPerColumn;

    return Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${movies.length}${hasMore ? '+' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                if (hasMore) ...[
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () =>
                        _navigateToMovieCategory(title, movies, fromCache),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'View More',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 11,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Movie items.

          Expanded(
            child: displayMovies.isEmpty
                ? Center(
                    child: Text(
                      'No movies',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: displayMovies.length,
                    itemBuilder: (context, index) {
                      final movie = displayMovies[index];
                      return _buildMovieItem(movie, categoryId,
                          fromCache: fromCache);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Navigate to a dedicated page for viewing all movies in a category.

  void _navigateToMovieCategory(
      String categoryName, List<Movie> movies, bool fromCache) {
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

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        // Watch the popular movies data.

        final popularMoviesAsync =
            ref.watch(popularMoviesWithCacheInfoProvider);

        return popularMoviesAsync.when(
          data: (popularCacheResult) {
            return StreamBuilder<List<Movie>>(
              stream: widget.favoritesService.toWatchMovies,
              builder: (context, toWatchSnapshot) {
                return StreamBuilder<List<Movie>>(
                  stream: widget.favoritesService.watchedMovies,
                  builder: (context, watchedSnapshot) {
                    final popularMovies = popularCacheResult.data;
                    final toWatchMovies = toWatchSnapshot.data ?? [];
                    final watchedMovies = watchedSnapshot.data ?? [];

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Popular Movies Column.

                          _buildKanbanColumn(
                            title: 'Popular',
                            movies: popularMovies,
                            categoryId: 'popular',
                            fromCache: popularCacheResult.fromCache,
                          ),

                          // To Watch Column.

                          _buildKanbanColumn(
                            title: 'To Watch',
                            movies: toWatchMovies,
                            categoryId: 'towatch',
                            fromCache: false,
                          ),

                          // Watched Column.

                          _buildKanbanColumn(
                            title: 'Watched',
                            movies: watchedMovies,
                            categoryId: 'watched',
                            fromCache: false,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Error loading movies: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        );
      },
    );
  }
}
