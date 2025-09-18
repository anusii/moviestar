/// Sharing models for POD operations in MovieStar.
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

import 'package:solidpod/solidpod.dart' show SolidFunctionCallStatus;
// ignore: implementation_imports
import 'package:solidpod/src/solid/constants/web_acl.dart' show RecipientType;

/// Request model for sharing a file.
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

/// Result model for sharing operations.
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

  factory ShareResult.success({
    Map<String, dynamic> metadata = const {},
    SolidFunctionCallStatus? status,
  }) {
    return ShareResult(
      success: true,
      metadata: metadata,
      status: status,
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

/// Request model for batch sharing.
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

/// Result model for batch sharing operations.
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

/// Permission request model.
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

/// Permission result model.
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
