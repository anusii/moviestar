/// Batch Sharing State Management.
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
/// Authors: Ashley Tang.

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart' show SolidFunctionCallStatus;
// ignore: implementation_imports
import 'package:solidpod/src/solid/constants/web_acl.dart' show RecipientType;

import 'package:moviestar/core/services/pod/sharing_service.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/models/sharing_models.dart';

/// Manages the state and operations for batch sharing functionality.

class BatchSharingState extends ChangeNotifier {
  // Form controllers.

  final formKey = GlobalKey<FormState>();
  final webIdController = TextEditingController();
  String? validatedWebId;

  // List of all files to be shared.

  List<ShareableFile> shareableFiles = [];

  // Sharing state.

  bool isSharing = false;
  Map<String, String> sharingProgress = {}; // fileName -> status
  String currentOperation = '';

  // Results.

  Map<String, SolidFunctionCallStatus> sharingResults = {};

  @override
  void dispose() {
    webIdController.dispose();
    super.dispose();
  }

  /// Initialize the list of files to be shared.
  /// Movie files are automatically set to read-only permissions.

  void initializeShareableFiles(
    String listId,
    String listName,
    List<Movie> movies,
  ) {
    shareableFiles = [
      // Movie list file.

      ShareableFile(
        fileName: 'user_lists/MovieList-$listId.ttl',
        displayName: listName,
        fileType: 'movielist',
        permissions: [
          'read',
        ], // Movie lists must have read permission at minimum
      ),
      // Individual movie files with read-only permissions by default.

      ...movies.map(
        (movie) {
          // Construct file name based on content type.

          final isTV = movie.contentType == ContentType.tvShow;
          final filePrefix = isTV ? 'TVShow' : 'Movie';
          final fileType = isTV ? 'tv' : 'movie';

          return ShareableFile(
            fileName: 'movies/$filePrefix-${movie.id}.ttl',
            displayName: movie.title,
            fileType: fileType,
            movie: movie,
            permissions: ['read'], // Movie files default to read-only
          );
        },
      ),
    ];
    notifyListeners();
  }

  /// Update WebID validation status.

  void updateWebId(String? webId) {
    validatedWebId = webId;
    notifyListeners();
  }

  /// Update permissions for a specific file.
  /// When updating movie list permissions, movie files stay read-only.

  void updateFilePermissions(int index, List<String> newPermissions) {
    final file = shareableFiles[index];
    if (file.fileType == 'movielist') {
      // Update movie list permissions normally.

      shareableFiles[index] = file.copyWith(permissions: newPermissions);
    } else {
      // Movie files always stay read-only.

      shareableFiles[index] = file.copyWith(permissions: ['read']);
    }
    notifyListeners();
  }

  /// Reset all file permissions to their defaults.
  /// Movie lists get the selected permissions, movie files stay read-only.

  void resetPermissionsToDefaults() {
    for (int i = 0; i < shareableFiles.length; i++) {
      final file = shareableFiles[i];
      if (file.fileType == 'movielist') {
        // Movie lists: read + write permissions by default.

        shareableFiles[i] = file.copyWith(permissions: ['read', 'write']);
      } else {
        // Individual movies: always read-only for security.

        shareableFiles[i] = file.copyWith(permissions: ['read']);
      }
    }
    notifyListeners();
  }

  /// Start the batch sharing process using PodSharingService.

  Future<BatchSharingResult> startBatchSharing(
    BuildContext context,
    Widget parentWidget,
  ) async {
    if (validatedWebId == null) {
      return BatchSharingResult.error('Please enter a valid WebID');
    }

    // Store context and widget to avoid async gap issues.

    final savedContext = context;
    final savedParentWidget = parentWidget;

    isSharing = true;
    sharingProgress.clear();
    sharingResults.clear();
    currentOperation = 'Initializing...';
    notifyListeners();

    try {
      int completedCount = 0;
      final totalCount = shareableFiles.length;

      // Share each file using PodSharingService.

      for (int i = 0; i < shareableFiles.length; i++) {
        final file = shareableFiles[i];

        // Skip files with no permissions selected (except movie/TV files which always get read).

        if (file.permissions.isEmpty && file.fileType == 'movielist') {
          sharingProgress[file.fileName] = 'skipped';
          currentOperation =
              'Skipped ${file.displayName} (no permissions selected)';
          notifyListeners();
          continue;
        }

        currentOperation =
            'Sharing ${file.displayName}... (${i + 1}/$totalCount)';
        sharingProgress[file.fileName] = 'sharing';
        notifyListeners();

        try {
          // Determine permissions: movie and TV files always get read-only.

          final permissionsToUse =
              (file.fileType == 'movie' || file.fileType == 'tv')
                  ? ['read']
                  : file.permissions;

          // Use PodSharingService for simplified sharing.

          final shareRequest = ShareRequest(
            fileName: file.fileName,
            displayName: file.displayName,
            permissions: permissionsToUse,
            recipientWebId: validatedWebId!,
            recipientType: RecipientType.individual,
          );

          // Check if context is still mounted before using it.

          if (!savedContext.mounted) {
            sharingProgress[file.fileName] = 'error';
            notifyListeners();
            continue;
          }

          final shareResult = await PodSharingService.shareFile(
            shareRequest,
            savedContext,
            savedParentWidget,
          );
          final success = shareResult.success;

          if (success) {
            sharingProgress[file.fileName] = 'success';
            completedCount++;
          } else {
            sharingProgress[file.fileName] = 'failed';
          }
          notifyListeners();
        } catch (e) {
          sharingProgress[file.fileName] = 'error';
          notifyListeners();
        }

        // Small delay between operations for UI updates.

        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Show completion message.

      currentOperation = 'Completed! Shared $completedCount/$totalCount files';
      notifyListeners();

      return BatchSharingResult.success(completedCount, totalCount);
    } catch (e) {
      currentOperation = 'Error: $e';
      notifyListeners();
      return BatchSharingResult.error('Error during sharing: $e');
    } finally {
      isSharing = false;
      notifyListeners();
    }
  }

  /// Check if sharing is ready (valid recipient and permissions).

  bool get isReadyToShare {
    final hasValidRecipient = validatedWebId != null;
    final hasAnyPermissions =
        shareableFiles.any((file) => file.permissions.isNotEmpty);
    return hasValidRecipient && hasAnyPermissions;
  }
}

/// Result of a batch sharing operation.

class BatchSharingResult {
  final bool success;
  final String? errorMessage;
  final int? completedCount;
  final int? totalCount;

  const BatchSharingResult._({
    required this.success,
    this.errorMessage,
    this.completedCount,
    this.totalCount,
  });

  factory BatchSharingResult.success(int completedCount, int totalCount) {
    return BatchSharingResult._(
      success: true,
      completedCount: completedCount,
      totalCount: totalCount,
    );
  }

  factory BatchSharingResult.error(String message) {
    return BatchSharingResult._(
      success: false,
      errorMessage: message,
    );
  }

  bool get isPartialSuccess =>
      success &&
      completedCount != null &&
      totalCount != null &&
      completedCount! < totalCount!;

  bool get isCompleteSuccess =>
      success &&
      completedCount != null &&
      totalCount != null &&
      completedCount! == totalCount!;
}
