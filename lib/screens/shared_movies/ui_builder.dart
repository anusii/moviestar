/// UI building utilities for shared movies screen.
/// Extracted from SharedMoviesScreen to reduce file size.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/widgets/list_shared_movies.dart';

/// Handles UI building for shared movies screen.

class SharedMoviesUIBuilder {
  /// Build the loaded screen with shared movies data.

  static Widget buildLoadedScreen(
    Map<String, dynamic> sharedMoviesMap,
    VoidCallback onDataChanged,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.m),
      child: ListSharedMovies(
        sharedMoviesMap: sharedMoviesMap,
        onDataChanged: onDataChanged,
      ),
    );
  }

  /// Build the empty state when no shared movies are found.

  static Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.l),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.share_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const Gap(Gaps.l),
            Text(
              'No Shared Movies',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const Gap(Gaps.m),
            Text(
              'Movies and lists that others share with you will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const Gap(Gaps.l),
            Icon(
              Icons.movie_outlined,
              size: 48,
              color: Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }

  /// Build the error state when there's an issue loading shared movies.

  static Widget buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.l),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            const Gap(Gaps.l),
            Text(
              'Error Loading Shared Movies',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.red[700],
              ),
            ),
            const Gap(Gaps.m),
            Text(
              'There was a problem loading shared movies. Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const Gap(Gaps.l),
            Icon(
              Icons.refresh,
              size: 48,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
