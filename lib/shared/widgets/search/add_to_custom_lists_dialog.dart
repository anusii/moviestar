/// Dialog for adding movies/TV shows to custom lists from search results.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/constants/timing_constants.dart';
import 'package:moviestar/core/services/favorites/favorites_service.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';

/// Dialog for adding a movie to custom lists.
class AddToCustomListsDialog extends StatefulWidget {
  final Movie movie;
  final ContentItem originalContentItem;
  final FavoritesService favoritesService;
  final VoidCallback onListsUpdated;

  const AddToCustomListsDialog({
    super.key,
    required this.movie,
    required this.originalContentItem,
    required this.favoritesService,
    required this.onListsUpdated,
  });

  @override
  State<AddToCustomListsDialog> createState() => _AddToCustomListsDialogState();
}

class _AddToCustomListsDialogState extends State<AddToCustomListsDialog> {
  final TextEditingController _newListController = TextEditingController();
  final Set<String> _selectedListIds = {};
  List<CustomList> _customLists = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCustomLists();
  }

  @override
  void dispose() {
    _newListController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomLists() async {
    try {
      final lists = await widget.favoritesService.getCustomLists();
      setState(() {
        _customLists = lists;
      });
      await _loadMovieListStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading lists: $e')),
        );
      }
    }
  }

  Future<void> _loadMovieListStatus() async {
    for (final list in _customLists) {
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

  Future<void> _refreshCustomListCounts() async {
    try {
      final lists = await widget.favoritesService.getCustomLists();
      setState(() {
        _customLists = lists;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing lists: $e')),
        );
      }
    }
  }

  Future<void> _toggleMovieInList(String listId, bool add) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (add) {
        final contentType =
            widget.originalContentItem.contentType == ContentType.tvShow
                ? 'tv'
                : 'movie';
        await widget.favoritesService.addMovieToCustomList(
          listId,
          widget.movie,
          contentType: contentType,
        );
        _selectedListIds.add(listId);
      } else {
        await widget.favoritesService
            .removeMovieFromCustomList(listId, widget.movie.id);
        _selectedListIds.remove(listId);
      }

      await _refreshCustomListCounts();
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
            _buildHeader(context),
            _buildListsContent(context),
            _buildCreateNewListButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              backgroundColor:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListsContent(BuildContext context) {
    return Expanded(
      child: _customLists.isNotEmpty
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _customLists.length,
              itemBuilder: (context, index) {
                final list = _customLists[index];
                final isSelected = _selectedListIds.contains(list.id);
                return _buildListItem(context, list, isSelected);
              },
            )
          : _buildEmptyListsState(context),
    );
  }

  Widget _buildListItem(
      BuildContext context, CustomList list, bool isSelected,) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
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
              list.name.isNotEmpty ? list.name[0].toUpperCase() : 'L',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              '${list.movieCount} items',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        value: isSelected,
        activeColor: Theme.of(context).colorScheme.primary,
        onChanged: _isLoading
            ? null
            : (value) => _toggleMovieInList(list.id, value ?? false),
      ),
    );
  }

  Widget _buildEmptyListsState(BuildContext context) {
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
              'Create your first custom list to organize your movies and TV shows!',
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

  Widget _buildCreateNewListButton(BuildContext context) {
    return Container(
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
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
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

    Navigator.pop(context);

    setState(() {
      _isLoading = true;
    });

    try {
      final newList = await widget.favoritesService.createCustomList(name);
      final contentType =
          widget.originalContentItem.contentType == ContentType.tvShow
              ? 'tv'
              : 'movie';
      await widget.favoritesService.addMovieToCustomList(
        newList.id,
        widget.movie,
        contentType: contentType,
      );
      _selectedListIds.add(newList.id);
      _newListController.clear();
      widget.onListsUpdated();

      if (mounted) {
        Navigator.pop(context);
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
                    'Created "$name" and added "${widget.movie.title}"',
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
