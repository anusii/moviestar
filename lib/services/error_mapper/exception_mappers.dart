/// Exception mapping utilities for error mapper service.
/// Extracted to reduce file size and improve organization.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:moviestar/models/app_error.dart';
import 'package:moviestar/utils/network_client.dart';

/// Handles mapping of specific exception types to user-friendly errors.

class ExceptionMappers {
  /// Maps NetworkException to user-friendly error.

  static UserFriendlyError mapNetworkException(
    NetworkException error,
    StackTrace stackTrace,
    List<ErrorAction> actions,
  ) {
    // Analyze status code to determine error type and actions.

    if (error.statusCode == 401) {
      return UserFriendlyError.apiKeyError(
        actions: actions,
        originalError: error,
        stackTrace: stackTrace,
      );
    } else if (error.statusCode != null && error.statusCode! >= 500) {
      return UserFriendlyError.serverError(
        actions: actions,
        originalError: error,
        stackTrace: stackTrace,
      );
    } else if (error.statusCode == 403) {
      return UserFriendlyError.apiKeyError(
        actions: actions,
        originalError: error,
        stackTrace: stackTrace,
      );
    } else if (error.statusCode == 404) {
      return UserFriendlyError.unknownError(
        actions: actions,
        originalError: error,
        stackTrace: stackTrace,
        customMessage:
            'The requested resource was not found. This may be a temporary issue.',
      );
    } else {
      return UserFriendlyError.networkError(
        actions: actions,
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Maps HTTP ClientException to user-friendly error.

  static UserFriendlyError mapHttpClientException(
    http.ClientException error,
    StackTrace stackTrace,
    List<ErrorAction> actions,
  ) {
    return UserFriendlyError.networkError(
      actions: actions,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Maps SocketException to user-friendly error.

  static UserFriendlyError mapSocketException(
    SocketException error,
    StackTrace stackTrace,
    List<ErrorAction> actions,
  ) {
    return UserFriendlyError.networkError(
      actions: actions,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Maps FormatException to user-friendly error.

  static UserFriendlyError mapFormatException(
    FormatException error,
    StackTrace stackTrace,
    List<ErrorAction> actions,
  ) {
    return UserFriendlyError.dataFormatError(
      actions: actions,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Maps TimeoutException to user-friendly error.

  static UserFriendlyError mapTimeoutException(
    TimeoutException error,
    StackTrace stackTrace,
    List<ErrorAction> actions,
  ) {
    return UserFriendlyError.timeoutError(
      actions: actions,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Maps unknown exceptions to user-friendly error.

  static UserFriendlyError mapUnknownException(
    Object error,
    StackTrace stackTrace,
    List<ErrorAction> actions,
  ) {
    return UserFriendlyError.unknownError(
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
