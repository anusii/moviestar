/// A reusable widget for displaying error states with consistent styling.
///
// Time-stamp: <Friday 2025-02-21 17:30:00 +1100 Ashley Tang>
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
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

import 'package:flutter/material.dart';

import 'package:moviestar/models/app_error.dart';
import 'package:moviestar/widgets/error_display/legacy_error_renderer.dart';
import 'package:moviestar/widgets/error_display/user_friendly_error_renderer.dart';

/// A reusable widget for displaying error states with consistent styling.
///
/// This widget provides a standard way to display errors across the app,.
/// including an error icon, message, multiple action buttons, and expandable.
/// technical details for debugging.
///
/// Usage examples:.
/// ```dart.
/// // Using UserFriendlyError (recommended).
/// ErrorDisplayWidget.fromUserFriendlyError(.
///   error: userFriendlyError,.
/// ).
///
/// // Legacy usage for backward compatibility.
/// ErrorDisplayWidget(.
///   message: 'Failed to load data',.
///   onRetry: () => refreshData(),.
/// ).
///
/// // Compact error widget for smaller spaces.
/// ErrorDisplayWidget.compact(.
///   message: 'Failed to load movies',.
///   onRetry: () => retryLoad(),.
/// ).
/// ```.

class ErrorDisplayWidget extends StatelessWidget {
  /// The error message to display.

  final String message;

  /// Optional callback for retry functionality (legacy support).

  final VoidCallback? onRetry;

  /// Size of the error icon. Defaults to 48.

  final double iconSize;

  /// Size of the error message text. Defaults to 16.

  final double textSize;

  /// Whether to show the widget in compact mode (smaller sizes).

  final bool isCompact;

  /// The user-friendly error to display (preferred over individual fields).

  final UserFriendlyError? userFriendlyError;

  /// Whether to show technical details by default.

  final bool showTechnicalDetailsInitially;

  /// Creates a new [ErrorDisplayWidget].

  // ignore: avoid-unnecessary-nullable-parameters.

  const ErrorDisplayWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.iconSize = 48,
    this.textSize = 16,
    this.isCompact = false,
    this.userFriendlyError,
    this.showTechnicalDetailsInitially = false,
  });

  /// Creates an [ErrorDisplayWidget] from a [UserFriendlyError].

  const ErrorDisplayWidget.fromUserFriendlyError({
    super.key,
    required UserFriendlyError error,
    this.iconSize = 48,
    this.textSize = 16,
    this.isCompact = false,
    this.showTechnicalDetailsInitially = false,
  })  : message = '',
        onRetry = null,
        userFriendlyError = error;

  /// Creates a compact version of the error widget for smaller spaces.

  const ErrorDisplayWidget.compact({
    super.key,
    required this.message,
    this.onRetry,
    this.userFriendlyError,
    this.showTechnicalDetailsInitially = false,
  })  : iconSize = 32,
        textSize = 14,
        isCompact = true;

  /// Creates a compact version from a [UserFriendlyError].

  const ErrorDisplayWidget.compactFromUserFriendlyError({
    super.key,
    required UserFriendlyError error,
    this.showTechnicalDetailsInitially = false,
  })  : message = '',
        onRetry = null,
        iconSize = 32,
        textSize = 14,
        isCompact = true,
        userFriendlyError = error;

  @override
  Widget build(BuildContext context) {
    // Use UserFriendlyError if available, otherwise fall back to legacy fields.

    if (userFriendlyError != null) {
      return UserFriendlyErrorRenderer(
        error: userFriendlyError!,
        iconSize: iconSize,
        textSize: textSize,
        isCompact: isCompact,
        showTechnicalDetailsInitially: showTechnicalDetailsInitially,
      );
    } else {
      return LegacyErrorRenderer(
        message: message,
        onRetry: onRetry,
        iconSize: iconSize,
        textSize: textSize,
        isCompact: isCompact,
      );
    }
  }
}
