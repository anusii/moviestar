/// Batch Sharing Permissions Panel Widget.
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

import 'package:flutter/material.dart';

import 'package:moviestar/models/sharing_models.dart';
import 'package:moviestar/widgets/sharing/batch_item_card.dart';

/// A panel that displays and manages file permissions for batch sharing.
/// Shows files with configurable permissions and reset functionality.

class BatchSharingPermissionsPanel extends StatelessWidget {
  /// List of files to be shared with their permissions.

  final List<ShareableFile> shareableFiles;

  /// Callback when file permissions are updated.

  final void Function(int index, List<String> permissions) onPermissionsChanged;

  /// Callback when permissions should be reset to defaults.

  final VoidCallback onResetPermissions;

  /// Creates a new [BatchSharingPermissionsPanel].

  const BatchSharingPermissionsPanel({
    super.key,
    required this.shareableFiles,
    required this.onPermissionsChanged,
    required this.onResetPermissions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Files & Permissions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure permissions for the movie list. Movie files are automatically set to read-only:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 4),
            _buildInfoBanner(context),
            const SizedBox(height: 12),

            // Reset button.

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onResetPermissions,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text(
                  'Reset to Defaults',
                  style: TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Files list with permission controls.

            ...shareableFiles.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: BatchSharingItemCard(
                  file: file,
                  index: index,
                  onPermissionsChanged: onPermissionsChanged,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Build the informational banner about movie file permissions.

  Widget _buildInfoBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Movie files are automatically shared with read-only permissions for security. Only configure permissions for the movie list.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue[700],
                    fontSize: 12,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
