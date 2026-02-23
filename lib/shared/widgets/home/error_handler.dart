/// Error handling components for home screen functionality.
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
/// Authors: Ashley Tang, Kevin Wang

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/core/services/api/key_validation_service.dart';
import 'package:moviestar/core/services/cache/hive_movie_cache_service.dart';
import 'package:moviestar/core/services/network/connectivity_service.dart';
import 'package:moviestar/models/app_error.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/services/error_mapper/smart_detection.dart';
import 'package:moviestar/services/error_mapper_service.dart';
import 'package:moviestar/widgets/error_display_widget.dart';

/// Utility class for handling errors in the home screen context.

class HomeErrorHandler {
  /// Checks if an error is an API key related error.

  static bool isApiKeyError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('401') ||
        errorString.contains('403') ||
        errorString.contains('unauthorized') ||
        errorString.contains('api key') ||
        errorString.contains('forbidden');
  }

  /// Checks all movie providers for API key errors and returns error state.

  static ApiKeyErrorState checkForApiKeyErrors(
    AsyncValue<CacheResult<List<dynamic>>> popularMovies,
    AsyncValue<CacheResult<List<dynamic>>> nowPlayingMovies,
    AsyncValue<CacheResult<List<dynamic>>> topRatedMovies,
    AsyncValue<CacheResult<List<dynamic>>> upcomingMovies,
  ) {
    bool foundApiKeyError = false;
    String? errorMessage;

    final providers = [
      popularMovies,
      nowPlayingMovies,
      topRatedMovies,
      upcomingMovies,
    ];

    for (final provider in providers) {
      if (provider.hasError) {
        final error = provider.error!;
        if (isApiKeyError(error)) {
          foundApiKeyError = true;
          errorMessage = error.toString();
          break;
        }
      }
    }

    return ApiKeyErrorState(
      hasError: foundApiKeyError,
      errorMessage: errorMessage,
    );
  }

  /// Builds a smart error widget for the home screen.

  static Widget buildSmartErrorWidget(
    WidgetRef ref,
    Object error,
    StackTrace stackTrace,
  ) {
    return FutureBuilder<UserFriendlyError>(
      future: _buildUserFriendlyError(ref, error, stackTrace),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(Dimensions.xl),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final userFriendlyError = snapshot.data;
        if (userFriendlyError != null) {
          return ErrorDisplayWidget.fromUserFriendlyError(
            error: userFriendlyError,
          );
        }

        return ErrorDisplayWidget(
          message: 'Error loading movies: $error',
          onRetry: () => ref.invalidate(recommendedMoviesWithCacheInfoProvider),
        );
      },
    );
  }

  /// Builds a compact smart error widget for movie rows.

  static Widget buildSmartErrorWidgetCompact(
    WidgetRef ref,
    Object error,
    StackTrace stackTrace,
    String title,
    VoidCallback onRetry,
  ) {
    return FutureBuilder<UserFriendlyError>(
      future: _buildUserFriendlyErrorCompact(ref, error, stackTrace, onRetry),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ErrorDisplayWidget.compact(
            message: 'Loading error details...',
          );
        }

        final userFriendlyError = snapshot.data;
        if (userFriendlyError != null) {
          return ErrorDisplayWidget.compactFromUserFriendlyError(
            error: userFriendlyError,
          );
        }

        return ErrorDisplayWidget.compact(
          message: 'Failed to load $title',
          onRetry: onRetry,
        );
      },
    );
  }

  static Future<UserFriendlyError> _buildUserFriendlyError(
    WidgetRef ref,
    Object error,
    StackTrace stackTrace,
  ) async {
    return _createUserFriendlyError(
      ref,
      error,
      stackTrace,
      () => ref.invalidate(recommendedMoviesWithCacheInfoProvider),
    );
  }

  static Future<UserFriendlyError> _buildUserFriendlyErrorCompact(
    WidgetRef ref,
    Object error,
    StackTrace stackTrace,
    VoidCallback onRetry,
  ) async {
    return _createUserFriendlyError(ref, error, stackTrace, onRetry);
  }

  static Future<UserFriendlyError> _createUserFriendlyError(
    WidgetRef ref,
    Object error,
    StackTrace stackTrace,
    VoidCallback onRetry,
  ) async {
    final apiKeyService = ref.read(apiKeyServiceProvider);
    final apiKeyValidationService = ApiKeyValidationService(apiKeyService);
    final networkConnectivityService = NetworkConnectivityService.forTMDB();

    final errorContext = ErrorContext(
      onRetry: onRetry,
      onConfigureApiKey: null,
      apiKeyValidationService: apiKeyValidationService,
      networkConnectivityService: networkConnectivityService,
    );

    try {
      return await ErrorMapperService.mapErrorSmart(
        error,
        stackTrace,
        context: errorContext,
      );
    } catch (e) {
      return ErrorMapperService.mapError(
        error,
        stackTrace,
        context: errorContext,
      );
    }
  }
}

/// Represents the state of API key errors.

class ApiKeyErrorState {
  final bool hasError;
  final String? errorMessage;

  const ApiKeyErrorState({
    required this.hasError,
    this.errorMessage,
  });
}
