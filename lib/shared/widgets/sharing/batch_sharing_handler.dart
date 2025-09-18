/// Core batch sharing functionality handler.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart' show SolidFunctionCallStatus;
// ignore: implementation_imports
import 'package:solidpod/src/solid/constants/web_acl.dart' show RecipientType;

import 'package:moviestar/core/services/pod/pod_sharing_service.dart';
import 'package:moviestar/models/sharing_models.dart';
import 'package:moviestar/widgets/sharing/sharing_components.dart';

/// Handler for batch sharing operations.
class BatchSharingHandler {
  /// Start the batch sharing process using PodSharingService.
  static Future<BatchSharingResult> performBatchSharing({
    required BuildContext context,
    required Widget widget,
    required String validatedWebId,
    required List<ShareableFile> shareableFiles,
    required Function(String, String) onProgressUpdate,
    required Function(String) onOperationUpdate,
  }) async {
    final Map<String, String> sharingProgress = {};
    final Map<String, SolidFunctionCallStatus> sharingResults = {};

    try {
      int completedCount = 0;
      final totalCount = shareableFiles.length;

      onOperationUpdate('Initializing...');

      // Share each file using PodSharingService
      for (int i = 0; i < shareableFiles.length; i++) {
        final file = shareableFiles[i];

        // Skip files with no permissions selected (except movie/TV files which always get read).
        if (file.permissions.isEmpty && file.fileType == 'movielist') {
          sharingProgress[file.fileName] = 'skipped';
          onProgressUpdate(
            file.fileName,
            'skipped',
          );
          onOperationUpdate(
            'Skipped ${file.displayName} (no permissions selected)',
          );
          continue;
        }

        onProgressUpdate(file.fileName, 'sharing');
        onOperationUpdate(
          'Sharing ${file.displayName}... (${i + 1}/$totalCount)',
        );

        try {
          // Determine permissions: movie and TV files always get read-only.
          final permissionsToUse =
              (file.fileType == 'movie' || file.fileType == 'tv')
                  ? ['read']
                  : file.permissions;

          // Use PodSharingService for simplified sharing
          final shareRequest = ShareRequest(
            fileName: file.fileName,
            displayName: file.displayName,
            permissions: permissionsToUse,
            recipientWebId: validatedWebId,
            recipientType: RecipientType.individual,
          );
          final shareResult =
              await PodSharingService.shareFile(shareRequest, context, widget);
          final success = shareResult.success;

          if (success) {
            sharingProgress[file.fileName] = 'success';
            onProgressUpdate(file.fileName, 'success');
            completedCount++;
          } else {
            sharingProgress[file.fileName] = 'failed';
            onProgressUpdate(file.fileName, 'failed');
          }
        } catch (e) {
          sharingProgress[file.fileName] = 'error';
          onProgressUpdate(file.fileName, 'error');
        }

        // Small delay between operations for UI updates
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Show completion message
      onOperationUpdate('Completed! Shared $completedCount/$totalCount files');

      return BatchSharingResult(
        success: completedCount == totalCount,
        completedCount: completedCount,
        totalCount: totalCount,
        sharingProgress: sharingProgress,
        sharingResults: sharingResults,
      );
    } catch (e) {
      onOperationUpdate('Error: $e');
      return BatchSharingResult(
        success: false,
        completedCount: 0,
        totalCount: shareableFiles.length,
        sharingProgress: sharingProgress,
        sharingResults: sharingResults,
        error: e.toString(),
      );
    }
  }
}

/// Result of a batch sharing operation.
class BatchSharingResult {
  final bool success;
  final int completedCount;
  final int totalCount;
  final Map<String, String> sharingProgress;
  final Map<String, SolidFunctionCallStatus> sharingResults;
  final String? error;

  const BatchSharingResult({
    required this.success,
    required this.completedCount,
    required this.totalCount,
    required this.sharingProgress,
    required this.sharingResults,
    this.error,
  });
}
