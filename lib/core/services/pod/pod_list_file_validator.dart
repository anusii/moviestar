/// File validation utilities for POD custom lists.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

/// Handles file validation for POD list management.
class PodListFileValidator {
  /// Checks if a filename is a valid MovieList file.
  static bool isValidMovieListFile(String fileName) {
    if (!fileName.startsWith('MovieList-') || !fileName.endsWith('.ttl')) {
      return false;
    }

    // Skip ACL, backup, or other metadata files that might be created during sharing
    if (fileName.contains('.acl.') ||
        fileName.contains('_backup') ||
        fileName.contains('_shared') ||
        fileName.contains('.meta.') ||
        fileName.contains('~') ||
        fileName.startsWith('.')) {
      debugPrint('⚠️ [PodListFileValidator] Skipping metadata file: $fileName');
      return false;
    }

    return true;
  }

  /// Extracts MovieList ID from filename.
  static String? extractMovieListId(String fileName) {
    try {
      return fileName.replaceAll('MovieList-', '').replaceAll('.ttl', '');
    } catch (e) {
      return null;
    }
  }

  /// Checks if a list name is a standard system list.
  static bool isStandardList(String name) {
    return name == 'To Watch' || name == 'Watched';
  }

  /// Validates that a movie ID is valid (positive integer).
  static bool isValidMovieId(int movieId) {
    return movieId > 0;
  }

  /// Validates that a list name is acceptable.
  static bool isValidListName(String name) {
    return name.trim().isNotEmpty && name.length <= 100;
  }
}
