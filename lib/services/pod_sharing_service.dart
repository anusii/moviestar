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
}
