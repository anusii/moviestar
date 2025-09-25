/// Create app folder.
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

import 'package:solidpod/solidpod.dart';

import 'package:moviestar/constants/paths.dart';

/// Creates an app folder in POD with initialisation file.
///
/// Returns a [Future<SolidFunctionCallStatus>] indicating the creation result.
/// The [folderName] parameter specifies which folder to create (e.g. 'movies').
/// If [createInitFile] is true, creates an initialisation file in the folder.

Future<SolidFunctionCallStatus> createAppFolder({
  required String folderName,
  required BuildContext context,
  bool createInitFile = true,
  required void Function(bool) onProgressChange,
  required void Function() onSuccess,
}) async {
  try {
    onProgressChange.call(true);

    // Check current resources with retry logic for encryption key errors.

    final dirUrl = await getDirUrl(basePath);
    late List<String> existingFolders;
    late List<String> existingFiles;

    // Try multiple times with increasing delays to handle transient encryption issues.

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final resources = await getResourcesInContainer(dirUrl);
        existingFolders = resources.subDirs;
        existingFiles = resources.files;
        break; // Success - exit retry loop.
      } catch (e) {
        if (e.toString().contains('Duplicated encryption key') ||
            e.toString().contains('Invalid content in file') ||
            e.toString().contains('enc-keys.ttl')) {
          if (attempt < 3) {
            // Wait with exponential backoff before retrying.

            await Future.delayed(Duration(milliseconds: 500 * attempt));
            // Retrying silently.

            continue;
          } else {
            // Continue with empty lists - we'll try to create the folder anyway.

            existingFolders = [];
            existingFiles = [];
            break;
          }
        } else {
          // Re-throw other errors.

          rethrow;
        }
      }
    }

    // Check if exists as directory.

    bool existsAsDir = existingFolders.contains(folderName);
    if (existsAsDir) {
      onSuccess.call();
      return SolidFunctionCallStatus.success;
    }

    // Check if exists as file and delete if necessary.

    bool existsAsFile = existingFiles.contains(folderName);
    if (existsAsFile) {
      if (!context.mounted) return SolidFunctionCallStatus.fail;

      // Full path for deletion needs to include basePath (e.g. moviestar/data).

      await deleteFile('$basePath/$folderName');
    }

    if (!context.mounted) {
      return SolidFunctionCallStatus.fail;
    }

    // Create the app folder structure with retry logic for encryption issues.

    SolidFunctionCallStatus result = SolidFunctionCallStatus.fail;
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        result = await writePod(
          '$folderName/.init',
          '',
          context,
          const Text('Creating folder'),
          encrypted: false,
        );
        if (result == SolidFunctionCallStatus.success) break;
      } catch (e) {
        if (e.toString().contains('Duplicated encryption key') ||
            e.toString().contains('Invalid content in file') ||
            e.toString().contains('enc-keys.ttl')) {
          if (attempt == 1) {}
          if (attempt < 3) {
            await Future.delayed(Duration(milliseconds: 500 * attempt));
            continue;
          }
        }
        rethrow;
      }
    }

    // If folder creation was successful and initialization file is requested.

    if (result == SolidFunctionCallStatus.success && createInitFile) {
      String initContent;

      // Initialisation content for all folders in Turtle format.

      initContent = '''
@prefix : <#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

:folder "$folderName" ;
        :created "${DateTime.now().toIso8601String()}"^^xsd:dateTime ;
        :version "1.0" .
''';

      if (!context.mounted) return result;

      // Create initialization file with retry logic for encryption issues.

      SolidFunctionCallStatus initResult = SolidFunctionCallStatus.fail;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          initResult = await writePod(
            '$folderName/init.ttl',
            initContent,
            context,
            const Text('Creating initialization file'),
            encrypted: true,
          );
          if (initResult == SolidFunctionCallStatus.success) break;
        } catch (e) {
          if (e.toString().contains('Duplicated encryption key') ||
              e.toString().contains('Invalid content in file') ||
              e.toString().contains('enc-keys.ttl')) {
            if (attempt == 1) {}
            if (attempt < 3) {
              await Future.delayed(Duration(milliseconds: 500 * attempt));
              continue;
            }
            // For the final attempt, try creating without encryption as fallback.

            if (attempt == 3) {
              if (!context.mounted) throw Exception('Context not mounted');
              initResult = await writePod(
                '$folderName/init.ttl',
                initContent,
                context,
                const Text(
                  'Creating initialization file (unencrypted fallback)',
                ),
                encrypted: false,
              );
            }
          } else {
            rethrow;
          }
        }
      }

      if (initResult == SolidFunctionCallStatus.success) {
        onSuccess.call();
        return SolidFunctionCallStatus.success;
      }
    }

    return result;
  } catch (e) {
    return SolidFunctionCallStatus.fail;
  } finally {
    onProgressChange.call(false);
  }
}
