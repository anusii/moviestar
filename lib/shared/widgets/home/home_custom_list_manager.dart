/// HomeScreen Custom List Manager Service - Custom list functionality and POD integration
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

import 'package:moviestar/core/services/cache/hive_movie_cache_service.dart';
import 'package:moviestar/core/services/favorites/favorites_service.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/screens/movie_category_screen.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/widgets/movie_card.dart';

/// Service class that handles custom list management, POD integration, and movie rendering
class HomeCustomListManager {
  final FavoritesService favoritesService;
  final Map<String, ScrollController> scrollControllers;
  final bool Function() isMounted;
  final void Function(Route<dynamic>) safeNavigateTo;
  final Widget Function(WidgetRef, Object, StackTrace, String, VoidCallback)
      buildSmartErrorWidgetCompact;
  final Widget Function(WidgetRef, Object, StackTrace, String, VoidCallback)
      buildSmartErrorWidgetCompactWithRetry;
  final Widget Function(
      BuildContext,
      WidgetRef,
      String,
      AsyncValue<CacheResult<List<Movie>>>,
      String,
      CacheCategory,
      bool,) buildMovieRow;
  final StatefulWidget parentWidget;

  const HomeCustomListManager({
    required this.favoritesService,
    required this.scrollControllers,
    required this.isMounted,
    required this.safeNavigateTo,
    required this.buildSmartErrorWidgetCompact,
    required this.buildSmartErrorWidgetCompactWithRetry,
    required this.buildMovieRow,
    required this.parentWidget,
  });

  /// Builds custom list rows based on user's custom lists
  Widget buildCustomListRows(
      BuildContext context, Widget Function(CustomList) onCustomListTapped,) {
    return StreamBuilder<List<CustomList>>(
      stream: favoritesService.customLists,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            height: 200,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text('Error loading custom lists: ${snapshot.error}'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Container(
            height: 200,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final customLists = snapshot.data!;
        if (customLists.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: customLists.map((customList) {
            return _buildCustomListRow(context, customList, onCustomListTapped);
          }).toList(),
        );
      },
    );
  }

  /// Builds individual custom list row with movies
  Widget _buildCustomListRow(
    BuildContext context,
    CustomList customList,
    Widget Function(CustomList) onCustomListTapped,
  ) {
    return FutureBuilder<List<Movie>>(
      future: _loadMoviesForCustomList(customList),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            height: 200,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text('Error loading movies for ${customList.name}'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Container(
            height: 200,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final movies = snapshot.data!;
        if (movies.isEmpty) {
          return _buildEmptyCustomListRow(context, customList);
        }

        return _buildMovieRow(
          context,
          customList.name,
          movies,
          'custom_${customList.id}',
          () => _navigateToCustomListDetail(customList),
        );
      },
    );
  }

  /// Builds "To Watch" movie row
  Widget buildToWatchMovieRow(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Movie>>(
      stream: favoritesService.toWatchMovies,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return buildSmartErrorWidgetCompact(
            ref,
            snapshot.error!,
            StackTrace.current,
            'To Watch Movies',
            () {
              // Retry by refreshing the stream
            },
          );
        }

        if (!snapshot.hasData) {
          return Container(
            height: 200,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final movies = snapshot.data!;
        if (movies.isEmpty) {
          return _buildEmptyToWatchRow(context);
        }

        return _buildMovieRow(
          context,
          'To Watch',
          movies,
          'toWatch',
          () => _navigateToMovieCategory('To Watch', movies),
        );
      },
    );
  }

  /// Builds "Watched" movie row
  Widget buildWatchedMovieRow(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Movie>>(
      stream: favoritesService.watchedMovies,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return buildSmartErrorWidgetCompact(
            ref,
            snapshot.error!,
            StackTrace.current,
            'Watched Movies',
            () {
              // Retry by refreshing the stream
            },
          );
        }

        if (!snapshot.hasData) {
          return Container(
            height: 200,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final movies = snapshot.data!;
        if (movies.isEmpty) {
          return _buildEmptyWatchedRow(context);
        }

        return _buildMovieRow(
          context,
          'Watched',
          movies,
          'watched',
          () => _navigateToMovieCategory('Watched', movies),
        );
      },
    );
  }

  /// Builds async list section for list view mode
  Widget buildAsyncListSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    AsyncValue<CacheResult<List<Movie>>> moviesAsync,
  ) {
    return moviesAsync.when(
      data: (cacheResult) {
        final movies = cacheResult.data;
        if (movies.isEmpty) {
          return const SizedBox.shrink();
        }
        return _buildListSection(
            context, title, _buildMovieListItems(context, movies),);
      },
      loading: () => _buildLoadingSection(context, title),
      error: (error, stackTrace) =>
          _buildErrorSection(context, ref, title, error, stackTrace),
    );
  }

  /// Builds custom list sections for list view mode
  Widget buildCustomListListSections(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<CustomList>>(
      stream: favoritesService.customLists,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorSection(context, ref, 'Custom Lists',
              snapshot.error!, StackTrace.current,);
        }

        if (!snapshot.hasData) {
          return _buildLoadingSection(context, 'Custom Lists');
        }

        final customLists = snapshot.data!;
        if (customLists.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: customLists.map((customList) {
            return FutureBuilder<List<Movie>>(
              future: _loadMoviesForCustomList(customList),
              builder: (context, movieSnapshot) {
                if (movieSnapshot.hasError) {
                  return _buildErrorSection(context, ref, customList.name,
                      movieSnapshot.error!, StackTrace.current,);
                }

                if (!movieSnapshot.hasData) {
                  return _buildLoadingSection(context, customList.name);
                }

                final movies = movieSnapshot.data!;
                if (movies.isEmpty) {
                  return const SizedBox.shrink();
                }

                return _buildListSection(context, customList.name,
                    _buildMovieListItems(context, movies),);
              },
            );
          }).toList(),
        );
      },
    );
  }

  /// Builds "To Watch" list items for list view mode
  Widget buildToWatchListItems(BuildContext context) {
    return StreamBuilder<List<Movie>>(
      stream: favoritesService.toWatchMovies,
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final movies = snapshot.data!;
        if (movies.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildListSection(
            context, 'To Watch', _buildMovieListItems(context, movies),);
      },
    );
  }

  /// Builds "Watched" list items for list view mode
  Widget buildWatchedListItems(BuildContext context) {
    return StreamBuilder<List<Movie>>(
      stream: favoritesService.watchedMovies,
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final movies = snapshot.data!;
        if (movies.isEmpty) {
          return const SizedBox.shrink();
        }

        return _buildListSection(
            context, 'Watched', _buildMovieListItems(context, movies),);
      },
    );
  }

  // Helper methods for building UI components

  /// Loads movies for a custom list
  Future<List<Movie>> _loadMoviesForCustomList(CustomList customList) async {
    try {
      return await favoritesService.getMoviesInCustomList(customList.id);
    } catch (e) {
      // If fetching fails, return empty list
      return [];
    }
  }

  /// Builds a movie row with horizontal scrolling
  Widget _buildMovieRow(
    BuildContext context,
    String title,
    List<Movie> movies,
    String scrollKey,
    VoidCallback onViewAll,
  ) {
    final scrollController = scrollControllers[scrollKey] ?? ScrollController();
    if (!scrollControllers.containsKey(scrollKey)) {
      scrollControllers[scrollKey] = scrollController;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              TextButton(
                onPressed: onViewAll,
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 300,
          child: ListView.builder(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 12),
                child: MovieCard(
                  movie: movie,
                  onTap: () => _navigateToMovieDetails(movie),
                  favoritesService: favoritesService,
                ),
              );
            },
          ),
        ),
        const Gap(16),
      ],
    );
  }

  /// Builds empty custom list row
  Widget _buildEmptyCustomListRow(BuildContext context, CustomList customList) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            customList.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            'Empty',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Builds empty "To Watch" row
  Widget _buildEmptyToWatchRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'To Watch',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Gap(8),
          Text(
            'No movies in your watchlist yet',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Builds empty "Watched" row
  Widget _buildEmptyWatchedRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Watched',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const Gap(8),
          Text(
            'No watched movies yet',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  /// Builds list section for list view mode
  Widget _buildListSection(BuildContext context, String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        content,
        const Gap(16),
      ],
    );
  }

  /// Builds movie list items for list view mode
  Widget _buildMovieListItems(BuildContext context, List<Movie> movies) {
    return Column(
      children: movies.map((movie) {
        return ListTile(
          leading: movie.posterUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    movie.posterUrl,
                    width: 40,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 40,
                        height: 60,
                        color: Theme.of(context).colorScheme.surface,
                        child: Icon(
                          Icons.movie,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      );
                    },
                  ),
                )
              : Container(
                  width: 40,
                  height: 60,
                  color: Theme.of(context).colorScheme.surface,
                  child: Icon(
                    Icons.movie,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
          title: Text(movie.title),
          subtitle: movie.releaseDate != null
              ? Text(movie.releaseDate.year.toString())
              : null,
          onTap: () => _navigateToMovieDetails(movie),
        );
      }).toList(),
    );
  }

  /// Builds loading section
  Widget _buildLoadingSection(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
        const Gap(16),
      ],
    );
  }

  /// Builds error section
  Widget _buildErrorSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    Object error,
    StackTrace stackTrace,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        SizedBox(
          height: 200,
          child: buildSmartErrorWidgetCompact(
            ref,
            error,
            stackTrace,
            title,
            () {
              // Retry logic
            },
          ),
        ),
        const Gap(16),
      ],
    );
  }

  // Navigation methods

  /// Navigates to movie details screen
  void _navigateToMovieDetails(Movie movie) {
    if (!isMounted()) return;

    safeNavigateTo(
      MaterialPageRoute(
        builder: (context) => MovieDetailsScreen(
          movie: movie,
          favoritesService: favoritesService,
        ),
      ),
    );
  }

  /// Navigates to movie category screen
  void _navigateToMovieCategory(String categoryName, List<Movie> movies) {
    if (!isMounted()) return;

    safeNavigateTo(
      MaterialPageRoute(
        builder: (context) => MovieCategoryScreen(
          categoryName: categoryName,
          movies: movies,
          favoritesService: favoritesService,
        ),
      ),
    );
  }

  /// Navigates to custom list detail screen (placeholder)
  void _navigateToCustomListDetail(CustomList customList) {
    // TODO: Implement custom list detail screen navigation
    // This would navigate to a screen showing all movies in the custom list
  }
}
