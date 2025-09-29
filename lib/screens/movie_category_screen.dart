/// Movie Category Screen - Full list view for a specific category.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Ashley Tang.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/widgets/base_screen.dart';
import 'package:moviestar/widgets/movie_card.dart';

/// Screen that displays all movies in a specific category.

class MovieCategoryScreen extends ConsumerStatefulWidget {
  final String categoryName;
  final List<Movie> movies;
  final FavoritesService favoritesService;
  final bool fromCache;

  const MovieCategoryScreen({
    super.key,
    required this.categoryName,
    required this.movies,
    required this.favoritesService,
    this.fromCache = false,
  });

  @override
  ConsumerState<MovieCategoryScreen> createState() =>
      _MovieCategoryScreenState();
}

class _MovieCategoryScreenState extends ConsumerState<MovieCategoryScreen>
    with ScreenStateMixin {
  final ScrollController _scrollController = ScrollController();
  String _sortBy = 'default'; // default, title, rating, year.

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Get sorted movies based on current sort option.

  List<Movie> get _sortedMovies {
    final movies = List<Movie>.from(widget.movies);

    switch (_sortBy) {
      case 'title':
        movies.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'rating':
        movies.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
        break;
      case 'year':
        movies.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
        break;
      case 'default':
      default:
        // Keep original order (e.g., popularity for API results).

        break;
    }

    return movies;
  }

  // Build the sort options.

  Widget _buildSortOptions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Sort by:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const Gap(12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSortChip('Default', 'default'),
                  const Gap(8),
                  _buildSortChip('Title', 'title'),
                  const Gap(8),
                  _buildSortChip('Rating', 'rating'),
                  const Gap(8),
                  _buildSortChip('Year', 'year'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build a sort chip.

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          safeSetState(() {
            _sortBy = value;
          });
        }
      },
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurface,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  // Build the movie grid.

  Widget _buildMovieGrid() {
    final movies = _sortedMovies;

    if (movies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.movie_outlined,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
              const Gap(16),
              Text(
                'No movies found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
              const Gap(8),
              Text(
                'There are no movies in this category.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return MovieCard.poster(
            movie: movie,
            fromCache: widget.fromCache,
            width: double.infinity,
            favoritesService: widget.favoritesService,
            onTap: () {
              safeNavigateTo(
                MaterialPageRoute(
                  builder: (context) => MovieDetailsScreen(
                    movie: movie,
                    favoritesService: widget.favoritesService,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: widget.categoryName,
      automaticallyImplyLeading: true,
      actions: [
        // Movie count indicator.

        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${widget.movies.length} movies',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
      body: Column(
        children: [
          // Sort options.

          _buildSortOptions(),
          // Movie grid.

          Expanded(
            child: _buildMovieGrid(),
          ),
        ],
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: ValueNotifier(
          false,
        ), // We'll implement scroll-to-top later if needed.
        builder: (context, showScrollToTop, child) {
          return FloatingActionButton.small(
            onPressed: () {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            },
            tooltip: 'Scroll to top',
            child: const Icon(Icons.keyboard_arrow_up),
          );
        },
      ),
    );
  }
}
