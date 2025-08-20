/// Screen for managing the user's list of watched movies.
///
// Time-stamp: <Thursday 2025-04-10 11:47:48 +1000 Graham Williams>
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
/// Authors: Kevin Wang

library;

import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import '../models/movie.dart';
import '../services/favorites_service.dart';
import '../services/favorites_service_adapter.dart';
import '../services/movie_list_service.dart';
import '../services/user_profile_service.dart';
import '../utils/movie_sort_util.dart';
import '../widgets/share_list_dialog.dart';
import '../widgets/sort_controls.dart';
import 'movie_details_screen.dart';

/// A screen that displays the user's list of watched movies.

class WatchedScreen extends StatefulWidget {
  /// Service for managing favorite movies.

  final FavoritesService favoritesService;

  /// Creates a new [WatchedScreen] widget.

  const WatchedScreen({super.key, required this.favoritesService});

  @override
  State<WatchedScreen> createState() => _WatchedScreenState();
}

/// State class for the watched screen.

class _WatchedScreenState extends State<WatchedScreen> {
  /// Currently selected sort criteria.
  MovieSortCriteria _sortCriteria = MovieSortCriteria.nameAsc;

  // Share the Watched list as a movie list.

  Future<void> _shareWatchedList() async {
    try {
      // Check if the favorites service supports POD storage.

      if (widget.favoritesService is! FavoritesServiceAdapter) {
        _showErrorSnackBar('POD storage is required for sharing lists');
        return;
      }

      final adapter = widget.favoritesService as FavoritesServiceAdapter;
      if (!adapter.isPodStorageEnabled) {
        _showErrorSnackBar('POD storage must be enabled to share lists');
        return;
      }

      // Create UserProfileService and get the standard Watched list ID.

      final userProfileService = UserProfileService(context, widget);
      final movieListService =
          MovieListService(context, widget, userProfileService);
      final watchedListId =
          await movieListService.getOrCreateStandardMovieList('watched');

      if (watchedListId == null) {
        _showErrorSnackBar('Could not access Watched list');
        return;
      }

      if (!mounted) {
        return;
      }

      // Show the share dialog.

      final result = await ShareListDialog.show(
        context: context,
        listId: watchedListId,
        movieListService: movieListService,
        onShared: () {
          _showSuccessSnackBar('Watched list shared successfully!');
        },
      );

      if (result == true) {
        // Additional success handling if needed.
      }
    } catch (e) {
      _showErrorSnackBar('Error sharing list: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareWatchedList,
            tooltip: 'Share Watched List',
          ),
        ],
      ),
      body: Column(
        children: [
          SortControls(
            selectedCriteria: _sortCriteria,
            onSortChanged: (criteria) {
              setState(() {
                _sortCriteria = criteria;
              });
            },
          ),
          Expanded(
            child: StreamBuilder<List<Movie>>(
              stream: widget.favoritesService.watchedMovies,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final movies = sortMovies(snapshot.data!, _sortCriteria);

                if (movies.isEmpty) {
                  return Center(
                    child: Text(
                      'Your watched list is empty',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    final movie = movies[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: movie.posterUrl,
                          width: 50,
                          height: 75,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                      title: Text(
                        movie.title,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      subtitle: Text(
                        '⭐ ${movie.voteAverage.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          widget.favoritesService.removeFromWatched(movie);
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
