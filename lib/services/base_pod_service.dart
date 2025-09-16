/// Base service class for POD-based services with common patterns.
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
/// Authors: Ashley Tang

library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:moviestar/services/pod_file_operations_service.dart';
import 'package:moviestar/utils/is_logged_in.dart';

/// Result of a POD file operation.
class FileOperationResult {
  final bool success;
  final String? data;
  final String? error;

  const FileOperationResult({
    required this.success,
    this.data,
    this.error,
  });
}

/// Base class for services that interact with Solid POD storage.
/// Provides common functionality for login validation, context checking,
/// and POD file operations while preserving exact existing behavior.
abstract class BasePodService extends ChangeNotifier {
  final BuildContext _context;
  final Widget _child;

  BasePodService(this._context, this._child);

  /// Widget context for POD operations.
  @protected
  BuildContext get context => _context;

  /// Widget for returning after operations.
  @protected
  Widget get child => _child;

  /// Executes a POD operation with standard validation and error handling.
  /// Preserves exact behavior of existing services.
  @protected
  Future<T?> executePodOperation<T>({
    required Future<T?> Function() operation,
    required String operationName,
    bool requiresLogin = true,
    bool checkContext = true,
  }) async {
    try {
      // Check login status if required
      if (requiresLogin) {
        final loggedIn = await isLoggedIn();
        if (!loggedIn) {
          debugPrint('❌ User not logged in, cannot execute $operationName');
          return null;
        }
      }

      // Check context validity if required
      if (checkContext && !context.mounted) {
        debugPrint('❌ Context not mounted, cannot execute $operationName');
        return null;
      }

      // Execute the actual operation
      return await operation();
    } catch (e) {
      debugPrint('❌ Error in $operationName: $e');
      return null;
    }
  }

  /// Safely reads a file from POD with standard error handling.
  /// Returns file content directly or null on failure.
  @protected
  Future<String?> safeReadFile(String path) async {
    return await executePodOperation(
      operation: () async {
        final result = await PodFileOperationsService.readFile(
          path,
          context,
          child,
        );
        if (result.success) {
          return result.data ?? '';
        }
        return null;
      },
      operationName: 'readFile($path)',
    );
  }

  /// Safely writes a file to POD with standard error handling.
  /// Returns true on success, false on failure.
  @protected
  Future<bool> safeWriteFile(
    String path,
    String content, {
    bool encrypted = false,
  }) async {
    final result = await executePodOperation(
      operation: () async {
        final result = await PodFileOperationsService.writeFile(
          path,
          content,
          context,
          child,
          encrypted: encrypted,
        );
        return result.success;
      },
      operationName: 'writeFile($path)',
    );
    return result ?? false;
  }

  /// Safely deletes a file from POD with standard error handling.
  /// Returns true on success, false on failure.
  @protected
  Future<bool> safeDeleteFile(String path) async {
    final result = await executePodOperation(
      operation: () async {
        final result = await PodFileOperationsService.deleteFile(
          path,
          context,
          child,
        );
        return result.success;
      },
      operationName: 'deleteFile($path)',
    );
    return result ?? false;
  }

  /// Standard debug logging format used across all services.
  @protected
  void logDebug(String message, {bool isError = false}) {
    debugPrint(isError ? '❌ $message' : message);
  }

  /// Standard success logging format.
  @protected
  void logSuccess(String message) {
    debugPrint('✅ $message');
  }

  /// Standard info logging format.
  @protected
  void logInfo(String message) {
    debugPrint('ℹ️ $message');
  }

  /// Standard warning logging format.
  @protected
  void logWarning(String message) {
    debugPrint('⚠️ $message');
  }
}
