/// Loading and Error State Widgets for Custom Lists.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

/// Widget that displays loading state for custom lists.

class CustomListLoadingState extends StatelessWidget {
  /// Message to display while loading.

  final String message;

  /// Creates a new [CustomListLoadingState].

  const CustomListLoadingState({
    super.key,
    this.message = 'Loading Custom Lists...',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget that displays empty state for custom lists.

class CustomListEmptyState extends StatelessWidget {
  /// Name of the custom list.

  final String listName;

  /// Creates a new [CustomListEmptyState].

  const CustomListEmptyState({
    super.key,
    required this.listName,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'No movies in $listName yet',
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

/// Widget that displays loading state for movie content.

class MovieLoadingCard extends StatelessWidget {
  /// Width of the loading card.

  final double width;

  /// Height of the loading card.

  final double height;

  /// Whether this is for a list item layout.

  final bool isListItem;

  /// Creates a new [MovieLoadingCard].

  const MovieLoadingCard({
    super.key,
    this.width = 100,
    this.height = 150,
    this.isListItem = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isListItem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Text(
                  'Loading movie...',
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          const Gap(8),
          Text(
            'Loading...',
            style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget that displays error state for movie loading.

class MovieErrorCard extends StatelessWidget {
  /// Width of the error card.

  final double width;

  /// Height of the error card.

  final double height;

  /// Whether this is for a list item layout.

  final bool isListItem;

  /// Creates a new [MovieErrorCard].

  const MovieErrorCard({
    super.key,
    this.width = 100,
    this.height = 150,
    this.isListItem = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isListItem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const Gap(16),
              Expanded(
                child: Text(
                  'Error loading movie',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const Gap(8),
          Text(
            'Error',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
