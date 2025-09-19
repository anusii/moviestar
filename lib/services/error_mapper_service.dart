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

import 'package:http/http.dart' as http;

import 'package:moviestar/models/app_error.dart';
import 'package:moviestar/services/error_mapper/error_analysis.dart';
import 'package:moviestar/services/error_mapper/exception_mappers.dart';
import 'package:moviestar/services/error_mapper/smart_detection.dart';
import 'package:moviestar/utils/network_client.dart';

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
    try {
      return await SmartErrorDetection.mapErrorSmart(error, stackTrace,
          context: context);
    } catch (e) {
      // Fall back to traditional error mapping
      return _mapErrorTraditionally(error, stackTrace, context);
    }
  }

  /// Maps errors using traditional logic (fallback).
  static UserFriendlyError _mapErrorTraditionally(
    Object error,
    StackTrace stackTrace,
    ErrorContext? context,
  ) {
    final actions = _buildActions(context);

    if (error is NetworkException) {
      return ExceptionMappers.mapNetworkException(error, stackTrace, actions);
    } else if (error is http.ClientException) {
      return ExceptionMappers.mapHttpClientException(
          error, stackTrace, actions);
    } else if (error is SocketException) {
      return ExceptionMappers.mapSocketException(error, stackTrace, actions);
    } else if (error is FormatException) {
      return ExceptionMappers.mapFormatException(error, stackTrace, actions);
    } else if (error is TimeoutException) {
      return ExceptionMappers.mapTimeoutException(error, stackTrace, actions);
    } else {
      return ExceptionMappers.mapUnknownException(error, stackTrace, actions);
    }
  }

  /// Builds actions list based on context.
  static List<ErrorAction> _buildActions(ErrorContext? context) {
    final actions = <ErrorAction>[];

    if (context?.onRetry != null) {
      actions.add(ErrorAction.retry(context!.onRetry!));
    }
    if (context?.onConfigureApiKey != null) {
      actions.add(ErrorAction.configureApiKey(context!.onConfigureApiKey!));
    }
    if (context?.onNetworkSettings != null) {
      actions.add(ErrorAction.networkSettings(context!.onNetworkSettings!));
    }
    if (context?.onContactSupport != null) {
      actions.add(ErrorAction.contactSupport(context!.onContactSupport!));
    }

    return actions;
  }

  /// Analyzes error text to detect specific patterns and suggest appropriate error types.
  static ErrorType analyzeErrorText(String errorText) {
    return ErrorAnalysis.analyzeErrorText(errorText);
  }

  /// Creates a user-friendly error from a raw error string (fallback method).
  static UserFriendlyError fromErrorString(
    String errorText, {
    ErrorContext? context,
    Object? originalError,
    StackTrace? stackTrace,
  }) {
    return ErrorAnalysis.fromErrorString(
      errorText,
      onRetry: context?.onRetry,
      onConfigureApiKey: context?.onConfigureApiKey,
      onNetworkSettings: context?.onNetworkSettings,
      onContactSupport: context?.onContactSupport,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }
}
