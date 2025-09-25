/// Vertical Section Layout for Custom Lists.
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

import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/core/services/favorites/service_adapter.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/screens/custom_list_detail_screen.dart';
import 'package:moviestar/shared/widgets/home/custom_list_movie_card.dart';

/// A widget that displays a custom list as a vertical section with movie items.
/// Used in list view layouts of the home screen.

class CustomListSection extends ConsumerWidget {
  /// The custom list to display.

  final CustomList customList;

  /// Service for managing favorites.

  final FavoritesService favoritesService;

  /// Parent widget for navigation context.

  final StatefulWidget parentWidget;

  /// Callback for navigation.

  final void Function(Route<dynamic> route) onNavigate;

  /// Creates a new [CustomListSection].

  const CustomListSection({
    super.key,
    required this.customList,
    required this.favoritesService,
    required this.parentWidget,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context),
        _buildListItems(context, ref),
        const Gap(16),
      ],
    );
  }

  /// Builds the section header with title and "View More" button.

  Widget _buildSectionHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToCustomListDetail(),
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

  /// Builds the list of movie items for this custom list.

  Widget _buildListItems(BuildContext context, WidgetRef ref) {
    final movieIds = customList.movieIds;

    if (movieIds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('No movies in ${customList.name}'),
      );
    }

    // Check if we have POD data available.

    if (favoritesService is FavoritesServiceAdapter) {
      final adapter = favoritesService as FavoritesServiceAdapter;

      if (adapter.isPodStorageEnabled) {
        return FutureBuilder<List<Movie>>(
          future: favoritesService.getMoviesInCustomList(customList.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              // Fallback to ID-based loading.

              return _buildItemsFromIds(movieIds);
            }

            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final podMovies = snapshot.data!;
              return _buildItemsFromMovies(podMovies);
            } else {
              return _buildItemsFromIds(movieIds);
            }
          },
        );
      }
    }

    return _buildItemsFromIds(movieIds);
  }

  /// Builds list items from movie objects (when we have full data from PODs).

  Widget _buildItemsFromMovies(List<Movie> movies) {
    final displayMovies = movies.take(5).toList();

    return Column(
      children: displayMovies.map((movie) {
        return CustomListDirectMovieCard(
          movie: movie,
          favoritesService: favoritesService,
          parentWidget: parentWidget,
          onNavigate: onNavigate,
          isListItem: true,
        );
      }).toList(),
    );
  }

  /// Builds list items from IDs (fallback when POD data not available).

  Widget _buildItemsFromIds(List<int> movieIds) {
    final displayMovieIds = movieIds.take(5).toList();

    return Column(
      children: displayMovieIds.asMap().entries.map((entry) {
        final index = entry.key;
        final movieId = entry.value;
        final contentType = customList.getContentTypeAt(index);

        return CustomListMovieCard(
          movieId: movieId,
          contentType: contentType,
          favoritesService: favoritesService,
          parentWidget: parentWidget,
          onNavigate: onNavigate,
          isListItem: true,
        );
      }).toList(),
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
