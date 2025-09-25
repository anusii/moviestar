/// Content builders for Add Movies to List Screen.
/// Extracted to reduce file size and improve organization.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/widgets/error_display_widget.dart';

/// Builds content-related widgets for the Add Movies to List screen.
class ContentBuilders {
  /// Build a content card for a content item.
  static Widget buildContentCard(
    BuildContext context,
    ContentItem contentItem,
    Set<int> moviesInList,
    VoidCallback onAdd,
  ) {
    final isInList = moviesInList.contains(contentItem.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: contentItem.posterUrl,
            width: 50,
            height: 75,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 50,
              height: 75,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              width: 50,
              height: 75,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.movie,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        title: Text(
          contentItem.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isInList
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  contentItem.voteAverage.toStringAsFixed(1),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${contentItem.contentTypeLabel} • ${contentItem.releaseYear}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (contentItem.overview.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                contentItem.overview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: isInList
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
            : IconButton(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: onAdd,
              ),
      ),
    );
  }

  /// Build a search section with title and content list.
  static Widget buildSearchSection(
    BuildContext context,
    String title,
    List<ContentItem> contents,
    IconData icon,
    Set<int> moviesInList,
    Function(ContentItem) onAddContent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${contents.length}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...contents.map(
          (content) => buildContentCard(
            context,
            content,
            moviesInList,
            () => onAddContent(content),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Build the search tab content.
  static Widget buildSearchTab(
    BuildContext context, {
    required bool isSearchLoading,
    required String? error,
    required Map<String, List<ContentItem>> searchResults,
    required TextEditingController searchController,
    required Set<int> moviesInList,
    required Function(ContentItem) onAddContent,
    required VoidCallback onRetry,
  }) {
    if (isSearchLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return ErrorDisplayWidget(
        message: 'Search failed: $error',
        onRetry: onRetry,
      );
    }

    final hasNoResults = searchResults.isEmpty ||
        searchResults.values.every((list) => list.isEmpty);

    if (hasNoResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              searchController.text.isEmpty
                  ? 'Search for movies and TV shows to add'
                  : searchController.text.length < 2
                      ? 'Type at least 2 characters'
                      : 'No results found',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchController.text.isEmpty
                  ? 'Use the search bar above to find content'
                  : searchController.text.length < 2
                      ? 'Search requires at least 2 characters'
                      : 'Try different keywords or check spelling',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        if (searchResults['movies']?.isNotEmpty == true)
          buildSearchSection(
            context,
            'Movies',
            searchResults['movies']!,
            Icons.movie,
            moviesInList,
            onAddContent,
          ),
        if (searchResults['tv']?.isNotEmpty == true)
          buildSearchSection(
            context,
            'TV Shows',
            searchResults['tv']!,
            Icons.tv,
            moviesInList,
            onAddContent,
          ),
      ],
    );
  }

  /// Build the suggestions tab content.
  static Widget buildSuggestionsTab(
    BuildContext context, {
    required bool isSuggestionsLoading,
    required String? error,
    required List<ContentItem> suggestedContent,
    required Set<int> moviesInList,
    required Function(ContentItem) onAddContent,
    required VoidCallback onRetry,
  }) {
    if (isSuggestionsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return ErrorDisplayWidget(
        message: 'Failed to load suggestions: $error',
        onRetry: onRetry,
      );
    }

    if (suggestedContent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No suggestions available',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try refreshing or use search instead',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        buildSearchSection(
          context,
          'Recommended Content',
          suggestedContent,
          Icons.trending_up,
          moviesInList,
          onAddContent,
        ),
      ],
    );
  }
}
