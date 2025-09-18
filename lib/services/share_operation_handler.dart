/// Handles sharing operations for POD files.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart'
    show
        SolidFunctionCallStatus,
        getWebId,
        grantPermission,
        loginIfRequired,
        getKeyFromUserIfRequired;

import 'package:moviestar/models/sharing_models.dart';
import 'package:moviestar/services/webid_validator.dart';

/// Handles sharing operations and permission management for POD files.
class ShareOperationHandler {
  /// Get the current user's WebID.
  static Future<String?> getCurrentWebId() async {
    try {
      final webId = await getWebId();
      return webId;
    } catch (e) {
      debugPrint('Error getting WebID: $e');
      return null;
    }
  }

  /// Share a single file using real POD permission granting.
  static Future<ShareResult> shareFile(
    ShareRequest request,
    BuildContext context,
    Widget widget,
  ) async {
    try {
      // Check if context is still mounted before async operations
      if (!context.mounted) {
        return ShareResult.failure('Context no longer mounted');
      }

      // Ensure user is logged in and has proper keys
      await loginIfRequired(context);
      if (!context.mounted) {
        return ShareResult.failure('Context no longer mounted');
      }

      await getKeyFromUserIfRequired(context, widget);
      if (!context.mounted) {
        return ShareResult.failure('Context no longer mounted');
      }

      // Validate WebID
      if (!await WebIdValidator.validateWebId(request.recipientWebId)) {
        return ShareResult.failure('Invalid WebID: ${request.recipientWebId}');
      }

      // Get current user's WebID
      final ownerWebId = await getCurrentWebId();
      if (ownerWebId == null) {
        return ShareResult.failure('Unable to get current user WebID');
      }

      if (!context.mounted) {
        return ShareResult.failure('Context no longer mounted');
      }

      // Grant permission using actual solidpod call
      final result = await grantPermission(
        request.fileName,
        true, // fileFlag - this is a file, not a folder
        request.permissions,
        request.recipientType,
        [request.recipientWebId],
        ownerWebId,
        context,
        widget,
        isExternalRes: false,
      );

      if (result == SolidFunctionCallStatus.success) {
        return ShareResult.success(
          metadata: {
            'fileName': request.fileName,
            'displayName': request.displayName,
            'recipientWebId': request.recipientWebId,
            'permissions': request.permissions,
            'timestamp': DateTime.now().toIso8601String(),
          },
          status: result,
        );
      } else {
        return ShareResult.failure(
          'Failed to grant permission: $result',
          status: result,
        );
      }
    } catch (e) {
      return ShareResult.failure('Error sharing file: $e');
    }
  }

  /// Share multiple files.
  static Future<BatchShareResult> shareMultipleFiles(
    List<ShareRequest> requests,
    BuildContext context,
    Widget widget, {
    bool stopOnError = false,
  }) async {
    final results = <ShareResult>[];

    for (final request in requests) {
      final result = await shareFile(request, context, widget);
      results.add(result);

      if (!result.success && stopOnError) {
        break;
      }
    }

    return BatchShareResult(results: results);
  }

  /// Grant permissions for a file using real POD calls.
  static Future<PermissionResult> grantPermissions(
    PermissionRequest request,
    BuildContext context,
    Widget widget,
  ) async {
    try {
      // Check if context is still mounted before async operations
      if (!context.mounted) {
        return const PermissionResult(
          granted: false,
          error: 'Context no longer mounted',
        );
      }

      // Ensure user is logged in and has proper keys
      await loginIfRequired(context);
      if (!context.mounted) {
        return const PermissionResult(
          granted: false,
          error: 'Context no longer mounted',
        );
      }

      await getKeyFromUserIfRequired(context, widget);
      if (!context.mounted) {
        return const PermissionResult(
          granted: false,
          error: 'Context no longer mounted',
        );
      }

      // Get current user's WebID
      final ownerWebId = await getCurrentWebId();
      if (ownerWebId == null) {
        return const PermissionResult(
          granted: false,
          error: 'Unable to get current user WebID',
        );
      }

      if (!context.mounted) {
        return const PermissionResult(
          granted: false,
          error: 'Context no longer mounted',
        );
      }

      // Grant permission using actual solidpod call
      final result = await grantPermission(
        request.fileName,
        true, // fileFlag
        request.permissions,
        request.recipientType,
        [request.webId],
        ownerWebId,
        context,
        widget,
        isExternalRes: false,
      );

      return PermissionResult(
        granted: result == SolidFunctionCallStatus.success,
        error: result == SolidFunctionCallStatus.success
            ? null
            : 'Failed to grant permission: $result',
        status: result,
      );
    } catch (e) {
      return PermissionResult(
        granted: false,
        error: 'Error granting permissions: $e',
      );
    }
  }

  /// Perform batch sharing with progress callback.
  static Future<BatchShareResult> performBatchShare(
    BatchShareRequest request,
    BuildContext context,
    Widget widget, {
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
        context,
        widget,
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

  /// Get sharing status message.
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
}
