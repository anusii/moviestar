/// Base utilities for Turtle serialization.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

/// Base class providing common utilities for all Turtle serializers.

abstract class TurtleBaseSerializer {
  /// Escapes special characters in strings for TTL format.

  static String escapeString(String input) {
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  /// Escapes and sanitizes strings for TTL format.

  static String escapeAndSanitizeString(String input) {
    return escapeString(input);
  }

  /// Generates a unique ID for resources.

  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (1000 + (DateTime.now().microsecond % 9000)).toString();
  }
}
