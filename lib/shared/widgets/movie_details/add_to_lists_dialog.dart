/// Add to Lists Dialog for Movie Details Screen.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';

/// Dialog for adding a movie to custom lists.
class AddToListsDialog extends StatefulWidget {
  final Movie movie;
  final FavoritesService favoritesService;
  final List<CustomList> customLists;
  final VoidCallback onListsUpdated;
  final ContentType contentType;

  const AddToListsDialog({
    super.key,
    required this.movie,
    required this.favoritesService,
    required this.customLists,
    required this.onListsUpdated,
    required this.contentType,
  });

  @override
  State<AddToListsDialog> createState() => _AddToListsDialogState();
}

class _AddToListsDialogState extends State<AddToListsDialog> {
  final TextEditingController _newListController = TextEditingController();
  final Set<String> _selectedListIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMovieListStatus();
  }

  @override
  void dispose() {
    _newListController.dispose();
    super.dispose();
  }

  Future<void> _loadMovieListStatus() async {
    for (final list in widget.customLists) {
      final isInList = await widget.favoritesService.isMovieInCustomList(
        list.id,
        widget.movie.id,
      );
      if (isInList) {
        _selectedListIds.add(list.id);
      }
    }
    setState(() {});
  }

  Future<void> _toggleMovieInList(String listId, bool add) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (add) {
        await widget.favoritesService.addMovieToCustomList(
          listId,
          widget.movie,
          contentType:
              widget.contentType == ContentType.tvShow ? 'tv' : 'movie',
        );
        _selectedListIds.add(listId);
      } else {
        await widget.favoritesService
            .removeMovieFromCustomList(listId, widget.movie.id);
        _selectedListIds.remove(listId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating list: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Calculate the updated movie count for a list, accounting for current selections.
  int _getUpdatedMovieCount(CustomList list) {
    final isCurrentlySelected = _selectedListIds.contains(list.id);
    final wasOriginallyInList = widget.customLists
        .firstWhere((l) => l.id == list.id)
        .movieIds
        .contains(widget.movie.id);

    // If the movie was originally in the list and is now deselected, subtract 1.
    if (wasOriginallyInList && !isCurrentlySelected) {
      return list.movieCount - 1;
    }
    // If the movie was not originally in the list but is now selected, add 1.
    else if (!wasOriginallyInList && isCurrentlySelected) {
      return list.movieCount + 1;
    }
    // Otherwise, return the original count.
    else {
      return list.movieCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.playlist_add,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add to Lists',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          widget.movie.title,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Lists content
            Expanded(
              child: widget.customLists.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.customLists.length,
                      itemBuilder: (context, index) {
                        final list = widget.customLists[index];
                        final isSelected = _selectedListIds.contains(list.id);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.2),
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.1)
                                : null,
                          ),
                          child: CheckboxListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            secondary: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  list.name.isNotEmpty
                                      ? list.name[0].toUpperCase()
                                      : 'L',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              list.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Icon(
                                  Icons.movie,
                                  size: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_getUpdatedMovieCount(list)} movies/tv shows',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            value: isSelected,
                            activeColor: Theme.of(context).colorScheme.primary,
                            onChanged: _isLoading
                                ? null
                                : (value) =>
                                    _toggleMovieInList(list.id, value ?? false),
                          ),
                        );
                      },
                    )
                  : _buildEmptyListsState(),
            ),

            // Create new list button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _showCreateNewListDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create New List'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyListsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_add_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No Custom Lists Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first custom list to organize your movies!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateNewListDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New List'),
        content: TextField(
          controller: _newListController,
          decoration: const InputDecoration(
            labelText: 'List Name',
            hintText: 'Enter a unique name for your list...',
            border: OutlineInputBorder(),
            helperText: 'Tip: Use unique names to avoid duplicates',
            helperMaxLines: 2,
          ),
          autofocus: true,
          onSubmitted: (_) => _createNewListAndAdd(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _createNewListAndAdd,
            child: const Text('Create & Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewListAndAdd() async {
    final name = _newListController.text.trim();
    if (name.isEmpty) return;

    Navigator.pop(context); // Close create dialog

    setState(() {
      _isLoading = true;
    });

    try {
      final newList = await widget.favoritesService.createCustomList(name);
      await widget.favoritesService.addMovieToCustomList(
        newList.id,
        widget.movie,
        contentType: (widget.movie.contentType ?? widget.contentType) ==
                ContentType.tvShow
            ? 'tv'
            : 'movie',
      );
      _selectedListIds.add(newList.id);
      _newListController.clear();
      widget.onListsUpdated();

      if (mounted) {
        Navigator.pop(context); // Close main dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created "$name" and added "${widget.movie.title}"'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating list: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
