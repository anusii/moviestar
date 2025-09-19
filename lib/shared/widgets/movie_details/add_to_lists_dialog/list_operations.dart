/// List operations for add to lists dialog.
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

/// Static helper class for list operations.
class ListOperations {
  /// Load which lists the movie is currently in.
  static Future<Set<String>> loadMovieListStatus(
    FavoritesService favoritesService,
    List<CustomList> customLists,
    Movie movie,
  ) async {
    final selectedListIds = <String>{};
    for (final list in customLists) {
      final isInList = await favoritesService.isMovieInCustomList(
        list.id,
        movie.id,
      );
      if (isInList) {
        selectedListIds.add(list.id);
      }
    }
    return selectedListIds;
  }

  /// Toggle a movie in a custom list (add or remove).
  static Future<void> toggleMovieInList(
    BuildContext context,
    FavoritesService favoritesService,
    Movie movie,
    ContentType contentType,
    String listId,
    bool add,
    Set<String> selectedListIds,
  ) async {
    try {
      if (add) {
        await favoritesService.addMovieToCustomList(
          listId,
          movie,
          contentType: contentType == ContentType.tvShow ? 'tv' : 'movie',
        );
        selectedListIds.add(listId);
      } else {
        await favoritesService.removeMovieFromCustomList(listId, movie.id);
        selectedListIds.remove(listId);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating list: $e')),
        );
      }
    }
  }

  /// Calculate the updated movie count for a list, accounting for current selections.
  static int getUpdatedMovieCount(
    CustomList list,
    Movie movie,
    List<CustomList> originalCustomLists,
    Set<String> selectedListIds,
  ) {
    final isCurrentlySelected = selectedListIds.contains(list.id);
    final wasOriginallyInList = originalCustomLists
        .firstWhere((l) => l.id == list.id)
        .movieIds
        .contains(movie.id);

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
}
