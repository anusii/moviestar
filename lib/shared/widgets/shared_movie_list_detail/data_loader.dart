/// Data loading operations for shared movie list detail screen.
/// Handles movie title loading, content fetching, and data parsing.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/shared/widgets/shared_movie_list_detail/data_loader/data_parser.dart';
import 'package:moviestar/shared/widgets/shared_movie_list_detail/data_loader/fetch_operations.dart';

// Re-export helper classes for backward compatibility.

export 'package:moviestar/shared/widgets/shared_movie_list_detail/data_loader/data_parser.dart';
export 'package:moviestar/shared/widgets/shared_movie_list_detail/data_loader/fetch_operations.dart';
export 'package:moviestar/shared/widgets/shared_movie_list_detail/data_loader/url_handlers.dart';

/// Handles data loading operations for shared movie list detail screen.

class SharedListDataLoader {
  final WidgetRef ref;
  final BuildContext context;
  final StatefulWidget widget;
  final String ownerWebId;
  final String sharedByWebId;

  SharedListDataLoader({
    required this.ref,
    required this.context,
    required this.widget,
    required this.ownerWebId,
    required this.sharedByWebId,
  });

  /// Load movie titles from TMDB API for all movies in the list.
  /// This will also detect and update content types.

  Future<Map<String, String>> loadMovieTitles(
    List<Map<String, dynamic>> movies,
  ) async {
    try {
      final cachedMovieService = ref.read(cachedMovieServiceProvider);
      final Map<String, String> titles = {};

      for (final movieData in movies) {
        final movieId =
            int.tryParse(movieData['movieId']?.toString() ?? '0') ?? 0;
        if (movieId > 0) {
          try {
            // First try to fetch enhanced data that includes content type detection and actual title.

            final enhancedData = await FetchOperations.fetchIndividualMovieData(
              context,
              widget,
              ownerWebId,
              sharedByWebId,
              movieData,
            );
            final contentType = enhancedData['content_type'] ?? 'movie';

            // Check if we got an actual title from the TTL file.

            String? actualTitle =
                DataParser.extractTitleFromEnhancedData(enhancedData);

            if (actualTitle != null) {
              // We have the actual title from the shared file.

              titles[movieId.toString()] = actualTitle;
            } else if (contentType == 'tv') {
              // For TV shows without a parsed title, use a generic title since the cachedMovieService doesn't support TV shows yet.

              titles[movieId.toString()] = 'TV Show $movieId';
            } else {
              // For movies without a parsed title, use the TMDB API.

              final movie = await cachedMovieService.getMovieDetails(movieId);
              titles[movieId.toString()] = movie.title;
            }
          } catch (e) {
            // Use content type from enhanced data if available.

            if (!context.mounted) return {};
            final enhancedData = await FetchOperations.fetchIndividualMovieData(
              context,
              widget,
              ownerWebId,
              sharedByWebId,
              movieData,
            );
            final contentType = enhancedData['content_type'] ?? 'movie';

            titles[movieId.toString()] = contentType == 'tv'
                ? 'TV Show $movieId'
                : 'Movie $movieId'; // Fallback
          }
        }
      }

      return titles;
    } catch (e) {
      return {};
    }
  }
}
