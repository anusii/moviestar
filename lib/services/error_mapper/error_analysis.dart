/// Error analysis utilities for error mapper service.
/// Extracted to reduce file size and improve organization.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/models/app_error.dart';

/// Handles error text analysis and error creation from strings.
class ErrorAnalysis {
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
    VoidCallback? onRetry,
    VoidCallback? onConfigureApiKey,
    VoidCallback? onNetworkSettings,
    VoidCallback? onContactSupport,
    Object? originalError,
    StackTrace? stackTrace,
  }) {
    final errorType = analyzeErrorText(errorText);
    final actions = <ErrorAction>[];

    // Add common actions based on error type
    switch (errorType) {
      case ErrorType.apiKeyError:
        if (onConfigureApiKey != null) {
          actions.add(ErrorAction.configureApiKey(onConfigureApiKey));
        }
        if (onRetry != null) {
          actions.add(ErrorAction.retry(onRetry));
        }
        return UserFriendlyError.apiKeyError(
          actions: actions,
          originalError: originalError,
          stackTrace: stackTrace,
        );

      case ErrorType.networkError:
        if (onRetry != null) {
          actions.add(ErrorAction.retry(onRetry));
        }
        if (onNetworkSettings != null) {
          actions.add(ErrorAction.networkSettings(onNetworkSettings));
        }
        return UserFriendlyError.networkError(
          actions: actions,
          originalError: originalError,
          stackTrace: stackTrace,
        );

      case ErrorType.serverError:
        if (onRetry != null) {
          actions.add(ErrorAction.retry(onRetry));
        }
        return UserFriendlyError.serverError(
          actions: actions,
          originalError: originalError,
          stackTrace: stackTrace,
        );

      case ErrorType.timeoutError:
        if (onRetry != null) {
          actions.add(ErrorAction.retry(onRetry));
        }
        return UserFriendlyError.timeoutError(
          actions: actions,
          originalError: originalError,
          stackTrace: stackTrace,
        );

      case ErrorType.dataFormatError:
        if (onRetry != null) {
          actions.add(ErrorAction.retry(onRetry));
        }
        return UserFriendlyError.dataFormatError(
          actions: actions,
          originalError: originalError,
          stackTrace: stackTrace,
        );

      case ErrorType.unknownError:
        if (onRetry != null) {
          actions.add(ErrorAction.retry(onRetry));
        }
        if (onContactSupport != null) {
          actions.add(ErrorAction.contactSupport(onContactSupport));
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
}
