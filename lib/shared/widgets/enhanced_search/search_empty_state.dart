/// Search Empty State Component - Empty state display for search screen
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:moviestar/constants/dimensions.dart';

/// Widget that displays the empty state for search functionality
class SearchEmptyState extends StatelessWidget {
  final String searchText;

  const SearchEmptyState({
    super.key,
    required this.searchText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const Gap(Gaps.xxl),
          Text(
            _getEmptyStateTitle(),
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const Gap(Gaps.m),
          Text(
            'Find content by title, actor, or genre',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  /// Get the appropriate title based on search state
  String _getEmptyStateTitle() {
    if (searchText.isEmpty) {
      return 'Search for movies and TV shows';
    } else if (searchText.length < 2) {
      return 'Type at least 2 characters';
    } else {
      return 'No results found';
    }
  }
}