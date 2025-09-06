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

import 'package:moviestar/constants/timing_constants.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/services/favorites_service.dart';
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
    with TickerProviderStateMixin {
  // Controller for the search text field.

  final TextEditingController _searchController = TextEditingController();

  // Loading state indicator for search.

  bool _isSearchLoading = false;

  // Loading state indicator for suggestions.

  bool _isSuggestionsLoading = true;

  // Error message if any.

  String? _error;

  // Search results categorized by search type.

  Map<String, List<Movie>> _searchResults = {};

  // Suggested movies (popular, trending, etc.)

  List<Movie> _suggestedMovies = [];

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
    _loadSuggestedMovies();
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
    setState(() {
      _moviesInList = Set.from(widget.customList.movieIds);
    });
  }

  // Loads suggested movies from popular/trending categories.

  Future<void> _loadSuggestedMovies() async {
    setState(() {
      _isSuggestionsLoading = true;
      _error = null;
    });

    try {
      final popularMoviesWithCacheInfo =
          await ref.read(popularMoviesWithCacheInfoProvider.future);
      final topRatedMoviesWithCacheInfo =
          await ref.read(topRatedMoviesWithCacheInfoProvider.future);

      // Combine popular and top-rated movies, remove duplicates.

      final allSuggestions = <Movie>[];
      allSuggestions.addAll(popularMoviesWithCacheInfo.data);
      allSuggestions.addAll(topRatedMoviesWithCacheInfo.data);

      // Remove duplicates and movies already in the list.

      final uniqueSuggestions = <int, Movie>{};
      for (final movie in allSuggestions) {
        if (!_moviesInList.contains(movie.id)) {
          uniqueSuggestions[movie.id] = movie;
        }
      }

      setState(() {
        _suggestedMovies = uniqueSuggestions.values.take(20).toList();
        _isSuggestionsLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
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
      setState(() {
        _searchResults = {};
        _error = null;
        _isSearchLoading = false;
      });
      return;
    }

    if (query.length < 2) {
      return;
    }

    setState(() {
      _isSearchLoading = true;
      _error = null;
    });

    try {
      final movieService = ref.read(movieServiceProvider);
      final results = await movieService.searchMoviesComprehensive(query);

      // Filter out movies already in the list.
      final filteredResults = <String, List<Movie>>{};
      for (final entry in results.entries) {
        filteredResults[entry.key] = entry.value
            .where((movie) => !_moviesInList.contains(movie.id))
            .toList();
      }

      if (_searchController.text == query) {
        setState(() {
          _searchResults = filteredResults;
          _isSearchLoading = false;
        });
      }
    } catch (e) {
      if (_searchController.text == query) {
        setState(() {
          _error = e.toString();
          _isSearchLoading = false;
        });
      }
    }
  }

  // Adds a movie to the custom list.

  Future<void> _addMovieToList(Movie movie) async {
    try {
      await widget.favoritesService
          .addMovieToCustomList(widget.customList.id, movie);
      setState(() {
        _moviesInList.add(movie.id);
      });

      if (mounted) {
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
                    'Added "${movie.title}" to ${widget.customList.name}',
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
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error adding movie: $e',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
            elevation: 6,
            duration: TimingConstants.snackbarLongDuration,
          ),
        );
      }
    }
  }

  // Builds a movie item card.

  Widget _buildMovieCard(Movie movie) {
    final isInList = _moviesInList.contains(movie.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: movie.posterUrl,
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
        title: Text(
          movie.title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
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
                  movie.voteAverage.toStringAsFixed(1),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  movie.releaseDate.year.toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (movie.overview.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                movie.overview,
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
                onPressed: () => _addMovieToList(movie),
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
                  ? 'Search for movies to add'
                  : _searchController.text.length < 2
                      ? 'Type at least 2 characters'
                      : 'No movies found',
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
              'Find movies by title, actor, or genre',
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

  Widget _buildSearchSection(String title, List<Movie> movies, IconData icon) {
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
                  '${movies.length}',
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
        ...movies.map((movie) => _buildMovieCard(movie)),
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
        onRetry: _loadSuggestedMovies,
      );
    }

    if (_suggestedMovies.isEmpty) {
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
                'Popular Movies',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ..._suggestedMovies.map((movie) => _buildMovieCard(movie)),
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
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Movies'),
            Text(
              widget.customList.name,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Search', icon: Icon(Icons.search)),
            Tab(text: 'Suggestions', icon: Icon(Icons.trending_up)),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                      hintText: 'Search by title, actor, or genre...',
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
                        setState(() {}), // To show/hide clear button.
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
