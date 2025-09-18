/// Helper class for MovieListService file operations.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:moviestar/core/services/pod/pod_file_operations_service.dart';
import 'package:moviestar/core/services/pod/pod_operations_mixin.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/utils/turtle_serializer.dart';

/// Helper class for MovieList file operations.
/// Extracted to reduce MovieListService file size.
class MovieListFileHelper with PodOperationsMixin {
  final BuildContext _context;
  final Widget _child;

  MovieListFileHelper(this._context, this._child);

  /// Creates a movie file in POD for a specific movie.
  Future<void> createMovieFile(
    Movie movie, {
    String contentType = 'movie',
  }) async {
    try {
      final movieTtl = TurtleSerializer.movieWithUserDataToTurtleOntology(
        movie,
        null, // No rating for new movie file
        null, // No comment for new movie file
      );

      final fileName = getMovieFilePath(movie.id, contentType: contentType);

      if (!_context.mounted) return;

      await PodFileOperationsService.writeFile(
        fileName,
        movieTtl,
        _context,
        _child,
        encrypted: false,
      );
    } catch (e) {
      debugPrint('❌ Error creating movie file: $e');
    }
  }

  /// Loads full movie data from individual movie file.
  Future<Movie?> loadFullMovieData(
    int movieId, {
    String contentType = 'movie',
  }) async {
    try {
      final movieFileName = 'moviestar/data/movies/Movie-$movieId.ttl';
      final tvShowFileName = 'moviestar/data/movies/TVShow-$movieId.ttl';


      if (!_context.mounted) return null;

      String result = '';

      // For TV shows, try TVShow file first, then fall back to Movie file
      if (contentType == 'tv' || contentType == 'tvShow') {
        try {
          final readResult = await PodFileOperationsService.readFile(
            tvShowFileName,
            _context,
            _child,
          );
          result = readResult.success ? (readResult.data ?? '') : '';
        } catch (e) {
          // Fall back to Movie file for backward compatibility
          if (!isFileNotFoundError(e)) {
            rethrow;
          }
          if (!_context.mounted) return null;
          final readResult = await PodFileOperationsService.readFile(
            movieFileName,
            _context,
            _child,
          );
          result = readResult.success ? (readResult.data ?? '') : '';
        }
      } else {
        // For movies, just try Movie file
        final readResult = await PodFileOperationsService.readFile(
          movieFileName,
          _context,
          _child,
        );
        result = readResult.success ? (readResult.data ?? '') : '';
      }

      if (result.isNotEmpty) {
        final movieData = TurtleSerializer.movieWithUserDataFromTurtle(result);
        if (movieData != null && movieData['movie'] is Movie) {
          final movie = movieData['movie'] as Movie;
          return movie;
        } else {
        }
      } else {
      }
    } catch (e) {
      if (!isFileNotFoundError(e)) {
        debugPrint('❌ Error loading movie data for $movieId: $e');
      }
    }
    return null;
  }

  /// Scans the user_lists directory for MovieLists.
  Future<List<String>> scanMovieListDirectory() async {
    try {
      final dirUrl = await getDirUrl('moviestar/data/user_lists');
      final resources = await getResourcesInContainer(dirUrl);

      return resources.files
          .where((f) => f.startsWith('MovieList-') && f.endsWith('.ttl'))
          .toList();
    } catch (e) {
      if (!isFileNotFoundError(e) && !isPermissionError(e)) {
        debugPrint('❌ Error scanning user_lists directory: $e');
      }
      return [];
    }
  }

  /// Finds an existing MovieList by type and name.
  Future<String?> findExistingMovieList(
    String listType,
    String displayName,
  ) async {
    try {
      final files = await scanMovieListDirectory();

      for (final fileName in files) {
        final movieListId =
            fileName.replaceAll('MovieList-', '').replaceAll('.ttl', '');

        try {
          final filePath = 'user_lists/$fileName';
          if (!_context.mounted) return null;

          final result = await PodFileOperationsService.readFile(
            'moviestar/data/$filePath',
            _context,
            _child,
          );

          if (result.success && (result.data?.isNotEmpty ?? false)) {
            if (_matchesListType(result.data!, listType, displayName)) {
              return movieListId;
            }
          }
        } catch (e) {
          debugPrint('❌ Error reading MovieList $fileName: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error finding existing MovieList: $e');
    }
    return null;
  }

  /// Gets the file path for a movie file.
  @override
  String getMovieFilePath(int movieId, {String contentType = 'movie'}) {
    final prefix =
        contentType == 'tv' || contentType == 'tvShow' ? 'TVShow' : 'Movie';
    return 'moviestar/data/movies/$prefix-$movieId.ttl';
  }

  /// Gets the file path for a MovieList file.
  @override
  String getMovieListFilePath(String movieListId) {
    return 'user_lists/MovieList-$movieListId.ttl';
  }

  bool _matchesListType(
    String ttlContent,
    String listType,
    String displayName,
  ) {
    final namePattern = RegExp(r'sdo:name\s+"([^"]+)"');
    final descPattern = RegExp(r'sdo:description\s+"([^"]+)"');

    final nameMatch = namePattern.firstMatch(ttlContent);
    if (nameMatch != null && nameMatch.group(1)!.trim() == displayName) {
      return true;
    }

    final descMatch = descPattern.firstMatch(ttlContent);
    if (descMatch != null) {
      final desc = descMatch.group(1)!.trim();

      switch (listType) {
        case 'to_watch':
          return desc.contains('want to watch') || desc.contains('to watch');
        case 'watched':
          return desc.contains('have watched') || desc.contains('you watched');
        case 'favorites':
          return desc.contains('favorite');
        default:
          return false;
      }
    }

    return false;
  }
}
