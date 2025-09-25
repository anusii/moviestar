/// List Shared Movies Widget for MovieStar.
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
/// Authors: Software Innovation Institute.

library;

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/core/services/favorites/service_adapter.dart';
import 'package:moviestar/core/services/favorites/service_manager.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/screens/shared_movie_list_detail_screen.dart';
import 'package:moviestar/widgets/common_sharing_ui.dart';
import 'package:moviestar/widgets/shared_movies/item_builders.dart';

class ListSharedMovies extends StatefulWidget {
  final Map<String, dynamic>
      sharedMoviesMap; // Contains both 'movies' and 'movieLists' keys
  final VoidCallback onDataChanged;

  const ListSharedMovies({
    super.key,
    required this.sharedMoviesMap,
    required this.onDataChanged,
  });

  @override
  State<ListSharedMovies> createState() => _ListSharedMoviesState();
}

class _ListSharedMoviesState extends State<ListSharedMovies> {
  // Share a movie using the common sharing UI.

  Future<void> _shareMovie(Movie movie, String movieFilePath) async {
    try {
      final result = await navigateToGrantPermissionUi(
        context: context,
        fileName: movieFilePath,
        title: 'Share "${movie.title}"',
        accessModeList: const ['read'],
        recipientTypeList: const ['indi'],
        returnWidget: widget,
      );

      if (mounted) {
        // Refresh the parent screen data.

        widget.onDataChanged();

        // Show result message.

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result == true
                  ? 'Movie "${movie.title}" shared successfully'
                  : 'Share cancelled for "${movie.title}"',
            ),
            backgroundColor: result == true
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing "${movie.title}": $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Handle navigation for tapped items.

  Future<void> _handleItemTap({
    required String resourceUrl,
    required Map<String, dynamic> itemData,
  }) async {
    final movieTitle = itemData['fileName'] ?? 'Unknown Movie';

    try {
      if (itemData['type'] == 'movieList') {
        await _navigateToMovieList(resourceUrl, itemData);
      } else {
        await _navigateToMovie(resourceUrl, itemData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening: $movieTitle'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Navigate to movie list detail screen.

  Future<void> _navigateToMovieList(
    String resourceUrl,
    Map<String, dynamic> itemData,
  ) async {
    final movieTitle = itemData['fileName'] ?? 'Unknown Movie';
    final listName = itemData['listName'] ?? movieTitle;
    final listDescription = itemData['description'] ?? '';
    final movies =
        (itemData['movies'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[];
    final owner = itemData['owner'] ?? '';
    final ownerWebId = itemData['ownerWebId'] ?? '';
    final sharedBy = itemData['sharedBy'] ?? '';
    final sharedByWebId = itemData['sharedByWebId'] ?? '';
    final permissions = itemData['permissions'] ?? 'none';

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SharedMovieListDetailScreen(
            listName: listName,
            listDescription: listDescription,
            owner: owner,
            ownerWebId: ownerWebId,
            sharedBy: sharedBy,
            sharedByWebId: sharedByWebId,
            movies: movies,
            permissions: permissions,
          ),
        ),
      );
    }
  }

  // Navigate to movie details screen.

  Future<void> _navigateToMovie(
    String resourceUrl,
    Map<String, dynamic> itemData,
  ) async {
    final movieTitle = itemData['fileName'] ?? 'Unknown Movie';
    final movieId = int.tryParse(itemData['movieId']?.toString() ?? '0') ?? 0;
    final posterUrl = itemData['posterUrl'] ?? '';
    final backdropUrl = itemData['backdropUrl'] ?? posterUrl ?? '';
    final overview = itemData['overview'] ?? 'Shared movie';
    final releaseDate =
        DateTime.tryParse(itemData['releaseDate'] ?? '') ?? DateTime.now();
    final voteAverage = (itemData['voteAverage'] as num?)?.toDouble() ?? 0.0;
    final genreIds =
        (itemData['genreIds'] as List?)?.map((e) => e as int).toList() ??
            <int>[];

    final movie = Movie(
      id: movieId,
      title: movieTitle,
      overview: overview,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      voteAverage: voteAverage,
      releaseDate: releaseDate,
      genreIds: genreIds,
    );

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final favoritesServiceManager =
        FavoritesServiceManager(prefs, context, widget);
    final favoritesService = FavoritesServiceAdapter(favoritesServiceManager);

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MovieDetailsScreen(
            movie: movie,
            favoritesService: favoritesService,
            sharedMovieData: itemData,
          ),
        ),
      );
    }
  }

  // Handle share action for movies.

  Future<void> _handleShareAction({
    required String resourceUrl,
    required Map<String, dynamic> itemData,
  }) async {
    final movieTitle = itemData['fileName'] ?? 'Unknown Movie';
    final movieId = int.tryParse(itemData['movieId']?.toString() ?? '0') ?? 0;
    final posterUrl = itemData['posterUrl'] ?? '';
    final backdropUrl = itemData['backdropUrl'] ?? posterUrl ?? '';
    final overview = itemData['overview'] ?? 'My rated movie';
    final releaseDate =
        DateTime.tryParse(itemData['releaseDate'] ?? '') ?? DateTime.now();
    final voteAverage = (itemData['voteAverage'] as num?)?.toDouble() ?? 0.0;
    final genreIds =
        (itemData['genreIds'] as List?)?.map((e) => e as int).toList() ??
            <int>[];

    final movie = Movie(
      id: movieId,
      title: movieTitle,
      overview: overview,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      voteAverage: voteAverage,
      releaseDate: releaseDate,
      genreIds: genreIds,
    );

    await _shareMovie(movie, resourceUrl);
  }

  @override
  Widget build(BuildContext context) {
    // Separate movies and movie lists from the shared data.

    final movies =
        widget.sharedMoviesMap['movies'] as Map<String, dynamic>? ?? {};
    final movieLists =
        widget.sharedMoviesMap['movieLists'] as Map<String, dynamic>? ?? {};

    // Combine both into a single list for display.

    final allItems = <MapEntry<String, Map<String, dynamic>>>[];

    // Add movie lists first (higher priority).

    for (final entry in movieLists.entries) {
      final listData = entry.value as Map<String, dynamic>;
      listData['type'] = 'movieList'; // Add type identifier
      allItems.add(MapEntry(entry.key, listData));
    }

    // Add individual movies.

    for (final entry in movies.entries) {
      final movieData = entry.value as Map<String, dynamic>;
      movieData['type'] = 'movie'; // Add type identifier
      allItems.add(MapEntry(entry.key, movieData));
    }

    if (allItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(Dimensions.xxxl),
          child: Text(
            'No shared movies or lists yet',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final entry = allItems[index];
        final resourceUrl = entry.key;
        final itemData = entry.value;
        final isUserRatedMovie = itemData['isUserRatedMovie'] == true;
        final canShare = itemData['canShare'] == true;

        // Use appropriate builder method based on item type.

        if (itemData['type'] == 'movieList') {
          return SharedMoviesItemBuilders.buildMovieListItem(
            context: context,
            itemData: itemData,
            resourceUrl: resourceUrl,
            onTap: () => _handleItemTap(
              resourceUrl: resourceUrl,
              itemData: itemData,
            ),
          );
        } else {
          return SharedMoviesItemBuilders.buildMovieItem(
            context: context,
            itemData: itemData,
            resourceUrl: resourceUrl,
            onTap: () => _handleItemTap(
              resourceUrl: resourceUrl,
              itemData: itemData,
            ),
            onShare: isUserRatedMovie && canShare
                ? () => _handleShareAction(
                      resourceUrl: resourceUrl,
                      itemData: itemData,
                    )
                : () {},
          );
        }
      },
    );
  }
}
