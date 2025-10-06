/// Drop operation handling for kanban drag and drop.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:moviestar/constants/timing_constants.dart';
import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/shared/widgets/kanban/board_controller.dart';

/// Static helper class for handling drop operations.

class DropOperations {
  /// Determine if the drop operation is a copy (from Recommended) or move.

  static bool isCopyOperation(KanbanColumnType sourceType) {
    return sourceType == KanbanColumnType.recommended;
  }

  /// Apply optimistic UI updates for drop operation.

  static void applyOptimisticUpdates(
    KanbanBoardController controller,
    MovieDragData dragData,
    KanbanColumnType targetType,
    String targetId,
    bool isCopyOperation,
  ) {
    controller.addOptimisticMovie(targetType, targetId, dragData.movie);
    // Always remove from source for immediate UI feedback.
    // For copy operations from Recommended, this prevents the delay
    // where the movie appears in both lists during filtering.

    controller.removeOptimisticMovie(
      dragData.sourceType,
      dragData.sourceId,
      dragData.movie,
    );
  }

  /// Add movie to target list based on column type.

  static Future<void> addToTargetList(
    FavoritesService favoritesService,
    Movie movie,
    KanbanColumnType targetType,
    String targetId,
  ) async {
    final contentTypeString =
        movie.contentType == ContentType.tvShow ? 'tv' : 'movie';

    switch (targetType) {
      case KanbanColumnType.toWatch:
        await favoritesService.addToWatch(
          movie,
          contentType: contentTypeString,
        );
        break;
      case KanbanColumnType.watched:
        await favoritesService.addToWatched(
          movie,
          contentType: contentTypeString,
        );
        break;
      case KanbanColumnType.customList:
        await favoritesService.addMovieToCustomList(
          targetId,
          movie,
          contentType: contentTypeString,
        );
        break;
      case KanbanColumnType.recommended:
      // Can't drop into popular.
    }
  }

  /// Remove movie from source list for move operations.

  static Future<void> removeFromSourceList(
    FavoritesService favoritesService,
    Movie movie,
    KanbanColumnType sourceType,
    String sourceId,
  ) async {
    switch (sourceType) {
      case KanbanColumnType.toWatch:
        await favoritesService.removeFromToWatch(movie);
        break;
      case KanbanColumnType.watched:
        await favoritesService.removeFromWatched(movie);
        break;
      case KanbanColumnType.customList:
        await favoritesService.removeMovieFromCustomList(sourceId, movie.id);
        break;
      case KanbanColumnType.recommended:
        // Can't remove from popular.

        break;
    }
  }

  /// Ensure a movie file exists for the given movie.
  /// This is important for movies from the Recommended list that might not have local files yet.

  static Future<void> ensureMovieFileExists(
    FavoritesService favoritesService,
    Movie movie,
  ) async {
    try {
      // Check if the movie file already exists.

      final hasFile = await favoritesService.hasMovieFile(movie);

      if (!hasFile) {
        // For new movies (typically from Recommended), we might need to create basic metadata.
        // The favorites service should handle this automatically when adding to lists,
        // but we can add a small delay to ensure the movie data is properly cached.

        await Future.delayed(TimingConstants.movieCardHoverHideDelay);
      }
    } catch (e) {
      // If checking fails, continue anyway - the favorites service should handle creation.
    }
  }

  /// Clear optimistic state after successful operation.

  static void clearOptimisticState(
    KanbanBoardController controller,
    MovieDragData dragData,
    KanbanColumnType targetType,
    String targetId,
    bool isCopyOperation,
  ) {
    controller.clearOptimisticState(targetType, targetId, dragData.movie.id);
    // Always clear source optimistic state since we always apply it.

    controller.clearOptimisticState(
      dragData.sourceType,
      dragData.sourceId,
      dragData.movie.id,
    );
  }

  /// Mark sync errors for failed operations.

  static void markSyncErrors(
    KanbanBoardController controller,
    MovieDragData dragData,
    KanbanColumnType targetType,
    String targetId,
    bool isCopyOperation,
  ) {
    controller.markSyncError(targetType, targetId, dragData.movie.id);
    // Always mark source sync error since we always apply optimistic removal.

    controller.markSyncError(
      dragData.sourceType,
      dragData.sourceId,
      dragData.movie.id,
    );
  }
}
