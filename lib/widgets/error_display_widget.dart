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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

/// A reusable widget for displaying error states with consistent styling.
///
/// This widget provides a standard way to display errors across the app,
/// including an error icon, message, and optional retry button.
///
/// Usage examples:
/// ```dart
/// // Full-size error widget for main content areas
/// ErrorDisplayWidget(
///   message: 'Failed to load data',
///   onRetry: () => refreshData(),
/// )
///
/// // Compact error widget for smaller spaces like horizontal lists
/// ErrorDisplayWidget.compact(
///   message: 'Failed to load movies',
///   onRetry: () => retryLoad(),
/// )
///
/// // Error widget without retry button
/// ErrorDisplayWidget(
///   message: 'No internet connection',
/// )
/// ```

class ErrorDisplayWidget extends StatelessWidget {
  /// The error message to display.

  final String message;

  /// Optional callback for retry functionality.

  final VoidCallback? onRetry;

  /// Size of the error icon. Defaults to 48.

  final double iconSize;

  /// Size of the error message text. Defaults to 16.

  final double textSize;

  /// Whether to show the widget in compact mode (smaller sizes).

  final bool isCompact;

  /// Creates a new [ErrorDisplayWidget].

  const ErrorDisplayWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.iconSize = 48,
    this.textSize = 16,
    this.isCompact = false,
  });

  /// Creates a compact version of the error widget for smaller spaces.

  const ErrorDisplayWidget.compact({
    super.key,
    required this.message,
    this.onRetry,
  })  : iconSize = 32,
        textSize = 14,
        isCompact = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: iconSize, color: errorColor),
            SizedBox(height: isCompact ? 8.0 : 16.0),
            Text(
              message,
              style: TextStyle(color: errorColor, fontSize: textSize),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: isCompact ? 8.0 : 16.0),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
