/// Kanban Drag Handler - Drag & Drop Operations.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/constants/timing_constants.dart';
import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';

import 'board_controller.dart';

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
    debugPrint('   Drag Source: ${dragData.sourceType} (${dragData.sourceId})');
    debugPrint('   Drop Target: $targetType ($targetId)');
    debugPrint('   Movie: ${dragData.movie.title} (ID: ${dragData.movie.id})');
    debugPrint('   Movie ContentType: ${dragData.movie.contentType}');

    // Don't allow dropping on same column
    if (dragData.sourceType == targetType && dragData.sourceId == targetId) {
      return;
    }

    // Determine if this is a copy or move operation
    final isCopyOperation = dragData.sourceType == KanbanColumnType.popular;

    // Apply optimistic UI updates immediately
    controller.addOptimisticMovie(targetType, targetId, dragData.movie);
    if (!isCopyOperation) {
      controller.removeOptimisticMovie(
        dragData.sourceType,
        dragData.sourceId,
        dragData.movie,
      );
    }

    // Add to queue for progress tracking
    final operationDescription = isCopyOperation
        ? 'Copy ${dragData.movie.title} to $targetName'
        : 'Move ${dragData.movie.title} to $targetName';
    final operationId = controller.addToQueue(operationDescription);

    // Perform background sync
    _syncDropOperation(
      dragData,
      targetType,
      targetId,
      targetName,
      isCopyOperation,
      operationId,
    );
  }

  /// Background sync operation.
  Future<void> _syncDropOperation(
    MovieDragData dragData,
    KanbanColumnType targetType,
    String targetId,
    String targetName,
    bool isCopyOperation,
    int operationId,
  ) async {
    debugPrint('   Movie: ${dragData.movie.title} (ID: ${dragData.movie.id})');
    debugPrint('   ContentType: ${dragData.movie.contentType}');
    debugPrint('   Target: $targetType ($targetName)');
    debugPrint('   Copy operation: $isCopyOperation');

    controller.updateQueueStatus(operationId, OperationStatus.inProgress);
    try {
      // Ensure movie file exists before adding to user lists
      await _ensureMovieFileExists(dragData.movie);

      // Add to target list
      switch (targetType) {
        case KanbanColumnType.toWatch:
          final contentTypeString =
              dragData.movie.contentType == ContentType.tvShow ? 'tv' : 'movie';
          debugPrint(
            '🎬 [KanbanDrag] Adding to ToWatch with contentType string: $contentTypeString',
          );
          await favoritesService.addToWatch(
            dragData.movie,
            contentType: contentTypeString,
          );
          break;
        case KanbanColumnType.watched:
          final contentTypeString =
              dragData.movie.contentType == ContentType.tvShow ? 'tv' : 'movie';
          debugPrint(
            '🎬 [KanbanDrag] Adding to Watched with contentType string: $contentTypeString',
          );
          await favoritesService.addToWatched(
            dragData.movie,
            contentType: contentTypeString,
          );
          break;
        case KanbanColumnType.customList:
          final contentTypeString =
              dragData.movie.contentType == ContentType.tvShow ? 'tv' : 'movie';
          debugPrint(
            '🎬 [KanbanDrag] Adding to custom list with contentType string: $contentTypeString',
          );
          await favoritesService.addMovieToCustomList(
            targetId,
            dragData.movie,
            contentType: contentTypeString,
          );
          break;
        case KanbanColumnType.popular:
        // Can't drop into popular
      }

      // Only remove from source if it's a move operation (not from Popular)
      if (!isCopyOperation) {
        await _removeFromCurrentList(
          dragData.movie,
          dragData.sourceType,
          dragData.sourceId,
        );
      }

      // Clear optimistic state and update queue status
      controller.clearOptimisticState(targetType, targetId, dragData.movie.id);
      if (!isCopyOperation) {
        controller.clearOptimisticState(
          dragData.sourceType,
          dragData.sourceId,
          dragData.movie.id,
        );
      }
      controller.updateQueueStatus(operationId, OperationStatus.completed);
    } catch (e) {
      // Revert optimistic updates on error
      controller.markSyncError(targetType, targetId, dragData.movie.id);
      if (!isCopyOperation) {
        controller.markSyncError(
          dragData.sourceType,
          dragData.sourceId,
          dragData.movie.id,
        );
      }

      controller.updateQueueStatus(operationId, OperationStatus.failed);
    }
  }

  /// Remove movie from its current list.
  Future<void> _removeFromCurrentList(
    Movie movie,
    KanbanColumnType sourceType,
    String sourceId,
  ) async {
    switch (sourceType) {
      case KanbanColumnType.toWatch:
        await favoritesService.removeFromToWatch(movie);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed "${movie.title}" from To Watch')),
          );
        }
        break;
      case KanbanColumnType.watched:
        await favoritesService.removeFromWatched(movie);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed "${movie.title}" from Watched')),
          );
        }
        break;
      case KanbanColumnType.customList:
        await favoritesService.removeMovieFromCustomList(sourceId, movie.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed "${movie.title}" from custom list'),
            ),
          );
        }
        break;
      case KanbanColumnType.popular:
        // Can't remove from popular
        break;
    }
  }

  /// Ensure a movie file exists for the given movie.
  /// This is important for movies from the Popular list that might not have local files yet.
  Future<void> _ensureMovieFileExists(Movie movie) async {
    try {
      // Check if the movie file already exists
      final hasFile = await favoritesService.hasMovieFile(movie);

      if (!hasFile) {
        // For new movies (typically from Popular), we might need to create basic metadata
        // The favorites service should handle this automatically when adding to lists,
        // but we can add a small delay to ensure the movie data is properly cached
        await Future.delayed(TimingConstants.movieCardHoverHideDelay);
      }
    } catch (e) {
      // If checking fails, continue anyway - the favorites service should handle creation
      debugPrint(
        'Warning: Could not verify movie file existence for ${movie.title}: $e',
      );
    }
  }

  /// Show context menu for movie copy operations.
  void showMovieContextMenu(
    Offset position,
    Movie movie,
    KanbanColumnType sourceType,
    String sourceId,
    String sourceName,
  ) {
    // Get current custom lists for dynamic menu
    favoritesService.customLists.first.then((customLists) {
      if (!context.mounted) return;
      showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(
          position.dx,
          position.dy,
          position.dx + 1,
          position.dy + 1,
        ),
        items: _buildContextMenuItems(movie, sourceType, sourceId, customLists),
      ).then((action) {
        if (action != null) {
          _handleContextMenuAction(action, movie, sourceType, sourceId);
        }
      });
    }).catchError((e) {
      // Fallback to basic menu if custom lists can't be loaded
      if (!context.mounted) return;
      showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(
          position.dx,
          position.dy,
          position.dx + 1,
          position.dy + 1,
        ),
        items: _buildContextMenuItems(movie, sourceType, sourceId, []),
      ).then((action) {
        if (action != null) {
          _handleContextMenuAction(action, movie, sourceType, sourceId);
        }
      });
    });
  }

  /// Build context menu items based on current movie location.
  List<PopupMenuEntry<String>> _buildContextMenuItems(
    Movie movie,
    KanbanColumnType sourceType,
    String sourceId,
    List<CustomList> customLists,
  ) {
    final items = <PopupMenuEntry<String>>[];

    // Add "Copy to..." options
    if (sourceType != KanbanColumnType.toWatch) {
      items.add(
        const PopupMenuItem(
          value: 'copy_to_watch',
          child: Row(
            children: [
              Icon(Icons.bookmark_add_outlined),
              Gap(Gaps.m),
              Text('Copy to To Watch'),
            ],
          ),
        ),
      );
    }

    if (sourceType != KanbanColumnType.watched) {
      items.add(
        const PopupMenuItem(
          value: 'copy_watched',
          child: Row(
            children: [
              Icon(Icons.check_circle_outline),
              Gap(Gaps.m),
              Text('Copy to Watched'),
            ],
          ),
        ),
      );
    }

    // Add custom list options
    for (final customList in customLists) {
      // Skip if the movie is already in this custom list
      if (sourceType == KanbanColumnType.customList &&
          sourceId == customList.id) {
        continue;
      }

      items.add(
        PopupMenuItem(
          value: 'copy_custom_${customList.id}',
          child: Row(
            children: [
              const Icon(Icons.playlist_add),
              const Gap(Gaps.m),
              Expanded(
                child: Text(
                  'Copy to ${customList.name}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Add divider before remove option (only for non-Popular movies)
    if (sourceType != KanbanColumnType.popular) {
      if (items.isNotEmpty) {
        items.add(const PopupMenuDivider());
      }
      items.add(
        PopupMenuItem(
          value: 'remove',
          child: Row(
            children: [
              Icon(
                Icons.remove_circle_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const Gap(Gaps.m),
              Text(
                'Remove from this list',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ),
      );
    }

    return items;
  }

  /// Handle context menu action with optimistic UI updates.
  Future<void> _handleContextMenuAction(
    String action,
    Movie movie,
    KanbanColumnType sourceType,
    String sourceId, {
    String contentType = 'movie',
  }) async {
    // Apply optimistic UI updates first
    String? targetListId;
    KanbanColumnType? targetType;
    String successMessage = '';

    switch (action) {
      case 'copy_to_watch':
        targetType = KanbanColumnType.toWatch;
        targetListId = 'towatch';
        successMessage = 'Added "${movie.title}" to To Watch';
        controller.addOptimisticMovie(targetType, targetListId, movie);
        break;
      case 'copy_watched':
        targetType = KanbanColumnType.watched;
        targetListId = 'watched';
        successMessage = 'Added "${movie.title}" to Watched';
        controller.addOptimisticMovie(targetType, targetListId, movie);
        break;
      case 'remove':
        successMessage = 'Removed "${movie.title}" from list';
        controller.removeOptimisticMovie(sourceType, sourceId, movie);
        break;
      default:
        if (action.startsWith('copy_custom_')) {
          targetType = KanbanColumnType.customList;
          targetListId = action.substring('copy_custom_'.length);
          successMessage = 'Added "${movie.title}" to custom list';
          controller.addOptimisticMovie(targetType, targetListId, movie);
        }
    }

    // Add to queue for progress tracking
    final operationId = controller.addToQueue(
      successMessage
          .replaceFirst('Added', 'Adding')
          .replaceFirst('Removed', 'Removing'),
    );

    // Perform background sync
    _syncContextMenuAction(
      action,
      movie,
      sourceType,
      sourceId,
      targetType,
      targetListId,
      successMessage,
      contentType,
      operationId,
    );
  }

  /// Background sync for context menu actions.
  Future<void> _syncContextMenuAction(
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
      // Ensure movie file exists for copy operations (especially from Popular)
      if (action != 'remove') {
        await _ensureMovieFileExists(movie);
      }

      switch (action) {
        case 'copy_to_watch':
          await favoritesService.addToWatch(movie, contentType: contentType);
          break;
        case 'copy_watched':
          await favoritesService.addToWatched(movie, contentType: contentType);
          break;
        case 'remove':
          await _removeFromCurrentList(movie, sourceType, sourceId);
          break;
        default:
          // Handle custom list copy operations
          if (action.startsWith('copy_custom_')) {
            final listId = action.substring('copy_custom_'.length);
            await favoritesService.addMovieToCustomList(
              listId,
              movie,
              contentType: contentType,
            );
          }
      }

      // Clear optimistic state and update queue status
      if (targetType != null && targetListId != null) {
        controller.clearOptimisticState(targetType, targetListId, movie.id);
      }
      if (action == 'remove') {
        controller.clearOptimisticState(sourceType, sourceId, movie.id);
      }
      controller.updateQueueStatus(operationId, OperationStatus.completed);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } catch (e) {
      // Revert optimistic updates on error
      if (targetType != null && targetListId != null) {
        controller.markSyncError(targetType, targetListId, movie.id);
      }
      if (action == 'remove') {
        controller.markSyncError(sourceType, sourceId, movie.id);
      }

      controller.updateQueueStatus(operationId, OperationStatus.failed);

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${action.replaceAll('_', ' ')} "${movie.title}"',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
