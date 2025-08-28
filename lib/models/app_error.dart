/// Models for handling application errors in a user-friendly way.
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
/// Authors: Claude Code

library;

import 'package:flutter/material.dart';

/// Types of errors that can occur in the application.
enum ErrorType {
  /// API key is missing or invalid (401 errors).
  apiKeyError,

  /// Network connectivity issues.
  networkError,

  /// Server is temporarily unavailable (5xx errors).
  serverError,

  /// Request timed out.
  timeoutError,

  /// Invalid data format or parsing errors.
  dataFormatError,

  /// Unknown or unexpected errors.
  unknownError,
}

/// Types of actions users can take to resolve errors.
enum ErrorActionType {
  /// Retry the failed operation.
  retry,

  /// Navigate to API key configuration.
  configureApiKey,

  /// Navigate to network settings.
  networkSettings,

  /// Contact support.
  contactSupport,

  /// Dismiss the error.
  dismiss,
}

/// Represents an action that can be taken to resolve an error.
class ErrorAction {
  /// The type of action.
  final ErrorActionType type;

  /// The label to display on the action button.
  final String label;

  /// The callback to execute when the action is triggered.
  final VoidCallback onPressed;

  /// Icon to display with the action (optional).
  final IconData? icon;

  /// Whether this action is the primary action (highlighted).
  final bool isPrimary;

  const ErrorAction({
    required this.type,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = false,
  });

  /// Creates a retry action.
  static ErrorAction retry(VoidCallback onRetry) {
    return ErrorAction(
      type: ErrorActionType.retry,
      label: 'Retry',
      onPressed: onRetry,
      icon: Icons.refresh,
      isPrimary: true,
    );
  }

  /// Creates a configure API key action.
  static ErrorAction configureApiKey(VoidCallback onConfigure) {
    return ErrorAction(
      type: ErrorActionType.configureApiKey,
      label: 'Configure API Key',
      onPressed: onConfigure,
      icon: Icons.vpn_key,
      isPrimary: true,
    );
  }

  /// Creates a network settings action.
  static ErrorAction networkSettings(VoidCallback onSettings) {
    return ErrorAction(
      type: ErrorActionType.networkSettings,
      label: 'Network Settings',
      onPressed: onSettings,
      icon: Icons.settings,
    );
  }

  /// Creates a contact support action.
  static ErrorAction contactSupport(VoidCallback onContact) {
    return ErrorAction(
      type: ErrorActionType.contactSupport,
      label: 'Contact Support',
      onPressed: onContact,
      icon: Icons.help_outline,
    );
  }

  /// Creates a dismiss action.
  static ErrorAction dismiss(VoidCallback onDismiss) {
    return ErrorAction(
      type: ErrorActionType.dismiss,
      label: 'Dismiss',
      onPressed: onDismiss,
      icon: Icons.close,
    );
  }
}

/// Represents a user-friendly error with actionable guidance.
class UserFriendlyError {
  /// The type of error.
  final ErrorType type;

  /// User-friendly title for the error.
  final String title;

  /// User-friendly message explaining what went wrong.
  final String message;

  /// Additional details or suggestions for resolution.
  final String? details;

  /// Actions the user can take to resolve the error.
  final List<ErrorAction> actions;

  /// The original technical error (for debugging/logging).
  final Object? originalError;

  /// The original stack trace (for debugging/logging).
  final StackTrace? stackTrace;

  /// Icon to display with the error.
  final IconData icon;

  /// Color theme for the error display.
  final Color? color;

  const UserFriendlyError({
    required this.type,
    required this.title,
    required this.message,
    this.details,
    this.actions = const [],
    this.originalError,
    this.stackTrace,
    this.icon = Icons.error_outline,
    this.color,
  });

  /// Creates an API key error.
  static UserFriendlyError apiKeyError({
    required List<ErrorAction> actions,
    Object? originalError,
    StackTrace? stackTrace,
  }) {
    return UserFriendlyError(
      type: ErrorType.apiKeyError,
      title: 'API Key Issue',
      message:
          'Your API key is missing or invalid. Please configure your API key to continue.',
      details:
          'You need a valid TMDB API key to fetch movie information. Get one free at https://www.themoviedb.org/settings/api',
      actions: actions,
      originalError: originalError,
      stackTrace: stackTrace,
      icon: Icons.vpn_key_off,
    );
  }

  /// Creates a network error.
  static UserFriendlyError networkError({
    required List<ErrorAction> actions,
    Object? originalError,
    StackTrace? stackTrace,
  }) {
    return UserFriendlyError(
      type: ErrorType.networkError,
      title: 'Connection Problem',
      message:
          'Unable to connect to the internet. Please check your connection and try again.',
      details:
          'Make sure you have a stable internet connection and that your device is not in airplane mode.',
      actions: actions,
      originalError: originalError,
      stackTrace: stackTrace,
      icon: Icons.wifi_off,
    );
  }

  /// Creates a server error.
  static UserFriendlyError serverError({
    required List<ErrorAction> actions,
    Object? originalError,
    StackTrace? stackTrace,
  }) {
    return UserFriendlyError(
      type: ErrorType.serverError,
      title: 'Server Temporarily Unavailable',
      message:
          'The movie database is temporarily unavailable. Please try again in a few minutes.',
      details:
          'This is usually a temporary issue that resolves itself quickly.',
      actions: actions,
      originalError: originalError,
      stackTrace: stackTrace,
      icon: Icons.cloud_off,
    );
  }

  /// Creates a timeout error.
  static UserFriendlyError timeoutError({
    required List<ErrorAction> actions,
    Object? originalError,
    StackTrace? stackTrace,
  }) {
    return UserFriendlyError(
      type: ErrorType.timeoutError,
      title: 'Request Timed Out',
      message:
          'The request took too long to complete. This might be due to a slow connection.',
      details: 'Try again, or check if your internet connection is stable.',
      actions: actions,
      originalError: originalError,
      stackTrace: stackTrace,
      icon: Icons.hourglass_empty,
    );
  }

  /// Creates a data format error.
  static UserFriendlyError dataFormatError({
    required List<ErrorAction> actions,
    Object? originalError,
    StackTrace? stackTrace,
  }) {
    return UserFriendlyError(
      type: ErrorType.dataFormatError,
      title: 'Data Format Issue',
      message:
          'Received unexpected data from the server. This may be a temporary issue.',
      details:
          'The server returned data in an unexpected format. Please try again.',
      actions: actions,
      originalError: originalError,
      stackTrace: stackTrace,
      icon: Icons.broken_image,
    );
  }

  /// Creates an unknown error.
  static UserFriendlyError unknownError({
    required List<ErrorAction> actions,
    Object? originalError,
    StackTrace? stackTrace,
    String? customMessage,
  }) {
    return UserFriendlyError(
      type: ErrorType.unknownError,
      title: 'Something Went Wrong',
      message:
          customMessage ?? 'An unexpected error occurred. Please try again.',
      details: 'If this problem continues, please contact support.',
      actions: actions,
      originalError: originalError,
      stackTrace: stackTrace,
      icon: Icons.error_outline,
    );
  }

  /// Whether this error has technical details available for debugging.
  bool get hasTechnicalDetails => originalError != null;

  /// Gets the technical error details as a formatted string.
  String get technicalDetails {
    if (originalError == null) return 'No technical details available';

    final buffer = StringBuffer();
    buffer.writeln('Error: ${originalError.toString()}');

    if (stackTrace != null) {
      buffer.writeln('\nStack Trace:');
      buffer.writeln(stackTrace.toString());
    }

    return buffer.toString();
  }
}
