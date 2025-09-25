/// Kanban Drag Handler - Drag & Drop Operations.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/shared/widgets/kanban/drag_handler/context_menu_builder.dart';
import 'package:moviestar/shared/widgets/kanban/drag_handler/context_menu_handler.dart';
import 'package:moviestar/shared/widgets/kanban/drag_handler/drop_operations.dart';
import 'package:moviestar/shared/widgets/kanban/drag_handler/message_helpers.dart';
import 'package:moviestar/shared/widgets/kanban/drag_handler/sync_operations.dart';

import 'board_controller.dart';

// Re-export helper classes for backward compatibility
export 'package:moviestar/shared/widgets/kanban/drag_handler/context_menu_builder.dart';
export 'package:moviestar/shared/widgets/kanban/drag_handler/context_menu_handler.dart';
export 'package:moviestar/shared/widgets/kanban/drag_handler/drop_operations.dart';
export 'package:moviestar/shared/widgets/kanban/drag_handler/message_helpers.dart';
export 'package:moviestar/shared/widgets/kanban/drag_handler/sync_operations.dart';

/// Handler for all drag and drop operations in the kanban board.
class KanbanDragHandler {
  final FavoritesService favoritesService;
  final KanbanBoardController controller;
  final BuildContext context;

  const KanbanDragHandler({
    required this.favoritesService,
    required this.controller,
    required this.context,
  });

  /// Handle drop operation with optimistic UI updates.
  Future<void> handleDrop(
    MovieDragData dragData,
    KanbanColumnType targetType,
    String targetId,
    String targetName,
  ) async {
    // Don't allow dropping on same column
    if (dragData.sourceType == targetType && dragData.sourceId == targetId) {
      return;
    }

    // Determine if this is a copy or move operation
    final isCopyOperation = DropOperations.isCopyOperation(dragData.sourceType);

    // Apply optimistic UI updates immediately
    DropOperations.applyOptimisticUpdates(
      controller,
      dragData,
      targetType,
      targetId,
      isCopyOperation,
    );

    // Add to queue for progress tracking
    final operationDescription = MessageHelpers.generateOperationDescription(
      dragData.movie,
      targetName,
      isCopyOperation,
    );
    final operationId = controller.addToQueue(operationDescription);

    // Perform background sync
    SyncOperations.syncDropOperation(
      favoritesService,
      controller,
      dragData,
      targetType,
      targetId,
      isCopyOperation,
      operationId,
    );
  }

  /// Show context menu for movie copy operations.
  void showMovieContextMenu(
    Offset position,
    Movie movie,
    KanbanColumnType sourceType,
    String sourceId,
    String sourceName,
  ) {
    ContextMenuHandler.showMovieContextMenu(
      context,
      position,
      movie,
      sourceType,
      sourceId,
      sourceName,
      favoritesService,
      _handleContextMenuAction,
    );
  }

  /// Handle context menu action with optimistic UI updates.
  Future<void> _handleContextMenuAction(
    String action,
    Movie movie,
    KanbanColumnType sourceType,
    String sourceId, {
    String contentType = 'movie',
  }) async {
    // Parse action and apply optimistic UI updates
    final actionData = ContextMenuBuilder.parseAction(action);
    final successMessage = action == 'remove'
        ? 'Removed "${movie.title}" ${actionData.successMessage}'
        : 'Added "${movie.title}" ${actionData.successMessage}';

    if (action == 'remove') {
      controller.removeOptimisticMovie(sourceType, sourceId, movie);
    } else if (actionData.targetType != null &&
        actionData.targetListId != null) {
      controller.addOptimisticMovie(
        actionData.targetType!,
        actionData.targetListId!,
        movie,
      );
    }

    // Add to queue for progress tracking
    final operationId = controller.addToQueue(
      MessageHelpers.successMessageToOperation(successMessage),
    );

    // Perform background sync
    SyncOperations.syncContextMenuAction(
      context,
      favoritesService,
      controller,
      action,
      movie,
      sourceType,
      sourceId,
      actionData.targetType,
      actionData.targetListId,
      successMessage,
      contentType,
      operationId,
    );
  }
}
