/// Screen for adding movies to a custom list with search and suggestions.
///
// Time-stamp: <Monday 2025-08-18 10:00:00 +1000 Ashley Tang>
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
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/widgets/base_screen.dart';
import 'package:moviestar/widgets/error_display_widget.dart';

/// Screen for adding movies to a custom list with search functionality.

class AddMoviesToListScreen extends ConsumerStatefulWidget {
  /// The custom list to add movies to.

  final CustomList customList;

  /// Service for managing favorite movies and lists.

  final FavoritesService favoritesService;

  /// Creates a new [AddMoviesToListScreen] widget.

  const AddMoviesToListScreen({
    super.key,
    required this.customList,
    required this.favoritesService,
  });

  @override
  ConsumerState<AddMoviesToListScreen> createState() =>
      _AddMoviesToListScreenState();
}

/// State class for the add movies to list screen.

class _AddMoviesToListScreenState extends ConsumerState<AddMoviesToListScreen>
    with TickerProviderStateMixin, ScreenStateMixin {
  // Controller for the search text field.

  final TextEditingController _searchController = TextEditingController();

  // Loading state indicator for suggestions.

  bool _isSuggestionsLoading = true;

  // Loading state indicator for search.

  bool _isSearchLoading = false;

  // Error message if any.

  String? _error;

  // Search results categorized by search type.

  Map<String, List<ContentItem>> _searchResults = {};

  // Suggested content (popular movies and TV shows)

  List<ContentItem> _suggestedContent = [];

  // Timer for debouncing search requests.

  Timer? _debounceTimer;

  // Tab controller for switching between search and suggestions.

  late TabController _tabController;

  // Set of movie IDs that are already in the list.

  Set<int> _moviesInList = {};

  // Duration to wait before executing search after user stops typing.

  static const Duration _debounceDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _loadMoviesInList();
    _loadSuggestedContent();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // Loads the list of movies already in this custom list.

  Future<void> _loadMoviesInList() async {
    safeSetState(() {
      _moviesInList = Set.from(widget.customList.movieIds);
    });
  }

  // Loads suggested content from popular mixed content (movies and TV shows).

  Future<void> _loadSuggestedContent() async {
    safeSetState(() {
      _isSuggestionsLoading = true;
    });
    safeSetState(() => _error = null);

    try {
      final contentService = ref.read(contentServiceProvider);
      final popularMixedContent = await contentService.getPopularMixedContent();

      // Remove content already in the list.
      final filteredSuggestions = popularMixedContent
          .where((content) => !_moviesInList.contains(content.id))
          .take(20)
          .toList();

      safeSetState(() {
        _suggestedContent = filteredSuggestions;
        _isSuggestionsLoading = false;
      });
    } catch (e) {
      safeSetState(() => _error = e.toString());
      safeSetState(() {
        _isSuggestionsLoading = false;
      });
    }
  }

  // Called when search text changes.

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _searchMovies(_searchController.text);
    });
  }

  // Searches for movies based on the provided query.

  Future<void> _searchMovies(String query) async {
    if (query.isEmpty) {
      safeSetState(() {
        _searchResults = {};
        _error = null;
        _isSearchLoading = false;
      });
      return;
    }

    if (query.length < 2) {
      return;
    }

    safeSetState(() {
      _isSearchLoading = true;
      _error = null;
    });

    try {
      final contentService = ref.read(contentServiceProvider);
      final results = await contentService.searchContentComprehensive(query);

      // Filter out content already in the list.
      final filteredResults = <String, List<ContentItem>>{};
      for (final entry in results.entries) {
        filteredResults[entry.key] = entry.value
            .where((content) => !_moviesInList.contains(content.id))
            .toList();
      }

      if (_searchController.text == query) {
        safeSetState(() {
          _searchResults = filteredResults;
          _isSearchLoading = false;
        });
      }
    } catch (e) {
      if (_searchController.text == query) {
        safeSetState(() {
          _error = e.toString();
          _isSearchLoading = false;
        });
      }
    }
  }

  // Adds a content item to the custom list.

  Future<void> _addContentToList(ContentItem contentItem) async {
    try {
      final movie = Movie.fromContentItem(contentItem);
      final contentType =
          contentItem.contentType == ContentType.tvShow ? 'tv' : 'movie';

      await widget.favoritesService.addMovieToCustomList(
        widget.customList.id,
        movie,
        contentType: contentType,
      );
      setState(() {
        _moviesInList.add(contentItem.id);
      });

      showSuccessSnackBar(
        'Added "${contentItem.title}" to ${widget.customList.name}',
      );
    } catch (e) {
      showErrorSnackBar('Error adding content: $e');
    }
  }

  // Builds a content item card (for search results).

  Widget _buildContentCard(ContentItem contentItem) {
    final isInList = _moviesInList.contains(contentItem.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
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
              child: const Icon(Icons.movie),
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
                  fontWeight: FontWeight.w600,
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
                onPressed: () => _addContentToList(contentItem),
              ),
      ),
    );
  }

  // Builds the search tab content.

  Widget _buildSearchTab() {
    if (_isSearchLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ErrorDisplayWidget(
        message: 'Search failed: $_error',
        onRetry: () => _searchMovies(_searchController.text),
      );
    }

    if (_searchResults.isEmpty || _hasNoSearchResults()) {
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
              _searchController.text.isEmpty
                  ? 'Search for movies and TV shows to add'
                  : _searchController.text.length < 2
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
              'Find movies and TV shows by title, actor, or genre',
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        if (_searchResults['title']?.isNotEmpty ?? false) ...[
          _buildSearchSection(
            'Title Matches',
            _searchResults['title']!,
            Icons.movie,
          ),
        ],
        if (_searchResults['actor']?.isNotEmpty ?? false) ...[
          _buildSearchSection(
            'Actor Matches',
            _searchResults['actor']!,
            Icons.person,
          ),
        ],
        if (_searchResults['genre']?.isNotEmpty ?? false) ...[
          _buildSearchSection(
            'Genre Matches',
            _searchResults['genre']!,
            Icons.category,
          ),
        ],
      ],
    );
  }

  // Builds a search results section.

  Widget _buildSearchSection(
    String title,
    List<ContentItem> contents,
    IconData icon,
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
        ...contents.map((content) => _buildContentCard(content)),
        const SizedBox(height: 8),
      ],
    );
  }

  // Builds the suggestions tab content.

  Widget _buildSuggestionsTab() {
    if (_isSuggestionsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ErrorDisplayWidget(
        message: 'Failed to load suggestions: $_error',
        onRetry: _loadSuggestedContent,
      );
    }

    if (_suggestedContent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_outlined,
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
          ],
        ),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Popular Content',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ..._suggestedContent.map((content) => _buildContentCard(content)),
      ],
    );
  }

  // Check if all search result categories are empty.

  bool _hasNoSearchResults() {
    return (_searchResults['title']?.isEmpty ?? true) &&
        (_searchResults['actor']?.isEmpty ?? true) &&
        (_searchResults['genre']?.isEmpty ?? true);
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      titleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Content'),
          Text(
            widget.customList.name,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      isLoading:
          false, // Only use BaseScreen loading for overall screen loading
      error: null, // Handle errors within individual tabs
      onErrorRetry: null,
      appBarBottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Search', icon: Icon(Icons.search)),
          Tab(text: 'Suggestions', icon: Icon(Icons.trending_up)),
        ],
      ),
      body: Column(
        children: [
          // Search bar (only shown in search tab).
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              if (_tabController.index == 0) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Search movies and TV shows by title, actor, or genre...',
                      hintStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    onChanged: (value) =>
                        safeSetState(() {}), // To show/hide clear button.
                    onSubmitted: (value) {
                      _debounceTimer?.cancel();
                      _searchMovies(value);
                    },
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Tab content.
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSearchTab(),
                _buildSuggestionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
