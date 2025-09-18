/// Movie Kanban Board Widget - Orchestrator for Kanban Components
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
import 'package:moviestar/core/services/favorites/favorites_service.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/screens/custom_list_detail_screen.dart';
import 'package:moviestar/screens/movie_category_screen.dart';
// Import extracted kanban components
import 'package:moviestar/shared/widgets/kanban/kanban_board_controller.dart';
import 'package:moviestar/shared/widgets/kanban/kanban_card_widget.dart';
import 'package:moviestar/shared/widgets/kanban/kanban_column_widget.dart';
import 'package:moviestar/shared/widgets/kanban/kanban_drag_handler.dart';
import 'package:moviestar/shared/widgets/kanban/kanban_list_operations.dart'
    hide KanbanColumnType;
import 'package:moviestar/shared/widgets/kanban/kanban_search_filter.dart';
import 'package:moviestar/shared/widgets/kanban/kanban_settings_panel.dart';
import 'package:moviestar/widgets/error_display_widget.dart';
import 'package:moviestar/widgets/sort_controls.dart';

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

  final int _maxItemsPerColumn = 8;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
    _kanbanController = KanbanBoardController();
    _searchController = KanbanSearchController();
    _settingsController = KanbanSettingsController();

    // Initialize drag handler after context is available
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

  /// Handle drop operations
  void _handleDrop(
    MovieDragData dragData,
    KanbanColumnType targetType,
    String targetId,
    String targetName,
  ) {
    _dragHandler.handleDrop(dragData, targetType, targetId, targetName);
  }

  /// Show context menu for movie operations
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

  /// Navigate to category screen
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

  /// Navigate to custom list detail screen
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

  /// Build movie item using the kanban card widget
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
                // Search bar (if search functionality is enabled)
                if (_searchController.hasActiveFilters)
                  KanbanSearchBar(
                    controller: _searchController,
                    onClear: () => setState(() {}),
                  ),

                // Main kanban board
                Expanded(
                  child: _buildKanbanBoard(),
                ),
              ],
            ),

            // Floating operation queue indicator (no layout shift)
            if (_kanbanController.operationQueue.isNotEmpty)
              _buildFloatingOperationIndicator(),
          ],
        );
      },
    );
  }

  /// Build floating operation queue indicator (no layout shift)
  Widget _buildFloatingOperationIndicator() {
    final queue = _kanbanController.operationQueue;
    if (queue.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: 16,
      right: 16,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.m,
            vertical: Dimensions.s,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const Gap(Dimensions.s),
              Text(
                '${queue.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the main kanban board with columns
  Widget _buildKanbanBoard() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _horizontalScrollController,
      child: Consumer(
        builder: (context, ref, child) {
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
                      return StreamBuilder<List<CustomList>>(
                        stream: widget.favoritesService.customLists,
                        builder: (context, customListsSnapshot) {
                          return _buildKanbanColumns(
                            popularCacheResult,
                            toWatchSnapshot,
                            watchedSnapshot,
                            customListsSnapshot,
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) {
              return ErrorDisplayWidget(
                message: 'Error loading movies: $error',
                onRetry: () =>
                    ref.invalidate(popularMoviesWithCacheInfoProvider),
              );
            },
          );
        },
      ),
    );
  }

  /// Build all kanban columns
  Widget _buildKanbanColumns(
    dynamic popularCacheResult,
    AsyncSnapshot<List<Movie>> toWatchSnapshot,
    AsyncSnapshot<List<Movie>> watchedSnapshot,
    AsyncSnapshot<List<CustomList>> customListsSnapshot,
  ) {
    final popularMovies = popularCacheResult.data ?? <Movie>[];
    final toWatchMovies = toWatchSnapshot.data ?? [];
    final watchedMovies = watchedSnapshot.data ?? [];
    final customLists = customListsSnapshot.data ?? [];

    // Apply search filters if active
    final filteredPopular = _searchController.hasActiveFilters
        ? _searchController.filterMovies(popularMovies)
        : popularMovies;
    final filteredToWatch = _searchController.hasActiveFilters
        ? _searchController.filterMovies(toWatchMovies)
        : toWatchMovies;
    final filteredWatched = _searchController.hasActiveFilters
        ? _searchController.filterMovies(watchedMovies)
        : watchedMovies;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Popular column
        _buildSingleColumn(
          title: 'Popular',
          movies: filteredPopular,
          categoryId: 'popular',
          columnType: KanbanColumnType.popular,
          fromCache: popularCacheResult.fromCache ?? false,
          isLoading:
              popularMovies.isEmpty && !(popularCacheResult.fromCache ?? false),
        ),

        // To Watch column
        _buildSingleColumn(
          title: 'To Watch',
          movies: filteredToWatch,
          categoryId: 'towatch',
          columnType: KanbanColumnType.toWatch,
          fromCache: true,
          isLoading: !toWatchSnapshot.hasData,
        ),

        // Watched column
        _buildSingleColumn(
          title: 'Watched',
          movies: filteredWatched,
          categoryId: 'watched',
          columnType: KanbanColumnType.watched,
          fromCache: true,
          isLoading: !watchedSnapshot.hasData,
        ),

        // Custom list columns
        ...customLists
            .map((customList) => _buildUnifiedCustomListColumn(customList)),
      ],
    );
  }

  /// Build a single kanban column using the extracted component
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

  /// Build unified custom list column using KanbanColumnWidget
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

  /// Build custom list column (legacy - kept for reference)
  Widget _buildCustomListColumn(CustomList customList) {
    final movieIds = customList.movieIds.take(_maxItemsPerColumn * 2).toList();

    return SizedBox(
      width: 220,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: Dimensions.m),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: CustomListMoviesWidget(
          movieIds: movieIds,
          customList: customList,
          favoritesService: widget.favoritesService,
          sortCriteria: _kanbanController.columnSortCriteria[customList.id] ??
              MovieSortCriteria.nameAsc,
          maxItems: _settingsController.settings.maxItemsPerColumn,
          optimisticMovies: const {}, // TODO: Integrate optimistic movies from controller
          buildMovieItem: (movie, index) => _buildMovieItem(
            movie,
            customList.id,
            fromCache: true,
            columnType: KanbanColumnType.customList,
            columnId: customList.id,
            columnName: customList.name,
          ),
        ),
      ),
    );
  }
}
