/// Lists Grid Widget Component - Scrollable grid display of custom list cards.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/utils/date_format_util.dart';

/// Widget that displays a scrollable grid of custom list cards.
class ListsGridWidget extends StatelessWidget {
  final List<CustomList> customLists;
  final VoidCallback onRefresh;
  final Function(CustomList list) onListTap;
  final Function(CustomList list) onAddMovies;
  final Function(CustomList list) onListOptions;

  const ListsGridWidget({
    super.key,
    required this.customLists,
    required this.onRefresh,
    required this.onListTap,
    required this.onAddMovies,
    required this.onListOptions,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: customLists.length,
        itemBuilder: (context, index) {
          final list = customLists[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onListTap(list),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // List avatar with gradient background.
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          list.name.isNotEmpty
                              ? list.name[0].toUpperCase()
                              : 'L',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // List details.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            list.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (list.description != null &&
                              list.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              list.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.movie,
                                      size: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${list.movieCount}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Updated ${DateFormatUtil.formatShort(list.updatedAt)}',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Action buttons.
                    Column(
                      children: [
                        MarkdownTooltip(
                          message: '''

**Add Movies**

Search for movies and add them to "${list.name}".
Browse popular suggestions or search by title, actor, or genre.

                          ''',
                          child: IconButton(
                            icon: Icon(
                              Icons.add_circle_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onPressed: () => onAddMovies(list),
                          ),
                        ),
                        MarkdownTooltip(
                          message: '''

**List Options**

Edit list name and description, or delete this list.

                          ''',
                          child: IconButton(
                            icon: Icon(
                              Icons.more_vert,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            onPressed: () => onListOptions(list),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
