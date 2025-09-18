/// Service for mapping technical errors to user-friendly error messages and actions.
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
/// Authors: Ashley Tang.

library;

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

import 'package:moviestar/core/services/api/key_validation_service.dart';
import 'package:moviestar/core/services/network/network_connectivity_service.dart';
import 'package:moviestar/models/app_error.dart';
import 'package:moviestar/utils/network_client.dart';

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

/// Service that maps technical exceptions to user-friendly errors.
class ErrorMapperService {
  /// Maps a technical error to a user-friendly error with appropriate actions.
  /// This is the synchronous version for backward compatibility.
  static UserFriendlyError mapError(
    Object error,
    StackTrace stackTrace, {
    ErrorContext? context = const ErrorContext(),
  }) {
    return _mapErrorTraditionally(error, stackTrace, context);
  }

  /// Maps a technical error to a user-friendly error with smart detection.
  /// This version performs async API key and network validation for better accuracy.
  static Future<UserFriendlyError> mapErrorSmart(
    Object error,
    StackTrace stackTrace, {
    ErrorContext? context = const ErrorContext(),
  }) async {
    // Step 1: Check if this is clearly an API key error based on error content
    if (ApiKeyValidationService.isApiKeyError(error)) {
      // Verify API key status if service is available
      if (context?.apiKeyValidationService != null) {
        try {
          final apiKeyResult =
              await context!.apiKeyValidationService!.validateApiKey();
          if (apiKeyResult.shouldShowApiKeyError) {
            return _createApiKeyError(error, stackTrace, context, apiKeyResult);
          }
        } catch (e) {
          // If API key validation fails, fall back to error-based detection
        }
      }
      // Fallback to error-based API key detection
      return _mapApiKeyError(error, stackTrace, context);
    }

    // Step 2: Check network connectivity if this seems like a network error
    if (NetworkConnectivityService.isNetworkError(error) &&
        context?.networkConnectivityService != null) {
      try {
        final connectivityResult =
            await context!.networkConnectivityService!.quickCheck();

        if (connectivityResult.isNetworkProblem) {
          // Definitive network problem
          return _createNetworkError(
            error,
            stackTrace,
            context,
            connectivityResult,
          );
        } else if (connectivityResult.isInconclusive) {
          // Network check failed, might still be network issue
          return _mapPossibleNetworkError(error, stackTrace, context);
        }
        // If network is fine, continue with other checks
      } catch (e) {
        // If network check fails, assume it could be a network issue
        return _mapPossibleNetworkError(error, stackTrace, context);
      }
    }

    // Step 3: Double-check API key if network seems fine but we have auth-like errors
    if (context?.apiKeyValidationService != null &&
        _couldBeApiKeyIssue(error)) {
      try {
        final apiKeyResult =
            await context!.apiKeyValidationService!.validateApiKey();
        if (apiKeyResult.shouldShowApiKeyError) {
          return _createApiKeyError(error, stackTrace, context, apiKeyResult);
        }
      } catch (e) {
        // If API key validation fails, continue with traditional mapping
      }
    }

    // Step 4: Fall back to traditional error mapping
    return _mapErrorTraditionally(error, stackTrace, context);
  }

  /// Maps errors using traditional logic (fallback).
  static UserFriendlyError _mapErrorTraditionally(
    Object error,
    StackTrace stackTrace,
    ErrorContext? context,
  ) {
    if (error is NetworkException) {
      return _mapNetworkException(error, stackTrace, context);
    } else if (error is http.ClientException) {
      return _mapHttpClientException(error, stackTrace, context);
    } else if (error is SocketException) {
      return _mapSocketException(error, stackTrace, context);
    } else if (error is FormatException) {
      return _mapFormatException(error, stackTrace, context);
    } else if (error is TimeoutException) {
      return _mapTimeoutException(error, stackTrace, context);
    } else {
      return _mapUnknownException(error, stackTrace, context);
    }
  }

  /// Maps NetworkException to user-friendly error.
  static UserFriendlyError _mapNetworkException(
    NetworkException error,
    StackTrace stackTrace,
    ErrorContext? context,
  ) {
    final actions = <ErrorAction>[];

    // Analyze status code to determine error type and actions
    if (error.statusCode == 401) {
      // API key issue
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
    } else if (error.statusCode != null && error.statusCode! >= 500) {
      // Server error
      if (context?.onRetry != null) {
        actions.add(ErrorAction.retry(context!.onRetry!));
      }
      if (context?.onContactSupport != null) {
        actions.add(ErrorAction.contactSupport(context!.onContactSupport!));
      }

      return UserFriendlyError.serverError(
        actions: actions,
        originalError: error,
        stackTrace: stackTrace,
      );
    } else if (error.statusCode == 403) {
      // Forbidden - likely API key issue
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
    } else if (error.statusCode == 404) {
      // Not found - could be network or data issue
      if (context?.onRetry != null) {
        actions.add(ErrorAction.retry(context!.onRetry!));
      }

      return UserFriendlyError.unknownError(
        actions: actions,
        originalError: error,
        stackTrace: stackTrace,
        customMessage:
            'The requested resource was not found. This may be a temporary issue.',
      );
    } else {
      // Generic network error
      if (context?.onRetry != null) {
        actions.add(ErrorAction.retry(context!.onRetry!));
      }
      if (context?.onNetworkSettings != null) {
        actions.add(ErrorAction.networkSettings(context!.onNetworkSettings!));
      }

      return UserFriendlyError.networkError(
        actions: actions,
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Maps HTTP ClientException to user-friendly error.
  static UserFriendlyError _mapHttpClientException(
    http.ClientException error,
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

    return UserFriendlyError.networkError(
      actions: actions,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Maps SocketException to user-friendly error.
  static UserFriendlyError _mapSocketException(
    SocketException error,
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

    return UserFriendlyError.networkError(
      actions: actions,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Maps FormatException to user-friendly error.
  static UserFriendlyError _mapFormatException(
    FormatException error,
    StackTrace stackTrace,
    ErrorContext? context,
  ) {
    final actions = <ErrorAction>[];

    if (context?.onRetry != null) {
      actions.add(ErrorAction.retry(context!.onRetry!));
    }
    if (context?.onContactSupport != null) {
      actions.add(ErrorAction.contactSupport(context!.onContactSupport!));
    }

    return UserFriendlyError.dataFormatError(
      actions: actions,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Maps TimeoutException to user-friendly error.
  static UserFriendlyError _mapTimeoutException(
    TimeoutException error,
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

    return UserFriendlyError.timeoutError(
      actions: actions,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Maps unknown exceptions to user-friendly error.
  static UserFriendlyError _mapUnknownException(
    Object error,
    StackTrace stackTrace,
    ErrorContext? context,
  ) {
    final actions = <ErrorAction>[];

    if (context?.onRetry != null) {
      actions.add(ErrorAction.retry(context!.onRetry!));
    }
    if (context?.onContactSupport != null) {
      actions.add(ErrorAction.contactSupport(context!.onContactSupport!));
    }

    return UserFriendlyError.unknownError(
      actions: actions,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Analyzes error text to detect specific patterns and suggest appropriate error types.
  static ErrorType analyzeErrorText(String errorText) {
    final lowerText = errorText.toLowerCase();

    if (lowerText.contains('401') ||
        lowerText.contains('unauthorized') ||
        lowerText.contains('api key') ||
        lowerText.contains('forbidden') && lowerText.contains('403')) {
      return ErrorType.apiKeyError;
    }

    if (lowerText.contains('timeout') || lowerText.contains('timed out')) {
      return ErrorType.timeoutError;
    }

    if (lowerText.contains('network') ||
        lowerText.contains('connection') ||
        lowerText.contains('socket')) {
      return ErrorType.networkError;
    }

    if (lowerText.contains('server') ||
        lowerText.contains('500') ||
        lowerText.contains('503') ||
        lowerText.contains('502')) {
      return ErrorType.serverError;
    }

    if (lowerText.contains('format') ||
        lowerText.contains('parse') ||
        lowerText.contains('json') ||
        lowerText.contains('xml')) {
      return ErrorType.dataFormatError;
    }

    return ErrorType.unknownError;
  }

  /// Creates a user-friendly error from a raw error string (fallback method).
  static UserFriendlyError fromErrorString(
    String errorText, {
    ErrorContext? context,
    Object? originalError,
    StackTrace? stackTrace,
  }) {
    final errorType = analyzeErrorText(errorText);
    final actions = <ErrorAction>[];

    // Add common actions based on error type
    switch (errorType) {
      case ErrorType.apiKeyError:
        if (context?.onConfigureApiKey != null) {
          actions.add(ErrorAction.configureApiKey(context!.onConfigureApiKey!));
        }
        if (context?.onRetry != null) {
          actions.add(ErrorAction.retry(context!.onRetry!));
        }
        return UserFriendlyError.apiKeyError(
          actions: actions,
          originalError: originalError,
          stackTrace: stackTrace,
        );

      case ErrorType.networkError:
        if (context?.onRetry != null) {
          actions.add(ErrorAction.retry(context!.onRetry!));
        }
        if (context?.onNetworkSettings != null) {
          actions.add(ErrorAction.networkSettings(context!.onNetworkSettings!));
        }
        return UserFriendlyError.networkError(
          actions: actions,
          originalError: originalError,
          stackTrace: stackTrace,
        );

      case ErrorType.serverError:
        if (context?.onRetry != null) {
          actions.add(ErrorAction.retry(context!.onRetry!));
        }
        return UserFriendlyError.serverError(
          actions: actions,
          originalError: originalError,
          stackTrace: stackTrace,
        );

      case ErrorType.timeoutError:
        if (context?.onRetry != null) {
          actions.add(ErrorAction.retry(context!.onRetry!));
        }
        return UserFriendlyError.timeoutError(
          actions: actions,
          originalError: originalError,
          stackTrace: stackTrace,
        );

      case ErrorType.dataFormatError:
        if (context?.onRetry != null) {
          actions.add(ErrorAction.retry(context!.onRetry!));
        }
        return UserFriendlyError.dataFormatError(
          actions: actions,
          originalError: originalError,
          stackTrace: stackTrace,
        );

      case ErrorType.unknownError:
        if (context?.onRetry != null) {
          actions.add(ErrorAction.retry(context!.onRetry!));
        }
        if (context?.onContactSupport != null) {
          actions.add(ErrorAction.contactSupport(context!.onContactSupport!));
        }
        return UserFriendlyError.unknownError(
          actions: actions,
          originalError: originalError,
          stackTrace: stackTrace,
          customMessage: errorText.isNotEmpty
              ? errorText
              : 'An unexpected error occurred. Please try again.',
        );
    }
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

/// Custom TimeoutException for timeout scenarios.
class TimeoutException implements Exception {
  final String message;

  const TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
