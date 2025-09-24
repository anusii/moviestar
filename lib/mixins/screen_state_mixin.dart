/// Mixin providing common screen state management functionality.
///
// Time-stamp: <Tuesday 2025-09-09 15:30:00 +1000 Claude>
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

import 'package:flutter/material.dart';

import 'package:moviestar/constants/timing_constants.dart';

/// Mixin that provides common state management functionality for screen widgets.
///
/// This mixin eliminates boilerplate code by providing:.
/// - Safe navigation methods with mounted checks.
/// - Loading state management.
/// - Consistent error and success messaging.
/// - Mounted-safe setState wrapper.

mixin ScreenStateMixin<T extends StatefulWidget> on State<T> {
  /// Whether the screen is currently in a loading state.

  bool _isLoading = false;

  /// Getter for current loading state.

  bool get isLoading => _isLoading;

  /// Safely calls setState only if the widget is still mounted.
  ///
  /// This prevents "setState() called after dispose()" errors that are.
  /// common when async operations complete after widget disposal.

  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  /// Sets the loading state and updates the UI safely.

  void setLoadingState(bool loading) {
    safeSetState(() {
      _isLoading = loading;
    });
  }

  /// Shows a loading state with optional message.

  void showLoading([String? message]) {
    setLoadingState(true);
    if (message != null) {
      showLoadingSnackBar(message);
    }
  }

  /// Hides the loading state.

  void hideLoading() {
    setLoadingState(false);
  }

  /// Safely navigates to a new route with mounted check.
  ///
  /// Returns the result from the navigation, or null if widget is not mounted.

  Future<U?> safeNavigateTo<U>(Route<U> route) async {
    if (!mounted) return null;
    return Navigator.push<U>(context, route);
  }

  /// Safely navigates to a named route with mounted check.

  Future<U?> safeNavigateToNamed<U>(
    String routeName, {
    Object? arguments,
  }) async {
    if (!mounted) return null;
    return Navigator.pushNamed<U>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Safely pops the current route if mounted.

  void safePop<U>([U? result]) {
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop<U>(context, result);
    }
  }

  /// Shows a loading snackbar with spinner.

  void showLoadingSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
        duration: TimingConstants.snackbarVeryLongDuration,
      ),
    );
  }

  /// Shows an error snackbar with consistent styling.

  void showErrorSnackBar(String message, {VoidCallback? onRetry}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
            if (onRetry != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onRetry,
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: TimingConstants.snackbarLongDuration,
      ),
    );
  }

  /// Shows a success snackbar with consistent styling.

  void showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: TimingConstants.snackbarStandardDuration,
      ),
    );
  }

  /// Shows an info snackbar with consistent styling.

  void showInfoSnackBar(String message, {Duration? duration}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: duration ?? TimingConstants.snackbarStandardDuration,
      ),
    );
  }

  /// Hides the current snackbar if one is showing.

  void hideCurrentSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Executes an async operation with automatic loading state management.
  ///
  /// Shows loading state during execution and handles errors automatically.
  /// Returns true if the operation succeeded, false if it failed.

  Future<bool> executeWithLoading(
    Future<void> Function() operation, {
    String? loadingMessage,
    String? successMessage,
    String? errorMessage,
    VoidCallback? onError,
  }) async {
    try {
      if (loadingMessage != null) {
        showLoadingSnackBar(loadingMessage);
      } else {
        showLoading();
      }

      await operation();

      hideCurrentSnackBar();
      hideLoading();

      if (successMessage != null) {
        showSuccessSnackBar(successMessage);
      }

      return true;
    } catch (e) {
      hideCurrentSnackBar();
      hideLoading();

      final message = errorMessage ?? 'Operation failed: $e';
      showErrorSnackBar(message, onRetry: onError);

      return false;
    }
  }

  /// Gets themed colors for consistent styling.

  ColorScheme get colorScheme => Theme.of(context).colorScheme;

  /// Gets themed text styles for consistent styling.

  TextTheme get textTheme => Theme.of(context).textTheme;
}
