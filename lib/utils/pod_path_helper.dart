/// Utility functions to handle solidpod path discrepancies between writePod and readPod.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

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
      .replaceAll(RegExp(r'^/+'), '') // Remove leading slashes
      .replaceAll(RegExp(r'/+$'), '') // Remove trailing slashes
      .replaceAll('\\', '/'); // Normalize separators
}
