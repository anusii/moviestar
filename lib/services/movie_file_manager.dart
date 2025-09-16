/// Manages movie file operations for POD sharing.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/models/sharing_models.dart';
import 'package:moviestar/core/services/pod/pod_file_operations_service.dart';
import 'package:moviestar/services/share_operation_handler.dart';
import 'package:moviestar/services/webid_validator.dart';
import 'package:moviestar/utils/turtle_serializer.dart';

/// Handles movie file operations for POD sharing.
class MovieFileManager {
  /// Generate movie file name based on content type
  static String getMovieFileName(Movie movie) {
    final contentPrefix =
        movie.contentType == ContentType.tvShow ? 'TVShow' : 'Movie';
    return 'movies/$contentPrefix-${movie.id}.ttl';
  }

  /// Check if a movie file exists in POD
  static Future<bool> movieFileExists(
    Movie movie,
    BuildContext context,
    Widget child,
  ) async {
    final fileName = getMovieFileName(movie);
    return PodFileOperationsService.fileExists(fileName, context, child);
  }

  /// Read movie data from POD
  static Future<Map<String, dynamic>?> readMovieData(
    Movie movie,
    BuildContext context,
    Widget child,
  ) async {
    final fileName = getMovieFileName(movie);
    final result =
        await PodFileOperationsService.readFile(fileName, context, child);

    if (result.success && result.data != null) {
      try {
        return TurtleSerializer.movieWithUserDataFromTurtle(result.data!);
      } catch (e) {
        debugPrint('Error parsing movie data: $e');
        return null;
      }
    }

    return null;
  }

  /// Write movie data to POD
  static Future<bool> writeMovieData(
    Movie movie,
    BuildContext context,
    Widget child, {
    double? rating,
    String? comment,
  }) async {
    final fileName = getMovieFileName(movie);
    final ttlContent = TurtleSerializer.movieWithUserDataToTurtleOntology(
      movie,
      rating,
      comment,
    );

    final result = await PodFileOperationsService.writeFile(
      fileName,
      ttlContent,
      context,
      child,
      encrypted: false,
    );

    return result.success;
  }

  /// Share a movie file with enhanced error handling
  static Future<ShareResult> shareMovieFile(
    Movie movie,
    String recipientWebId,
    BuildContext context,
    Widget child, {
    List<String> permissions = const ['read'],
  }) async {
    try {
      // Validate WebID first
      if (!await WebIdValidator.validateWebId(recipientWebId)) {
        return ShareResult.failure('Invalid recipient WebID: $recipientWebId');
      }

      // Check if context is still mounted before checking movie file
      if (!context.mounted) {
        return ShareResult.failure('Context no longer mounted');
      }

      // Check if movie file exists
      if (!await movieFileExists(movie, context, child)) {
        return ShareResult.failure('Movie file does not exist for sharing');
      }

      if (!context.mounted) {
        return ShareResult.failure('Context no longer mounted');
      }

      final fileName = getMovieFileName(movie);

      // Create share request
      final shareRequest = ShareRequest(
        fileName: fileName,
        displayName: movie.title,
        permissions: permissions,
        recipientWebId: recipientWebId,
        metadata: {
          'movieId': movie.id,
          'movieTitle': movie.title,
          'contentType': movie.contentType?.toString() ?? 'movie',
        },
      );

      return await ShareOperationHandler.shareFile(
        shareRequest,
        context,
        child,
      );
    } catch (e) {
      return ShareResult.failure('Error sharing movie file: $e');
    }
  }

  /// Batch share multiple movie files
  static Future<BatchShareResult> shareMultipleMovieFiles(
    List<Movie> movies,
    String recipientWebId,
    BuildContext context,
    Widget child, {
    List<String> permissions = const ['read'],
    void Function(int completed, int total)? onProgress,
  }) async {
    final shareRequests = movies
        .map(
          (movie) => ShareRequest(
            fileName: getMovieFileName(movie),
            displayName: movie.title,
            permissions: permissions,
            recipientWebId: recipientWebId,
            metadata: {
              'movieId': movie.id,
              'movieTitle': movie.title,
              'contentType': movie.contentType?.toString() ?? 'movie',
            },
          ),
        )
        .toList();

    final batchRequest = BatchShareRequest(
      requests: shareRequests,
      recipientWebId: recipientWebId,
    );

    return await ShareOperationHandler.performBatchShare(
      batchRequest,
      context,
      child,
      onProgress: onProgress,
    );
  }

  /// Create or update a movie file with user data
  static Future<bool> createOrUpdateMovieFile(
    Movie movie,
    BuildContext context,
    Widget child, {
    double? rating,
    String? comment,
  }) async {
    // Read existing data first to preserve any existing rating/comment
    final existingData = await readMovieData(movie, context, child);
    final existingRating = existingData?['rating'] as double?;
    final existingComment = existingData?['comment'] as String?;

    // Use provided parameters, fallback to existing data
    final finalRating = rating ?? existingRating;
    final finalComment = comment ?? existingComment;

    // ignore: use_build_context_synchronously
    return await writeMovieData(
      movie,
      context, // ignore: use_build_context_synchronously
      child,
      rating: finalRating,
      comment: finalComment,
    );
  }
}
