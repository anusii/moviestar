/// Mixin providing common POD operation patterns for services.
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

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:moviestar/utils/is_logged_in.dart';

/// Mixin that provides common POD operation patterns.
/// Preserves exact retry logic and validation patterns from existing services.

mixin PodOperationsMixin {
  /// Retries an operation with exponential backoff.
  /// Matches exact retry behavior from existing services.

  Future<T?> retryOperation<T>({
    required Future<T?> Function() operation,
    required String operationName,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    bool exponentialBackoff = true,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final result = await operation();
        return result;
      } catch (e) {
        final isLastAttempt = attempt == maxRetries;

        if (isLastAttempt) {
          return null;
        }

        // Calculate delay with exponential backoff if enabled.

        final delay =
            exponentialBackoff ? initialDelay * attempt : initialDelay;

        await Future.delayed(delay);
      }
    }
    return null;
  }

  /// Validates that the context is still mounted.
  /// Returns true if valid, false otherwise.

  bool validateContext(BuildContext context) {
    if (!context.mounted) {
      return false;
    }
    return true;
  }

  /// Validates that the user is logged in.
  /// Returns true if logged in, false otherwise.

  Future<bool> validateLogin() async {
    final loggedIn = await isLoggedIn();
    if (!loggedIn) {
      return false;
    }
    return true;
  }

  /// Validates both context and login status.
  /// Returns true if both are valid, false otherwise.

  Future<bool> validateContextAndLogin(BuildContext context) async {
    if (!validateContext(context)) return false;
    if (!await validateLogin()) return false;
    return true;
  }

  /// Generates a standard file path for MovieList files.
  /// Follows ontology naming convention.

  String getMovieListFilePath(String movieListId) {
    return 'user_lists/MovieList-$movieListId.ttl';
  }

  /// Generates a standard file path for Movie files.
  /// Follows ontology naming convention.

  String getMovieFilePath(int movieId, {String contentType = 'movie'}) {
    if (contentType == 'tv' || contentType == 'tvShow') {
      return 'moviestar/data/movies/TVShow-$movieId.ttl';
    }
    return 'moviestar/data/movies/Movie-$movieId.ttl';
  }

  /// Checks if an error indicates a file doesn't exist.

  bool isFileNotFoundError(Object error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('does not exist') ||
        errorStr.contains('404') ||
        errorStr.contains('not found');
  }

  /// Checks if an error is related to permissions.

  bool isPermissionError(Object error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('permission') ||
        errorStr.contains('auth') ||
        errorStr.contains('unauthorized') ||
        errorStr.contains('forbidden') ||
        errorStr.contains('403');
  }

  /// Checks if an error is related to network issues.

  bool isNetworkError(Object error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('network') ||
        errorStr.contains('connection') ||
        errorStr.contains('timeout') ||
        errorStr.contains('socket');
  }
}
