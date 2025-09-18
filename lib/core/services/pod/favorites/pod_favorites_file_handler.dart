/// File handling operations for POD favorites service.
/// Handles TTL parsing and movie data loading operations.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:moviestar/core/services/pod/pod_favorites_file_manager.dart';
import 'package:moviestar/models/movie.dart';

/// Handles file operations for POD favorites service.
class PodFavoritesFileHandler {
  final PodFavoritesFileManager _fileManager;
  final Function(String fileName) safeReadFile;

  PodFavoritesFileHandler(
    this._fileManager,
    this.safeReadFile,
  );

  /// Parses movies from TTL content.
  Future<List<Movie>> parseMoviesFromTtl(String ttlContent) async {
    debugPrint(
      '🎬 [PodFavoritesFileHandler] Parsing TTL content (${ttlContent.length} chars)',
    );
    debugPrint(
      '🎬 [PodFavoritesFileHandler] TTL content preview: ${ttlContent.substring(0, ttlContent.length > 200 ? 200 : ttlContent.length)}...',
    );

    final movieListData = await _fileManager.parseMovieListData(ttlContent);
    if (movieListData != null) {
      debugPrint(
        '🎬 [PodFavoritesFileHandler] Parsed ${movieListData.length} placeholder movies from TTL',
      );

      // Load full movie details for each placeholder movie
      final fullMovies = <Movie>[];
      for (int i = 0; i < movieListData.length; i++) {
        final placeholderMovie = movieListData[i];
        debugPrint(
          '🎬 [PodFavoritesFileHandler] Loading full details for movie ID: ${placeholderMovie.id}',
        );

        try {
          // Load full movie details from individual movie file
          final fullMovie =
              await _fileManager.loadFullMovieDetails(placeholderMovie);
          if (fullMovie != null) {
            fullMovies.add(fullMovie);
            debugPrint(
              '🎬 [PodFavoritesFileHandler] Loaded: ${fullMovie.title} (ID: ${fullMovie.id})',
            );
          } else {
            // Fallback to placeholder if individual file doesn't exist
            debugPrint(
              '🎬 [PodFavoritesFileHandler] No individual file found, using placeholder for ID: ${placeholderMovie.id}',
            );
            fullMovies.add(placeholderMovie);
          }
        } catch (e) {
          debugPrint(
            '🎬 [PodFavoritesFileHandler] Error loading full details for movie ${placeholderMovie.id}: $e',
          );
          // Fallback to placeholder on error
          fullMovies.add(placeholderMovie);
        }
      }

      debugPrint(
        '🎬 [PodFavoritesFileHandler] Final result: ${fullMovies.length} movies with full details',
      );
      return fullMovies;
    } else {
      debugPrint(
          '🎬 [PodFavoritesFileHandler] Failed to parse movies from TTL',);
    }

    return movieListData ?? [];
  }

  /// Loads favorites data from POD files.
  Future<Map<String, List<Movie>>> loadFavoritesData() async {
    debugPrint('🎬 [PodFavoritesFileHandler] loadFavoritesData() called');

    final toWatchData =
        await safeReadFile('moviestar/data/user_lists/to_watch.ttl');
    final watchedData =
        await safeReadFile('moviestar/data/user_lists/watched.ttl');

    debugPrint(
      '🎬 [PodFavoritesFileHandler] toWatchData: ${toWatchData?.length ?? 0} chars',
    );
    debugPrint(
      '🎬 [PodFavoritesFileHandler] watchedData: ${watchedData?.length ?? 0} chars',
    );

    final result = <String, List<Movie>>{};

    if (toWatchData != null && toWatchData.isNotEmpty) {
      final movies = await parseMoviesFromTtl(toWatchData);
      debugPrint(
        '🎬 [PodFavoritesFileHandler] Parsed ${movies.length} to-watch movies',
      );
      result['toWatch'] = movies;
    } else {
      debugPrint(
        '🎬 [PodFavoritesFileHandler] No toWatch data, using empty list',
      );
      result['toWatch'] = [];
    }

    if (watchedData != null && watchedData.isNotEmpty) {
      final movies = await parseMoviesFromTtl(watchedData);
      debugPrint(
        '🎬 [PodFavoritesFileHandler] Parsed ${movies.length} watched movies',
      );
      result['watched'] = movies;
    } else {
      debugPrint(
        '🎬 [PodFavoritesFileHandler] No watched data, using empty list',
      );
      result['watched'] = [];
    }

    return result;
  }

  /// Gets a movie by ID from cache or file manager.
  Future<Movie?> getMovie(int movieId) async {
    return await _fileManager.loadMovieData(movieId);
  }
}
