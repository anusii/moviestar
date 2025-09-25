/// Display and interaction widgets for sharing in MovieStar.
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
/// Authors: Software Innovation Institute.

library;

import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:solidpod/solidpod.dart' show GrantPermissionUi;

import 'package:moviestar/widgets/sharing/components.dart';
import 'package:moviestar/widgets/sharing/form_widgets.dart';

/// Sharing status indicator.

class SharingStatusIndicator extends StatelessWidget {
  final ShareStatus status;
  final String? message;
  final VoidCallback? onRetry;

  const SharingStatusIndicator({
    super.key,
    required this.status,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String defaultMessage;

    switch (status) {
      case ShareStatus.idle:
        icon = Icons.share;
        color = Theme.of(context).colorScheme.secondary;
        defaultMessage = 'Ready to share';
        break;
      case ShareStatus.sharing:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                message ?? 'Sharing...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      case ShareStatus.success:
        icon = Icons.check_circle;
        color = Colors.green;
        defaultMessage = 'Successfully shared';
        break;
      case ShareStatus.error:
        icon = Icons.error;
        color = Colors.red;
        defaultMessage = 'Sharing failed';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message ?? defaultMessage,
              style: TextStyle(color: color),
            ),
          ),
          if (status == ShareStatus.error && onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

/// Batch sharing item tile.

class ShareableItemTile extends StatelessWidget {
  final ShareableFile file;
  final ValueChanged<List<String>> onPermissionsChanged;
  final bool isReadOnly;
  final VoidCallback? onRemove;

  const ShareableItemTile({
    super.key,
    required this.file,
    required this.onPermissionsChanged,
    this.isReadOnly = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isMovieList = file.fileType == 'movielist';
    final hasMovie = file.movie != null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icon or thumbnail.

            if (hasMovie)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: file.movie!.posterUrl,
                  width: 40,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 40,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.movie, color: Colors.grey),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 40,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.movie, color: Colors.grey),
                  ),
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isMovieList
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  isMovieList ? Icons.list : Icons.movie,
                  color: isMovieList
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[600],
                ),
              ),
            const SizedBox(width: 12),
            // File info.

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.displayName,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isMovieList ? Icons.folder : Icons.insert_drive_file,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isMovieList ? 'Movie List' : 'Movie File',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Permissions.

            if (isReadOnly)
              Chip(
                label: Text(
                  file.permissions.join(', ').toUpperCase(),
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor: file.permissions.contains('write')
                    ? Colors.orange.withValues(alpha: 0.2)
                    : Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
              )
            else
              PermissionSelector(
                availablePermissions:
                    isMovieList ? const ['read', 'write'] : const ['read'],
                selectedPermissions: file.permissions,
                onChanged: onPermissionsChanged,
                readOnly: !isMovieList,
                requireRead: isMovieList, // Movie lists require read permission
              ),
            // Remove button.

            if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: onRemove,
                color: Colors.red,
                tooltip: 'Remove from sharing',
              ),
          ],
        ),
      ),
    );
  }
}

/// Navigate to GrantPermissionUi with consistent theming.

Future<bool?> navigateToGrantPermissionUi({
  required BuildContext context,
  required String fileName,
  required String title,
  List<String> accessModeList = const ['read'],
  List<String> recipientTypeList = const ['indi'],
  Widget? returnWidget,
}) async {
  final currentContext = context;

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (navContext) => Theme(
        data: Theme.of(currentContext).copyWith(),
        child: Scaffold(
          backgroundColor: Theme.of(currentContext).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(title),
            backgroundColor:
                Theme.of(currentContext).appBarTheme.backgroundColor,
            foregroundColor:
                Theme.of(currentContext).appBarTheme.foregroundColor,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(currentContext)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: Theme.of(currentContext).colorScheme.primary,
                  size: 20,
                ),
              ),
              onPressed: () {
                Navigator.of(navContext).pop(null);
              },
              tooltip: 'Back',
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: Theme.of(currentContext).colorScheme.onSurface,
                ),
                onPressed: () {
                  Navigator.of(navContext).pop(null);
                },
                tooltip: 'Cancel',
              ),
            ],
          ),
          body: GrantPermissionUi(
            fileName: fileName,
            title: '',
            accessModeList: accessModeList,
            recipientTypeList: recipientTypeList,
            showAppBar: false,
            backgroundColor: Theme.of(currentContext).scaffoldBackgroundColor,
            child: returnWidget ?? Container(),
          ),
        ),
      ),
    ),
  );

  return result as bool?;
}
