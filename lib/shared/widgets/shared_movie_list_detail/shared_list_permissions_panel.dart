/// Shared List Permissions Panel Component - Access Controls, Sharing Status, and User Management
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SharedListPermissionsPanel extends ConsumerWidget {
  final String permissions;
  final String ownerWebId;
  final String sharedByWebId;
  final VoidCallback? onPermissionChange;

  const SharedListPermissionsPanel({
    super.key,
    required this.permissions,
    required this.ownerWebId,
    required this.sharedByWebId,
    this.onPermissionChange,
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

    return Container(
      margin: const EdgeInsets.all(16),
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
          // Permissions header
          Row(
            children: [
              Icon(
                Icons.security,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Sharing Permissions',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Permission status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: permissions.contains('write')
                ? colorScheme.tertiaryContainer
                : colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  permissions.contains('write') ? Icons.edit : Icons.visibility,
                  color: permissions.contains('write')
                    ? colorScheme.onTertiaryContainer
                    : colorScheme.onPrimaryContainer,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  permissions.contains('write') ? 'Read & Write Access' : 'Read Only Access',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: permissions.contains('write')
                      ? colorScheme.onTertiaryContainer
                      : colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Permission details
          Text(
            permissions.contains('write')
              ? 'You can view and edit this shared list'
              : 'You can view this shared list but cannot make changes',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 16),

          // User info section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shared List Details',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              _buildUserInfo(
                context,
                'Owner',
                _getOwnerName(ownerWebId),
                Icons.person,
                colorScheme.primary,
              ),

              if (ownerWebId != sharedByWebId) ...[
                const SizedBox(height: 6),
                _buildUserInfo(
                  context,
                  'Shared by',
                  _getOwnerName(sharedByWebId),
                  Icons.share,
                  colorScheme.secondary,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(
    BuildContext context,
    String label,
    String userName,
    IconData icon,
    Color iconColor,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: iconColor,
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            userName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}