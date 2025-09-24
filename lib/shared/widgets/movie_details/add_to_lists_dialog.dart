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
import 'package:moviestar/shared/widgets/movie_details/add_to_lists_dialog/list_operations.dart';
import 'package:moviestar/shared/widgets/movie_details/add_to_lists_dialog/ui_builder.dart';

// Re-export helper classes for backward compatibility.

export 'package:moviestar/shared/widgets/movie_details/add_to_lists_dialog/list_operations.dart';
export 'package:moviestar/shared/widgets/movie_details/add_to_lists_dialog/ui_builder.dart';

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
    final selectedIds = await ListOperations.loadMovieListStatus(
      widget.favoritesService,
      widget.customLists,
      widget.movie,
    );
    setState(() {
      _selectedListIds.addAll(selectedIds);
    });
  }

  Future<void> _toggleMovieInList(String listId, bool add) async {
    setState(() {
      _isLoading = true;
    });

    await ListOperations.toggleMovieInList(
      context,
      widget.favoritesService,
      widget.movie,
      widget.contentType,
      listId,
      add,
      _selectedListIds,
    );

    setState(() {
      _isLoading = false;
    });
  }

  int _getUpdatedMovieCount(CustomList list) {
    return ListOperations.getUpdatedMovieCount(
      list,
      widget.movie,
      widget.customLists,
      _selectedListIds,
    );
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
            // Header.

            UiBuilder.buildHeader(context, widget.movie),

            // Lists content.

            Expanded(
              child: widget.customLists.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.customLists.length,
                      itemBuilder: (context, index) {
                        final list = widget.customLists[index];
                        final isSelected = _selectedListIds.contains(list.id);

                        return UiBuilder.buildListItem(
                          context,
                          list,
                          widget.movie,
                          isSelected,
                          _isLoading,
                          _getUpdatedMovieCount(list),
                          (value) =>
                              _toggleMovieInList(list.id, value ?? false),
                        );
                      },
                    )
                  : UiBuilder.buildEmptyListsState(context),
            ),

            // Create new list button.

            UiBuilder.buildCreateListButton(
              context,
              _isLoading,
              _showCreateNewListDialog,
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateNewListDialog() {
    UiBuilder.showCreateNewListDialog(
      context,
      _newListController,
      _createNewListAndAdd,
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
