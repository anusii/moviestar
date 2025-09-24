/// Batch Sharing Progress Tracker Widget.
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

import 'package:cached_network_image/cached_network_image.dart';

import 'package:moviestar/models/sharing_models.dart';
import 'package:moviestar/utils/movie_display_utils.dart';

/// A widget that displays the progress of batch sharing operations.
/// Shows current operation status and progress for each file.

class BatchSharingProgressTracker extends StatelessWidget {
  /// Current operation being performed.

  final String currentOperation;

  /// List of files being shared.

  final List<ShareableFile> shareableFiles;

  /// Progress status for each file (fileName -> status).

  final Map<String, String> sharingProgress;

  /// Creates a new [BatchSharingProgressTracker].

  const BatchSharingProgressTracker({
    super.key,
    required this.currentOperation,
    required this.shareableFiles,
    required this.sharingProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress header.

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    currentOperation,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Files progress list.

          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Files Progress',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: shareableFiles.length,
                        itemBuilder: (context, index) {
                          final file = shareableFiles[index];
                          final progress =
                              sharingProgress[file.fileName] ?? 'pending';

                          return _buildProgressItem(context, file, progress);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a single progress item for a file.

  Widget _buildProgressItem(
    BuildContext context,
    ShareableFile file,
    String progress,
  ) {
    final (icon, iconColor) = _getProgressIcon(progress);

    return ListTile(
      leading: progress == 'sharing'
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              ),
            )
          : Icon(icon, color: iconColor),
      title: Text(file.displayName),
      subtitle: Text(
        '${file.fileType} • ${file.permissions.join(", ")}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: file.movie != null && isValidImageUrl(file.movie!.posterUrl)
          ? SizedBox(
              width: 40,
              height: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: file.movie!.posterUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.movie, size: 16),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.movie, size: 16),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  /// Get the appropriate icon and color for a progress status.

  (IconData, Color) _getProgressIcon(String progress) {
    switch (progress) {
      case 'success':
        return (Icons.check_circle, Colors.green);
      case 'failed':
      case 'error':
        return (Icons.error, Colors.red);
      case 'sharing':
        return (Icons.sync, Colors.blue);
      case 'skipped':
        return (Icons.skip_next, Colors.orange);
      default:
        return (Icons.pending, Colors.grey);
    }
  }
}
