/// Movie Kanban Board Widget - Orchestrator for Kanban Components.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Kevin Wang.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/core/services/cache/hive_movie_cache_service.dart';
import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/screens/custom_list_detail_screen.dart';
import 'package:moviestar/screens/movie_category_screen.dart';
import 'package:moviestar/shared/widgets/home/movie_filtering_helper.dart';
import 'package:moviestar/shared/widgets/kanban/board_controller.dart';
import 'package:moviestar/shared/widgets/kanban/card_widget.dart';
import 'package:moviestar/shared/widgets/kanban/column_widget.dart';
import 'package:moviestar/shared/widgets/kanban/drag_handler.dart';
import 'package:moviestar/shared/widgets/kanban/search_filter.dart';
import 'package:moviestar/shared/widgets/kanban/settings_panel.dart';
import 'package:moviestar/shared/widgets/kanban/skeleton_column.dart';
import 'package:moviestar/widgets/error_display_widget.dart';
import 'package:moviestar/widgets/kanban_stream_builder.dart';
import 'package:moviestar/widgets/movie_kanban_board/operation_indicator.dart';

/// Custom Kanban board widget for displaying movies in columns.
/// Now serves as an orchestrator for the extracted kanban components.

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
  late ScrollController _horizontalScrollController;
  late KanbanBoardController _kanbanController;
  late KanbanDragHandler _dragHandler;
  late KanbanSearchController _searchController;
  late KanbanSettingsController _settingsController;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
    _kanbanController = KanbanBoardController();
    _kanbanController.loadSortPreferences();
    _searchController = KanbanSearchController();
    _settingsController = KanbanSettingsController();

    // Initialize drag handler after context is available.

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dragHandler = KanbanDragHandler(
        favoritesService: widget.favoritesService,
        controller: _kanbanController,
        context: context,
      );
    });
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _kanbanController.dispose();
    _searchController.dispose();
    _settingsController.dispose();
    super.dispose();
  }

  /// Handle drop operations.

  void _handleDrop(
    MovieDragData dragData,
    KanbanColumnType targetType,
    String targetId,
    String targetName,
  ) {
    _dragHandler.handleDrop(dragData, targetType, targetId, targetName);
  }

  /// Show context menu for movie operations.

  void _showMovieContextMenu(
    Offset position,
    Movie movie,
    KanbanColumnType sourceType,
    String sourceId,
    String sourceName,
  ) {
    _dragHandler.showMovieContextMenu(
      position,
      movie,
      sourceType,
      sourceId,
      sourceName,
    );
  }

  /// Navigate to category screen.

  void _navigateToCategory(
    String title,
    List<Movie> movies,
    bool fromCache,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieCategoryScreen(
          categoryName: title,
          movies: movies,
          fromCache: fromCache,
          favoritesService: widget.favoritesService,
        ),
      ),
    );
  }

  /// Navigate to custom list detail screen.

  void _navigateToCustomList(CustomList customList) {
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

  /// Build movie item using the kanban card widget.

  Widget _buildMovieItem(
    Movie movie,
    String category, {
    required bool fromCache,
    required KanbanColumnType columnType,
    required String columnId,
    required String columnName,
  }) {
    return KanbanCardWidget(
      movie: movie,
      category: category,
      fromCache: fromCache,
      columnType: columnType,
      columnId: columnId,
      columnName: columnName,
      favoritesService: widget.favoritesService,
      controller: _kanbanController,
      onShowContextMenu: _showMovieContextMenu,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _kanbanController,
        _searchController,
        _settingsController,
      ]),
      builder: (context, child) {
        return Stack(
          children: [
            Column(
              children: [
                // Search bar (if search functionality is enabled).

                if (_searchController.hasActiveFilters)
                  KanbanSearchBar(
                    controller: _searchController,
                    onClear: () => setState(() {}),
                  ),

                // Main kanban board.

                Expanded(
                  child: _buildKanbanBoard(),
                ),
              ],
            ),

            // Floating operation queue indicator (no layout shift).

            if (_kanbanController.operationQueue.isNotEmpty)
              KanbanOperationIndicator(
                queueCount: _kanbanController.operationQueue.length,
              ),
          ],
        );
      },
    );
  }

  /// Build the main kanban board with columns.

  Widget _buildKanbanBoard() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _horizontalScrollController,
      child: Consumer(
        builder: (context, ref, child) {
          final recommendedMoviesAsync =
              ref.watch(recommendedMoviesWithCacheInfoProvider);
          return recommendedMoviesAsync.when(
            data: (recommendedCacheResult) {
              return FutureBuilder<List<Movie>>(
                future: MovieFilteringHelper.filterMoviesByUserLists(
                  widget.favoritesService,
                  recommendedCacheResult.data,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Show original data while filtering to avoid empty list issues.

                    return KanbanStreamBuilder(
                      favoritesService: widget.favoritesService,
                      recommendedCacheResult: recommendedCacheResult,
                      builder: _buildKanbanColumns,
                    );
                  }

                  final filteredCacheResult = CacheResult<List<Movie>>(
                    data: snapshot.data ?? recommendedCacheResult.data,
                    fromCache: recommendedCacheResult.fromCache,
                    cacheAge: recommendedCacheResult.cacheAge,
                  );

                  return KanbanStreamBuilder(
                    favoritesService: widget.favoritesService,
                    recommendedCacheResult: filteredCacheResult,
                    builder: _buildKanbanColumns,
                  );
                },
              );
            },
            loading: () => KanbanStreamBuilder(
              favoritesService: widget.favoritesService,
              recommendedCacheResult: const CacheResult<List<Movie>>(
                data: <Movie>[],
                fromCache: false,
              ),
              builder: _buildKanbanColumns,
            ),
            error: (error, stackTrace) {
              return ErrorDisplayWidget(
                message: 'Error loading movies: $error',
                onRetry: () =>
                    ref.invalidate(recommendedMoviesWithCacheInfoProvider),
              );
            },
          );
        },
      ),
    );
  }

  /// Build all kanban columns.

  Widget _buildKanbanColumns(
    dynamic recommendedCacheResult,
    AsyncSnapshot<List<Movie>> toWatchSnapshot,
    AsyncSnapshot<List<Movie>> watchedSnapshot,
    AsyncSnapshot<List<CustomList>> customListsSnapshot,
    KanbanLoadingData loadingData,
  ) {
    final recommendedMovies = recommendedCacheResult.data ?? <Movie>[];
    final toWatchMovies = toWatchSnapshot.data ?? [];
    final watchedMovies = watchedSnapshot.data ?? [];
    final customLists = customListsSnapshot.data ?? [];

    // Apply search filters if active.

    final filteredRecommended = _searchController.hasActiveFilters
        ? _searchController.filterMovies(recommendedMovies)
        : recommendedMovies;
    final filteredToWatch = _searchController.hasActiveFilters
        ? _searchController.filterMovies(toWatchMovies)
        : toWatchMovies;
    final filteredWatched = _searchController.hasActiveFilters
        ? _searchController.filterMovies(watchedMovies)
        : watchedMovies;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recommended column.

        _buildSingleColumn(
          title: 'Recommended',
          movies: filteredRecommended,
          categoryId: 'recommended',
          columnType: KanbanColumnType.recommended,
          fromCache: recommendedCacheResult.fromCache ?? false,
          isLoading: recommendedMovies.isEmpty &&
              !(recommendedCacheResult.fromCache ?? false),
        ),

        // To Watch column.

        _buildSingleColumn(
          title: 'To Watch',
          movies: filteredToWatch,
          categoryId: 'towatch',
          columnType: KanbanColumnType.toWatch,
          fromCache: true,
          isLoading: !toWatchSnapshot.hasData,
        ),

        // Watched column.

        _buildSingleColumn(
          title: 'Watched',
          movies: filteredWatched,
          categoryId: 'watched',
          columnType: KanbanColumnType.watched,
          fromCache: true,
          isLoading: !watchedSnapshot.hasData,
        ),

        // Custom list columns with skeleton support and smooth transitions.

        ..._buildCustomListColumnsWithTransitions(customLists, loadingData),
      ],
    );
  }

  /// Build a single kanban column using the extracted component.

  Widget _buildSingleColumn({
    required String title,
    required List<Movie> movies,
    required String categoryId,
    required KanbanColumnType columnType,
    required bool fromCache,
    bool isLoading = false,
    CustomList? customList,
  }) {
    final columnData = KanbanColumnData(
      title: title,
      movies: movies,
      categoryId: categoryId,
      fromCache: fromCache,
      columnType: columnType,
      isLoading: isLoading,
      customList: customList,
    );

    return KanbanColumnWidget(
      columnData: columnData,
      controller: _kanbanController,
      favoritesService: widget.favoritesService,
      maxItemsPerColumn: _settingsController.settings.maxItemsPerColumn,
      onDrop: _handleDrop,
      onNavigateToCategory: _navigateToCategory,
      onNavigateToCustomList: _navigateToCustomList,
      buildMovieItem: _buildMovieItem,
    );
  }

  /// Build unified custom list column using KanbanColumnWidget.

  Widget _buildUnifiedCustomListColumn(CustomList customList) {
    return FutureBuilder<List<Movie>>(
      future: widget.favoritesService.getMoviesInCustomList(customList.id),
      builder: (context, snapshot) {
        final movies = snapshot.data ?? [];

        return _buildSingleColumn(
          title: customList.name,
          movies: movies,
          categoryId: customList.id,
          columnType: KanbanColumnType.customList,
          fromCache: true,
          isLoading: snapshot.connectionState == ConnectionState.waiting,
          customList: customList,
        );
      },
    );
  }

  /// Build custom list columns with smooth transitions from skeleton to real content.

  List<Widget> _buildCustomListColumnsWithTransitions(
    List<CustomList> customLists,
    KanbanLoadingData loadingData,
  ) {
    // If we're in initial loading and have no custom lists yet, show skeleton columns.

    if (loadingData.showSkeletonColumns) {
      return [
        const AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: KanbanColumnSkeleton(
            key: ValueKey('skeleton_1'),
            title: 'Loading Lists...',
            itemCount: 2,
          ),
        ),
        const AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: KanbanColumnSkeleton(
            key: ValueKey('skeleton_2'),
            title: 'Loading Lists...',
            itemCount: 1,
          ),
        ),
      ];
    }

    // Show actual custom list columns with smooth transitions.

    return customLists
        .map(
          (customList) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildUnifiedCustomListColumn(customList),
          ),
        )
        .toList();
  }
}
