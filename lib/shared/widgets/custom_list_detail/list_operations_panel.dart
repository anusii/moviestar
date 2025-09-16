/// List Operations Panel Component - Edit, Delete, and Manage Custom List Operations
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/core/services/favorites/favorites_service.dart';
import 'package:moviestar/core/services/favorites/favorites_service_adapter.dart';

class ListOperationsPanel extends ConsumerWidget {
  final CustomList customList;
  final FavoritesService favoritesService;
  final Function(CustomList updatedList) onListUpdated;
  final Function(String message) onShowSuccessMessage;
  final VoidCallback onListDeleted;

  const ListOperationsPanel({
    super.key,
    required this.customList,
    required this.favoritesService,
    required this.onListUpdated,
    required this.onShowSuccessMessage,
    required this.onListDeleted,
  });

  Future<void> _showEditListDialog(BuildContext context) async {
    final nameController = TextEditingController(text: customList.name);
    final descriptionController = TextEditingController(text: customList.description ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'List Name',
                border: OutlineInputBorder(),
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final description = descriptionController.text.trim();
                final updatedList = customList.copyWith(
                  name: name,
                  description: description.isEmpty ? null : description,
                  updatedAt: DateTime.now(),
                );

                await favoritesService.updateCustomList(updatedList);

                if (context.mounted) {
                  Navigator.pop(context);
                  onListUpdated(updatedList);
                  onShowSuccessMessage('Updated "$name" list');
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: Text(
          'Are you sure you want to delete "${customList.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await favoritesService.deleteCustomList(customList.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                onListDeleted();
                onShowSuccessMessage('Deleted "${customList.name}" list');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showListOptions(BuildContext context) async {
    final hasMovies = customList.movieIds.isNotEmpty;
    final isPodEnabled = favoritesService is FavoritesServiceAdapter &&
        (favoritesService as FavoritesServiceAdapter).isPodStorageEnabled;

    await showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit List'),
            onTap: () {
              Navigator.pop(context);
              _showEditListDialog(context);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.share,
              color: (hasMovies && isPodEnabled)
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.38),
            ),
            title: Text(
              'Share List',
              style: TextStyle(
                color: (hasMovies && isPodEnabled)
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.38),
              ),
            ),
            subtitle: (hasMovies && isPodEnabled)
                ? null
                : Text(
                    hasMovies
                        ? 'POD storage required'
                        : 'Add movies to share',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
            onTap: (hasMovies && isPodEnabled)
                ? () {
                    Navigator.pop(context);
                    // Share functionality will be handled by parent
                  }
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text(
              'Delete List',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(); // This component provides dialogs and sheets, no persistent UI
  }

  // Public method to show options modal
  void showOptions(BuildContext context) {
    _showListOptions(context);
  }

  // Public method to show edit dialog
  void showEditDialog(BuildContext context) {
    _showEditListDialog(context);
  }
}