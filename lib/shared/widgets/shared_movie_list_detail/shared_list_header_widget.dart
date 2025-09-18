/// Shared List Header Widget Component - Display List Metadata, Owner Info, and Permissions.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class SharedListHeaderWidget extends ConsumerWidget {
  final String listName;
  final String listDescription;
  final String owner;
  final String ownerWebId;
  final String sharedBy;
  final String sharedByWebId;
  final String permissions;
  final int totalMovies;
  final int loadedMovies;

  const SharedListHeaderWidget({
    super.key,
    required this.listName,
    required this.listDescription,
    required this.owner,
    required this.ownerWebId,
    required this.sharedBy,
    required this.sharedByWebId,
    required this.permissions,
    required this.totalMovies,
    required this.loadedMovies,
  });

  String _getOwnerName(String webId) {
    if (webId.isEmpty) return 'Unknown';

    try {
      final match = RegExp(r'://[^/]+/([^/]+)/').firstMatch(webId);
      if (match != null) {
        final username = match.group(1) ?? 'Unknown';
        return username.replaceAll('-', ' ');
      }

      return webId.length > 30 ? '${webId.substring(0, 30)}...' : webId;
    } catch (e) {
      return webId.length > 30 ? '${webId.substring(0, 30)}...' : webId;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // List name
        Text(
          listName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 8),

        // List description
        if (listDescription.isNotEmpty) ...[
          Text(
            listDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
        ],

        // Owner and sharing info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Owner info
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Owner: ',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _getOwnerName(ownerWebId),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Shared by info (if different from owner)
              if (sharedByWebId != ownerWebId) ...[
                Row(
                  children: [
                    Icon(
                      Icons.share_outlined,
                      size: 18,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Shared by: ',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _getOwnerName(sharedByWebId),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Permissions info
              Row(
                children: [
                  Icon(
                    permissions.contains('write')
                        ? Icons.edit
                        : Icons.visibility,
                    size: 18,
                    color: permissions.contains('write')
                        ? colorScheme.tertiary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Access: ',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: permissions.contains('write')
                          ? colorScheme.tertiaryContainer
                          : colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      permissions.contains('write')
                          ? 'Read & Write'
                          : 'Read Only',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: permissions.contains('write')
                            ? colorScheme.onTertiaryContainer
                            : colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Movie count and loading indicator
        Row(
          children: [
            // Movie count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.movie_outlined,
                    size: 16,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    totalMovies == 1 ? '1 movie' : '$totalMovies movies',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Loading indicator if still loading
            if (loadedMovies < totalMovies) ...[
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Loading $loadedMovies/$totalMovies',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ] else ...[
              Icon(
                Icons.check_circle_outline,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'All movies loaded',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 16),
        Divider(color: colorScheme.outline.withOpacity(0.2)),
        const SizedBox(height: 16),
      ],
    );
  }
}
