/// Utility functions for Turtle serialization
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'dart:math';

/// Utility functions for Turtle/RDF processing
class TurtleUtils {
  /// Generates a unique ID for RDF resources
  static String generateId() {
    final random = Random();
    return random.nextInt(1000000).toString();
  }

  /// Escapes special characters in strings for Turtle format
  static String escapeString(String input) {
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  /// Escapes and sanitizes strings for RDF literals
  static String escapeAndSanitizeString(String input) {
    if (input.isEmpty) return input;

    return input
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t')
        .replaceAll('\u0008', '\\b')
        .replaceAll('\u000c', '\\f')
        .replaceAll('\u0001', '')
        .replaceAll('\u0002', '')
        .replaceAll('\u0003', '')
        .replaceAll('\u0004', '')
        .replaceAll('\u0005', '')
        .replaceAll('\u0006', '')
        .replaceAll('\u0007', '')
        .replaceAll('\u000e', '')
        .replaceAll('\u000f', '')
        .replaceAll('\u0010', '')
        .replaceAll('\u0011', '')
        .replaceAll('\u0012', '')
        .replaceAll('\u0013', '')
        .replaceAll('\u0014', '')
        .replaceAll('\u0015', '')
        .replaceAll('\u0016', '')
        .replaceAll('\u0017', '')
        .replaceAll('\u0018', '')
        .replaceAll('\u0019', '')
        .replaceAll('\u001a', '')
        .replaceAll('\u001b', '')
        .replaceAll('\u001c', '')
        .replaceAll('\u001d', '')
        .replaceAll('\u001e', '')
        .replaceAll('\u001f', '')
        .replaceAll('\u007f', '');
  }

  /// Validates if a string contains valid UTF-8 characters for RDF
  static bool isValidRdfString(String input) {
    if (input.isEmpty) return true;

    // Check for control characters that aren't allowed in RDF
    for (int i = 0; i < input.length; i++) {
      final char = input.codeUnitAt(i);
      if ((char < 0x20 && char != 0x09 && char != 0x0A && char != 0x0D) ||
          char == 0x7F) {
        return false;
      }
    }

    return true;
  }

  /// Creates a safe RDF URI local name from a string
  static String createSafeLocalName(String input) {
    if (input.isEmpty) return 'unnamed';

    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
