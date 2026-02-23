/// File handling operations for POD favorites service.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Ashley Tang, Kevin Wang

library;

import 'dart:async';

import 'package:moviestar/core/services/pod/favorites_file_manager.dart';
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
    final movieListData = await _fileManager.parseMovieListData(ttlContent);
    if (movieListData != null) {
      // Load full movie details for each placeholder movie.

      final fullMovies = <Movie>[];
      for (int i = 0; i < movieListData.length; i++) {
        final placeholderMovie = movieListData[i];

        try {
          // Load full movie details from individual movie file.

          final fullMovie =
              await _fileManager.loadFullMovieDetails(placeholderMovie);
          fullMovies.add(fullMovie ?? placeholderMovie);
        } catch (e) {
          fullMovies.add(placeholderMovie);
        }
      }
      return fullMovies;
    }

    return movieListData ?? [];
  }

  /// Loads favorites data from POD files.

  Future<Map<String, List<Movie>>> loadFavoritesData() async {
    final toWatchData =
        await safeReadFile('moviestar/data/user_lists/to_watch.ttl');
    final watchedData =
        await safeReadFile('moviestar/data/user_lists/watched.ttl');

    final result = <String, List<Movie>>{};

    if (toWatchData != null && toWatchData.isNotEmpty) {
      final movies = await parseMoviesFromTtl(toWatchData);
      result['toWatch'] = movies;
    } else {
      result['toWatch'] = [];
    }

    if (watchedData != null && watchedData.isNotEmpty) {
      final movies = await parseMoviesFromTtl(watchedData);
      result['watched'] = movies;
    } else {
      result['watched'] = [];
    }

    return result;
  }

  /// Gets a movie by ID from cache or file manager.

  Future<Movie?> getMovie(int movieId) async {
    return await _fileManager.loadMovieData(movieId);
  }
}
