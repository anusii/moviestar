/// Main home screen of the Movie Star application, displaying featured and trending movies.
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
/// Authors: Kevin Wang, Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/providers/theme_provider.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/screens/search_screen.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/widgets/error_display_widget.dart';

/// A screen that displays various movie categories and trending content with caching.

class HomeScreen extends ConsumerStatefulWidget {
  /// Service for managing favorite movies.

  final FavoritesService favoritesService;

  /// Creates a new [HomeScreen] widget.

  const HomeScreen({super.key, required this.favoritesService});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

/// State class for the home screen.

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Map of scroll controllers for different movie categories.

  final Map<String, ScrollController> _scrollControllers = {};

  @override
  void initState() {
    super.initState();
    _scrollControllers['popular'] = ScrollController();
    _scrollControllers['nowPlaying'] = ScrollController();
    _scrollControllers['topRated'] = ScrollController();
    _scrollControllers['upcoming'] = ScrollController();
  }

  @override
  void dispose() {
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Builds a horizontal scrollable row of movies.

  Widget _buildMovieRow(
    String title,
    AsyncValue<List<Movie>> moviesAsync,
    String key,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).textTheme.headlineMedium?.color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: moviesAsync.when(
            data: (movies) => Scrollbar(
              controller: _scrollControllers[key],
              thickness: 6,
              radius: const Radius.circular(3),
              thumbVisibility: true,
              child: ListView.builder(
                controller: _scrollControllers[key],
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  final movie = movies[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: movie.posterUrl,
                          width: 130,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => ErrorDisplayWidget.compact(
              message: 'Failed to load $title',
              onRetry: () {
                ref.invalidate(popularMoviesProvider);
                ref.invalidate(nowPlayingMoviesProvider);
                ref.invalidate(topRatedMoviesProvider);
                ref.invalidate(upcomingMoviesProvider);
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Forces refresh of all movie data.

  Future<void> _forceRefresh() async {
    // Invalidate all providers to force refresh.

    ref.invalidate(popularMoviesProvider);
    ref.invalidate(nowPlayingMoviesProvider);
    ref.invalidate(topRatedMoviesProvider);
    ref.invalidate(upcomingMoviesProvider);
    ref.invalidate(cacheStatsProvider);

    // Force refresh through the cached service.

    final cachedService = ref.read(configuredCachedMovieServiceProvider);
    await cachedService.forceRefreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final popularMovies = ref.watch(popularMoviesProvider);
    final nowPlayingMovies = ref.watch(nowPlayingMoviesProvider);
    final topRatedMovies = ref.watch(topRatedMoviesProvider);
    final upcomingMovies = ref.watch(upcomingMoviesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: const Text(
          'MOVIE STAR',
          style: TextStyle(
            color: Colors.red,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding:
                const EdgeInsets.only(right: 60.0), // Space for debug banner
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _forceRefresh,
                  tooltip: 'Refresh data',
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    final movieService = ref.read(movieServiceProvider);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchScreen(
                          favoritesService: widget.favoritesService,
                          movieService: movieService,
                        ),
                      ),
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final themeMode = ref.watch(themeModeProvider);
                    final isDarkMode = themeMode == ThemeMode.dark;
                    return IconButton(
                      icon: Icon(
                        isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      ),
                      onPressed: () async {
                        await ref
                            .read(themeModeProvider.notifier)
                            .toggleTheme();
                      },
                      tooltip: isDarkMode
                          ? 'Switch to light mode'
                          : 'Switch to dark mode',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _forceRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMovieRow('Popular on Movie Star', popularMovies, 'popular'),
              _buildMovieRow('Now Playing', nowPlayingMovies, 'nowPlaying'),
              _buildMovieRow('Top Rated', topRatedMovies, 'topRated'),
              _buildMovieRow('Upcoming', upcomingMovies, 'upcoming'),
            ],
          ),
        ),
      ),
    );
  }
}
