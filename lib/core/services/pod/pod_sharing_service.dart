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
/// Authors: Software Innovation Institute.

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart' show SolidFunctionCallStatus;

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/models/sharing_models.dart';
import 'package:moviestar/services/movie_file_manager.dart';
import 'package:moviestar/services/share_operation_handler.dart';
import 'package:moviestar/services/webid_validator.dart';

/// Service class for POD sharing operations.
class PodSharingService {
  /// Get the current user's WebID.
  static Future<String?> getCurrentWebId() async {
    return ShareOperationHandler.getCurrentWebId();
  }

  /// Validate a WebID (with caching).
  static Future<bool> validateWebId(String webId) async {
    return WebIdValidator.validateWebId(webId);
  }

  /// Share a single file using real POD permission granting.
  static Future<ShareResult> shareFile(
    ShareRequest request,
    BuildContext context,
    Widget widget,
  ) async {
    return ShareOperationHandler.shareFile(request, context, widget);
  }

  /// Share multiple files.
  static Future<BatchShareResult> shareMultipleFiles(
    List<ShareRequest> requests,
    BuildContext context,
    Widget widget, {
    bool stopOnError = false,
  }) async {
    return ShareOperationHandler.shareMultipleFiles(
      requests,
      context,
      widget,
      stopOnError: stopOnError,
    );
  }

  /// Grant permissions for a file using real POD calls.
  static Future<PermissionResult> grantPermissions(
    PermissionRequest request,
    BuildContext context,
    Widget widget,
  ) async {
    return ShareOperationHandler.grantPermissions(request, context, widget);
  }

  /// Perform batch sharing with progress callback.
  static Future<BatchShareResult> performBatchShare(
    BatchShareRequest request,
    BuildContext context,
    Widget widget, {
    void Function(int completed, int total)? onProgress,
  }) async {
    return ShareOperationHandler.performBatchShare(
      request,
      context,
      widget,
      onProgress: onProgress,
    );
  }

  /// Clear WebID validation cache.
  static void clearCache() {
    WebIdValidator.clearCache();
  }

  /// Get sharing status message.
  static String getStatusMessage(SolidFunctionCallStatus status) {
    return ShareOperationHandler.getStatusMessage(status);
  }

  /// Generate movie file name based on content type.
  static String getMovieFileName(Movie movie) {
    return MovieFileManager.getMovieFileName(movie);
  }

  /// Check if a movie file exists in POD.
  static Future<bool> movieFileExists(
    Movie movie,
    BuildContext context,
    Widget child,
  ) async {
    return MovieFileManager.movieFileExists(movie, context, child);
  }

  /// Read movie data from POD.
  static Future<Map<String, dynamic>?> readMovieData(
    Movie movie,
    BuildContext context,
    Widget child,
  ) async {
    return MovieFileManager.readMovieData(movie, context, child);
  }

  /// Write movie data to POD.
  static Future<bool> writeMovieData(
    Movie movie,
    BuildContext context,
    Widget child, {
    double? rating,
    String? comment,
  }) async {
    return MovieFileManager.writeMovieData(
      movie,
      context,
      child,
      rating: rating,
      comment: comment,
    );
  }

  /// Share a movie file with enhanced error handling.
  static Future<ShareResult> shareMovieFile(
    Movie movie,
    String recipientWebId,
    BuildContext context,
    Widget child, {
    List<String> permissions = const ['read'],
  }) async {
    return MovieFileManager.shareMovieFile(
      movie,
      recipientWebId,
      context,
      child,
      permissions: permissions,
    );
  }

  /// Batch share multiple movie files.
  static Future<BatchShareResult> shareMultipleMovieFiles(
    List<Movie> movies,
    String recipientWebId,
    BuildContext context,
    Widget child, {
    List<String> permissions = const ['read'],
    void Function(int completed, int total)? onProgress,
  }) async {
    return MovieFileManager.shareMultipleMovieFiles(
      movies,
      recipientWebId,
      context,
      child,
      permissions: permissions,
      onProgress: onProgress,
    );
  }

  /// Create or update a movie file with user data.
  static Future<bool> createOrUpdateMovieFile(
    Movie movie,
    BuildContext context,
    Widget child, {
    double? rating,
    String? comment,
  }) async {
    return MovieFileManager.createOrUpdateMovieFile(
      movie,
      context,
      child,
      rating: rating,
      comment: comment,
    );
  }
}
