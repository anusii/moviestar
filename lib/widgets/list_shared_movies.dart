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
/// Authors: Software Innovation Institute

library;

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:solidpod/solidpod.dart';

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/screens/shared_movie_list_detail_screen.dart';
import 'package:moviestar/services/favorites_service_adapter.dart';
import 'package:moviestar/services/favorites_service_manager.dart';

class ListSharedMovies extends StatefulWidget {
  final Map<String, dynamic>
      sharedMoviesMap; // Contains both 'movies' and 'movieLists' keys
  final VoidCallback? onDataChanged;

  const ListSharedMovies({
    super.key,
    required this.sharedMoviesMap,
    this.onDataChanged,
  });

  @override
  State<ListSharedMovies> createState() => _ListSharedMoviesState();
}

class _ListSharedMoviesState extends State<ListSharedMovies> {
  // Share a movie using the GrantPermissionUi.

  Future<void> _shareMovie(Movie movie, String movieFilePath) async {
    try {
      // Store the current navigation context.

      final currentContext = context;

      // Navigate to GrantPermissionUi with custom app bar and proper navigation.

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (navContext) => Theme(
            data: Theme.of(currentContext).copyWith(),
            child: Scaffold(
              backgroundColor: Theme.of(currentContext).scaffoldBackgroundColor,
              appBar: AppBar(
                title: Text('Share "${movie.title}"'),
                backgroundColor:
                    Theme.of(currentContext).appBarTheme.backgroundColor,
                foregroundColor:
                    Theme.of(currentContext).appBarTheme.foregroundColor,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(currentContext)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: Theme.of(currentContext).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  onPressed: () {
                    // Ensure we properly return to the main navigation context.

                    Navigator.of(navContext).pop(null);
                  },
                  tooltip: 'Back to My Movies',
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(currentContext).colorScheme.onSurface,
                    ),
                    onPressed: () {
                      Navigator.of(navContext).pop(null);
                    },
                    tooltip: 'Cancel',
                  ),
                ],
              ),
              body: GrantPermissionUi(
                fileName: movieFilePath,
                title: '',
                accessModeList: const ['read'],
                recipientList: const ['indi'],
                showAppBar: false,
                backgroundColor:
                    Theme.of(currentContext).scaffoldBackgroundColor,
                child: widget,
              ),
            ),
          ),
        ),
      );

      // Ensure we're back in the correct context after navigation.

      if (mounted) {
        // Add a small delay to ensure navigation has fully completed.

        await Future.delayed(const Duration(milliseconds: 100));

        if (mounted) {
          // Refresh the parent screen data regardless of result.

          if (widget.onDataChanged != null) {
            widget.onDataChanged!();
          }

          // Force a rebuild to ensure the UI is properly refreshed.

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {});
            }
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result != null
                ? 'Movie "${movie.title}" shared successfully'
                : 'Share cancelled for "${movie.title}"'),
            backgroundColor: result != null
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error sharing movie: $e');
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

  // Extract owner name from WebID.

  String _getOwnerName(String webId) {
    try {
      final uri = Uri.parse(webId);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.first.replaceAll('-', ' ').toUpperCase();
      }
      return 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  // Build rating display.

  Widget _buildRatingDisplay(dynamic rating) {
    if (rating == null) return const SizedBox.shrink();

    final ratingValue =
        rating is double ? rating : double.tryParse(rating.toString()) ?? 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: Colors.amber, size: 16),
        const SizedBox(width: 4),
        Text(
          ratingValue.toStringAsFixed(1),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // Build permissions badge.

  Widget _buildPermissionsBadge(String permissions) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: permissions.contains('read')
            ? Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: permissions.contains('read')
              ? Theme.of(context).colorScheme.tertiary
              : Theme.of(context).colorScheme.error,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            permissions.contains('read')
                ? Icons.visibility
                : Icons.visibility_off,
            size: 12,
            color: permissions.contains('read')
                ? Theme.of(context).colorScheme.tertiary
                : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 4),
          Text(
            permissions.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: permissions.contains('read')
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Separate movies and movie lists from the shared data
    final movies =
        widget.sharedMoviesMap['movies'] as Map<String, dynamic>? ?? {};
    final movieLists =
        widget.sharedMoviesMap['movieLists'] as Map<String, dynamic>? ?? {};

    // Combine both into a single list for display
    final allItems = <MapEntry<String, Map<String, dynamic>>>[];

    // Add movie lists first (higher priority)
    for (final entry in movieLists.entries) {
      final listData = entry.value as Map<String, dynamic>;
      listData['type'] = 'movieList'; // Add type identifier
      allItems.add(MapEntry(entry.key, listData));
    }

    // Add individual movies
    for (final entry in movies.entries) {
      final movieData = entry.value as Map<String, dynamic>;
      movieData['type'] = 'movie'; // Add type identifier
      allItems.add(MapEntry(entry.key, movieData));
    }

    if (allItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
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

        final movieTitle = itemData['fileName'] ?? 'Unknown Movie';
        final owner = itemData['owner'] ?? '';
        final ownerWebId = itemData['ownerWebId'] ?? '';
        final sharedBy = itemData['sharedBy'] ?? '';
        final sharedByWebId = itemData['sharedByWebId'] ?? '';
        final permissions = itemData['permissions'] ?? 'none';
        final rating = itemData['rating'];
        final comments = itemData['comments'] ?? '';
        final isUserRatedMovie = itemData['isUserRatedMovie'] == true;
        final canShare = itemData['canShare'] == true;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              try {
                // Check if this is a movie list or individual movie
                if (itemData['type'] == 'movieList') {
                  // Navigate to SharedMovieListDetailScreen
                  final listName = itemData['listName'] ?? movieTitle;
                  final listDescription = itemData['description'] ?? '';
                  final movies = (itemData['movies'] as List<dynamic>?)
                          ?.cast<Map<String, dynamic>>() ??
                      <Map<String, dynamic>>[];

                  if (context.mounted) {
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
                } else {
                  // Handle individual movie navigation
                  final movieId =
                      int.tryParse(itemData['movieId']?.toString() ?? '0') ?? 0;
                  final posterUrl = itemData['posterUrl'] ?? '';
                  final backdropUrl =
                      itemData['backdropUrl'] ?? posterUrl ?? '';
                  final overview = itemData['overview'] ?? 'Shared movie';
                  final releaseDate =
                      DateTime.tryParse(itemData['releaseDate'] ?? '') ??
                          DateTime.now();
                  final voteAverage =
                      (itemData['voteAverage'] as num?)?.toDouble() ?? 0.0;
                  final genreIds = (itemData['genreIds'] as List?)
                          ?.map((e) => e as int)
                          .toList() ??
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

                  // Get SharedPreferences and create FavoritesServiceManager.
                  final prefs = await SharedPreferences.getInstance();
                  if (!context.mounted) return;

                  final favoritesServiceManager =
                      FavoritesServiceManager(prefs, context, widget);
                  final favoritesService =
                      FavoritesServiceAdapter(favoritesServiceManager);

                  // Navigate to MovieDetailsScreen with shared movie data.
                  if (context.mounted) {
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
              } catch (e) {
                debugPrint('Error navigating: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error opening: $movieTitle'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with movie icon and title.

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          itemData['type'] == 'movieList'
                              ? Icons.playlist_play
                              : Icons.movie,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemData['type'] == 'movieList'
                                  ? 'List: ${itemData['listName'] ?? movieTitle}'
                                  : movieTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (itemData['type'] == 'movieList') ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.movie,
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${itemData['movieCount'] ?? 0} movies',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (rating != null) ...[
                              const SizedBox(height: 4),
                              _buildRatingDisplay(rating),
                            ],
                          ],
                        ),
                      ),
                      if (isUserRatedMovie && canShare) ...[
                        IconButton(
                          onPressed: () async {
                            // Create Movie object
                            final movieId = int.tryParse(
                                    itemData['movieId']?.toString() ?? '0') ??
                                0;
                            final posterUrl = itemData['posterUrl'] ?? '';
                            final backdropUrl =
                                itemData['backdropUrl'] ?? posterUrl ?? '';
                            final overview =
                                itemData['overview'] ?? 'My rated movie';
                            final releaseDate = DateTime.tryParse(
                                    itemData['releaseDate'] ?? '') ??
                                DateTime.now();
                            final voteAverage =
                                (itemData['voteAverage'] as num?)?.toDouble() ??
                                    0.0;
                            final genreIds = (itemData['genreIds'] as List?)
                                    ?.map((e) => e as int)
                                    .toList() ??
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

                            // Use the movie file path from the URL.

                            await _shareMovie(movie, resourceUrl);
                          },
                          icon: const Icon(Icons.share),
                          tooltip: 'Share this movie with others',
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            foregroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ] else
                        _buildPermissionsBadge(permissions),
                    ],
                  ),

                  // Movie/List details.

                  if (comments.isNotEmpty ||
                      (itemData['type'] == 'movieList' &&
                          itemData['description'] != null &&
                          itemData['description'].toString().isNotEmpty)) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.comment,
                                size: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                itemData['type'] == 'movieList'
                                    ? 'Description:'
                                    : 'Review:',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            itemData['type'] == 'movieList'
                                ? (itemData['description'] ?? '')
                                : comments,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Sharing info or ownership info.

                  Row(
                    children: [
                      Expanded(
                        child: isUserRatedMovie
                            ? const SizedBox.shrink()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Owner: ${_getOwnerName(owner)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.share,
                                        size: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Shared by: ${_getOwnerName(sharedBy)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isUserRatedMovie
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1)
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isUserRatedMovie ? Icons.edit : Icons.visibility,
                          size: 16,
                          color: isUserRatedMovie
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
