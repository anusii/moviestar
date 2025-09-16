/// Add to Custom Lists Dialog Component - Dialog for managing custom list membership
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
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/core/services/favorites/favorites_service.dart';

/// Dialog for adding a movie to custom lists
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
        // Determine content type based on the original ContentItem
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

      // Refresh the custom lists to update counts without losing selection state
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

  Future<void> _createNewList() async {
    final listName = _newListController.text.trim();
    if (listName.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newList = await widget.favoritesService.createCustomList(
        listName,
        description: '',
      );

      // Add the movie to the new list immediately
      final contentType = widget.originalContentItem.contentType == ContentType.tvShow
          ? 'tv'
          : 'movie';
      await widget.favoritesService.addMovieToCustomList(
        newList.id,
        widget.movie,
        contentType: contentType,
      );

      _selectedListIds.add(newList.id);
      _newListController.clear();

      // Reload all lists to show the new one
      await _loadCustomLists();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created list "$listName" and added movie')),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add to Lists',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const Gap(Gaps.s),
                        Text(
                          widget.movie.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            // Create new list section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create New List',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Gap(Gaps.m),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newListController,
                          decoration: InputDecoration(
                            hintText: 'List name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: (_) => _createNewList(),
                        ),
                      ),
                      const Gap(Gaps.m),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _createNewList,
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Existing lists
            Expanded(
              child: _customLists.isEmpty
                  ? const Center(
                      child: Text('No custom lists yet'),
                    )
                  : ListView.builder(
                      itemCount: _customLists.length,
                      itemBuilder: (context, index) {
                        final list = _customLists[index];
                        final isSelected = _selectedListIds.contains(list.id);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: _isLoading
                              ? null
                              : (bool? value) {
                                  _toggleMovieInList(list.id, value ?? false);
                                },
                          title: Text(
                            list.name,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${list.movieCount} movies',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.trailing,
                        );
                      },
                    ),
            ),

            // Loading indicator
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: LinearProgressIndicator(),
              ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Gap(Gaps.m),
                  ElevatedButton(
                    onPressed: () {
                      widget.onListsUpdated();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}