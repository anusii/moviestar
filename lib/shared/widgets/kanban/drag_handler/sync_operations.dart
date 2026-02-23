/// Sync operations for kanban drag and drop background processing.
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
/// Authors: Ashley Tang, Kevin Wang

library;

import 'package:flutter/material.dart';

import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/shared/widgets/kanban/board_controller.dart';

import 'drop_operations.dart';
import 'message_helpers.dart';

/// Static helper class for background sync operations.

class SyncOperations {
  /// Background sync operation for drop actions.

  static Future<void> syncDropOperation(
    FavoritesService favoritesService,
    KanbanBoardController controller,
    MovieDragData dragData,
    KanbanColumnType targetType,
    String targetId,
    bool isCopyOperation,
    int operationId,
  ) async {
    controller.updateQueueStatus(operationId, OperationStatus.inProgress);
    try {
      // Ensure movie file exists before adding to user lists.

      await DropOperations.ensureMovieFileExists(
        favoritesService,
        dragData.movie,
      );

      // Add to target list.

      await DropOperations.addToTargetList(
        favoritesService,
        dragData.movie,
        targetType,
        targetId,
      );

      // Only remove from source if it's a move operation (not from Recommended).

      if (!isCopyOperation) {
        await DropOperations.removeFromSourceList(
          favoritesService,
          dragData.movie,
          dragData.sourceType,
          dragData.sourceId,
        );
      }

      // Clear optimistic state and update queue status.

      DropOperations.clearOptimisticState(
        controller,
        dragData,
        targetType,
        targetId,
        isCopyOperation,
      );
      controller.updateQueueStatus(operationId, OperationStatus.completed);
    } catch (e) {
      // Revert optimistic updates on error.

      DropOperations.markSyncErrors(
        controller,
        dragData,
        targetType,
        targetId,
        isCopyOperation,
      );
      controller.updateQueueStatus(operationId, OperationStatus.failed);
    }
  }

  /// Background sync for context menu actions.

  static Future<void> syncContextMenuAction(
    BuildContext context,
    FavoritesService favoritesService,
    KanbanBoardController controller,
    String action,
    Movie movie,
    KanbanColumnType sourceType,
    String sourceId,
    KanbanColumnType? targetType,
    String? targetListId,
    String successMessage,
    String contentType,
    int operationId,
  ) async {
    controller.updateQueueStatus(operationId, OperationStatus.inProgress);
    try {
      // Ensure movie file exists for copy operations (especially from Recommended).

      if (action != 'remove') {
        await DropOperations.ensureMovieFileExists(favoritesService, movie);
      }

      switch (action) {
        case 'copy_to_watch':
          await favoritesService.addToWatch(movie, contentType: contentType);
          break;
        case 'copy_watched':
          await favoritesService.addToWatched(movie, contentType: contentType);
          break;
        case 'remove':
          await DropOperations.removeFromSourceList(
            favoritesService,
            movie,
            sourceType,
            sourceId,
          );
          if (context.mounted) {
            MessageHelpers.showRemovalMessage(context, movie, sourceType);
          }
          break;
        default:
          // Handle custom list copy operations.

          if (action.startsWith('copy_custom_')) {
            final listId = action.substring('copy_custom_'.length);
            await favoritesService.addMovieToCustomList(
              listId,
              movie,
              contentType: contentType,
            );
          }
      }

      // Clear optimistic state and update queue status.

      if (targetType != null && targetListId != null) {
        controller.clearOptimisticState(targetType, targetListId, movie.id);
      }
      if (action == 'remove') {
        controller.clearOptimisticState(sourceType, sourceId, movie.id);
      }
      controller.updateQueueStatus(operationId, OperationStatus.completed);

      // Show success message (except for remove, which is handled above).

      if (action != 'remove') {
        if (context.mounted) {
          MessageHelpers.showSuccessMessage(
            context,
            action,
            movie,
            successMessage.substring(
              successMessage.indexOf('"') + movie.title.length + 2,
            ),
          );
        }
      }
    } catch (e) {
      // Revert optimistic updates on error.

      if (targetType != null && targetListId != null) {
        controller.markSyncError(targetType, targetListId, movie.id);
      }
      if (action == 'remove') {
        controller.markSyncError(sourceType, sourceId, movie.id);
      }

      controller.updateQueueStatus(operationId, OperationStatus.failed);

      // Show error message.

      if (context.mounted) {
        MessageHelpers.showErrorMessage(context, action, movie);
      }
    }
  }
}
