/// Enhanced search screen supporting both movies and TV shows.
///
// Time-stamp: <Friday 2025-01-17 19:45:00 +1000 Assistant>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
/// Authors: Ashley Tang

library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:gap/gap.dart';

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/services/content_service.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/widgets/error_display_widget.dart';

/// Enhanced search screen that supports both movies and TV shows.

class EnhancedSearchScreen extends StatefulWidget {
  /// Service for managing favorite movies.

  final FavoritesService favoritesService;
  final ContentService contentService;

  /// Creates a new [EnhancedSearchScreen] widget.

  const EnhancedSearchScreen({
    super.key,
    required this.favoritesService,
    required this.contentService,
  });

  @override
  State<EnhancedSearchScreen> createState() => _EnhancedSearchScreenState();
}

//
class _EnhancedSearchScreenState extends State<EnhancedSearchScreen> {
  // Controller for the search text field.

  final TextEditingController _searchController = TextEditingController();

  // Loading state indicator.

  bool _isLoading = false;

  // Error message if any.

  String? _error;

  // Comprehensive search results categorised by search type.

  Map<String, List<ContentItem>> _searchResults = {};

  // Timer for debouncing search requests.

  Timer? _debounceTimer;

  // Duration to wait before executing search after user stops typing.

  static const Duration _debounceDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    // Listen to text changes for dynamic search.

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Called when search text changes.

  void _onSearchChanged() {
    // Cancel previous timer if it exists.

    _debounceTimer?.cancel();

    // Start new timer for debouncing.

    _debounceTimer = Timer(_debounceDuration, () {
      _searchContent(_searchController.text);
    });
  }

  // Searches for content based on the provided query.

  Future<void> _searchContent(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = {};
        _error = null;
        _isLoading = false;
      });
      return;
    }

    // Don't search if query is too short.

    if (query.length < 2) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await widget.contentService.searchContentComprehensive(
        query,
      );

      // Only update state if this search is still relevant.

      if (_searchController.text == query) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Only update state if this search is still relevant.

      if (_searchController.text == query) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Builds a section of search results for a specific category.

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
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                categoryIcon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const Gap(8),
              Text(
                categoryTitle,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(8),
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
                child: CachedNetworkImage(
                  imageUrl: contentItem.posterUrl,
                  width: 50,
                  height: 75,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
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
              onTap: () {
                // For now, only navigate to movie details for movies
                // TODO: Create a universal content details screen or TV show details screen
                if (contentItem.contentType == ContentType.movie) {
                  final movie = Movie.fromContentItem(contentItem);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailsScreen(
                        movie: movie,
                        favoritesService: widget.favoritesService,
                      ),
                    ),
                  );
                } else {
                  // For TV shows, show a simple dialog for now
                  _showTVShowDialog(contentItem);
                }
              },
            );
          },
        ),
        const Gap(16),
      ],
    );
  }

  // Shows a dialog with basic TV show information.

  void _showTVShowDialog(ContentItem tvShow) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tvShow.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tvShow.posterUrl.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: tvShow.posterUrl,
                      width: 150,
                      height: 225,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                    ),
                  ),
                ),
              const Gap(16),
              Text(
                'TV Show • First aired: ${tvShow.releaseYear}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Gap(8),
              Text('Rating: ⭐ ${tvShow.voteAverage.toStringAsFixed(1)}'),
              const Gap(8),
              if (tvShow.overview.isNotEmpty) ...[
                const Text(
                  'Overview:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Gap(4),
                Text(tvShow.overview),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Search movies and TV shows...',
            hintStyle: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            // Dynamic search is handled by the listener.
            // This rebuild is just to show/hide the clear button.

            setState(() {});
          },
          onSubmitted: (value) {
            // Immediate search when user presses Enter.

            _debounceTimer?.cancel();
            _searchContent(value);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorDisplayWidget(
                  message: 'Search failed: $_error',
                  onRetry: () => _searchContent(_searchController.text),
                )
              : _searchResults.isEmpty || _hasNoResults()
                  ? Center(
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
                          const Gap(16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'Search for movies and TV shows'
                                : _searchController.text.length < 2
                                    ? 'Type at least 2 characters'
                                    : 'No results found',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 18,
                            ),
                          ),
                          const Gap(8),
                          Text(
                            'Find content by title, actor, or genre',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildResultsSection(
                            'title',
                            _searchResults['title'] ?? [],
                          ),
                          _buildResultsSection(
                            'actor',
                            _searchResults['actor'] ?? [],
                          ),
                          _buildResultsSection(
                            'genre',
                            _searchResults['genre'] ?? [],
                          ),
                        ],
                      ),
                    ),
    );
  }

  // Check if all search result categories are empty.

  bool _hasNoResults() {
    return (_searchResults['title']?.isEmpty ?? true) &&
        (_searchResults['actor']?.isEmpty ?? true) &&
        (_searchResults['genre']?.isEmpty ?? true);
  }
}
