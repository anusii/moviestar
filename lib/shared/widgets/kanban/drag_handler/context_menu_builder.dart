/// Context menu builder for kanban drag operations.
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
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/shared/widgets/kanban/board_controller.dart';

/// Static helper class for building context menus.
class ContextMenuBuilder {
  /// Build context menu items based on current movie location.
  static List<PopupMenuEntry<String>> buildContextMenuItems(
    BuildContext context,
    Movie movie,
    KanbanColumnType sourceType,
    String sourceId,
    List<CustomList> customLists,
  ) {
    final items = <PopupMenuEntry<String>>[];

    // Add "Copy to..." options.

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

    // Add custom list options.

    for (final customList in customLists) {
      // Skip if the movie is already in this custom list.

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

    // Add divider before remove option (only for non-Recommended movies).

    if (sourceType != KanbanColumnType.recommended) {
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

  /// Parse context menu action to determine target details.
  static ContextMenuAction parseAction(String action) {
    String? targetListId;
    KanbanColumnType? targetType;
    String successMessage = '';

    switch (action) {
      case 'copy_to_watch':
        targetType = KanbanColumnType.toWatch;
        targetListId = 'towatch';
        successMessage = 'to To Watch';
        break;
      case 'copy_watched':
        targetType = KanbanColumnType.watched;
        targetListId = 'watched';
        successMessage = 'to Watched';
        break;
      case 'remove':
        successMessage = 'from list';
        break;
      default:
        if (action.startsWith('copy_custom_')) {
          targetType = KanbanColumnType.customList;
          targetListId = action.substring('copy_custom_'.length);
          successMessage = 'to custom list';
        }
    }

    return ContextMenuAction(
      targetType: targetType,
      targetListId: targetListId,
      successMessage: successMessage,
    );
  }
}

/// Data class for context menu action details.
class ContextMenuAction {
  final KanbanColumnType? targetType;
  final String? targetListId;
  final String successMessage;

  const ContextMenuAction({
    this.targetType,
    this.targetListId,
    required this.successMessage,
  });
}
