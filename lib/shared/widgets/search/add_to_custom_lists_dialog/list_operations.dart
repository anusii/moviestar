/// List management operations for custom lists dialog.
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

/// Static helper class for custom list operations.
class ListOperations {
  /// Loads all custom lists from the favorites service.
  static Future<List<CustomList>> loadCustomLists(
    FavoritesService favoritesService,
  ) async {
    return await favoritesService.getCustomLists();
  }

  /// Loads the status of a movie in all custom lists.
  static Future<Set<String>> loadMovieListStatus(
    FavoritesService favoritesService,
    List<CustomList> customLists,
    int movieId,
  ) async {
    final selectedListIds = <String>{};

    for (final list in customLists) {
      final isInList = await favoritesService.isMovieInCustomList(
        list.id,
        movieId,
      );
      if (isInList) {
        selectedListIds.add(list.id);
      }
    }

    return selectedListIds;
  }

  /// Toggles a movie's membership in a custom list.
  static Future<void> toggleMovieInList(
    FavoritesService favoritesService,
    String listId,
    Movie movie,
    ContentItem originalContentItem,
    bool add,
  ) async {
    if (add) {
      final contentType =
          originalContentItem.contentType == ContentType.tvShow ? 'tv' : 'movie';
      await favoritesService.addMovieToCustomList(
        listId,
        movie,
        contentType: contentType,
      );
    } else {
      await favoritesService.removeMovieFromCustomList(listId, movie.id);
    }
  }

  /// Creates a new list and adds the movie to it.
  static Future<CustomList> createNewListAndAdd(
    FavoritesService favoritesService,
    String listName,
    Movie movie,
    ContentItem originalContentItem,
  ) async {
    final newList = await favoritesService.createCustomList(listName);
    final contentType =
        originalContentItem.contentType == ContentType.tvShow ? 'tv' : 'movie';
    await favoritesService.addMovieToCustomList(
      newList.id,
      movie,
      contentType: contentType,
    );
    return newList;
  }

  /// Shows error message via SnackBar.
  static void showErrorMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}