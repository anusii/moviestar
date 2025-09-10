/// Standardized widget for displaying movies in a grid layout.
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

/// A standardized widget for displaying movies in a grid layout.
///
/// This widget provides a consistent way to display movies in a responsive grid
/// with configurable columns and aspect ratios.
class MovieGridWidget extends StatelessWidget {
  /// The list of movies to display.
  final List<Movie> movies;

  /// The favorites service for quick actions and navigation.
  final FavoritesService favoritesService;

  /// Whether the grid is currently loading.
  final bool isLoading;

  /// Error message to display, if any.
  final String? errorMessage;

  /// Custom empty state widget.
  final Widget? emptyWidget;

  /// Title to display above the grid.
  final String? title;

  /// Number of columns in the grid.
  final int crossAxisCount;

  /// Aspect ratio of each grid item.
  final double childAspectRatio;

  /// Main axis spacing between items.
  final double mainAxisSpacing;

  /// Cross axis spacing between items.
  final double crossAxisSpacing;

  /// Padding around the grid.
  final EdgeInsetsGeometry? padding;

  /// Maximum width for each grid item.
  final double? maxItemWidth;

  /// Whether to show content type indicator on posters.
  final bool showContentType;

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

  /// Whether to use a sliver grid (for CustomScrollView).
  final bool sliver;

  /// Creates a movie grid widget.
  const MovieGridWidget({
    super.key,
    required this.movies,
    required this.favoritesService,
    this.isLoading = false,
    this.errorMessage,
    this.emptyWidget,
    this.title,
    this.crossAxisCount = 3,
    this.childAspectRatio = 0.7,
    this.mainAxisSpacing = Dimensions.m,
    this.crossAxisSpacing = Dimensions.m,
    this.padding,
    this.maxItemWidth = 200,
    this.showContentType = true,
    this.onMovieTap,
    this.enableQuickActions = true,
    this.fromCache,
    this.cacheAge,
    this.cacheOnlyMode,
    this.sliver = false,
  });

  /// Creates a responsive movie grid that adjusts columns based on screen width.
  static Widget responsive({
    Key? key,
    required List<Movie> movies,
    required FavoritesService favoritesService,
    bool isLoading = false,
    String? errorMessage,
    Widget? emptyWidget,
    String? title,
    double minItemWidth = 130,
    double maxItemWidth = 200,
    double childAspectRatio = 0.7,
    double mainAxisSpacing = Dimensions.m,
    double crossAxisSpacing = Dimensions.m,
    EdgeInsetsGeometry? padding,
    bool showContentType = true,
    void Function(Movie movie)? onMovieTap,
    bool enableQuickActions = true,
    bool? fromCache,
    Duration? cacheAge,
    bool? cacheOnlyMode,
    bool sliver = false,
  }) {
    return _ResponsiveMovieGrid(
      key: key,
      movies: movies,
      favoritesService: favoritesService,
      isLoading: isLoading,
      errorMessage: errorMessage,
      emptyWidget: emptyWidget,
      title: title,
      minItemWidth: minItemWidth,
      maxItemWidth: maxItemWidth,
      childAspectRatio: childAspectRatio,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      padding: padding,
      showContentType: showContentType,
      onMovieTap: onMovieTap,
      enableQuickActions: enableQuickActions,
      fromCache: fromCache,
      cacheAge: cacheAge,
      cacheOnlyMode: cacheOnlyMode,
      sliver: sliver,
    );
  }

  void _handleMovieTap(BuildContext context, Movie movie) {
    if (onMovieTap != null) {
      onMovieTap!(movie);
    } else {
      navigateToMovieDetails(context, movie, favoritesService);
    }
  }

  Widget _buildContent(BuildContext context) {
    // Handle loading state
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Handle error state
    if (errorMessage != null) {
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
              errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Handle empty state
    if (movies.isEmpty) {
      return emptyWidget ??
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
              ],
            ),
          );
    }

    // Build the grid
    final gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
    );

    if (sliver) {
      return SliverPadding(
        padding: padding ?? const EdgeInsets.all(Dimensions.m),
        sliver: SliverGrid(
          gridDelegate: gridDelegate,
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildGridItem(context, movies[index]),
            childCount: movies.length,
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding ?? const EdgeInsets.all(Dimensions.m),
      gridDelegate: gridDelegate,
      itemCount: movies.length,
      itemBuilder: (context, index) => _buildGridItem(context, movies[index]),
    );
  }

  Widget _buildGridItem(BuildContext context, Movie movie) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = maxItemWidth != null
            ? constraints.maxWidth.clamp(0, maxItemWidth!).toDouble()
            : constraints.maxWidth;

        return Center(
          child: SizedBox(
            width: width,
            child: MovieCard.poster(
              movie: movie,
              width: width,
              fromCache: fromCache,
              cacheAge: cacheAge,
              cacheOnlyMode: cacheOnlyMode,
              favoritesService: favoritesService,
              showContentType: showContentType,
              enableQuickActions: enableQuickActions,
              onTap: () => _handleMovieTap(context, movie),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (title != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: padding?.resolve(TextDirection.ltr).left ?? Dimensions.m,
              top: padding?.resolve(TextDirection.ltr).top ?? Dimensions.m,
              right: padding?.resolve(TextDirection.ltr).right ?? Dimensions.m,
            ),
            child: Text(
              title!,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const Gap(Gaps.m),
          Expanded(child: _buildContent(context)),
        ],
      );
    }

    return _buildContent(context);
  }
}

/// A responsive version of MovieGridWidget that calculates columns dynamically.
class _ResponsiveMovieGrid extends StatelessWidget {
  final List<Movie> movies;
  final FavoritesService favoritesService;
  final bool isLoading;
  final String? errorMessage;
  final Widget? emptyWidget;
  final String? title;
  final double minItemWidth;
  final double maxItemWidth;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final EdgeInsetsGeometry? padding;
  final bool showContentType;
  final void Function(Movie movie)? onMovieTap;
  final bool enableQuickActions;
  final bool? fromCache;
  final Duration? cacheAge;
  final bool? cacheOnlyMode;
  final bool sliver;

  const _ResponsiveMovieGrid({
    super.key,
    required this.movies,
    required this.favoritesService,
    required this.isLoading,
    this.errorMessage,
    this.emptyWidget,
    this.title,
    required this.minItemWidth,
    required this.maxItemWidth,
    required this.childAspectRatio,
    required this.mainAxisSpacing,
    required this.crossAxisSpacing,
    this.padding,
    required this.showContentType,
    this.onMovieTap,
    required this.enableQuickActions,
    this.fromCache,
    this.cacheAge,
    this.cacheOnlyMode,
    required this.sliver,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate number of columns based on available width
        final availableWidth = constraints.maxWidth -
            (padding?.resolve(TextDirection.ltr).horizontal ??
                Dimensions.m * 2);

        int crossAxisCount = (availableWidth / minItemWidth).floor();
        crossAxisCount = crossAxisCount.clamp(1, 10);

        // Adjust item width to fit exactly
        final itemWidth =
            (availableWidth - (crossAxisCount - 1) * crossAxisSpacing) /
                crossAxisCount;
        final actualItemWidth = itemWidth.clamp(minItemWidth, maxItemWidth);

        return MovieGridWidget(
          movies: movies,
          favoritesService: favoritesService,
          isLoading: isLoading,
          errorMessage: errorMessage,
          emptyWidget: emptyWidget,
          title: title,
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          padding: padding,
          maxItemWidth: actualItemWidth,
          showContentType: showContentType,
          onMovieTap: onMovieTap,
          enableQuickActions: enableQuickActions,
          fromCache: fromCache,
          cacheAge: cacheAge,
          cacheOnlyMode: cacheOnlyMode,
          sliver: sliver,
        );
      },
    );
  }
}
