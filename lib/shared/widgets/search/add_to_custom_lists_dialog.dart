/// Dialog for adding movies/TV shows to custom lists from search results.
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
import 'package:moviestar/shared/widgets/search/add_to_custom_lists_dialog/dialog_helpers.dart';
import 'package:moviestar/shared/widgets/search/add_to_custom_lists_dialog/list_operations.dart';
import 'package:moviestar/shared/widgets/search/add_to_custom_lists_dialog/ui_builders.dart';

// Re-export helper classes for backward compatibility
export 'package:moviestar/shared/widgets/search/add_to_custom_lists_dialog/dialog_helpers.dart';
export 'package:moviestar/shared/widgets/search/add_to_custom_lists_dialog/list_operations.dart';
export 'package:moviestar/shared/widgets/search/add_to_custom_lists_dialog/ui_builders.dart';

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
      final lists = await ListOperations.loadCustomLists(widget.favoritesService);
      setState(() {
        _customLists = lists;
      });
      await _loadMovieListStatus();
    } catch (e) {
      if (mounted) {
        ListOperations.showErrorMessage(context, 'Error loading lists: $e');
      }
    }
  }

  Future<void> _loadMovieListStatus() async {
    final selectedIds = await ListOperations.loadMovieListStatus(
      widget.favoritesService,
      _customLists,
      widget.movie.id,
    );
    setState(() {
      _selectedListIds.clear();
      _selectedListIds.addAll(selectedIds);
    });
  }

  Future<void> _refreshCustomListCounts() async {
    try {
      final lists = await ListOperations.loadCustomLists(widget.favoritesService);
      setState(() {
        _customLists = lists;
      });
    } catch (e) {
      if (mounted) {
        ListOperations.showErrorMessage(context, 'Error refreshing lists: $e');
      }
    }
  }

  Future<void> _toggleMovieInList(String listId, bool add) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ListOperations.toggleMovieInList(
        widget.favoritesService,
        listId,
        widget.movie,
        widget.originalContentItem,
        add,
      );

      if (add) {
        _selectedListIds.add(listId);
      } else {
        _selectedListIds.remove(listId);
      }

      await _refreshCustomListCounts();
    } catch (e) {
      if (mounted) {
        ListOperations.showErrorMessage(context, 'Error updating list: $e');
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
            UiBuilders.buildHeader(context, widget.movie),
            UiBuilders.buildListsContent(
              context,
              _customLists,
              _selectedListIds,
              _isLoading,
              _toggleMovieInList,
            ),
            UiBuilders.buildCreateNewListButton(
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
    DialogHelpers.showCreateNewListDialog(
      context,
      _newListController,
      _createNewListAndAdd,
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
      final newList = await ListOperations.createNewListAndAdd(
        widget.favoritesService,
        name,
        widget.movie,
        widget.originalContentItem,
      );

      _selectedListIds.add(newList.id);
      _newListController.clear();
      widget.onListsUpdated();

      if (mounted) {
        Navigator.pop(context);
        DialogHelpers.showSuccessMessage(context, name, widget.movie);
      }
    } catch (e) {
      if (mounted) {
        ListOperations.showErrorMessage(context, 'Error creating list: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
