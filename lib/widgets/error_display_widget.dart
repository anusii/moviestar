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
import 'package:flutter/services.dart';

import 'package:gap/gap.dart';

import 'package:moviestar/models/app_error.dart';

/// A reusable widget for displaying error states with consistent styling.
///
/// This widget provides a standard way to display errors across the app,
/// including an error icon, message, multiple action buttons, and expandable
/// technical details for debugging.
///
/// Usage examples:
/// ```dart
/// // Using UserFriendlyError (recommended)
/// ErrorDisplayWidget.fromUserFriendlyError(
///   error: userFriendlyError,
/// )
///
/// // Legacy usage for backward compatibility
/// ErrorDisplayWidget(
///   message: 'Failed to load data',
///   onRetry: () => refreshData(),
/// )
///
/// // Compact error widget for smaller spaces
/// ErrorDisplayWidget.compact(
///   message: 'Failed to load movies',
///   onRetry: () => retryLoad(),
/// )
/// ```

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
    // Use UserFriendlyError if available, otherwise fall back to legacy fields
    if (userFriendlyError != null) {
      return _UserFriendlyErrorWidget(
        error: userFriendlyError!,
        iconSize: iconSize,
        textSize: textSize,
        isCompact: isCompact,
        showTechnicalDetailsInitially: showTechnicalDetailsInitially,
      );
    } else {
      return _LegacyErrorWidget(
        message: message,
        onRetry: onRetry,
        iconSize: iconSize,
        textSize: textSize,
        isCompact: isCompact,
      );
    }
  }
}

// Widget for displaying UserFriendlyError with full functionality.

class _UserFriendlyErrorWidget extends StatefulWidget {
  final UserFriendlyError error;
  final double iconSize;
  final double textSize;
  final bool isCompact;
  final bool showTechnicalDetailsInitially;

  const _UserFriendlyErrorWidget({
    required this.error,
    required this.iconSize,
    required this.textSize,
    required this.isCompact,
    required this.showTechnicalDetailsInitially,
  });

  @override
  State<_UserFriendlyErrorWidget> createState() =>
      _UserFriendlyErrorWidgetState();
}

class _UserFriendlyErrorWidgetState extends State<_UserFriendlyErrorWidget> {
  late bool _showTechnicalDetails;

  @override
  void initState() {
    super.initState();
    _showTechnicalDetails = widget.showTechnicalDetailsInitially;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = widget.error.color ?? theme.colorScheme.error;
    final surfaceColor = theme.colorScheme.surface;
    final onSurfaceColor = theme.colorScheme.onSurface;

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: widget.isCompact ? 300 : 400,
          maxHeight: MediaQuery.of(context).size.height *
              0.8, // Prevent full-screen overflow.
        ),
        margin: EdgeInsets.all(widget.isCompact ? 12.0 : 16.0),
        padding: EdgeInsets.all(widget.isCompact ? 16.0 : 20.0),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: errorColor.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: errorColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error icon and title.

              Row(
                children: [
                  Icon(
                    widget.error.icon,
                    size: widget.iconSize,
                    color: errorColor,
                  ),
                  Gap(widget.isCompact ? 8.0 : 12.0),
                  Expanded(
                    child: Text(
                      widget.error.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: errorColor,
                        fontWeight: FontWeight.bold,
                        fontSize: widget.textSize + (widget.isCompact ? 0 : 2),
                      ),
                    ),
                  ),
                ],
              ),

              Gap(widget.isCompact ? 8.0 : 12.0),

              // Error message.

              Text(
                widget.error.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: onSurfaceColor,
                  fontSize: widget.textSize - (widget.isCompact ? 1 : 0),
                ),
                textAlign: TextAlign.start,
              ),

              // Additional details (if available).

              if (widget.error.details != null) ...[
                Gap(widget.isCompact ? 6.0 : 8.0),
                Text(
                  widget.error.details!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onSurfaceColor.withValues(alpha: 0.8),
                    fontSize: widget.textSize - (widget.isCompact ? 2 : 1),
                  ),
                  textAlign: TextAlign.start,
                ),
              ],

              // Action buttons.

              if (widget.error.actions.isNotEmpty) ...[
                Gap(widget.isCompact ? 12.0 : 16.0),
                _buildActionButtons(),
              ],

              // Technical details section (expandable).

              if (widget.error.hasTechnicalDetails) ...[
                Gap(widget.isCompact ? 8.0 : 12.0),
                _buildTechnicalDetailsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final actions = widget.error.actions;

    if (actions.length == 1) {
      // Single action - full width button.

      final action = actions.first;
      return SizedBox(
        width: double.infinity,
        child: action.isPrimary
            ? ElevatedButton.icon(
                onPressed: action.onPressed,
                icon: action.icon != null ? Icon(action.icon) : null,
                label: Text(action.label),
              )
            : OutlinedButton.icon(
                onPressed: action.onPressed,
                icon: action.icon != null ? Icon(action.icon) : null,
                label: Text(action.label),
              ),
      );
    } else if (actions.length == 2) {
      // Two actions - side by side with equal heights.

      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: actions[1].isPrimary
                  ? ElevatedButton.icon(
                      onPressed: actions[1].onPressed,
                      icon: actions[1].icon != null
                          ? Icon(actions[1].icon)
                          : null,
                      label: Text(
                        actions[1].label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        minimumSize: const Size(0, 48),
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: actions[1].onPressed,
                      icon: actions[1].icon != null
                          ? Icon(actions[1].icon)
                          : null,
                      label: Text(
                        actions[1].label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        minimumSize: const Size(0, 48),
                      ),
                    ),
            ),
            const Gap(8),
            Expanded(
              child: actions[0].isPrimary
                  ? ElevatedButton.icon(
                      onPressed: actions[0].onPressed,
                      icon: actions[0].icon != null
                          ? Icon(actions[0].icon)
                          : null,
                      label: Text(
                        actions[0].label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        minimumSize: const Size(0, 48),
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: actions[0].onPressed,
                      icon: actions[0].icon != null
                          ? Icon(actions[0].icon)
                          : null,
                      label: Text(
                        actions[0].label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        minimumSize: const Size(0, 48),
                      ),
                    ),
            ),
          ],
        ),
      );
    } else {
      // Multiple actions - wrap them.

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: actions.map((action) {
          return action.isPrimary
              ? ElevatedButton.icon(
                  onPressed: action.onPressed,
                  icon: action.icon != null ? Icon(action.icon) : null,
                  label: Text(action.label),
                )
              : OutlinedButton.icon(
                  onPressed: action.onPressed,
                  icon: action.icon != null ? Icon(action.icon) : null,
                  label: Text(action.label),
                );
        }).toList(),
      );
    }
  }

  Widget _buildTechnicalDetailsSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Expandable header.

        InkWell(
          onTap: () {
            setState(() {
              _showTechnicalDetails = !_showTechnicalDetails;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  _showTechnicalDetails ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const Gap(4),
                Text(
                  'Technical Details',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Technical details content (expandable).

        if (_showTechnicalDetails) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(
              maxHeight: 200, // Limit height to prevent overflow.
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Technical details text with scrolling.

                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      widget.error.technicalDetails,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),

                const Gap(8),

                // Copy to clipboard button with scroll hint.

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Scroll hint text
                    Expanded(
                      child: Text(
                        'Scroll to view all details',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                      ),
                    ),
                    // Copy button.

                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: widget.error.technicalDetails),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Technical details copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Legacy error widget for backward compatibility.

class _LegacyErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final double iconSize;
  final double textSize;
  final bool isCompact;

  const _LegacyErrorWidget({
    required this.message,
    this.onRetry,
    required this.iconSize,
    required this.textSize,
    required this.isCompact,
  });

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
            Gap(isCompact ? 8.0 : 16.0),
            Text(
              message,
              style: TextStyle(color: errorColor, fontSize: textSize),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              Gap(isCompact ? 8.0 : 16.0),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
