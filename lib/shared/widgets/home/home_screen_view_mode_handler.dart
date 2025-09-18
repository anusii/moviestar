/// HomeScreen View Mode Handler Component - View mode switching and content routing logic
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
import 'package:moviestar/providers/view_mode_provider.dart';
import 'package:moviestar/widgets/movie_kanban_board.dart';

/// Component that handles view mode switching and content routing for HomeScreen
class HomeScreenViewModeHandler extends StatelessWidget {
  final AsyncValue<CacheResult<List<Movie>>> popularMovies;
  final AsyncValue<CacheResult<List<Movie>>> nowPlayingMovies;
  final AsyncValue<CacheResult<List<Movie>>> topRatedMovies;
  final AsyncValue<CacheResult<List<Movie>>> upcomingMovies;
  final FavoritesService favoritesService;
  final Widget Function() buildToWatchMovieRow;
  final Widget Function() buildWatchedMovieRow;
  final Widget Function() buildCustomListRows;
  final Widget Function(
    String,
    AsyncValue<CacheResult<List<Movie>>>,
    String,
    CacheCategory,
  ) buildMovieRow;
  final Widget Function() buildCustomListListSections;
  final Widget Function(String, AsyncValue<CacheResult<List<Movie>>>)
      buildAsyncListSection;
  final Widget Function(String, Widget) buildListSection;
  final Widget Function() buildToWatchListItems;
  final Widget Function() buildWatchedListItems;
  final bool hasApiKeyError;
  final Widget Function() buildApiKeyErrorOverlay;

  const HomeScreenViewModeHandler({
    super.key,
    required this.popularMovies,
    required this.nowPlayingMovies,
    required this.topRatedMovies,
    required this.upcomingMovies,
    required this.favoritesService,
    required this.buildToWatchMovieRow,
    required this.buildWatchedMovieRow,
    required this.buildCustomListRows,
    required this.buildMovieRow,
    required this.buildCustomListListSections,
    required this.buildAsyncListSection,
    required this.buildListSection,
    required this.buildToWatchListItems,
    required this.buildWatchedListItems,
    required this.hasApiKeyError,
    required this.buildApiKeyErrorOverlay,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final currentViewMode = ref.watch(viewModeProvider);

        return _buildContentForViewMode(
          currentViewMode,
          popularMovies,
          nowPlayingMovies,
          topRatedMovies,
          upcomingMovies,
        );
      },
    );
  }

  /// Build content based on the selected view mode
  Widget _buildContentForViewMode(
    HomeViewMode viewMode,
    AsyncValue<CacheResult<List<Movie>>> popularMovies,
    AsyncValue<CacheResult<List<Movie>>> nowPlayingMovies,
    AsyncValue<CacheResult<List<Movie>>> topRatedMovies,
    AsyncValue<CacheResult<List<Movie>>> upcomingMovies,
  ) {
    // If there's an API key error, show the error overlay instead of the normal content
    if (hasApiKeyError) {
      return buildApiKeyErrorOverlay();
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

  /// Build the traditional grid/horizontal scroll view
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
          buildToWatchMovieRow(),
          buildWatchedMovieRow(),
          buildCustomListRows(),
          buildMovieRow(
            'Popular on Movie Star',
            popularMovies,
            'popular',
            CacheCategory.popular,
          ),
          buildMovieRow(
            'Now Playing',
            nowPlayingMovies,
            'nowPlaying',
            CacheCategory.nowPlaying,
          ),
          buildMovieRow(
            'Top Rated',
            topRatedMovies,
            'topRated',
            CacheCategory.topRated,
          ),
          buildMovieRow(
            'Upcoming',
            upcomingMovies,
            'upcoming',
            CacheCategory.upcoming,
          ),
        ],
      ),
    );
  }

  /// Build the kanban view with AppFlowy Board
  Widget _buildKanbanView(
    AsyncValue<CacheResult<List<Movie>>> popularMovies,
    AsyncValue<CacheResult<List<Movie>>> nowPlayingMovies,
    AsyncValue<CacheResult<List<Movie>>> topRatedMovies,
    AsyncValue<CacheResult<List<Movie>>> upcomingMovies,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: MovieKanbanBoard(
        favoritesService: favoritesService,
      ),
    );
  }

  /// Build a list view of movies
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
          // To Watch and Watched sections
          buildListSection('To Watch', buildToWatchListItems()),
          buildListSection('Watched', buildWatchedListItems()),

          // Custom List sections
          buildCustomListListSections(),

          // API Movie sections
          buildAsyncListSection('Popular on Movie Star', popularMovies),
          buildAsyncListSection('Now Playing', nowPlayingMovies),
          buildAsyncListSection('Top Rated', topRatedMovies),
          buildAsyncListSection('Upcoming', upcomingMovies),
        ],
      ),
    );
  }
}
