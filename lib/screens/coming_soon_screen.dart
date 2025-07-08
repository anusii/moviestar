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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/database/movie_cache_repository.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/utils/date_format_util.dart';
import 'package:moviestar/widgets/error_display_widget.dart';
import 'package:moviestar/widgets/movie_card.dart';

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

    ref.invalidate(upcomingMoviesWithCacheInfoProvider);

    // Force refresh through the cached service.

    final cachedService = ref.read(configuredCachedMovieServiceProvider);
    await cachedService.forceRefresh(CacheCategory.upcoming);
  }

  @override
  Widget build(BuildContext context) {
    final upcomingMoviesAsync = ref.watch(upcomingMoviesWithCacheInfoProvider);
    final cacheOnlyMode = ref.watch(cacheOnlyModeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Row(
          children: [
            Text(
              'Coming Soon',
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
            const SizedBox(width: 8),
            _buildCacheIndicator(upcomingMoviesAsync, cacheOnlyMode),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _forceRefresh,
            tooltip: 'Refresh upcoming movies',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _forceRefresh,
        child: upcomingMoviesAsync.when(
          data: (cacheResult) => ListView.builder(
            itemCount: cacheResult.data.length,
            itemBuilder: (context, index) {
              final movie = cacheResult.data[index];
              return MovieCard.listItem(
                movie: movie,
                fromCache: cacheResult.fromCache,
                cacheAge: cacheResult.cacheAge,
                cacheOnlyMode: cacheOnlyMode,
                customSubtitle: Text(
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

  /// Builds cache indicator for the app bar.

  Widget _buildCacheIndicator(
    AsyncValue<CacheResult<List<Movie>>> upcomingMoviesAsync,
    bool cacheOnlyMode,
  ) {
    return upcomingMoviesAsync.when(
      data: (cacheResult) {
        if (cacheOnlyMode) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.offline_pin, size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'OFFLINE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        final color = cacheResult.fromCache ? Colors.green : Colors.blue;
        final icon = cacheResult.fromCache ? Icons.offline_bolt : Icons.wifi;
        final text = cacheResult.fromCache ? 'CACHED' : 'LIVE';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
