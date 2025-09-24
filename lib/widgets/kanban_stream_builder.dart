/// Concurrent stream loading helper for Kanban board.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:rxdart/rxdart.dart';

import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';

/// Loading coordination data for kanban board.
class KanbanLoadingData {
  final bool isInitialLoading;
  final bool showSkeletonColumns;
  final int expectedCustomListCount;
  final int loadedCustomListCount;

  const KanbanLoadingData({
    required this.isInitialLoading,
    required this.showSkeletonColumns,
    required this.expectedCustomListCount,
    required this.loadedCustomListCount,
  });
}

/// Helper class for concurrent stream loading in kanban board.
class KanbanStreamBuilder extends StatelessWidget {
  final FavoritesService favoritesService;
  final dynamic recommendedCacheResult;
  final Widget Function(
    dynamic recommendedCacheResult,
    AsyncSnapshot<List<Movie>> toWatchSnapshot,
    AsyncSnapshot<List<Movie>> watchedSnapshot,
    AsyncSnapshot<List<CustomList>> customListsSnapshot,
    KanbanLoadingData loadingData,
  ) builder;

  const KanbanStreamBuilder({
    super.key,
    required this.favoritesService,
    required this.recommendedCacheResult,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    // Use concurrent stream loading instead of nested StreamBuilders.

    return StreamBuilder<List<dynamic>>(
      stream: Rx.combineLatest3(
        favoritesService.toWatchMovies,
        favoritesService.watchedMovies,
        favoritesService.customLists,
        (
          List<Movie> toWatch,
          List<Movie> watched,
          List<CustomList> customLists,
        ) =>
            [toWatch, watched, customLists],
      ),
      builder: (context, combinedSnapshot) {
        // Extract data with loading states.

        final toWatchMovies =
            combinedSnapshot.hasData && combinedSnapshot.data!.isNotEmpty
                ? combinedSnapshot.data![0] as List<Movie>
                : <Movie>[];
        final watchedMovies =
            combinedSnapshot.hasData && combinedSnapshot.data!.length > 1
                ? combinedSnapshot.data![1] as List<Movie>
                : <Movie>[];
        final customLists =
            combinedSnapshot.hasData && combinedSnapshot.data!.length > 2
                ? combinedSnapshot.data![2] as List<CustomList>
                : <CustomList>[];

        // Create snapshot objects for backward compatibility.
        // Use proper loading state detection - if connection is waiting and no data yet, mark as loading.

        final isInitialLoading =
            combinedSnapshot.connectionState == ConnectionState.waiting &&
                !combinedSnapshot.hasData;

        final toWatchSnapshot = isInitialLoading
            ? const AsyncSnapshot<List<Movie>>.waiting()
            : AsyncSnapshot<List<Movie>>.withData(
                combinedSnapshot.connectionState,
                toWatchMovies,
              );
        final watchedSnapshot = isInitialLoading
            ? const AsyncSnapshot<List<Movie>>.waiting()
            : AsyncSnapshot<List<Movie>>.withData(
                combinedSnapshot.connectionState,
                watchedMovies,
              );
        final customListsSnapshot = isInitialLoading
            ? const AsyncSnapshot<List<CustomList>>.waiting()
            : AsyncSnapshot<List<CustomList>>.withData(
                combinedSnapshot.connectionState,
                customLists,
              );

        // Create loading coordination data.
        // Show skeleton columns during initial loading or when custom lists are expected but not loaded.

        final expectedCustomListCount = customLists.length;
        final showSkeletonColumns =
            isInitialLoading && expectedCustomListCount == 0;

        final loadingData = KanbanLoadingData(
          isInitialLoading: isInitialLoading,
          showSkeletonColumns: showSkeletonColumns,
          expectedCustomListCount: expectedCustomListCount,
          loadedCustomListCount: expectedCustomListCount,
        );

        return builder(
          recommendedCacheResult,
          toWatchSnapshot,
          watchedSnapshot,
          customListsSnapshot,
          loadingData,
        );
      },
    );
  }
}
