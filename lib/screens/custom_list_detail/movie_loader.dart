/// Movie loading helper for custom list detail screen.
/// Extracted to reduce file size and improve organization.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';

/// Handles movie loading functionality for custom lists.
class MovieLoader {
  /// Load movies from API for a custom list.
  static Future<Map<int, Movie>> loadMoviesFromAPI(
    WidgetRef ref,
    List<int> movieIds,
    Function(int, Movie) onMovieLoaded,
    Function(int, String) onMovieError,
  ) async {
    final moviesMap = <int, Movie>{};
    final cachedMovieService = ref.read(cachedMovieServiceProvider);

    // Load movies in batches for better performance.

    const batchSize = 10;
    for (int i = 0; i < movieIds.length; i += batchSize) {
      final end =
          (i + batchSize < movieIds.length) ? i + batchSize : movieIds.length;
      final batch = movieIds.sublist(i, end);

      await Future.wait(
        batch.map((movieId) async {
          try {
            final movie = await cachedMovieService.getMovieDetails(movieId);
            moviesMap[movieId] = movie;
            onMovieLoaded(movieId, movie);
          } catch (e) {
            onMovieError(movieId, e.toString());
          }
        }),
      );
    }

    return moviesMap;
  }

  /// Get content as Movie with type.
  static Future<Movie> getContentAsMovieWithType(
    WidgetRef ref,
    int contentId,
  ) async {
    final cachedMovieService = ref.read(cachedMovieServiceProvider);
    final contentService = ref.read(contentServiceProvider);

    // First try as movie.

    try {
      final movie = await cachedMovieService.getMovieDetails(contentId);
      return movie;
    } catch (_) {
      // Try as TV show if movie fails.
    }

    // Try as TV show.

    try {
      final tvShow = await contentService.getTVDetails(contentId);
      return Movie.fromContentItem(tvShow);
    } catch (_) {
      // Handle error.
    }

    throw Exception('Content not found');
  }

  /// Retry loading a specific movie.
  static Future<void> retryLoadMovie(
    WidgetRef ref,
    int movieId,
    Map<int, Movie> moviesMap,
    Map<int, String> movieErrors,
    Function(int, Movie) onMovieLoaded,
    Function(int, String) onMovieError,
  ) async {
    // Clear any existing error.

    movieErrors.remove(movieId);

    try {
      final cachedMovieService = ref.read(cachedMovieServiceProvider);
      final movie = await cachedMovieService.getMovieDetails(movieId);

      moviesMap[movieId] = movie;
      onMovieLoaded(movieId, movie);
    } catch (e) {
      onMovieError(movieId, e.toString());
    }
  }
}
