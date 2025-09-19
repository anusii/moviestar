/// UI builders for custom lists dialog components.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';

/// Static helper class for building UI components in custom lists dialog.
class UiBuilders {
  /// Builds the dialog header with movie title and close button.
  static Widget buildHeader(BuildContext context, Movie movie) {
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
                  movie.title,
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

  /// Builds the main content area with list of custom lists or empty state.
  static Widget buildListsContent(
    BuildContext context,
    List<CustomList> customLists,
    Set<String> selectedListIds,
    bool isLoading,
    Function(String, bool) onToggleList,
  ) {
    return Expanded(
      child: customLists.isNotEmpty
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: customLists.length,
              itemBuilder: (context, index) {
                final list = customLists[index];
                final isSelected = selectedListIds.contains(list.id);
                return buildListItem(
                  context,
                  list,
                  isSelected,
                  isLoading,
                  onToggleList,
                );
              },
            )
          : buildEmptyListsState(context),
    );
  }

  /// Builds a single list item with checkbox.
  static Widget buildListItem(
    BuildContext context,
    CustomList list,
    bool isSelected,
    bool isLoading,
    Function(String, bool) onToggleList,
  ) {
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
        onChanged: isLoading
            ? null
            : (value) => onToggleList(list.id, value ?? false),
      ),
    );
  }

  /// Builds the empty state when no custom lists exist.
  static Widget buildEmptyListsState(BuildContext context) {
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

  /// Builds the create new list button at the bottom.
  static Widget buildCreateNewListButton(
    BuildContext context,
    bool isLoading,
    VoidCallback onPressed,
  ) {
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
          onPressed: isLoading ? null : onPressed,
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
}