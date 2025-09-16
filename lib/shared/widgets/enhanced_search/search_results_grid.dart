/// Search Results Grid Component - Movie/TV grid display with categorized results
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gap/gap.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/core/services/favorites/favorites_service.dart';
import 'package:moviestar/utils/movie_display_utils.dart';

/// Widget that displays search results in categorized sections
class SearchResultsGrid extends StatefulWidget {
  final Map<String, List<ContentItem>> searchResults;
  final FavoritesService favoritesService;
  final Function(String action, ContentItem contentItem) onListAction;
  final VoidCallback? onCustomListsDialogRequested;

  const SearchResultsGrid({
    super.key,
    required this.searchResults,
    required this.favoritesService,
    required this.onListAction,
    this.onCustomListsDialogRequested,
  });

  @override
  State<SearchResultsGrid> createState() => _SearchResultsGridState();
}

class _SearchResultsGridState extends State<SearchResultsGrid> with ScreenStateMixin {

  /// Builds the search results display organized by categories
  @override
  Widget build(BuildContext context) {
    // Check if we have any results
    if (_hasNoResults()) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultsSection('title', widget.searchResults['title'] ?? []),
          _buildResultsSection('actor', widget.searchResults['actor'] ?? []),
          _buildResultsSection('genre', widget.searchResults['genre'] ?? []),
        ],
      ),
    );
  }

  /// Builds a section of search results for a specific category
  Widget _buildResultsSection(String category, List<ContentItem> content) {
    if (content.isEmpty) return const SizedBox.shrink();

    String categoryTitle;
    IconData categoryIcon;

    switch (category) {
      case 'title':
        categoryTitle = 'By Title';
        categoryIcon = Icons.search;
        break;
      case 'actor':
        categoryTitle = 'By Actor';
        categoryIcon = Icons.person;
        break;
      case 'genre':
        categoryTitle = 'By Genre';
        categoryIcon = Icons.category;
        break;
      default:
        categoryTitle = category;
        categoryIcon = Icons.search;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(Dimensions.xl),
          child: Row(
            children: [
              Icon(
                categoryIcon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const Gap(Gaps.m),
              Text(
                categoryTitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(Gaps.m),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${content.length}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: content.length,
          itemBuilder: (context, index) {
            final contentItem = content[index];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: isValidImageUrl(contentItem.posterUrl)
                    ? CachedNetworkImage(
                        imageUrl: contentItem.posterUrl.trim(),
                        width: 50,
                        height: 75,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      )
                    : Container(
                        width: 50,
                        height: 75,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.movie,
                          color: Colors.grey,
                        ),
                      ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      contentItem.title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    contentItem.contentTypeIcon,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⭐ ${contentItem.voteAverage.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    '${contentItem.contentTypeLabel} • ${contentItem.releaseYear}',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.playlist_add),
                tooltip: 'Add to List',
                onSelected: (value) => _handleListAction(value, contentItem),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'to_watch',
                    child: Row(
                      children: [
                        Icon(Icons.bookmark_add_outlined),
                        SizedBox(width: 8),
                        Text('Add to To Watch'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'watched',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline),
                        SizedBox(width: 8),
                        Text('Add to Watched'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'custom_lists',
                    child: Row(
                      children: [
                        Icon(Icons.library_add_outlined),
                        SizedBox(width: 8),
                        Text('Add to Custom Lists'),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () => _navigateToDetails(contentItem),
            );
          },
        ),
        const Gap(Gaps.xxl),
      ],
    );
  }

  /// Navigate to movie/TV details screen
  void _navigateToDetails(ContentItem contentItem) {
    final movie = Movie.fromContentItem(contentItem);
    safeNavigateTo(
      MaterialPageRoute(
        builder: (context) => MovieDetailsScreen(
          movie: movie,
          favoritesService: widget.favoritesService,
          contentType: contentItem.contentType,
        ),
      ),
    );
  }

  /// Handle list action selection from popup menu
  void _handleListAction(String action, ContentItem contentItem) {
    widget.onListAction(action, contentItem);
  }

  /// Check if all search result categories are empty
  bool _hasNoResults() {
    return (widget.searchResults['title']?.isEmpty ?? true) &&
        (widget.searchResults['actor']?.isEmpty ?? true) &&
        (widget.searchResults['genre']?.isEmpty ?? true);
  }
}