/// Screen displaying upcoming movies and their release dates.
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

import 'package:moviestar/database/movie_cache_repository.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/providers/theme_provider.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/utils/date_format_util.dart';
import 'package:moviestar/widgets/error_display_widget.dart';

/// A screen that displays upcoming movies and their release dates with caching.

class ComingSoonScreen extends ConsumerStatefulWidget {
  /// Service for managing favorite movies.

  final FavoritesService favoritesService;

  /// Creates a new [ComingSoonScreen] widget.

  const ComingSoonScreen({super.key, required this.favoritesService});

  @override
  ConsumerState<ComingSoonScreen> createState() => _ComingSoonScreenState();
}

/// State class for the coming soon screen.

class _ComingSoonScreenState extends ConsumerState<ComingSoonScreen> {
  /// Forces refresh of upcoming movies data.

  Future<void> _forceRefresh() async {
    // Invalidate the provider to force refresh.

    ref.invalidate(upcomingMoviesProvider);

    // Force refresh through the cached service.

    final cachedService = ref.read(configuredCachedMovieServiceProvider);
    await cachedService.forceRefresh(CacheCategory.upcoming);
  }

  @override
  Widget build(BuildContext context) {
    final upcomingMoviesAsync = ref.watch(upcomingMoviesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          'Coming Soon',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 60.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _forceRefresh,
                  tooltip: 'Refresh upcoming movies',
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
        child: upcomingMoviesAsync.when(
          data: (movies) => ListView.builder(
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
                  'Release Date: ${DateFormatUtil.formatNumeric(movie.releaseDate)}',
                  style: const TextStyle(color: Colors.grey),
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
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ErrorDisplayWidget(
            message: 'Failed to load upcoming movies',
            onRetry: _forceRefresh,
          ),
        ),
      ),
    );
  }
}
