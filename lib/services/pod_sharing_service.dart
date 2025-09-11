/// POD Sharing Service for MovieStar.
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
/// Authors: Software Innovation Institute

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart' show SolidFunctionCallStatus, getWebId;
// ignore: implementation_imports
import 'package:solidpod/src/solid/constants/web_acl.dart' show RecipientType;

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/pod_file_operations_service.dart';
import 'package:moviestar/utils/turtle_serializer.dart';

/// Request model for sharing a file
class ShareRequest {
  final String fileName;
  final String displayName;
  final List<String> permissions;
  final String recipientWebId;
  final RecipientType recipientType;
  final Map<String, dynamic>? metadata;

  const ShareRequest({
    required this.fileName,
    required this.displayName,
    required this.permissions,
    required this.recipientWebId,
    this.recipientType = RecipientType.individual,
    this.metadata,
  });
}

/// Result model for sharing operations
class ShareResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? metadata;
  final SolidFunctionCallStatus? status;

  const ShareResult({
    required this.success,
    this.error,
    this.metadata,
    this.status,
  });

  factory ShareResult.success({Map<String, dynamic>? metadata}) {
    return ShareResult(
      success: true,
      metadata: metadata,
    );
  }

  factory ShareResult.failure(String error, {SolidFunctionCallStatus? status}) {
    return ShareResult(
      success: false,
      error: error,
      status: status,
    );
  }
}

/// Request model for batch sharing
class BatchShareRequest {
  final List<ShareRequest> requests;
  final String recipientWebId;
  final bool stopOnError;

  const BatchShareRequest({
    required this.requests,
    required this.recipientWebId,
    this.stopOnError = false,
  });
}

/// Result model for batch sharing operations
class BatchShareResult {
  final List<ShareResult> results;
  final int successCount;
  final int failureCount;
  final bool allSuccessful;

  BatchShareResult({
    required this.results,
  })  : successCount = results.where((r) => r.success).length,
        failureCount = results.where((r) => !r.success).length,
        allSuccessful = results.every((r) => r.success);
}

/// Permission request model
class PermissionRequest {
  final String fileName;
  final String webId;
  final List<String> permissions;
  final RecipientType recipientType;

  const PermissionRequest({
    required this.fileName,
    required this.webId,
    required this.permissions,
    this.recipientType = RecipientType.individual,
  });
}

/// Permission result model
class PermissionResult {
  final bool granted;
  final String? error;
  final SolidFunctionCallStatus? status;

  const PermissionResult({
    required this.granted,
    this.error,
    this.status,
  });
}

/// Service class for POD sharing operations
class PodSharingService {
  static final Map<String, bool> _webIdValidationCache = {};
  static const Duration _cacheExpiration = Duration(minutes: 5);
  static final Map<String, DateTime> _cacheTimestamps = {};

  /// Get the current user's WebID
  static Future<String?> getCurrentWebId() async {
    try {
      final webId = await getWebId();
      return webId;
    } catch (e) {
      debugPrint('Error getting WebID: $e');
      return null;
    }
  }

  /// Validate a WebID (with caching)
  static Future<bool> validateWebId(String webId) async {
    if (webId.isEmpty) return false;

    // Check cache
    final cacheKey = webId.toLowerCase();
    if (_webIdValidationCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheExpiration) {
        return _webIdValidationCache[cacheKey] ?? false;
      }
    }

    // Basic validation
    final isValid = _isValidWebIdFormat(webId);

    // Cache result
    _webIdValidationCache[cacheKey] = isValid;
    _cacheTimestamps[cacheKey] = DateTime.now();

    return isValid;
  }

  /// Check if WebID format is valid
  static bool _isValidWebIdFormat(String webId) {
    // Basic WebID format validation
    if (!webId.startsWith('http://') && !webId.startsWith('https://')) {
      return false;
    }

    try {
      final uri = Uri.parse(webId);
      return uri.hasAuthority && uri.path.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Share a single file (Note: This is a simplified version for testing)
  /// In real implementation, this would need BuildContext and Widget parameters
  static Future<ShareResult> shareFile(ShareRequest request) async {
    try {
      // Note: In real implementation, we would need BuildContext for these calls:
      // await loginIfRequired(context);
      // await getKeyFromUserIfRequired(context, widget);

      // Validate WebID
      if (!await validateWebId(request.recipientWebId)) {
        return ShareResult.failure('Invalid WebID: ${request.recipientWebId}');
      }

      // Note: In real implementation, we would use the actual grantPermission call:
      // final result = await grantPermission(
      //   request.fileName,
      //   true, // fileFlag
      //   request.permissions,
      //   request.recipientType,
      //   [request.recipientWebId],
      //   ownerWebId,
      //   context,
      //   widget,
      //   isExternalRes: false,
      // );

      // For now, simulate success for testing
      return ShareResult.success(
        metadata: {
          'fileName': request.fileName,
          'displayName': request.displayName,
          'recipientWebId': request.recipientWebId,
          'permissions': request.permissions,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      return ShareResult.failure('Error sharing file: $e');
    }
  }

  /// Share multiple files
  static Future<BatchShareResult> shareMultipleFiles(
    List<ShareRequest> requests, {
    bool stopOnError = false,
  }) async {
    final results = <ShareResult>[];

    for (final request in requests) {
      final result = await shareFile(request);
      results.add(result);

      if (!result.success && stopOnError) {
        break;
      }
    }

    return BatchShareResult(results: results);
  }

  /// Grant permissions for a file (Note: Simplified for testing)
  /// In real implementation, this would need BuildContext and Widget parameters
  static Future<PermissionResult> grantPermissions(
    PermissionRequest request,
  ) async {
    try {
      // Note: In real implementation, we would need BuildContext for these calls:
      // await loginIfRequired(context);
      // await getKeyFromUserIfRequired(context, widget);

      // For testing, simulate success
      return const PermissionResult(
        granted: true,
        error: null,
      );
    } catch (e) {
      return PermissionResult(
        granted: false,
        error: 'Error granting permissions: $e',
      );
    }
  }

  /// Perform batch sharing with progress callback
  static Future<BatchShareResult> performBatchShare(
    BatchShareRequest request, {
    void Function(int completed, int total)? onProgress,
  }) async {
    final results = <ShareResult>[];
    int completed = 0;

    for (final shareRequest in request.requests) {
      final result = await shareFile(
        ShareRequest(
          fileName: shareRequest.fileName,
          displayName: shareRequest.displayName,
          permissions: shareRequest.permissions,
          recipientWebId: request.recipientWebId,
          recipientType: shareRequest.recipientType,
          metadata: shareRequest.metadata,
        ),
      );

      results.add(result);
      completed++;

      onProgress?.call(completed, request.requests.length);

      if (!result.success && request.stopOnError) {
        break;
      }
    }

    return BatchShareResult(results: results);
  }

  /// Clear WebID validation cache
  static void clearCache() {
    _webIdValidationCache.clear();
    _cacheTimestamps.clear();
  }

  /// Get sharing status message
  static String getStatusMessage(SolidFunctionCallStatus status) {
    switch (status) {
      case SolidFunctionCallStatus.success:
        return 'Successfully shared';
      case SolidFunctionCallStatus.fail:
        return 'Failed to share';
      case SolidFunctionCallStatus.notLoggedIn:
        return 'Not logged in to POD';
      default:
        return 'Unknown status: ${status.name}';
    }
  }

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
      if (!await validateWebId(recipientWebId)) {
        return ShareResult.failure('Invalid recipient WebID: $recipientWebId');
      }

      // Check if movie file exists
      // ignore: use_build_context_synchronously
      if (!await movieFileExists(movie, context, child)) {
        return ShareResult.failure('Movie file does not exist for sharing');
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

      return await shareFile(shareRequest);
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

    return await performBatchShare(batchRequest, onProgress: onProgress);
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
