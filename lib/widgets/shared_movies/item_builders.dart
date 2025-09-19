/// Item builders for shared movies list.
/// Extracted to reduce file size and improve organization.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:moviestar/constants/dimensions.dart';

/// Builds individual items for shared movies list.
class SharedMoviesItemBuilders {
  /// Build a rating display widget.
  static Widget buildRatingDisplay(dynamic rating) {
    if (rating == null) {
      return const SizedBox.shrink();
    }

    final numRating = (rating as num).toDouble();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.star,
          color: Colors.amber,
          size: 16,
        ),
        const Gap(Gaps.xs),
        Text(
          numRating.toStringAsFixed(1),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  /// Build a permissions badge widget.
  static Widget buildPermissionsBadge(String permissions) {
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    switch (permissions.toLowerCase()) {
      case 'read':
        badgeColor = Colors.blue;
        badgeIcon = Icons.visibility;
        badgeText = 'Read';
        break;
      case 'write':
        badgeColor = Colors.green;
        badgeIcon = Icons.edit;
        badgeText = 'Edit';
        break;
      case 'control':
        badgeColor = Colors.purple;
        badgeIcon = Icons.admin_panel_settings;
        badgeText = 'Control';
        break;
      default:
        badgeColor = Colors.grey;
        badgeIcon = Icons.help_outline;
        badgeText = permissions;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: 12,
            color: badgeColor,
          ),
          const Gap(Gaps.xs),
          Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a movie list item.
  static Widget buildMovieListItem({
    required BuildContext context,
    required Map<String, dynamic> itemData,
    required String resourceUrl,
    required VoidCallback onTap,
  }) {
    final listName = itemData['listName'] ?? 'Unknown List';
    final description = itemData['description'] ?? '';
    final movieCount = itemData['movieCount'] ?? 0;
    final owner = itemData['owner'] ?? '';
    final permissions = itemData['permissions'] ?? 'read';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          child: Icon(
            Icons.list_alt,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          listName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty) ...[
              Text(description),
              const Gap(Gaps.xs),
            ],
            Row(
              children: [
                Text('$movieCount movies'),
                const Gap(Gaps.s),
                Text(
                  'by $owner',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const Gap(Gaps.s),
                buildPermissionsBadge(permissions),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  /// Build a movie item.
  static Widget buildMovieItem({
    required BuildContext context,
    required Map<String, dynamic> itemData,
    required String resourceUrl,
    required VoidCallback onTap,
    required VoidCallback onShare,
  }) {
    final movieTitle = itemData['fileName'] ?? 'Unknown Movie';
    final owner = itemData['owner'] ?? '';
    final permissions = itemData['permissions'] ?? 'read';
    final rating = itemData['rating'];
    final comments = itemData['comments'] ?? '';
    final posterUrl = itemData['posterUrl'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: posterUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  posterUrl,
                  width: 50,
                  height: 75,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 75,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.movie, color: Colors.grey),
                    );
                  },
                ),
              )
            : Container(
                width: 50,
                height: 75,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.movie, color: Colors.grey),
              ),
        title: Text(
          movieTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'by $owner',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const Gap(Gaps.s),
                buildPermissionsBadge(permissions),
              ],
            ),
            if (rating != null) ...[
              const Gap(Gaps.xs),
              buildRatingDisplay(rating),
            ],
            if (comments.isNotEmpty) ...[
              const Gap(Gaps.xs),
              Text(
                '"$comments"',
                style: const TextStyle(fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: onShare,
              tooltip: 'Share this movie',
            ),
            const Icon(Icons.arrow_forward_ios),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
