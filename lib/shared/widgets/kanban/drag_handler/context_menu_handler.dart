/// Context menu handler for kanban drag operations.
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

import 'context_menu_builder.dart';

/// Static helper class for handling context menu operations.

class ContextMenuHandler {
  /// Show context menu for movie copy operations.

  static void showMovieContextMenu(
    BuildContext context,
    Offset position,
    Movie movie,
    KanbanColumnType sourceType,
    String sourceId,
    String sourceName,
    FavoritesService favoritesService,
    Function(String, Movie, KanbanColumnType, String) onContextMenuAction,
  ) {
    // Get current custom lists for dynamic menu.

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
        items: ContextMenuBuilder.buildContextMenuItems(
          context,
          movie,
          sourceType,
          sourceId,
          customLists,
        ),
      ).then((action) {
        if (action != null) {
          onContextMenuAction(action, movie, sourceType, sourceId);
        }
      });
    }).catchError((e) {
      // Fallback to basic menu if custom lists can't be loaded.

      if (!context.mounted) return;
      showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(
          position.dx,
          position.dy,
          position.dx + 1,
          position.dy + 1,
        ),
        items: ContextMenuBuilder.buildContextMenuItems(
          context,
          movie,
          sourceType,
          sourceId,
          [],
        ),
      ).then((action) {
        if (action != null) {
          onContextMenuAction(action, movie, sourceType, sourceId);
        }
      });
    });
  }
}
