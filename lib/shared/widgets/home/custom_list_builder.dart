/// Custom List Builder for Home Screen.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:moviestar/core/services/api/content_service.dart';
import 'package:moviestar/core/services/cache/cached_movie_service.dart';
import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/core/services/favorites/service_adapter.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/screens/custom_list_detail_screen.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/widgets/movie_card.dart';

/// A widget that builds custom list sections for the home screen.
/// This component handles both grid view (horizontal scroll) and list view layouts.
class HomeCustomListBuilder extends ConsumerWidget {
  /// Service for managing favorite movies.
  final FavoritesService favoritesService;

  /// Parent widget for navigation context.
  final StatefulWidget parentWidget;

  /// Callback for safe navigation.
  final void Function(Route<dynamic> route) onNavigate;

  /// Map of scroll controllers for each custom list.
  final Map<String, ScrollController> scrollControllers;

  /// Whether to show as list sections (for list view) or movie rows (for grid view).
  final bool showAsListSections;

  /// Creates a new [HomeCustomListBuilder] widget.
  const HomeCustomListBuilder({
    super.key,
    required this.favoritesService,
    required this.parentWidget,
    required this.onNavigate,
    required this.scrollControllers,
    this.showAsListSections = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (showAsListSections) {
      return _buildCustomListListSections(context, ref);
    } else {
      return _buildCustomListRows(context, ref);
    }
  }

  /// Builds custom list rows for grid view.
  Widget _buildCustomListRows(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<CustomList>>(
      stream: favoritesService.customLists,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading Custom Lists...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        final customLists = snapshot.data ?? [];
        if (customLists.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: customLists.map((customList) {
            return _buildCustomListMovieRow(context, ref, customList);
          }).toList(),
        );
      },
    );
  }

  /// Builds a horizontal scrollable row for a custom list.
  Widget _buildCustomListMovieRow(
    BuildContext context,
    WidgetRef ref,
    CustomList customList,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToCustomListDetail(customList),
                  child: Text(
                    customList.name,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${customList.movieCount}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              const Gap(8),
              if (customList.movieCount > 5)
                TextButton(
                  onPressed: () => _navigateToCustomListDetail(customList),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View More',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: _buildCustomListContent(context, ref, customList),
        ),
      ],
    );
  }

  /// Builds content for a custom list.
  Widget _buildCustomListContent(
    BuildContext context,
    WidgetRef ref,
    CustomList customList,
  ) {
    final movieIds = customList.movieIds;

    if (favoritesService is FavoritesServiceAdapter) {
      final adapter = favoritesService as FavoritesServiceAdapter;

      if (adapter.isPodStorageEnabled) {
        return FutureBuilder<List<Movie>>(
          future: favoritesService.getMoviesInCustomList(customList.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {}

            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final podMovies = snapshot.data!;
              return _buildMovieCardsFromMovieObjects(
                context,
                ref,
                podMovies,
                customList,
              );
            } else {
              return _buildMovieCardsFromIds(
                context,
                ref,
                movieIds,
                customList,
              );
            }
          },
        );
      }
    }

    if (movieIds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'No movies in ${customList.name} yet',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return _buildMovieCardsFromIds(context, ref, movieIds, customList);
  }

  /// Builds movie cards from movie objects (when we have full data from PODs).
  Widget _buildMovieCardsFromMovieObjects(
    BuildContext context,
    WidgetRef ref,
    List<Movie> movies,
    CustomList customList,
  ) {
    return Scrollbar(
      controller: scrollControllers[customList.id] ?? ScrollController(),
      thickness: 6,
      radius: const Radius.circular(3),
      thumbVisibility: true,
      child: ListView.builder(
        controller: scrollControllers[customList.id],
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildCustomListMovieCardFromMovie(context, ref, movie),
          );
        },
      ),
    );
  }

  /// Builds movie cards from IDs (fallback when POD data not available).
  Widget _buildMovieCardsFromIds(
    BuildContext context,
    WidgetRef ref,
    List<int> movieIds,
    CustomList customList,
  ) {
    return Scrollbar(
      controller: scrollControllers[customList.id] ?? ScrollController(),
      thickness: 6,
      radius: const Radius.circular(3),
      thumbVisibility: true,
      child: ListView.builder(
        controller: scrollControllers[customList.id],
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: movieIds.length,
        itemBuilder: (context, index) {
          final movieId = movieIds[index];
          final contentType = customList.getContentTypeAt(index);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildCustomListMovieCard(
              context,
              ref,
              movieId,
              contentType: contentType,
            ),
          );
        },
      ),
    );
  }

  /// Builds a movie card directly from a Movie object using consistent MovieCard styling.
  Widget _buildCustomListMovieCardFromMovie(
    BuildContext context,
    WidgetRef ref,
    Movie movie,
  ) {
    return MovieCard.poster(
      movie: movie,
      fromCache: true,
      favoritesService: favoritesService,
      parentWidget: parentWidget,
      onTap: () {
        onNavigate(
          MaterialPageRoute(
            builder: (context) => MovieDetailsScreen(
              movie: movie,
              favoritesService: favoritesService,
              contentType: movie.contentType ?? ContentType.movie,
            ),
          ),
        );
      },
    );
  }

  /// Builds a movie card for a custom list movie (loading movie details on demand).
  Widget _buildCustomListMovieCard(
    BuildContext context,
    WidgetRef ref,
    int movieId, {
    String contentType = 'movie',
  }) {
    final cachedMovieService = ref.read(cachedMovieServiceProvider);
    final contentService = ref.read(contentServiceProvider);

    return FutureBuilder<Movie>(
      future: _getContentAsMovieWithType(
        movieId,
        contentType,
        cachedMovieService,
        contentService,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            width: 100,
            height: 150,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const Gap(8),
                Text(
                  'Error',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return Container(
            width: 100,
            height: 150,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const Gap(8),
                Text(
                  'Loading...',
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        final movie = snapshot.data!;
        return MovieCard.poster(
          movie: movie,
          fromCache: false,
          favoritesService: favoritesService,
          parentWidget: parentWidget,
          onTap: () {
            onNavigate(
              MaterialPageRoute(
                builder: (context) => MovieDetailsScreen(
                  movie: movie,
                  favoritesService: favoritesService,
                  contentType: movie.contentType ?? ContentType.movie,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Builds custom list sections for list view.
  Widget _buildCustomListListSections(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<CustomList>>(
      stream: favoritesService.customLists,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading Custom Lists...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        final customLists = snapshot.data ?? [];
        if (customLists.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: customLists.map((customList) {
            return _buildCustomListSection(context, ref, customList);
          }).toList(),
        );
      },
    );
  }

  /// Builds a list section for a custom list.
  Widget _buildCustomListSection(
    BuildContext context,
    WidgetRef ref,
    CustomList customList,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _navigateToCustomListDetail(customList),
                  child: Text(
                    customList.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              if (customList.movieCount > 5)
                TextButton(
                  onPressed: () => _navigateToCustomListDetail(customList),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View More',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
        _buildCustomListItems(context, ref, customList),
        const Gap(16),
      ],
    );
  }

  /// Builds list items for a custom list.
  Widget _buildCustomListItems(
    BuildContext context,
    WidgetRef ref,
    CustomList customList,
  ) {
    final movieIds = customList.movieIds;

    if (movieIds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('No movies in ${customList.name}'),
      );
    }

    if (favoritesService is FavoritesServiceAdapter) {
      final adapter = favoritesService as FavoritesServiceAdapter;

      if (adapter.isPodStorageEnabled) {
        return FutureBuilder<List<Movie>>(
          future: favoritesService.getMoviesInCustomList(customList.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {}

            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final podMovies = snapshot.data!;
              return _buildCustomListItemsFromMovieObjects(
                context,
                ref,
                podMovies,
              );
            } else {
              return _buildCustomListItemsFromIds(
                context,
                ref,
                movieIds,
                customList,
              );
            }
          },
        );
      }
    }

    return _buildCustomListItemsFromIds(context, ref, movieIds, customList);
  }

  /// Builds list items from movie objects (when we have full data from PODs).
  Widget _buildCustomListItemsFromMovieObjects(
    BuildContext context,
    WidgetRef ref,
    List<Movie> movies,
  ) {
    final displayMovies = movies.take(5).toList();

    return Column(
      children: displayMovies.map((movie) {
        return _buildCustomListMovieListItemFromMovie(context, ref, movie);
      }).toList(),
    );
  }

  /// Builds list items from IDs (fallback when POD data not available).
  Widget _buildCustomListItemsFromIds(
    BuildContext context,
    WidgetRef ref,
    List<int> movieIds,
    CustomList customList,
  ) {
    final displayMovieIds = movieIds.take(5).toList();

    return Column(
      children: displayMovieIds.asMap().entries.map((entry) {
        final index = entry.key;
        final movieId = entry.value;
        final contentType = customList.getContentTypeAt(index);
        return _buildCustomListMovieListItem(
          context,
          ref,
          movieId,
          contentType: contentType,
        );
      }).toList(),
    );
  }

  /// Builds a list item directly from a Movie object using consistent MovieCard styling.
  Widget _buildCustomListMovieListItemFromMovie(
    BuildContext context,
    WidgetRef ref,
    Movie movie,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: MovieCard.listItem(
        movie: movie,
        fromCache: true,
        favoritesService: favoritesService,
        parentWidget: parentWidget,
        onTap: () {
          onNavigate(
            MaterialPageRoute(
              builder: (context) => MovieDetailsScreen(
                movie: movie,
                favoritesService: favoritesService,
                contentType: movie.contentType ?? ContentType.movie,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds a list item for a custom list movie.
  Widget _buildCustomListMovieListItem(
    BuildContext context,
    WidgetRef ref,
    int movieId, {
    String contentType = 'movie',
  }) {
    final cachedMovieService = ref.read(cachedMovieServiceProvider);
    final contentService = ref.read(contentServiceProvider);

    return FutureBuilder<Movie>(
      future: _getContentAsMovieWithType(
        movieId,
        contentType,
        cachedMovieService,
        contentService,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const Gap(16),
                  Expanded(
                    child: Text(
                      'Error loading movie',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Text(
                      'Loading movie...',
                      style: TextStyle(
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final movie = snapshot.data!;
        return MovieCard.listItem(
          movie: movie,
          fromCache: false,
          favoritesService: favoritesService,
          parentWidget: parentWidget,
          onTap: () {
            onNavigate(
              MaterialPageRoute(
                builder: (context) => MovieDetailsScreen(
                  movie: movie,
                  favoritesService: favoritesService,
                  contentType: movie.contentType ?? ContentType.movie,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Helper method to get content as Movie based on known content type.
  Future<Movie> _getContentAsMovieWithType(
    int contentId,
    String contentType,
    CachedMovieService cachedMovieService,
    ContentService contentService,
  ) async {
    if (contentType == 'tv') {
      final tvShowContent = await contentService.getTVDetails(contentId);
      return Movie.fromContentItem(tvShowContent);
    } else {
      return await cachedMovieService.getMovieDetails(contentId);
    }
  }

  /// Navigate to custom list detail screen.
  void _navigateToCustomListDetail(CustomList customList) {
    onNavigate(
      MaterialPageRoute(
        builder: (context) => CustomListDetailScreen(
          customList: customList,
          favoritesService: favoritesService,
        ),
      ),
    );
  }
}
