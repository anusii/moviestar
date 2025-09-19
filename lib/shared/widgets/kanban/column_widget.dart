/// Kanban Column Widget - Individual Column Implementation.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/constants/timing_constants.dart';
import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/shared/widgets/kanban/column_widget/header_builder.dart';
import 'package:moviestar/shared/widgets/kanban/column_widget/movie_list_builder.dart';
import 'package:moviestar/utils/movie_sort_util.dart';
import 'package:moviestar/widgets/sort_controls.dart';

import 'board_controller.dart';

// Re-export helper classes for backward compatibility
export 'package:moviestar/shared/widgets/kanban/column_widget/header_builder.dart';
export 'package:moviestar/shared/widgets/kanban/column_widget/movie_list_builder.dart';

/// Column data for building kanban columns.
class KanbanColumnData {
  final String title;
  final List<Movie> movies;
  final String categoryId;
  final bool fromCache;
  final KanbanColumnType columnType;
  final bool isLoading;
  final CustomList? customList;

  const KanbanColumnData({
    required this.title,
    required this.movies,
    required this.categoryId,
    required this.fromCache,
    required this.columnType,
    this.isLoading = false,
    this.customList,
  });
}

/// Kanban column widget with drag target support.
class KanbanColumnWidget extends StatelessWidget {
  final KanbanColumnData columnData;
  final KanbanBoardController controller;
  final FavoritesService favoritesService;
  final int maxItemsPerColumn;
  final Function(MovieDragData, KanbanColumnType, String, String) onDrop;
  final Function(String, List<Movie>, bool) onNavigateToCategory;
  final Function(CustomList) onNavigateToCustomList;
  final Widget Function(
    Movie,
    String, {
    required bool fromCache,
    required KanbanColumnType columnType,
    required String columnId,
    required String columnName,
  }) buildMovieItem;

  const KanbanColumnWidget({
    super.key,
    required this.columnData,
    required this.controller,
    required this.favoritesService,
    required this.maxItemsPerColumn,
    required this.onDrop,
    required this.onNavigateToCategory,
    required this.onNavigateToCustomList,
    required this.buildMovieItem,
  });

  @override
  Widget build(BuildContext context) {
    // Apply optimistic updates
    final moviesWithOptimistic = controller.getMoviesWithOptimisticUpdates(
      columnData.movies,
      columnData.columnType,
      columnData.categoryId,
    );

    // Apply sorting based on column's sort criteria
    final sortCriteria = controller.columnSortCriteria[columnData.categoryId] ??
        MovieSortCriteria.nameAsc;
    final sortedMovies = sortMovies(
      List<Movie>.from(moviesWithOptimistic),
      sortCriteria,
    );

    final displayMovies = sortedMovies.take(maxItemsPerColumn).toList();
    final hasMore = sortedMovies.length > maxItemsPerColumn;
    final canAcceptDrop = columnData.columnType != KanbanColumnType.popular;
    final hasPendingOps = controller.isPendingOperation(
      columnData.columnType,
      columnData.categoryId,
      0, // dummy ID, just checking if any operations exist
    );

    Widget columnContent = Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: Dimensions.m),
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
          HeaderBuilder.buildColumnHeader(
            context,
            columnData.title,
            columnData.customList,
            sortedMovies,
            hasMore,
            hasPendingOps,
            columnData.categoryId,
            controller,
            onNavigateToCustomList,
            onNavigateToCategory,
            columnData.fromCache,
          ),

          // Movie items
          Expanded(
            child: MovieListBuilder.buildMovieList(
              context,
              columnData.title,
              columnData.categoryId,
              columnData.fromCache,
              columnData.columnType,
              columnData.isLoading,
              displayMovies,
              buildMovieItem,
            ),
          ),
        ],
      ),
    );

    // Wrap in DragTarget if it can accept drops
    if (!canAcceptDrop) {
      return columnContent;
    }

    return DragTarget<MovieDragData>(
      onAcceptWithDetails: (details) {
        onDrop(
          details.data,
          columnData.columnType,
          columnData.categoryId,
          columnData.title,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: TimingConstants.containerAnimationDuration,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isHovering
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: columnContent,
        );
      },
    );
  }
}
