/// Dialog builders for custom list detail screen.
/// Extracted to reduce file size and improve organization.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/models/custom_list.dart';

/// Builds dialog widgets for custom list operations.
class CustomListDialogBuilders {
  /// Show edit list dialog.
  static Future<void> showEditListDialog(
    BuildContext context,
    CustomList customList,
    FavoritesService favoritesService,
    VoidCallback onListUpdated,
  ) async {
    final nameController = TextEditingController(text: customList.name);
    final descriptionController = TextEditingController(
      text: customList.description,
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit List'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'List Name',
                  hintText: 'Enter list name',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Enter list description',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final newName = nameController.text.trim();
      if (newName.isNotEmpty) {
        // Update the list.

        final updatedList = CustomList(
          id: customList.id,
          name: newName,
          description: descriptionController.text.trim(),
          movieIds: customList.movieIds,
          createdAt: customList.createdAt,
          updatedAt: DateTime.now(),
        );

        await favoritesService.updateCustomList(updatedList);
        onListUpdated();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('List "$newName" updated'),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
            ),
          );
        }
      }
    }
  }

  /// Show delete confirmation dialog.
  static Future<void> showDeleteConfirmation(
    BuildContext context,
    CustomList customList,
    FavoritesService favoritesService,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete List?'),
          content: Text(
            'Are you sure you want to delete "${customList.name}"?\n\n'
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      await favoritesService.deleteCustomList(customList.id);
      navigator.pop();

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('List "${customList.name}" deleted'),
        ),
      );
    }
  }

  /// Show list options bottom sheet.
  static Future<void> showListOptions(
    BuildContext context,
    CustomList customList, {
    required VoidCallback onEdit,
    required VoidCallback onShare,
    required VoidCallback onDelete,
  }) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit List'),
                onTap: () {
                  Navigator.of(context).pop();
                  onEdit();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share to POD'),
                onTap: () {
                  Navigator.of(context).pop();
                  onShare();
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Delete List',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onDelete();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  /// Show remove movie confirmation dialog.
  static Future<bool> showRemoveMovieDialog(
    BuildContext context,
    String movieTitle,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Movie?'),
          content: Text(
            'Remove "$movieTitle" from this list?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }
}
