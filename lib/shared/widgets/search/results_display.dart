/// Search results display widget for enhanced search functionality.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:gap/gap.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/utils/movie_display_utils.dart';

/// Widget that displays search results organized by category.

class SearchResultsDisplay extends StatelessWidget {
  final Map<String, List<ContentItem>> searchResults;
  final FavoritesService favoritesService;
  final Function(Route<dynamic>) onNavigate;
  final Function(String, ContentItem) onHandleListAction;

  const SearchResultsDisplay({
    super.key,
    required this.searchResults,
    required this.favoritesService,
    required this.onNavigate,
    required this.onHandleListAction,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultsSection(context, 'title', searchResults['title'] ?? []),
          _buildResultsSection(context, 'actor', searchResults['actor'] ?? []),
          _buildResultsSection(context, 'genre', searchResults['genre'] ?? []),
        ],
      ),
    );
  }

  Widget _buildResultsSection(
    BuildContext context,
    String category,
    List<ContentItem> content,
  ) {
    if (content.isEmpty) return const SizedBox.shrink();

    final categoryTitle = _getCategoryTitle(category);
    final categoryIcon = _getCategoryIcon(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            return _buildResultItem(context, contentItem);
          },
        ),
        const Gap(Gaps.xxl),
      ],
    );
  }

  Widget _buildResultItem(BuildContext context, ContentItem contentItem) {
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
                errorWidget: (context, url, error) => const Icon(Icons.error),
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
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
          ),
          Text(
            '${contentItem.contentTypeLabel} • ${contentItem.releaseYear}',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.playlist_add),
        tooltip: 'Add to List',
        onSelected: (value) => onHandleListAction(value, contentItem),
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
      onTap: () {
        final movie = Movie.fromContentItem(contentItem);
        onNavigate(
          MaterialPageRoute(
            builder: (context) => MovieDetailsScreen(
              movie: movie,
              favoritesService: favoritesService,
              contentType: contentItem.contentType,
            ),
          ),
        );
      },
    );
  }

  String _getCategoryTitle(String category) {
    switch (category) {
      case 'title':
        return 'Titles';
      case 'actor':
        return 'Cast & Crew';
      case 'genre':
        return 'Genres';
      default:
        return category;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'title':
        return Icons.movie_outlined;
      case 'actor':
        return Icons.person_outline;
      case 'genre':
        return Icons.category_outlined;
      default:
        return Icons.search;
    }
  }

  /// Check if all search result categories are empty.

  static bool hasNoResults(Map<String, List<ContentItem>> searchResults) {
    return (searchResults['title']?.isEmpty ?? true) &&
        (searchResults['actor']?.isEmpty ?? true) &&
        (searchResults['genre']?.isEmpty ?? true);
  }
}
