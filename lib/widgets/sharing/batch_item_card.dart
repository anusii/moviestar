/// Batch Sharing Item Card Widget.
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

import 'package:cached_network_image/cached_network_image.dart';

import 'package:moviestar/models/sharing_models.dart';
import 'package:moviestar/utils/movie_display_utils.dart';

/// A card widget that displays a file item in the batch sharing interface.
/// Shows file information, permissions, and poster image if available.

class BatchSharingItemCard extends StatelessWidget {
  /// The shareable file to display.

  final ShareableFile file;

  /// The index of this file in the sharing list.

  final int index;

  /// Callback when permissions are updated for this file.

  final void Function(int index, List<String> permissions) onPermissionsChanged;

  /// Creates a new [BatchSharingItemCard].

  const BatchSharingItemCard({
    super.key,
    required this.file,
    required this.index,
    required this.onPermissionsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isIndividualFile = file.fileType == 'movie' || file.fileType == 'tv';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
        color: isIndividualFile
            ? Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.3)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File header.

          Row(
            children: [
              Icon(
                file.fileType == 'movielist'
                    ? Icons.list_alt
                    : (file.fileType == 'tv' ? Icons.tv : Icons.movie),
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      file.fileType == 'movielist'
                          ? 'Movie List'
                          : file.fileType == 'tv'
                              ? 'TV Show File (Read-only)'
                              : 'Movie File (Read-only)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              if (file.movie != null && isValidImageUrl(file.movie!.posterUrl))
                SizedBox(
                  width: 30,
                  height: 45,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: file.movie!.posterUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.movie, size: 12),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.movie, size: 12),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Permission checkboxes or read-only indicator.

          if (isIndividualFile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: Colors.green[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Read-only access (automatic)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green[700],
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
            )
          else
            // Permission checkboxes for movie list only.

            Wrap(
              spacing: 16,
              children: [
                _buildPermissionCheckbox(context, 'read', 'Read'),
                _buildPermissionCheckbox(context, 'write', 'Write'),
                _buildPermissionCheckbox(context, 'append', 'Append'),
                _buildPermissionCheckbox(context, 'control', 'Control'),
              ],
            ),
        ],
      ),
    );
  }

  /// Build permission checkbox.
  /// Only enables interaction for movie list files.

  Widget _buildPermissionCheckbox(
    BuildContext context,
    String permission,
    String label,
  ) {
    final isChecked = file.permissions.contains(permission);
    final isIndividualFile = file.fileType == 'movie' || file.fileType == 'tv';

    return InkWell(
      onTap: isIndividualFile
          ? null
          : () {
              final newPermissions = List<String>.from(file.permissions);
              if (isChecked) {
                newPermissions.remove(permission);
              } else {
                newPermissions.add(permission);
              }
              onPermissionsChanged(index, newPermissions);
            },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: isChecked,
            onChanged: isIndividualFile
                ? null
                : (value) {
                    final newPermissions = List<String>.from(file.permissions);
                    if (value == true) {
                      newPermissions.add(permission);
                    } else {
                      newPermissions.remove(permission);
                    }
                    onPermissionsChanged(index, newPermissions);
                  },
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isIndividualFile
                      ? Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5)
                      : null,
                ),
          ),
        ],
      ),
    );
  }
}
