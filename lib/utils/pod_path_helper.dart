/// Utility functions to handle solidpod path discrepancies between writePod and readPod.
///
// Time-stamp: <Thursday 2025-04-10 11:47:48 +1000 Graham Williams>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Ashley Tang.

library;

import 'package:solidpod/solidpod.dart';

/// Gets the full POD data path for reading files from POD.
///
/// Both readPod and writePod default to PathType.relativeToData,
/// automatically prepending getDataDirPath() to the fileName.
/// PodFileOperationsService handles prefix normalisation centrally,
/// so callers rarely need this helper directly.

Future<String> getReadPath(String relativePath) async {
  final dataDir = await getDataDirPath();
  return '$dataDir/$relativePath';
}
