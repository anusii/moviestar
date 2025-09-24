/// Header building helpers for kanban column widget.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/shared/widgets/kanban/board_controller.dart';
import 'package:moviestar/widgets/sort_controls.dart';

/// Static helper class for building column headers.
class HeaderBuilder {
  /// Build the complete column header.
  static Widget buildColumnHeader(
    BuildContext context,
    String title,
    CustomList? customList,
    List<Movie> sortedMovies,
    bool hasMore,
    bool hasPendingOps,
    String categoryId,
    KanbanBoardController controller,
    Function(CustomList) onNavigateToCustomList,
    Function(String, List<Movie>, bool) onNavigateToCategory,
    bool fromCache,
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
          // First row: Title + Count Badge + Sort button.

          Row(
            children: [
              Expanded(
                child: buildColumnTitle(
                  context,
                  title,
                  customList,
                  onNavigateToCustomList,
                ),
              ),
              buildCountBadge(context, sortedMovies, hasMore, hasPendingOps),
              const SizedBox(width: 8),
              buildSortButton(context, categoryId, controller),
            ],
          ),
          // Second row: View More button (only when needed).

          if (hasMore) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                buildViewMoreButton(
                  context,
                  title,
                  sortedMovies,
                  fromCache,
                  onNavigateToCategory,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build the column title widget.
  static Widget buildColumnTitle(
    BuildContext context,
    String title,
    CustomList? customList,
    Function(CustomList) onNavigateToCustomList,
  ) {
    if (customList != null) {
      return GestureDetector(
        onTap: () => onNavigateToCustomList(customList),
        child: Text(
          customList.name,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Build the count badge with optional pending operations indicator.
  static Widget buildCountBadge(
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

  /// Build the sort button with dropdown menu.
  static Widget buildSortButton(
    BuildContext context,
    String categoryId,
    KanbanBoardController controller,
  ) {
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
            controller.onSortChanged(categoryId, criteria),
        itemBuilder: (context) {
          final currentSort = controller.columnSortCriteria[categoryId] ??
              MovieSortCriteria.nameAsc;
          return [
            buildSortMenuItem(
              context,
              currentSort,
              MovieSortCriteria.nameAsc,
              'Name (A-Z)',
            ),
            buildSortMenuItem(
              context,
              currentSort,
              MovieSortCriteria.nameDesc,
              'Name (Z-A)',
            ),
            buildSortMenuItem(
              context,
              currentSort,
              MovieSortCriteria.ratingDesc,
              'Rating (High to Low)',
            ),
            buildSortMenuItem(
              context,
              currentSort,
              MovieSortCriteria.ratingAsc,
              'Rating (Low to High)',
            ),
            buildSortMenuItem(
              context,
              currentSort,
              MovieSortCriteria.dateDesc,
              'Date (Newest First)',
            ),
            buildSortMenuItem(
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

  /// Build a single sort menu item.
  static PopupMenuItem<MovieSortCriteria> buildSortMenuItem(
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

  /// Build the "View More" button.
  static Widget buildViewMoreButton(
    BuildContext context,
    String title,
    List<Movie> sortedMovies,
    bool fromCache,
    Function(String, List<Movie>, bool) onNavigateToCategory,
  ) {
    return TextButton(
      onPressed: () => onNavigateToCategory(title, sortedMovies, fromCache),
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
}
