/// Widget interaction helpers for integration tests.
///
/// Provides extension methods on WidgetTester for common UI interactions
/// like tapping icons, entering text, and waiting for widgets.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

/// Extension methods for common widget interactions in tests.

extension WidgetTestHelpers on WidgetTester {
  /// Find and tap an icon if it exists.
  ///
  /// Returns true if the icon was found and tapped, false otherwise.
  ///
  /// [icon] - The IconData to search for.
  /// [settleDuration] - Duration to wait after tapping (default 2 seconds).

  Future<bool> tapIconIfExists(
    IconData icon, {
    Duration settleDuration = const Duration(seconds: 2),
  }) async {
    final finder = find.byIcon(icon);
    if (finder.evaluate().isNotEmpty) {
      await tap(finder.first);
      await pumpAndSettle(settleDuration);
      return true;
    }
    return false;
  }

  /// Find a TextField and enter text.
  ///
  /// Returns true if a TextField was found and text was entered, false otherwise.
  ///
  /// [text] - The text to enter.
  /// [settleDuration] - Duration to wait after entering text (default 2 seconds).

  Future<bool> enterTextInField(
    String text, {
    Duration settleDuration = const Duration(seconds: 2),
  }) async {
    final textField = find.byType(TextField);
    if (textField.evaluate().isNotEmpty) {
      await enterText(textField.first, text);
      await pumpAndSettle(settleDuration);
      return true;
    }
    return false;
  }

  /// Tap a widget by its text label if it exists.
  ///
  /// Returns true if the text was found and tapped, false otherwise.
  ///
  /// [text] - The text to search for.
  /// [settleDuration] - Duration to wait after tapping (default 2 seconds).

  Future<bool> tapByText(
    String text, {
    Duration settleDuration = const Duration(seconds: 2),
  }) async {
    final finder = find.text(text);
    if (finder.evaluate().isNotEmpty) {
      await tap(finder.first);
      await pumpAndSettle(settleDuration);
      return true;
    }
    return false;
  }

  /// Wait for a widget to appear with timeout.
  ///
  /// Returns true if the widget appeared within the timeout, false otherwise.
  ///
  /// [finder] - The Finder to search for.
  /// [timeout] - Maximum time to wait (default 10 seconds).
  /// [checkInterval] - Time between checks (default 500ms).

  Future<bool> waitForWidget(
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
    Duration checkInterval = const Duration(milliseconds: 500),
  }) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      await pump(checkInterval);
      if (finder.evaluate().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  /// Dismiss a dialog by tapping a button with the given text.
  ///
  /// Common for dismissing "Later" buttons on API key dialogs.
  ///
  /// Returns true if the button was found and tapped, false otherwise.
  ///
  /// [buttonText] - The text of the button to tap.
  /// [settleDuration] - Duration to wait after tapping (default 2 seconds).

  Future<bool> dismissDialogByText(
    String buttonText, {
    Duration settleDuration = const Duration(seconds: 2),
  }) async {
    return tapByText(buttonText, settleDuration: settleDuration);
  }
}
