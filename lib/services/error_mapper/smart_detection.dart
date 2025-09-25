/// Smart error detection utilities for error mapper service.
/// Extracted to reduce file size and improve organization.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/core/services/api/key_validation_service.dart';
import 'package:moviestar/core/services/network/connectivity_service.dart';
import 'package:moviestar/models/app_error.dart';

/// Context for error mapping operations.

class ErrorContext {
  /// Optional retry callback.

  final VoidCallback? onRetry;

  /// Optional callback to navigate to API key configuration.

  final VoidCallback? onConfigureApiKey;

  /// Optional callback to navigate to network settings.

  final VoidCallback? onNetworkSettings;

  /// Optional callback to contact support.

  final VoidCallback? onContactSupport;

  /// Optional callback to dismiss the error.

  final VoidCallback? onDismiss;

  /// API key validation service for smart detection.

  final ApiKeyValidationService? apiKeyValidationService;

  /// Network connectivity service for smart detection.

  final NetworkConnectivityService? networkConnectivityService;

  const ErrorContext({
    this.onRetry,
    this.onConfigureApiKey,
    this.onNetworkSettings,
    this.onContactSupport,
    this.onDismiss,
    this.apiKeyValidationService,
    this.networkConnectivityService,
  });
}

/// Handles smart error detection and validation.

class SmartErrorDetection {
  /// Maps a technical error to a user-friendly error with smart detection.
  /// This version performs async API key and network validation for better accuracy.

  static Future<UserFriendlyError> mapErrorSmart(
    Object error,
    StackTrace stackTrace, {
    ErrorContext? context = const ErrorContext(),
  }) async {
    // Step 1: Check if this is clearly an API key error based on error content.

    if (ApiKeyValidationService.isApiKeyError(error)) {
      // Verify API key status if service is available.

      if (context?.apiKeyValidationService != null) {
        try {
          final apiKeyResult =
              await context!.apiKeyValidationService!.validateApiKey();
          if (apiKeyResult.shouldShowApiKeyError) {
            return _createApiKeyError(error, stackTrace, context, apiKeyResult);
          }
        } catch (e) {
          // If API key validation fails, fall back to error-based detection.
        }
      }
      // Fallback to error-based API key detection.

      return _mapApiKeyError(error, stackTrace, context);
    }

    // Step 2: Check network connectivity if this seems like a network error.

    if (NetworkConnectivityService.isNetworkError(error) &&
        context?.networkConnectivityService != null) {
      try {
        final connectivityResult =
            await context!.networkConnectivityService!.quickCheck();

        if (connectivityResult.isNetworkProblem) {
          // Definitive network problem.

          return _createNetworkError(
            error,
            stackTrace,
            context,
            connectivityResult,
          );
        } else if (connectivityResult.isInconclusive) {
          // Network check failed, might still be network issue.

          return _mapPossibleNetworkError(error, stackTrace, context);
        }
        // If network is fine, continue with other checks.
      } catch (e) {
        // If network check fails, assume it could be a network issue.

        return _mapPossibleNetworkError(error, stackTrace, context);
      }
    }

    // Step 3: Double-check API key if network seems fine but we have auth-like errors.

    if (context?.apiKeyValidationService != null &&
        _couldBeApiKeyIssue(error)) {
      try {
        final apiKeyResult =
            await context!.apiKeyValidationService!.validateApiKey();
        if (apiKeyResult.shouldShowApiKeyError) {
          return _createApiKeyError(error, stackTrace, context, apiKeyResult);
        }
      } catch (e) {
        // If API key validation fails, continue with traditional mapping.
      }
    }

    // Step 4: Should not reach here - caller should handle fallback.

    throw Exception('Smart detection failed, fallback required');
  }

  /// Checks if an error could potentially be an API key issue.

  static bool _couldBeApiKeyIssue(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('401') ||
        errorString.contains('403') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden') ||
        errorString.contains('authentication');
  }

  /// Creates an API key error with enhanced context.

  static UserFriendlyError _createApiKeyError(
    Object error,
    StackTrace stackTrace,
    ErrorContext context,
    ApiKeyValidationResult apiKeyResult,
  ) {
    final actions = <ErrorAction>[];

    if (context.onConfigureApiKey != null) {
      actions.add(ErrorAction.configureApiKey(context.onConfigureApiKey!));
    }
    if (context.onRetry != null) {
      actions.add(ErrorAction.retry(context.onRetry!));
    }

    String message;
    String? details;

    if (!apiKeyResult.isConfigured) {
      message =
          'No API key is configured. You need a TMDB API key to fetch movie information.';
      details =
          'Get a free API key at https://www.themoviedb.org/settings/api and configure it in Settings.';
    } else if (apiKeyResult.isValid == false) {
      message =
          apiKeyResult.errorMessage ?? 'Your API key appears to be invalid.';
      details =
          'Please check your API key in Settings or get a new one from https://www.themoviedb.org/settings/api';
    } else {
      message =
          'API authentication failed. Your key may be invalid or expired.';
      details = 'Please verify your API key in Settings.';
    }

    return UserFriendlyError(
      type: ErrorType.apiKeyError,
      title: 'API Key Issue',
      message: message,
      details: details,
      actions: actions,
      originalError: error,
      stackTrace: stackTrace,
      icon: Icons.vpn_key_off,
    );
  }

  /// Creates a network error with enhanced context.

  static UserFriendlyError _createNetworkError(
    Object error,
    StackTrace stackTrace,
    ErrorContext context,
    NetworkConnectivityResult connectivityResult,
  ) {
    final actions = <ErrorAction>[];

    if (context.onRetry != null) {
      actions.add(ErrorAction.retry(context.onRetry!));
    }
    if (context.onNetworkSettings != null) {
      actions.add(ErrorAction.networkSettings(context.onNetworkSettings!));
    }

    String message =
        'No internet connection detected. Please check your connection and try again.';
    String details =
        'Make sure you are connected to Wi-Fi or mobile data and that your device is not in airplane mode.';

    if (connectivityResult.errorMessage != null) {
      details = connectivityResult.errorMessage!;
    }

    return UserFriendlyError(
      type: ErrorType.networkError,
      title: 'Connection Problem',
      message: message,
      details: details,
      actions: actions,
      originalError: error,
      stackTrace: stackTrace,
      icon: Icons.wifi_off,
    );
  }

  /// Maps a possible network error when connectivity check is inconclusive.

  static UserFriendlyError _mapPossibleNetworkError(
    Object error,
    StackTrace stackTrace,
    ErrorContext? context,
  ) {
    final actions = <ErrorAction>[];

    if (context?.onRetry != null) {
      actions.add(ErrorAction.retry(context!.onRetry!));
    }
    if (context?.onNetworkSettings != null) {
      actions.add(ErrorAction.networkSettings(context!.onNetworkSettings!));
    }

    return UserFriendlyError(
      type: ErrorType.networkError,
      title: 'Connection Problem',
      message: 'Unable to connect to the service. This may be a network issue.',
      details:
          'Please check your internet connection and try again. If the problem persists, the service may be temporarily unavailable.',
      actions: actions,
      originalError: error,
      stackTrace: stackTrace,
      icon: Icons.wifi_off,
    );
  }

  /// Maps errors that are likely API key issues (fallback method).

  static UserFriendlyError _mapApiKeyError(
    Object error,
    StackTrace stackTrace,
    ErrorContext? context,
  ) {
    final actions = <ErrorAction>[];

    if (context?.onConfigureApiKey != null) {
      actions.add(ErrorAction.configureApiKey(context!.onConfigureApiKey!));
    }
    if (context?.onRetry != null) {
      actions.add(ErrorAction.retry(context!.onRetry!));
    }

    return UserFriendlyError.apiKeyError(
      actions: actions,
      originalError: error,
      stackTrace: stackTrace,
    );
  }
}
