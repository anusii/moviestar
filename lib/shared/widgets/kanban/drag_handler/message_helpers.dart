/// Message helpers for kanban operations.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/shared/widgets/kanban/board_controller.dart';

/// Static helper class for showing messages during kanban operations.
class MessageHelpers {
  /// Show removal success message.
  static void showRemovalMessage(
    BuildContext context,
    Movie movie,
    KanbanColumnType sourceType,
  ) {
    if (!context.mounted) return;

    String message;
    switch (sourceType) {
      case KanbanColumnType.toWatch:
        message = 'Removed "${movie.title}" from To Watch';
        break;
      case KanbanColumnType.watched:
        message = 'Removed "${movie.title}" from Watched';
        break;
      case KanbanColumnType.customList:
        message = 'Removed "${movie.title}" from custom list';
        break;
      case KanbanColumnType.recommended:
        return; // Can't remove from recommended
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Show success message for context menu actions.
  static void showSuccessMessage(
    BuildContext context,
    String action,
    Movie movie,
    String successMessage,
  ) {
    if (!context.mounted) return;

    final message = action == 'remove'
        ? 'Removed "${movie.title}" $successMessage'
        : 'Added "${movie.title}" $successMessage';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Show error message for failed operations.
  static void showErrorMessage(
    BuildContext context,
    String action,
    Movie movie,
  ) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failed to ${action.replaceAll('_', ' ')} "${movie.title}"',
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  /// Generate operation description for queue tracking.
  static String generateOperationDescription(
    Movie movie,
    String targetName,
    bool isCopyOperation,
  ) {
    return isCopyOperation
        ? 'Copy ${movie.title} to $targetName'
        : 'Move ${movie.title} to $targetName';
  }

  /// Convert success message to operation description for queue.
  static String successMessageToOperation(String successMessage) {
    return successMessage
        .replaceFirst('Added', 'Adding')
        .replaceFirst('Removed', 'Removing');
  }
}
