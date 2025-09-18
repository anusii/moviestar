/// Kanban List Operations - Custom List Management.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/core/services/favorites/favorites_service.dart';
import 'package:moviestar/core/services/favorites/favorites_service_adapter.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/utils/movie_sort_util.dart';
import 'package:moviestar/widgets/sort_controls.dart';

/// Widget that loads and displays movies from a custom list with optimistic updates.
class CustomListMoviesWidget extends ConsumerStatefulWidget {
  final List<int> movieIds;
  final CustomList customList;
  final FavoritesService favoritesService;
  final MovieSortCriteria sortCriteria;
  final int maxItems;
  final Widget Function(Movie movie, int index) buildMovieItem;
  final Map<String, Movie> optimisticMovies;

  const CustomListMoviesWidget({
    super.key,
    required this.movieIds,
    required this.customList,
    required this.favoritesService,
    required this.sortCriteria,
    required this.maxItems,
    required this.buildMovieItem,
    required this.optimisticMovies,
  });

  @override
  ConsumerState<CustomListMoviesWidget> createState() =>
      _CustomListMoviesWidgetState();
}

class _CustomListMoviesWidgetState
    extends ConsumerState<CustomListMoviesWidget> {
  final Map<int, Movie> _moviesMap = {};
  final Set<int> _loadingMovieIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  @override
  void didUpdateWidget(CustomListMoviesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if we need to load new movies (only load missing ones, don't reload all)
    final newMovieIds = widget.movieIds
        .where(
          (id) =>
              !oldWidget.movieIds.contains(id) &&
              !_moviesMap.containsKey(id) &&
              !widget.optimisticMovies
                  .containsKey('${id}_customList_${widget.customList.id}'),
        )
        .toList();

    // If sort criteria changed, reload all
    if (oldWidget.sortCriteria != widget.sortCriteria) {
      _loadMovies();
    }
    // If we have new movie IDs from optimistic updates, load only those
    else if (newMovieIds.isNotEmpty) {
      _loadNewMovies(newMovieIds);
    }
    // If movies were removed or optimistic movies changed, just update the UI
    else if (oldWidget.movieIds.length != widget.movieIds.length ||
        oldWidget.optimisticMovies != widget.optimisticMovies) {
      setState(() {}); // Trigger rebuild with current data
    }
  }

  /// Get content as movie with proper type handling.
  Future<Movie> _getContentAsMovieWithType(
    int contentId,
    String contentType,
  ) async {
    final cachedMovieService = ref.read(cachedMovieServiceProvider);
    final contentService = ref.read(contentServiceProvider);

    if (contentType == 'tv') {
      final tvShowContent = await contentService.getTVDetails(contentId);
      return Movie.fromContentItem(tvShowContent);
    } else {
      return await cachedMovieService.getMovieDetails(contentId);
    }
  }

  /// Load only specific new movies (for optimistic updates).
  Future<void> _loadNewMovies(List<int> movieIds) async {
    for (final movieId in movieIds) {
      if (_moviesMap.containsKey(movieId) ||
          _loadingMovieIds.contains(movieId)) {
        continue;
      }

      _loadingMovieIds.add(movieId);
      try {
        final contentType = widget.customList.getContentTypeAt(
          widget.movieIds.indexOf(movieId),
        );
        final movie = await _getContentAsMovieWithType(movieId, contentType);
        if (mounted) {
          setState(() {
            _moviesMap[movieId] = movie;
            _loadingMovieIds.remove(movieId);
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _loadingMovieIds.remove(movieId);
          });
        }
      }
    }
  }

  /// Load all movies for the custom list.
  Future<void> _loadMovies() async {
    setState(() {
      _isLoading = true;
    });

    // Try POD-first approach if POD storage is available
    if (widget.favoritesService is FavoritesServiceAdapter &&
        (widget.favoritesService as FavoritesServiceAdapter)
            .isPodStorageEnabled) {
      try {
        final podMovies = await widget.favoritesService
            .getMoviesInCustomList(widget.customList.id);

        if (podMovies.isNotEmpty) {
          if (mounted) {
            setState(() {
              _moviesMap.clear();
              for (final movie in podMovies) {
                _moviesMap[movie.id] = movie;
              }
              _isLoading = false;
            });
          }
          return;
        }
      } catch (e) {
        // Continue to fallback to API loading
      }
    }

    // Fallback to API loading (original method)
    await _loadMoviesFromAPI();
  }

  /// Original API loading method.
  Future<void> _loadMoviesFromAPI() async {
    // Load all movies needed for sorting
    final moviesToLoad = widget.movieIds.take(widget.maxItems * 2).toList();

    for (int i = 0; i < moviesToLoad.length; i++) {
      final movieId = moviesToLoad[i];

      if (_moviesMap.containsKey(movieId) ||
          _loadingMovieIds.contains(movieId)) {
        continue;
      }

      _loadingMovieIds.add(movieId);

      try {
        final contentType = widget.customList.getContentTypeAt(
          widget.movieIds.indexOf(movieId),
        );
        final movie = await _getContentAsMovieWithType(movieId, contentType);

        if (mounted) {
          setState(() {
            _moviesMap[movieId] = movie;
            _loadingMovieIds.remove(movieId);
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _loadingMovieIds.remove(movieId);
          });
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Get sorted movies with optimistic updates applied.
  List<Movie> _getSortedMovies() {
    // Get all loaded movies
    final loadedMovies = <Movie>[];
    for (final movieId in widget.movieIds) {
      Movie? movie = _moviesMap[movieId];

      // If not found in loaded movies, check optimistic movies
      if (movie == null) {
        final optimisticKey = '${movieId}_customList_${widget.customList.id}';
        movie = widget.optimisticMovies[optimisticKey];
      }

      if (movie != null) {
        loadedMovies.add(movie);
      }
    }

    // Apply sorting
    return sortMovies(loadedMovies, widget.sortCriteria);
  }

  @override
  Widget build(BuildContext context) {
    final sortedMovies = _getSortedMovies();

    // Only show loading if we have no movies at all (including optimistic ones)
    if (_isLoading && _moviesMap.isEmpty && sortedMovies.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(Dimensions.xl),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final displayMovies = sortedMovies.take(widget.maxItems).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: displayMovies.length,
      itemBuilder: (context, index) {
        return widget.buildMovieItem(displayMovies[index], index);
      },
    );
  }
}

/// Operations for managing movie lists in the kanban board.
class KanbanListOperations {
  /// Create a movie item builder function that uses the provided parameters.
  static Widget Function(Movie, int) createMovieItemBuilder({
    required String categoryId,
    required bool fromCache,
    required KanbanColumnType columnType,
    required String columnId,
    required String columnName,
    required Widget Function(
      Movie movie,
      String category, {
      required bool fromCache,
      required KanbanColumnType columnType,
      required String columnId,
      required String columnName,
    }) buildMovieItem,
  }) {
    return (Movie movie, int index) => buildMovieItem(
          movie,
          categoryId,
          fromCache: fromCache,
          columnType: columnType,
          columnId: columnId,
          columnName: columnName,
        );
  }

  /// Check if a movie exists in the given list of movies.
  static bool movieExistsInList(List<Movie> movies, int movieId) {
    return movies.any((movie) => movie.id == movieId);
  }

  /// Filter movies by content type.
  static List<Movie> filterMoviesByContentType(
    List<Movie> movies,
    ContentType? contentType,
  ) {
    if (contentType == null) return movies;
    return movies.where((movie) => movie.contentType == contentType).toList();
  }

  /// Get movies that are not in the given list (for filtering duplicates).
  static List<Movie> getMoviesNotInList(
    List<Movie> sourceMovies,
    List<Movie> excludeMovies,
  ) {
    final excludeIds = excludeMovies.map((m) => m.id).toSet();
    return sourceMovies
        .where((movie) => !excludeIds.contains(movie.id))
        .toList();
  }

  /// Merge two movie lists removing duplicates.
  static List<Movie> mergeMovieListsNoDuplicates(
    List<Movie> list1,
    List<Movie> list2,
  ) {
    final combined = <Movie>[];
    final seenIds = <int>{};

    for (final movie in list1) {
      if (!seenIds.contains(movie.id)) {
        combined.add(movie);
        seenIds.add(movie.id);
      }
    }

    for (final movie in list2) {
      if (!seenIds.contains(movie.id)) {
        combined.add(movie);
        seenIds.add(movie.id);
      }
    }

    return combined;
  }

  /// Batch load movie details from IDs.
  static Future<List<Movie>> batchLoadMovieDetails({
    required List<int> movieIds,
    required CustomList customList,
    required WidgetRef ref,
    int? maxCount,
  }) async {
    final cachedMovieService = ref.read(cachedMovieServiceProvider);
    final contentService = ref.read(contentServiceProvider);
    final movies = <Movie>[];

    final idsToLoad =
        maxCount != null ? movieIds.take(maxCount).toList() : movieIds;

    for (int i = 0; i < idsToLoad.length; i++) {
      final movieId = idsToLoad[i];
      try {
        final contentType = customList.getContentTypeAt(
          movieIds.indexOf(movieId),
        );

        Movie movie;
        if (contentType == 'tv') {
          final tvShowContent = await contentService.getTVDetails(movieId);
          movie = Movie.fromContentItem(tvShowContent);
        } else {
          movie = await cachedMovieService.getMovieDetails(movieId);
        }

        movies.add(movie);
      } catch (e) {
        debugPrint('Failed to load movie $movieId: $e');
        // Continue loading other movies even if one fails
      }
    }

    return movies;
  }
}

/// Enum for different column types in the kanban board (re-export for convenience).
enum KanbanColumnType {
  popular,
  toWatch,
  watched,
  customList,
}
