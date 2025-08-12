/// Screen for searching and discovering movies in the Movie Star application.
///
// Time-stamp: <Thursday 2025-04-10 11:47:48 +1000 Graham Williams>
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
/// Authors: Kevin Wang, Ashley Tang

library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:gap/gap.dart';

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/services/movie_service.dart';
import 'package:moviestar/widgets/error_display_widget.dart';

/// A screen that allows users to search for movies.

class SearchScreen extends StatefulWidget {
  /// Service for managing favorite movies.

  final FavoritesService favoritesService;
  final MovieService movieService;

  /// Creates a new [SearchScreen] widget.

  const SearchScreen({
    super.key,
    required this.favoritesService,
    required this.movieService,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

// State class for the search screen.

class _SearchScreenState extends State<SearchScreen> {
  // Controller for the search text field.

  final TextEditingController _searchController = TextEditingController();

  // Loading state indicator.

  bool _isLoading = false;

  // Error message if any.

  String? _error;

  // Comprehensive search results categorised by search type.

  Map<String, List<Movie>> _searchResults = {};

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
      _searchMovies(_searchController.text);
    });
  }

  // Searches for movies based on the provided query.

  Future<void> _searchMovies(String query) async {
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
      final results =
          await widget.movieService.searchMoviesComprehensive(query);

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

  Widget _buildResultsSection(String category, List<Movie> movies) {
    if (movies.isEmpty) return const SizedBox.shrink();

    String categoryTitle;
    IconData categoryIcon;

    switch (category) {
      case 'title':
        categoryTitle = 'By Title';
        categoryIcon = Icons.movie;
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
              Icon(categoryIcon,
                  color: Theme.of(context).colorScheme.primary, size: 20),
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
                  '${movies.length}',
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
          itemCount: movies.length,
          itemBuilder: (context, index) {
            final movie = movies[index];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: movie.posterUrl,
                  width: 50,
                  height: 75,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
              title: Text(
                movie.title,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              subtitle: Text(
                '⭐ ${movie.voteAverage.toStringAsFixed(1)}',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6)),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MovieDetailsScreen(
                      movie: movie,
                      favoritesService: widget.favoritesService,
                    ),
                  ),
                );
              },
            );
          },
        ),
        const Gap(16),
      ],
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
            hintText: 'Search by title, actor, or genre...',
            hintStyle: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6)),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6)),
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
            _searchMovies(value);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorDisplayWidget(
                  message: 'Search failed: $_error',
                  onRetry: () => _searchMovies(_searchController.text),
                )
              : _searchResults.isEmpty || _hasNoResults()
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.4)),
                          const Gap(16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'Search for movies'
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
                          const Gap(8),
                          Text(
                            'Find movies by title, actor, or genre',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.4)),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildResultsSection(
                              'title', _searchResults['title'] ?? []),
                          _buildResultsSection(
                              'actor', _searchResults['actor'] ?? []),
                          _buildResultsSection(
                              'genre', _searchResults['genre'] ?? []),
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
