/// Movie list building helpers for kanban column widget.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

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
            'Loading $title...',
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