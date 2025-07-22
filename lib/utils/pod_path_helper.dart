/// Utility functions to handle solidpod path discrepancies between writePod and readPod.
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

import 'package:solidpod/solidpod.dart';

/// Gets the correct path for reading files from POD.
///
/// Due to a discrepancy in solidpod:
/// - writePod automatically prepends getDataDirPath() to the fileName
/// - readPod uses the filePath directly without preprocessing
///
/// This function constructs the full path that readPod needs to match
/// what writePod actually writes.

Future<String> getReadPath(String relativePath) async {
  final dataDir = await getDataDirPath();
  return '$dataDir/$relativePath';
}

/// Gets the write path for POD operations.
///
/// For writePod, use the relative path directly since writePod
/// automatically handles the data directory prefix.

String getWritePath(String relativePath) {
  return relativePath;
}

/// Ensures consistent path formatting by removing leading/trailing slashes
/// and normalizing path separators.

String normalizePath(String path) {
  return path
      .replaceAll(RegExp(r'^/+'), '')
      .replaceAll(RegExp(r'/+$'), '')
      .replaceAll('\\', '/');
}
