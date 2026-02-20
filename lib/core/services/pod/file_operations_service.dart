/// Service for standardized POD file operations with error handling and retry logic.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart' as solidpod
    show writePod, readPod, deleteFile;

import 'package:moviestar/utils/is_logged_in.dart';

/// Result of a POD file operation.

class PodFileOperationResult {
  final bool success;
  final String? data;
  final String? error;

  const PodFileOperationResult({
    required this.success,
    this.data,
    this.error,
  });

  factory PodFileOperationResult.success([String? data]) {
    return PodFileOperationResult(success: true, data: data);
  }

  factory PodFileOperationResult.failure(String error) {
    return PodFileOperationResult(success: false, error: error);
  }
}

/// Standardized service for POD file operations with error handling and retry logic.

class PodFileOperationsService {
  /// Maximum number of retry attempts for failed operations.

  static const int _maxRetries = 3;

  /// Delay between retry attempts.

  static const Duration _retryDelay = Duration(milliseconds: 500);

  /// Reads a file from POD storage with automatic retry on failure.
  ///
  /// [fileName] - The path to the file in POD storage.
  /// [context] - Flutter build context for POD operations.
  /// [child] - Widget for navigation context.
  /// [retries] - Number of retry attempts (defaults to _maxRetries).

  static Future<PodFileOperationResult> readFile(
    String fileName,
    BuildContext context,
    Widget child, {
    int? retries,
  }) async {
    final maxAttempts = retries ?? _maxRetries;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        // Check if user is logged in.

        final loggedIn = await isLoggedIn();
        if (!loggedIn) {
          return PodFileOperationResult.failure(
            'User not logged in to POD storage',
          );
        }

        // Check if context is still mounted.

        if (!context.mounted) {
          return PodFileOperationResult.failure(
            'Context no longer mounted',
          );
        }

        // Attempt to read the file.

        final result = await solidpod.readPod(fileName);

        if (result.isNotEmpty) {
          return PodFileOperationResult.success(result);
        } else {
          // Empty result might be valid for some files.

          return PodFileOperationResult.success('');
        }
      } catch (e) {
        final errorMessage = e.toString();

        // Don't retry if file doesn't exist - this is expected for new files.

        if (errorMessage.contains('does not exist')) {
          return PodFileOperationResult.failure('File does not exist');
        }

        // Don't retry if context issues.

        if (errorMessage.contains('mounted') ||
            errorMessage.contains('context')) {
          return PodFileOperationResult.failure(errorMessage);
        }

        // If this is the last attempt, return the error.

        if (attempt == maxAttempts) {
          return PodFileOperationResult.failure(
            'Failed to read file after $maxAttempts attempts: $errorMessage',
          );
        }

        // Wait before retrying.

        await Future.delayed(_retryDelay * attempt);
      }
    }

    return PodFileOperationResult.failure(
      'Failed to read file after $maxAttempts attempts',
    );
  }

  /// Writes a file to POD storage with automatic retry on failure.
  ///
  /// [fileName] - The path to the file in POD storage.
  /// [content] - The content to write to the file.
  /// [context] - Flutter build context for POD operations.
  /// [child] - Widget for navigation context.
  /// [encrypted] - Whether to encrypt the file (defaults to false).
  /// [retries] - Number of retry attempts (defaults to _maxRetries).

  static Future<PodFileOperationResult> writeFile(
    String fileName,
    String content,
    BuildContext context,
    Widget child, {
    bool encrypted = false,
    int? retries,
  }) async {
    final maxAttempts = retries ?? _maxRetries;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        // Check if user is logged in.

        final loggedIn = await isLoggedIn();
        if (!loggedIn) {
          return PodFileOperationResult.failure(
            'User not logged in to POD storage',
          );
        }

        // Check if context is still mounted.

        if (!context.mounted) {
          return PodFileOperationResult.failure(
            'Context no longer mounted',
          );
        }

        // Attempt to write the file.

        await solidpod.writePod(
          fileName,
          content,
          encrypted: encrypted,
        );

        return PodFileOperationResult.success();
      } catch (e) {
        final errorMessage = e.toString();

        // Don't retry if context issues.

        if (errorMessage.contains('mounted') ||
            errorMessage.contains('context')) {
          return PodFileOperationResult.failure(errorMessage);
        }

        // If this is the last attempt, return the error.

        if (attempt == maxAttempts) {
          return PodFileOperationResult.failure(
            'Failed to write file after $maxAttempts attempts: $errorMessage',
          );
        }

        // Wait before retrying.

        await Future.delayed(_retryDelay * attempt);
      }
    }

    return PodFileOperationResult.failure(
      'Failed to write file after $maxAttempts attempts',
    );
  }

  /// Checks if a file exists in POD storage.
  ///
  /// [fileName] - The path to the file in POD storage.
  /// [context] - Flutter build context for POD operations.
  /// [child] - Widget for navigation context.

  static Future<bool> fileExists(
    String fileName,
    BuildContext context,
    Widget child,
  ) async {
    try {
      final result = await readFile(fileName, context, child, retries: 1);
      return result.success;
    } catch (e) {
      return false;
    }
  }

  /// Deletes a file from POD storage.
  ///
  /// [fileName] - The path to the file in POD storage.
  /// [context] - Flutter build context for POD operations.
  /// [child] - Widget for navigation context.

  static Future<PodFileOperationResult> deleteFile(
    String fileName,
    BuildContext context,
    Widget child,
  ) async {
    try {
      // Check if user is logged in.

      final loggedIn = await isLoggedIn();
      if (!loggedIn) {
        return PodFileOperationResult.failure(
          'User not logged in to POD storage',
        );
      }

      // Check if context is still mounted.

      if (!context.mounted) {
        return PodFileOperationResult.failure(
          'Context no longer mounted',
        );
      }

      // Use SolidPOD's deleteFile function directly.

      await solidpod.deleteFile(fileUrl: fileName);

      return PodFileOperationResult.success();
    } catch (e) {
      return PodFileOperationResult.failure(
        'Failed to delete file: ${e.toString()}',
      );
    }
  }

  /// Performs a batch write operation for multiple files.
  ///
  /// [operations] - Map of fileName -> content to write.
  /// [context] - Flutter build context for POD operations.
  /// [child] - Widget for navigation context.
  /// [encrypted] - Whether to encrypt the files (defaults to false).

  static Future<Map<String, PodFileOperationResult>> batchWrite(
    Map<String, String> operations,
    BuildContext context,
    Widget child, {
    bool encrypted = false,
  }) async {
    final results = <String, PodFileOperationResult>{};

    // Execute writes in parallel for better performance.

    final futures = operations.entries.map((entry) async {
      final fileName = entry.key;
      final content = entry.value;

      final result = await writeFile(
        fileName,
        content,
        context,
        child,
        encrypted: encrypted,
      );

      return MapEntry(fileName, result);
    });

    final completedOperations = await Future.wait(futures);

    for (final entry in completedOperations) {
      results[entry.key] = entry.value;
    }

    return results;
  }

  /// Gets the full POD path for a relative file path.
  ///
  /// [relativePath] - The relative path within the app's POD directory.

  static String getFullPodPath(String relativePath) {
    // Remove leading slash if present.

    final cleanPath =
        relativePath.startsWith('/') ? relativePath.substring(1) : relativePath;

    return cleanPath;
  }
}
