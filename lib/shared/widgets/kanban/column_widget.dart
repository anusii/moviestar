/// Kanban Column Widget - Individual Column Implementation.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/constants/timing_constants.dart';
import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/utils/movie_sort_util.dart';
import 'package:moviestar/widgets/sort_controls.dart';

import 'board_controller.dart';

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
          _buildColumnHeader(context, sortedMovies, hasMore, hasPendingOps),

          // Movie items
          Expanded(
            child: _buildMovieList(context, displayMovies),
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

  Widget _buildColumnHeader(
    BuildContext context,
    List<Movie> sortedMovies,
    bool hasMore,
    bool hasPendingOps,
  ) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First row: Title + Count Badge + Sort button
          Row(
            children: [
              Expanded(
                child: _buildColumnTitle(context),
              ),
              _buildCountBadge(context, sortedMovies, hasMore, hasPendingOps),
              const SizedBox(width: 8),
              _buildSortButton(context),
            ],
          ),
          // Second row: View More button (only when needed)
          if (hasMore) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                _buildViewMoreButton(context, sortedMovies),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColumnTitle(BuildContext context) {
    if (columnData.customList != null) {
      return GestureDetector(
        onTap: () => onNavigateToCustomList(columnData.customList!),
        child: Text(
          columnData.customList!.name,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Text(
      columnData.title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCountBadge(
    BuildContext context,
    List<Movie> sortedMovies,
    bool hasMore,
    bool hasPendingOps,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${sortedMovies.length}${hasMore ? '+' : ''}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
          ),
          if (hasPendingOps) ...[
            const SizedBox(width: 4),
            SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(
                strokeWidth: 1,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSortButton(BuildContext context) {
    return MarkdownTooltip(
      message:
          '**Sort** movies in this column\n\nClick to choose from:\n• Name (A-Z / Z-A)\n• Rating (High-Low / Low-High)\n• Date (Newest / Oldest)',
      child: PopupMenuButton<MovieSortCriteria>(
        tooltip: 'Sort',
        icon: Icon(
          Icons.sort,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onSelected: (criteria) =>
            controller.onSortChanged(columnData.categoryId, criteria),
        itemBuilder: (context) {
          final currentSort =
              controller.columnSortCriteria[columnData.categoryId] ??
                  MovieSortCriteria.nameAsc;
          return [
            _buildSortMenuItem(
              context,
              currentSort,
              MovieSortCriteria.nameAsc,
              'Name (A-Z)',
            ),
            _buildSortMenuItem(
              context,
              currentSort,
              MovieSortCriteria.nameDesc,
              'Name (Z-A)',
            ),
            _buildSortMenuItem(
              context,
              currentSort,
              MovieSortCriteria.ratingDesc,
              'Rating (High to Low)',
            ),
            _buildSortMenuItem(
              context,
              currentSort,
              MovieSortCriteria.ratingAsc,
              'Rating (Low to High)',
            ),
            _buildSortMenuItem(
              context,
              currentSort,
              MovieSortCriteria.dateDesc,
              'Date (Newest First)',
            ),
            _buildSortMenuItem(
              context,
              currentSort,
              MovieSortCriteria.dateAsc,
              'Date (Oldest First)',
            ),
          ];
        },
      ),
    );
  }

  PopupMenuItem<MovieSortCriteria> _buildSortMenuItem(
    BuildContext context,
    MovieSortCriteria currentSort,
    MovieSortCriteria criteria,
    String label,
  ) {
    return PopupMenuItem(
      value: criteria,
      child: Row(
        children: [
          Icon(
            currentSort == criteria
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildViewMoreButton(BuildContext context, List<Movie> sortedMovies) {
    return TextButton(
      onPressed: () => onNavigateToCategory(
        columnData.title,
        sortedMovies,
        columnData.fromCache,
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
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 11,
            ),
      ),
    );
  }

  Widget _buildMovieList(BuildContext context, List<Movie> displayMovies) {
    if (columnData.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const Gap(8),
            Text(
              'Loading ${columnData.title}...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      );
    }

    if (displayMovies.isEmpty) {
      return Center(
        child: Text(
          'No movies',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: displayMovies.length,
      itemBuilder: (context, index) {
        final movie = displayMovies[index];
        return buildMovieItem(
          movie,
          columnData.categoryId,
          fromCache: columnData.fromCache,
          columnType: columnData.columnType,
          columnId: columnData.categoryId,
          columnName: columnData.title,
        );
      },
    );
  }
}
