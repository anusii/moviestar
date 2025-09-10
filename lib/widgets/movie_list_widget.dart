/// Standardized widget for displaying lists of movies.
///
// Time-stamp: <Friday 2025-09-10 05:51:08 +1000 Graham Williams>
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

import 'package:gap/gap.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/utils/navigation_utils.dart';
import 'package:moviestar/widgets/movie_card.dart';
import 'package:moviestar/widgets/sort_controls.dart';

/// A standardized widget for displaying a list of movies.
///
/// This widget provides a consistent way to display movies in a vertical list
/// with optional sorting, loading states, empty states, and error handling.
class MovieListWidget extends StatefulWidget {
  /// The list of movies to display.
  final List<Movie> movies;

  /// The favorites service for quick actions and navigation.
  final FavoritesService favoritesService;

  /// Whether the list is currently loading.
  final bool isLoading;

  /// Error message to display, if any.
  final String? errorMessage;

  /// Custom empty state widget.
  final Widget? emptyWidget;

  /// Title to display above the list.
  final String? title;

  /// Whether to show sorting controls.
  final bool showSorting;

  /// Initial sort criteria.
  final MovieSortCriteria initialSortCriteria;

  /// Callback when sort criteria changes.
  final ValueChanged<MovieSortCriteria>? onSortChanged;

  /// Whether to show rating in list items.
  final bool showRating;

  /// Whether to show content type indicator.
  final bool showContentType;

  /// Whether to show release year.
  final bool showYear;

  /// Custom trailing widget builder for list items.
  final Widget Function(Movie movie)? trailingBuilder;

  /// Custom subtitle widget builder for list items.
  final Widget Function(Movie movie)? subtitleBuilder;

  /// Callback when a movie is tapped.
  final void Function(Movie movie)? onMovieTap;

  /// Whether to enable quick actions on hover.
  final bool enableQuickActions;

  /// Whether the data is from cache.
  final bool? fromCache;

  /// Age of cached data.
  final Duration? cacheAge;

  /// Whether the app is in offline mode.
  final bool? cacheOnlyMode;

  /// Padding around the list.
  final EdgeInsetsGeometry? padding;

  /// Whether to use a sliver list (for CustomScrollView).
  final bool sliver;

  /// Creates a movie list widget.
  const MovieListWidget({
    super.key,
    required this.movies,
    required this.favoritesService,
    this.isLoading = false,
    this.errorMessage,
    this.emptyWidget,
    this.title,
    this.showSorting = false,
    this.initialSortCriteria = MovieSortCriteria.nameAsc,
    this.onSortChanged,
    this.showRating = true,
    this.showContentType = true,
    this.showYear = false,
    this.trailingBuilder,
    this.subtitleBuilder,
    this.onMovieTap,
    this.enableQuickActions = true,
    this.fromCache,
    this.cacheAge,
    this.cacheOnlyMode,
    this.padding,
    this.sliver = false,
  });

  @override
  State<MovieListWidget> createState() => _MovieListWidgetState();
}

class _MovieListWidgetState extends State<MovieListWidget> {
  late MovieSortCriteria _currentSortCriteria;
  late List<Movie> _sortedMovies;

  @override
  void initState() {
    super.initState();
    _currentSortCriteria = widget.initialSortCriteria;
    _sortedMovies = _sortMovies(widget.movies);
  }

  @override
  void didUpdateWidget(MovieListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movies != widget.movies) {
      _sortedMovies = _sortMovies(widget.movies);
    }
  }

  List<Movie> _sortMovies(List<Movie> movies) {
    final sorted = List<Movie>.from(movies);

    switch (_currentSortCriteria) {
      case MovieSortCriteria.nameAsc:
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case MovieSortCriteria.nameDesc:
        sorted.sort((a, b) => b.title.compareTo(a.title));
        break;
      case MovieSortCriteria.ratingAsc:
        sorted.sort((a, b) => a.voteAverage.compareTo(b.voteAverage));
        break;
      case MovieSortCriteria.ratingDesc:
        sorted.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
        break;
      case MovieSortCriteria.dateAsc:
        sorted.sort((a, b) {
          final dateA = a.releaseDate;
          final dateB = b.releaseDate;
          return dateA.compareTo(dateB);
        });
        break;
      case MovieSortCriteria.dateDesc:
        sorted.sort((a, b) {
          final dateA = a.releaseDate;
          final dateB = b.releaseDate;
          return dateB.compareTo(dateA);
        });
        break;
    }

    return sorted;
  }

  void _handleSortChanged(MovieSortCriteria newCriteria) {
    setState(() {
      _currentSortCriteria = newCriteria;
      _sortedMovies = _sortMovies(widget.movies);
    });
    widget.onSortChanged?.call(newCriteria);
  }

  void _handleMovieTap(Movie movie) {
    if (widget.onMovieTap != null) {
      widget.onMovieTap!(movie);
    } else {
      navigateToMovieDetails(context, movie, widget.favoritesService);
    }
  }

  Widget _buildContent() {
    // Handle loading state
    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Handle error state
    if (widget.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const Gap(Gaps.m),
            Text(
              'Error loading movies',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Gap(Gaps.s),
            Text(
              widget.errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Handle empty state
    if (_sortedMovies.isEmpty) {
      return widget.emptyWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.movie_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const Gap(Gaps.m),
                Text(
                  'No movies found',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Gap(Gaps.s),
                Text(
                  'Try adjusting your filters or search criteria',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          );
    }

    // Build the movie list
    final listView = ListView.builder(
      shrinkWrap: !widget.sliver,
      physics: widget.sliver ? const NeverScrollableScrollPhysics() : null,
      padding: widget.padding ?? const EdgeInsets.all(Dimensions.m),
      itemCount: _sortedMovies.length,
      itemBuilder: (context, index) {
        final movie = _sortedMovies[index];

        return MovieCard.listItem(
          movie: movie,
          fromCache: widget.fromCache,
          cacheAge: widget.cacheAge,
          cacheOnlyMode: widget.cacheOnlyMode,
          favoritesService: widget.favoritesService,
          showRating: widget.showRating,
          showContentType: widget.showContentType,
          showYear: widget.showYear,
          enableQuickActions: widget.enableQuickActions,
          onTap: () => _handleMovieTap(movie),
          trailing: widget.trailingBuilder?.call(movie),
          customSubtitle: widget.subtitleBuilder?.call(movie),
        );
      },
    );

    return listView;
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) ...[
          Padding(
            padding: const EdgeInsets.all(Dimensions.m),
            child: Text(
              widget.title!,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
        ],
        if (widget.showSorting &&
            !widget.isLoading &&
            _sortedMovies.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.m),
            child: SortControls(
              selectedCriteria: _currentSortCriteria,
              onSortChanged: _handleSortChanged,
            ),
          ),
          const Gap(Gaps.s),
        ],
        Expanded(
          child: _buildContent(),
        ),
      ],
    );

    if (widget.sliver) {
      return SliverToBoxAdapter(child: content);
    }

    return content;
  }
}

/// A sliver version of MovieListWidget for use in CustomScrollView.
class SliverMovieList extends StatelessWidget {
  /// The list of movies to display.
  final List<Movie> movies;

  /// The favorites service for quick actions and navigation.
  final FavoritesService favoritesService;

  /// Whether to show rating in list items.
  final bool showRating;

  /// Whether to show content type indicator.
  final bool showContentType;

  /// Whether to show release year.
  final bool showYear;

  /// Custom trailing widget builder for list items.
  final Widget Function(Movie movie)? trailingBuilder;

  /// Custom subtitle widget builder for list items.
  final Widget Function(Movie movie)? subtitleBuilder;

  /// Callback when a movie is tapped.
  final void Function(Movie movie)? onMovieTap;

  /// Whether to enable quick actions on hover.
  final bool enableQuickActions;

  /// Whether the data is from cache.
  final bool? fromCache;

  /// Age of cached data.
  final Duration? cacheAge;

  /// Whether the app is in offline mode.
  final bool? cacheOnlyMode;

  /// Creates a sliver movie list.
  const SliverMovieList({
    super.key,
    required this.movies,
    required this.favoritesService,
    this.showRating = true,
    this.showContentType = true,
    this.showYear = false,
    this.trailingBuilder,
    this.subtitleBuilder,
    this.onMovieTap,
    this.enableQuickActions = true,
    this.fromCache,
    this.cacheAge,
    this.cacheOnlyMode,
  });

  void _handleMovieTap(BuildContext context, Movie movie) {
    if (onMovieTap != null) {
      onMovieTap!(movie);
    } else {
      navigateToMovieDetails(context, movie, favoritesService);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final movie = movies[index];

          return MovieCard.listItem(
            movie: movie,
            fromCache: fromCache,
            cacheAge: cacheAge,
            cacheOnlyMode: cacheOnlyMode,
            favoritesService: favoritesService,
            showRating: showRating,
            showContentType: showContentType,
            showYear: showYear,
            enableQuickActions: enableQuickActions,
            onTap: () => _handleMovieTap(context, movie),
            trailing: trailingBuilder?.call(movie),
            customSubtitle: subtitleBuilder?.call(movie),
          );
        },
        childCount: movies.length,
      ),
    );
  }
}
