/// Script to convert relative imports to package imports in Moviestar app.
///
// Time-stamp: <Thursday 2025-04-10 11:47:48 +1000 Graham Williams>
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
/// Authors: Ashley Tang

library;

import 'dart:io';

import 'package:flutter/material.dart';

void main() async {
  debugPrint('Starting import conversion for MovieStar project...');
  final libDir = Directory('lib');

  if (!await libDir.exists()) {
    debugPrint(
      'Error: lib/ directory not found. Please run this script from the project root.',
    );
    exit(1);
  }

  await convertImportsInDirectory(libDir);
  debugPrint('Import conversion completed successfully!');
}

/// Recursively processes all .dart files in the given directory.

Future<void> convertImportsInDirectory(Directory dir) async {
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      await convertImportsInFile(entity);
    }
  }
}

/// Converts relative imports to package imports in a single file.

Future<void> convertImportsInFile(File file) async {
  final content = await file.readAsString();
  final lines = content.split('\n');
  bool hasChanges = false;

  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();

    // Check if this is a relative import line (either ../ or local).

    if (line.startsWith('import ') &&
        (line.contains('../') || isLocalImport(line))) {
      // Extract the import path.

      final startQuote =
          line.contains("'") ? line.indexOf("'") : line.indexOf('"');
      final endQuote = line.lastIndexOf("'") != -1
          ? line.lastIndexOf("'")
          : line.lastIndexOf('"');

      if (startQuote != -1 && endQuote != -1 && startQuote < endQuote) {
        final importPath = line.substring(startQuote + 1, endQuote);

        if (importPath.startsWith('../') || isLocalDartFile(importPath)) {
          // Convert relative path to package path.

          final packagePath = convertRelativeToPackagePath(
            importPath,
            file.path,
          );

          if (packagePath != null) {
            final quote = line.contains("'") ? "'" : '"';
            lines[i] = 'import ${quote}package:moviestar/$packagePath$quote;';
            hasChanges = true;
            debugPrint(
              '✓ ${file.path}: $importPath → package:moviestar/$packagePath',
            );
          }
        }
      }
    }
  }

  if (hasChanges) {
    await file.writeAsString(lines.join('\n'));
  }
}

/// Checks if a line contains a local import (same directory .dart file).

bool isLocalImport(String line) {
  final startQuote = line.contains("'") ? line.indexOf("'") : line.indexOf('"');
  final endQuote = line.lastIndexOf("'") != -1
      ? line.lastIndexOf("'")
      : line.lastIndexOf('"');

  if (startQuote != -1 && endQuote != -1 && startQuote < endQuote) {
    final importPath = line.substring(startQuote + 1, endQuote);
    return isLocalDartFile(importPath);
  }
  return false;
}

/// Determines if an import path is a local .dart file (not package: or dart:).

bool isLocalDartFile(String importPath) {
  return importPath.endsWith('.dart') &&
      !importPath.startsWith('package:') &&
      !importPath.startsWith('dart:') &&
      !importPath.contains('/') &&
      !importPath.startsWith('../');
}

/// Converts a relative import path to a package import path.
///
/// Examples:
/// - ../models/movie.dart (from screens/) → models/movie.dart
/// - movie_details_screen.dart (from screens/) → screens/movie_details_screen.dart
/// - ../utils/network_client.dart (from services/) → utils/network_client.dart

String? convertRelativeToPackagePath(
  String relativePath,
  String currentFilePath,
) {
  // Normalise path separators to forward slashes.

  final normalizedPath = currentFilePath.replaceAll('\\', '/');

  // Find the lib directory in the path.

  int libIndex = normalizedPath.lastIndexOf('/lib/');
  int libStart;

  if (libIndex != -1) {
    // +5 for '/lib/'.

    libStart = libIndex + 5;
  } else {
    // Check if path starts with 'lib/'.

    if (normalizedPath.startsWith('lib/')) {
      // +4 for 'lib/'.

      libStart = 4;
    } else {
      return null;
    }
  }

  final currentFileRelative = normalizedPath.substring(libStart);
  final pathParts = currentFileRelative.split('/');

  // Remove the filename to get directory parts.

  final currentDirParts = pathParts.take(pathParts.length - 1).toList();

  // Handle local imports (same directory).

  if (!relativePath.contains('/') && !relativePath.startsWith('../')) {
    final allParts = <String>[];
    allParts.addAll(currentDirParts);
    allParts.add(relativePath);
    final packagePath = allParts.join('/');
    return packagePath.isEmpty ? null : packagePath;
  }

  // Split the relative path into parts.

  final parts = relativePath.split('/');

  // Process '../' parts to go up directories.

  int upLevels = 0;
  int startIndex = 0;

  for (int i = 0; i < parts.length; i++) {
    if (parts[i] == '..') {
      upLevels++;
      startIndex = i + 1;
    } else {
      break;
    }
  }

  // Calculate the target directory.

  final targetDirDepth = currentDirParts.length - upLevels;
  // Invalid path.

  if (targetDirDepth < 0) return null;

  final targetDirParts = currentDirParts.take(targetDirDepth).toList();
  final remainingParts = parts.skip(startIndex).toList();

  // Combine to get the package path.

  final allParts = <String>[];
  allParts.addAll(targetDirParts);
  allParts.addAll(remainingParts);
  final packagePath = allParts.join('/');

  return packagePath.isEmpty ? null : packagePath;
}
