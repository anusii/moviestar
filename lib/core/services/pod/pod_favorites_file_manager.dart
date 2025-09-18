/// File management operations for PodFavoritesService.
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
/// Authors: Ashley Tang.

library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:moviestar/core/services/pod/pod_file_operations_service.dart';
import 'package:moviestar/core/services/pod/pod_operations_mixin.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/utils/is_logged_in.dart';
import 'package:moviestar/utils/serializer.dart';

/// Manages movie file operations for PodFavoritesService.
/// Extracted to reduce main service file size while preserving exact behavior.
class PodFavoritesFileManager with PodOperationsMixin {
  final BuildContext _context;
  final Widget _child;

  /// Track which movies have files to avoid unnecessary reads.
  final Set<int> _moviesWithFiles = {};

  /// Track pending movie file updates to batch them.
  final Map<int, Timer> _pendingMovieUpdates = {};

  PodFavoritesFileManager(this._context, this._child);

  /// Gets the file path for a movie.
  String getMovieFilePathFor(Movie movie) {
    final contentType =
        movie.contentType == ContentType.tvShow ? 'tvShow' : 'movie';
    return getMovieFilePath(movie.id, contentType: contentType);
  }

  /// Gets the file path for a movie by movie object (compatibility method).
  String? getMovieFilePathByMovie(Movie movie) {
    return getMovieFilePathFor(movie);
  }

  /// Creates or updates a movie file with user data.
  /// Uses batching to avoid race conditions.
  Future<void> createOrUpdateMovieFile(
    Movie movie, {
    double? rating,
    String? comment,
    bool isWatched = false,
  }) async {
    // Cancel any pending update for this movie
    _pendingMovieUpdates[movie.id]?.cancel();

    // Schedule the update with a delay to batch multiple operations
    _pendingMovieUpdates[movie.id] = Timer(
      const Duration(milliseconds: 500),
      () async {
        await performMovieFileUpdate(
          movie,
          rating: rating,
          comment: comment,
          isWatched: isWatched,
        );
        _pendingMovieUpdates.remove(movie.id);
      },
    );
  }

  /// Performs the actual movie file update.
  Future<void> performMovieFileUpdate(
    Movie movie, {
    double? rating,
    String? comment,
    bool isWatched = false,
  }) async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        debugPrint('❌ User not logged in, cannot update movie file');
        return;
      }

      // Read existing file to preserve data
      Map<String, dynamic>? existingData;
      final filePath = getMovieFilePathFor(movie);

      try {
        if (!_context.mounted) return;
        final readResult = await PodFileOperationsService.readFile(
          filePath,
          _context,
          _child,
        );
        if (readResult.success && (readResult.data?.isNotEmpty ?? false)) {
          existingData = TurtleSerializer.movieWithUserDataFromTurtle(
            readResult.data!,
          );
        }
      } catch (e) {
        // File doesn't exist yet, that's okay
        if (!e.toString().contains('does not exist')) {
          debugPrint('❌ Error reading existing movie file: $e');
        }
      }

      // Prepare updated data
      final currentRating = rating ?? existingData?['rating'];
      final currentComment = comment ?? existingData?['comment'];

      // Create the TTL content
      final ttlContent = TurtleSerializer.movieWithUserDataToTurtle(
        movie,
        currentRating,
        currentComment,
      );

      if (!_context.mounted) {
        debugPrint('❌ Context not mounted, cannot write movie file');
        return;
      }

      // Write to POD
      final result = await PodFileOperationsService.writeFile(
        filePath,
        ttlContent,
        _context,
        _child,
        encrypted: false,
      );

      if (result.success) {
        _moviesWithFiles.add(movie.id);
        debugPrint('✅ Movie file updated for ${movie.title}');
      } else {
        debugPrint('❌ Failed to write movie file for ${movie.title}');
      }
    } catch (e) {
      debugPrint('❌ Error updating movie file: $e');
    }
  }

  /// Checks if a movie has an associated file in POD.
  Future<bool> hasMovieFile(Movie movie) async {
    // Check cache first
    if (_moviesWithFiles.contains(movie.id)) {
      return true;
    }

    // Check POD
    final filePath = getMovieFilePathFor(movie);
    final fileExists = await PodFileOperationsService.fileExists(
      filePath,
      _context,
      _child,
    );

    if (fileExists) {
      _moviesWithFiles.add(movie.id);
    }

    return fileExists;
  }

  /// Reads movie file data.
  Future<Map<String, dynamic>?> readMovieFile(Movie movie) async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        return null;
      }

      final filePath = getMovieFilePathFor(movie);
      if (!_context.mounted) return null;

      final result = await PodFileOperationsService.readFile(
        filePath,
        _context,
        _child,
      );

      if (result.success && (result.data?.isNotEmpty ?? false)) {
        return TurtleSerializer.movieWithUserDataFromTurtle(result.data!);
      }
    } catch (e) {
      if (!e.toString().contains('does not exist')) {
        debugPrint('❌ Error reading movie file: $e');
      }
    }
    return null;
  }

  /// Cancels all pending movie file updates.
  void cancelPendingUpdates() {
    for (final timer in _pendingMovieUpdates.values) {
      timer.cancel();
    }
    _pendingMovieUpdates.clear();
  }

  /// Loads full movie data from POD file.
  Future<Movie?> loadMovieData(int movieId) async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) return null;

      final filePath = getMovieFilePath(movieId, contentType: 'movie');
      if (!_context.mounted) return null;

      final result = await PodFileOperationsService.readFile(
        filePath,
        _context,
        _child,
      );

      if (result.success && (result.data?.isNotEmpty ?? false)) {
        // TODO: Convert Map<String, dynamic> to Movie
        return null; // TODO: Convert Map<String, dynamic> to Movie
      }
    } catch (e) {
      debugPrint('❌ Error loading movie data for ID $movieId: $e');
    }
    return null;
  }

  /// Parses movie list data from TTL content.
  Future<List<Movie>?> parseMovieListData(String ttlContent) async {
    try {
      final movieListData = TurtleSerializer.movieListFromTurtle(ttlContent);
      if (movieListData != null) {
        return movieListData['movies'] as List<Movie>? ?? [];
      }
    } catch (e) {
      debugPrint('❌ Error parsing movie list data: $e');
    }
    return null;
  }

  /// Loads full movie details from individual movie file for a placeholder movie.
  Future<Movie?> loadFullMovieDetails(Movie placeholderMovie) async {
    try {
      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        debugPrint('❌ User not logged in, cannot load movie details');
        return null;
      }

      // Construct the path to the individual movie file
      final contentTypeStr = placeholderMovie.contentType == ContentType.tvShow
          ? 'TVShow'
          : 'Movie';
      final movieFilePath =
          'moviestar/data/movies/$contentTypeStr-${placeholderMovie.id}.ttl';

      debugPrint(
        '🎬 [PodFavoritesFileManager] Attempting to read: $movieFilePath',
      );

      if (!_context.mounted) return null;

      // Read the individual movie TTL file using POD operations
      final result = await PodFileOperationsService.readFile(
        movieFilePath,
        _context,
        _child,
      );

      if (result.success && (result.data?.isNotEmpty ?? false)) {
        debugPrint(
          '🎬 [PodFavoritesFileManager] Found movie file (${result.data!.length} chars)',
        );

        // Parse the movie details from the TTL content
        final movieList = TurtleSerializer.moviesFromTurtle(result.data!);

        if (movieList.isNotEmpty) {
          final movieData = movieList.first;
          debugPrint(
            '🎬 [PodFavoritesFileManager] Successfully parsed movie details: ${movieData.title}',
          );
          return movieData;
        } else {
          debugPrint(
            '🎬 [PodFavoritesFileManager] Failed to parse movie from TTL content - empty list',
          );
        }
      } else {
        debugPrint(
          '🎬 [PodFavoritesFileManager] Movie file not found or empty: $movieFilePath',
        );
      }
    } catch (e) {
      debugPrint(
        '❌ Error loading full movie details for ${placeholderMovie.id}: $e',
      );
    }

    return null;
  }

  /// Disposes resources.
  void dispose() {
    cancelPendingUpdates();
  }
}
