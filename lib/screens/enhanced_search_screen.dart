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

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/constants/timing_constants.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/custom_list.dart';
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
  /// Validates if an image URL is valid and not empty.
  bool _isValidImageUrl(String url) {
    if (url.trim().isEmpty) {
      return false;
    }

    // Basic URL validation - must start with http:// or https://
    return url.trim().startsWith('http://') ||
        url.trim().startsWith('https://');
  }

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
                child: _isValidImageUrl(contentItem.posterUrl)
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
              onTap: () {
                // Navigate to details screen for both movies and TV shows
                final movie = Movie.fromContentItem(contentItem);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MovieDetailsScreen(
                      movie: movie,
                      favoritesService: widget.favoritesService,
                      contentType: contentItem.contentType,
                    ),
                  ),
                );
              },
            );
          },
        ),
        const Gap(Gaps.xxl),
      ],
    );
  }

  // Handles list actions from the popup menu.

  Future<void> _handleListAction(String action, ContentItem contentItem) async {
    final movie = Movie.fromContentItem(contentItem);

    switch (action) {
      case 'to_watch':
        try {
          await widget.favoritesService.addToWatch(
            movie,
            contentType:
                contentItem.contentType == ContentType.tvShow ? 'tv' : 'movie',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added "${movie.title}" to To Watch'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error adding to To Watch: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
        break;
      case 'watched':
        try {
          await widget.favoritesService.addToWatched(
            movie,
            contentType:
                contentItem.contentType == ContentType.tvShow ? 'tv' : 'movie',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added "${movie.title}" to Watched'),
                backgroundColor: Theme.of(context).colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error adding to Watched: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
        break;
      case 'custom_lists':
        _showAddToCustomListsDialog(contentItem);
        break;
    }
  }

  // Shows a dialog to add content item to custom lists.

  void _showAddToCustomListsDialog(ContentItem contentItem) {
    // Convert ContentItem to Movie for list operations (works for both movies and TV shows)
    final movie = Movie.fromContentItem(contentItem);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _AddToCustomListsDialog(
          movie: movie,
          originalContentItem: contentItem,
          favoritesService: widget.favoritesService,
          onListsUpdated: () {
            // No need to refresh search results
          },
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
                          const Gap(Gaps.xxl),
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
                          const Gap(Gaps.m),
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

/// Dialog for adding a movie to custom lists.
class _AddToCustomListsDialog extends StatefulWidget {
  final Movie movie;
  final ContentItem originalContentItem;
  final FavoritesService favoritesService;
  final VoidCallback onListsUpdated;

  const _AddToCustomListsDialog({
    required this.movie,
    required this.originalContentItem,
    required this.favoritesService,
    required this.onListsUpdated,
  });

  @override
  State<_AddToCustomListsDialog> createState() =>
      _AddToCustomListsDialogState();
}

class _AddToCustomListsDialogState extends State<_AddToCustomListsDialog> {
  final TextEditingController _newListController = TextEditingController();
  final Set<String> _selectedListIds = {};
  List<CustomList> _customLists = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCustomLists();
  }

  @override
  void dispose() {
    _newListController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomLists() async {
    try {
      final lists = await widget.favoritesService.getCustomLists();
      setState(() {
        _customLists = lists;
      });
      await _loadMovieListStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading lists: $e')),
        );
      }
    }
  }

  Future<void> _loadMovieListStatus() async {
    for (final list in _customLists) {
      final isInList = await widget.favoritesService.isMovieInCustomList(
        list.id,
        widget.movie.id,
      );
      if (isInList) {
        _selectedListIds.add(list.id);
      }
    }
    setState(() {});
  }

  Future<void> _refreshCustomListCounts() async {
    try {
      final lists = await widget.favoritesService.getCustomLists();
      setState(() {
        _customLists = lists;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing lists: $e')),
        );
      }
    }
  }

  Future<void> _toggleMovieInList(String listId, bool add) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (add) {
        // Determine content type based on the original ContentItem
        final contentType =
            widget.originalContentItem.contentType == ContentType.tvShow
                ? 'tv'
                : 'movie';
        await widget.favoritesService.addMovieToCustomList(
          listId,
          widget.movie,
          contentType: contentType,
        );
        _selectedListIds.add(listId);
      } else {
        await widget.favoritesService
            .removeMovieFromCustomList(listId, widget.movie.id);
        _selectedListIds.remove(listId);
      }

      // Refresh the custom lists to update counts without losing selection state
      await _refreshCustomListCounts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating list: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.playlist_add,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add to Lists',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          widget.movie.title,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Lists content
            Expanded(
              child: _customLists.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _customLists.length,
                      itemBuilder: (context, index) {
                        final list = _customLists[index];
                        final isSelected = _selectedListIds.contains(list.id);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withValues(alpha: 0.2),
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.1)
                                : null,
                          ),
                          child: CheckboxListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            secondary: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  list.name.isNotEmpty
                                      ? list.name[0].toUpperCase()
                                      : 'L',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              list.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            subtitle: Row(
                              children: [
                                Icon(
                                  Icons.movie,
                                  size: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${list.movieCount} items',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            value: isSelected,
                            activeColor: Theme.of(context).colorScheme.primary,
                            onChanged: _isLoading
                                ? null
                                : (value) =>
                                    _toggleMovieInList(list.id, value ?? false),
                          ),
                        );
                      },
                    )
                  : _buildEmptyListsState(),
            ),

            // Create new list button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _showCreateNewListDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create New List'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyListsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_add_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No Custom Lists Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first custom list to organize your movies and TV shows!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateNewListDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New List'),
        content: TextField(
          controller: _newListController,
          decoration: const InputDecoration(
            labelText: 'List Name',
            hintText: 'Enter a name for your list...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (_) => _createNewListAndAdd(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _createNewListAndAdd,
            child: const Text('Create & Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewListAndAdd() async {
    final name = _newListController.text.trim();
    if (name.isEmpty) return;

    Navigator.pop(context); // Close create dialog

    setState(() {
      _isLoading = true;
    });

    try {
      final newList = await widget.favoritesService.createCustomList(name);
      final contentType =
          widget.originalContentItem.contentType == ContentType.tvShow
              ? 'tv'
              : 'movie';
      await widget.favoritesService.addMovieToCustomList(
        newList.id,
        widget.movie,
        contentType: contentType,
      );
      _selectedListIds.add(newList.id);
      _newListController.clear();
      widget.onListsUpdated();

      if (mounted) {
        Navigator.pop(context); // Close main dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Created "$name" and added "${widget.movie.title}"',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            elevation: 6,
            duration: TimingConstants.snackbarStandardDuration,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating list: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
