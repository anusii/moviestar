/// List Header Widget Component - Display List Metadata, Title, Description, and Actions
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/utils/date_format_util.dart';

class ListHeaderWidget extends ConsumerWidget {
  final CustomList customList;
  final int totalMovies;
  final int loadedMovies;
  final VoidCallback onOptionsPressed;

  const ListHeaderWidget({
    super.key,
    required this.customList,
    required this.totalMovies,
    required this.loadedMovies,
    required this.onOptionsPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // List name and options
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                customList.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: onOptionsPressed,
              tooltip: 'List Options',
            ),
          ],
        ),

        const SizedBox(height: 8),

        // List description with tooltip if it's long
        if (customList.description?.isNotEmpty == true) ...[
          Row(
            children: [
              Icon(
                Icons.description,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: customList.description!.length > 100
                    ? MarkdownTooltip(
                        message: customList.description!,
                        child: Text(
                          '${customList.description!.substring(0, 97)}...',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : Text(
                        customList.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Movie count and creation date
        Row(
          children: [
            // Movie count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                totalMovies == 1 ? '1 movie' : '$totalMovies movies',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
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
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Loading $loadedMovies/$totalMovies',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],

            const Spacer(),

            // Creation date
            Text(
              'Created ${customList.createdAt.year}-${customList.createdAt.month.toString().padLeft(2, '0')}-${customList.createdAt.day.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        Divider(color: Theme.of(context).dividerColor),
        const SizedBox(height: 16),
      ],
    );
  }
}