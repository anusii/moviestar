/// Movie list building helpers for kanban column widget.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/shared/widgets/kanban/board_controller.dart';

/// Static helper class for building movie lists.

class MovieListBuilder {
  /// Build the movie list widget with loading and empty states.

  static Widget buildMovieList(
    BuildContext context,
    String title,
    String categoryId,
    bool fromCache,
    KanbanColumnType columnType,
    bool isLoading,
    List<Movie> displayMovies,
    Widget Function(
      Movie,
      String, {
      required bool fromCache,
      required KanbanColumnType columnType,
      required String columnId,
      required String columnName,
    }) buildMovieItem,
  ) {
    if (isLoading) {
      return buildLoadingState(context, title);
    }

    if (displayMovies.isEmpty) {
      return buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: displayMovies.length,
      itemBuilder: (context, index) {
        final movie = displayMovies[index];
        return buildMovieItem(
          movie,
          categoryId,
          fromCache: fromCache,
          columnType: columnType,
          columnId: categoryId,
          columnName: title,
        );
      },
    );
  }

  /// Build loading state widget.

  static Widget buildLoadingState(BuildContext context, String title) {
    return _buildSkeletonLoadingState(context, title);
  }

  /// Build skeleton-style loading state for consistent kanban column loading UX.

  static Widget _buildSkeletonLoadingState(BuildContext context, String title) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildLoadingMovieItem(context),
        );
      },
    );
  }

  /// Build a loading skeleton for a movie item.

  static Widget _buildLoadingMovieItem(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Poster skeleton.

          Container(
            width: 50,
            height: 70,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Gap(8),
          // Text content skeleton.

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title skeleton.

                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Gap(4),
                // Subtitle skeleton.

                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const Gap(8),
        ],
      ),
    );
  }

  /// Build empty state widget.

  static Widget buildEmptyState(BuildContext context) {
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
}
