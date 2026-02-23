/// Horizontal Row Layout for Custom Lists.
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
/// Authors: Ashley Tang, Kevin Wang

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/core/services/favorites/service_adapter.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/screens/custom_list_detail_screen.dart';
import 'package:moviestar/shared/widgets/home/custom_list_movie_card.dart';
import 'package:moviestar/shared/widgets/home/custom_list_states.dart';

/// A widget that displays a custom list as a horizontal scrollable row.
/// Used in grid view layouts of the home screen.

class CustomListRow extends ConsumerWidget {
  /// The custom list to display.

  final CustomList customList;

  /// Service for managing favorites.

  final FavoritesService favoritesService;

  /// Parent widget for navigation context.

  final StatefulWidget parentWidget;

  /// Callback for navigation.

  final void Function(Route<dynamic> route) onNavigate;

  /// Scroll controller for this specific list.

  final ScrollController? scrollController;

  /// Creates a new [CustomListRow].

  const CustomListRow({
    super.key,
    required this.customList,
    required this.favoritesService,
    required this.parentWidget,
    required this.onNavigate,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRowHeader(context),
        SizedBox(
          height: 200,
          child: _buildContent(context, ref),
        ),
      ],
    );
  }

  /// Builds the row header with title, count badge, and "View More" button.

  Widget _buildRowHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToCustomListDetail(),
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
              onPressed: () => _navigateToCustomListDetail(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
    );
  }

  /// Builds the scrollable content for the custom list.

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final movieIds = customList.movieIds;

    // Check if we have POD data available.

    if (favoritesService is FavoritesServiceAdapter) {
      final adapter = favoritesService as FavoritesServiceAdapter;

      if (adapter.isPodStorageEnabled) {
        return FutureBuilder<List<Movie>>(
          future: favoritesService.getMoviesInCustomList(customList.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              // Fallback to ID-based loading.

              return _buildMovieCardsFromIds(movieIds);
            }

            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final podMovies = snapshot.data!;
              return _buildMovieCardsFromMovies(podMovies);
            } else {
              return _buildMovieCardsFromIds(movieIds);
            }
          },
        );
      }
    }

    if (movieIds.isEmpty) {
      return CustomListEmptyState(listName: customList.name);
    }

    return _buildMovieCardsFromIds(movieIds);
  }

  /// Builds horizontal scrollable movie cards from movie objects.

  Widget _buildMovieCardsFromMovies(List<Movie> movies) {
    return Scrollbar(
      controller: scrollController ?? ScrollController(),
      thickness: 6,
      radius: const Radius.circular(3),
      thumbVisibility: true,
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CustomListDirectMovieCard(
              movie: movie,
              favoritesService: favoritesService,
              parentWidget: parentWidget,
              onNavigate: onNavigate,
            ),
          );
        },
      ),
    );
  }

  /// Builds horizontal scrollable movie cards from movie IDs.

  Widget _buildMovieCardsFromIds(List<int> movieIds) {
    return Scrollbar(
      controller: scrollController ?? ScrollController(),
      thickness: 6,
      radius: const Radius.circular(3),
      thumbVisibility: true,
      child: ListView.builder(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: movieIds.length,
        itemBuilder: (context, index) {
          final movieId = movieIds[index];
          final contentType = customList.getContentTypeAt(index);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CustomListMovieCard(
              movieId: movieId,
              contentType: contentType,
              favoritesService: favoritesService,
              parentWidget: parentWidget,
              onNavigate: onNavigate,
            ),
          );
        },
      ),
    );
  }

  /// Navigate to custom list detail screen.

  void _navigateToCustomListDetail() {
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
