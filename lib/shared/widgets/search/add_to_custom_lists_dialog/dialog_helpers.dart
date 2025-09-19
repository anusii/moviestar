/// Dialog helpers for creating new custom lists.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/constants/timing_constants.dart';
import 'package:moviestar/models/movie.dart';

/// Static helper class for dialog operations.
class DialogHelpers {
  /// Shows the create new list dialog.
  static void showCreateNewListDialog(
    BuildContext context,
    TextEditingController controller,
    VoidCallback onCreateAndAdd,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New List'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'List Name',
            hintText: 'Enter a unique name for your list...',
            border: OutlineInputBorder(),
            helperText: 'Tip: Use unique names to avoid duplicates',
            helperMaxLines: 2,
          ),
          autofocus: true,
          onSubmitted: (_) => onCreateAndAdd(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: onCreateAndAdd,
            child: const Text('Create & Add'),
          ),
        ],
      ),
    );
  }

  /// Shows a success message for creating a new list and adding a movie.
  static void showSuccessMessage(
    BuildContext context,
    String listName,
    Movie movie,
  ) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Created "$listName" and added "${movie.title}"',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 6,
        duration: TimingConstants.snackbarStandardDuration,
      ),
    );
  }
}