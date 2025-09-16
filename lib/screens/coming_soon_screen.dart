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

import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/core/services/favorites/favorites_service.dart';
import 'package:moviestar/utils/date_format_util.dart';
import 'package:moviestar/widgets/base_screen.dart';
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

class _ComingSoonScreenState extends ConsumerState<ComingSoonScreen>
    with ScreenStateMixin {
  /// Forces refresh of upcoming movies data.

  Future<void> _forceRefresh() async {
    // Invalidate the provider to force refresh.

    ref.invalidate(upcomingMoviesWithCacheInfoProvider);

    // Force refresh through the cached service.

    final cachedService = ref.read(configuredCachedMovieServiceProvider);
    await cachedService.forceRefreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final upcomingMoviesAsync = ref.watch(upcomingMoviesWithCacheInfoProvider);
    final cacheOnlyMode = ref.watch(cacheOnlyModeProvider);

    return BaseScreen(
      title: 'Coming Soon',
      enableRefresh: true,
      onRefresh: _forceRefresh,
      body: upcomingMoviesAsync.when(
        data: (cacheResult) => ListView.builder(
          itemCount: cacheResult.data.length,
          itemBuilder: (context, index) {
            final movie = cacheResult.data[index];
            return MovieCard.listItem(
              movie: movie,
              fromCache: cacheResult.fromCache,
              cacheAge: cacheResult.cacheAge,
              cacheOnlyMode: cacheOnlyMode,
              favoritesService: widget.favoritesService,
              parentWidget: widget,
              customSubtitle: Row(
                children: [
                  Text(
                    'Release: ${DateFormatUtil.formatNumeric(movie.releaseDate)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (movie.contentType != null) ...[
                    const Text(' • '),
                    Text(
                      movie.contentType == ContentType.movie ? '🎬' : '📺',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Text(' '),
                    Text(
                      movie.contentType == ContentType.movie
                          ? 'Movie'
                          : 'TV Show',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ],
              ),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorDisplayWidget(
          message: 'Failed to load upcoming movies',
          onRetry: _forceRefresh,
        ),
      ),
    );
  }
}
