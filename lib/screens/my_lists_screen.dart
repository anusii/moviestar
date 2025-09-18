/// Screen displaying all custom movie lists created by the user.
///
// Time-stamp: <Monday 2025-08-18 10:00:00 +1000 Ashley Tang>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
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
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/core/services/favorites/favorites_service.dart';
import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/screens/add_movies_to_list_screen.dart';
import 'package:moviestar/screens/custom_list_detail_screen.dart';
import 'package:moviestar/shared/widgets/lists/list_dialogs.dart';
import 'package:moviestar/shared/widgets/lists/list_item_card.dart';
import 'package:moviestar/shared/widgets/lists/list_sharing_handler.dart';
import 'package:moviestar/shared/widgets/lists/lists_empty_state.dart';
import 'package:moviestar/widgets/base_screen.dart';

/// A screen that displays all custom movie lists.

class MyListsScreen extends ConsumerStatefulWidget {
  /// Service for managing favorite movies and lists.

  final FavoritesService favoritesService;

  /// Creates a new [MyListsScreen] widget.

  const MyListsScreen({
    super.key,
    required this.favoritesService,
  });

  @override
  ConsumerState<MyListsScreen> createState() => _MyListsScreenState();
}

/// State class for the my lists screen.

class _MyListsScreenState extends ConsumerState<MyListsScreen>
    with ScreenStateMixin {
  List<CustomList> _customLists = [];
  late ListSharingHandler _sharingHandler;

  @override
  void initState() {
    super.initState();
    _sharingHandler = ListSharingHandler(
      context: context,
      widget: widget,
      ref: ref,
      favoritesService: widget.favoritesService,
      screenState: this,
    );
    setLoadingState(true);
    _loadCustomLists();

    widget.favoritesService.customLists.listen((lists) {
      safeSetState(() {
        _customLists = lists;
      });
      setLoadingState(false);
    });
  }

  Future<void> _loadCustomLists() async {
    final lists = await widget.favoritesService.getCustomLists();

    safeSetState(() {
      _customLists = lists;
    });
    setLoadingState(false);
  }

  void _showCreateListDialog() {
    ListDialogs.showCreateListDialog(
      context,
      widget.favoritesService,
      () {}, // No specific callback needed
    );
  }

  void _openListDetail(CustomList list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomListDetailScreen(
          customList: list,
          favoritesService: widget.favoritesService,
        ),
      ),
    );
  }

  void _openAddMoviesScreen(CustomList list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMoviesToListScreen(
          customList: list,
          favoritesService: widget.favoritesService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'My Lists',
      isLoading: isLoading,
      body: _customLists.isEmpty
          ? ListsEmptyState(onCreateList: _showCreateListDialog)
          : _buildListView(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateListDialog,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New List'),
        elevation: 4,
      ),
    );
  }

  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: _loadCustomLists,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _customLists.length,
        itemBuilder: (context, index) {
          final list = _customLists[index];
          return ListItemCard(
            list: list,
            favoritesService: widget.favoritesService,
            onTap: () => _openListDetail(list),
            onAddMovies: () => _openAddMoviesScreen(list),
            onShowOptions: () => _sharingHandler.showListOptions(
              list,
              () => ListDialogs.showEditListDialog(
                context,
                list,
                widget.favoritesService,
              ),
              () => ListDialogs.showDeleteConfirmation(
                context,
                list,
                widget.favoritesService,
              ),
            ),
          );
        },
      ),
    );
  }
}
