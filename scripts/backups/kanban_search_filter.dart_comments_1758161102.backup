/// Kanban Search & Filter - Search and Filtering Logic
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';

/// Search and filter controller for kanban board
class KanbanSearchController extends ChangeNotifier {
  String _searchQuery = '';
  final Set<String> _selectedGenres = {};
  double? _minRating;
  double? _maxRating;
  int? _startYear;
  int? _endYear;
  ContentType? _contentTypeFilter;
  bool _isSearchActive = false;

  // Getters
  String get searchQuery => _searchQuery;
  Set<String> get selectedGenres => Set.unmodifiable(_selectedGenres);
  double? get minRating => _minRating;
  double? get maxRating => _maxRating;
  int? get startYear => _startYear;
  int? get endYear => _endYear;
  ContentType? get contentTypeFilter => _contentTypeFilter;
  bool get isSearchActive => _isSearchActive;
  bool get hasActiveFilters => _isSearchActive || _hasAnyFilters();

  /// Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query.trim();
    _isSearchActive = _searchQuery.isNotEmpty;
    notifyListeners();
  }

  /// Toggle genre filter
  void toggleGenre(String genre) {
    if (_selectedGenres.contains(genre)) {
      _selectedGenres.remove(genre);
    } else {
      _selectedGenres.add(genre);
    }
    notifyListeners();
  }

  /// Set rating range filter
  void setRatingRange(double? min, double? max) {
    _minRating = min;
    _maxRating = max;
    notifyListeners();
  }

  /// Set year range filter
  void setYearRange(int? start, int? end) {
    _startYear = start;
    _endYear = end;
    notifyListeners();
  }

  /// Set content type filter
  void setContentTypeFilter(ContentType? contentType) {
    _contentTypeFilter = contentType;
    notifyListeners();
  }

  /// Clear all filters
  void clearAllFilters() {
    _searchQuery = '';
    _selectedGenres.clear();
    _minRating = null;
    _maxRating = null;
    _startYear = null;
    _endYear = null;
    _contentTypeFilter = null;
    _isSearchActive = false;
    notifyListeners();
  }

  /// Clear only search query
  void clearSearch() {
    _searchQuery = '';
    _isSearchActive = false;
    notifyListeners();
  }

  /// Check if any filters are active (excluding search)
  bool _hasAnyFilters() {
    return _selectedGenres.isNotEmpty ||
        _minRating != null ||
        _maxRating != null ||
        _startYear != null ||
        _endYear != null ||
        _contentTypeFilter != null;
  }

  /// Filter movies based on current criteria
  List<Movie> filterMovies(List<Movie> movies) {
    if (!hasActiveFilters) return movies;

    return movies.where((movie) {
      // Search query filter
      if (_isSearchActive && _searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final titleMatch = movie.title.toLowerCase().contains(query);
        final overviewMatch = movie.overview.toLowerCase().contains(query);
        final genreMatch = movie.genreIds.any((genreId) {
          // Simple genre matching - could be enhanced with genre name lookup
          return genreId.toString().contains(query);
        });

        if (!titleMatch && !overviewMatch && !genreMatch) {
          return false;
        }
      }

      // Genre filter
      if (_selectedGenres.isNotEmpty) {
        final movieGenres = movie.genreIds.map((id) => id.toString()).toSet();
        if (!_selectedGenres.any((genre) => movieGenres.contains(genre))) {
          return false;
        }
      }

      // Rating filter
      if (_minRating != null && movie.voteAverage < _minRating!) {
        return false;
      }
      if (_maxRating != null && movie.voteAverage > _maxRating!) {
        return false;
      }

      // Year filter
      if (_startYear != null || _endYear != null) {
        final movieYear = movie.releaseDate.year;
        if (_startYear != null && movieYear < _startYear!) {
          return false;
        }
        if (_endYear != null && movieYear > _endYear!) {
          return false;
        }
      }

      // Content type filter
      if (_contentTypeFilter != null &&
          movie.contentType != _contentTypeFilter) {
        return false;
      }

      return true;
    }).toList();
  }
}

/// Search bar widget for kanban board
class KanbanSearchBar extends StatefulWidget {
  final KanbanSearchController controller;
  final String hintText;
  final VoidCallback? onClear;

  const KanbanSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Search movies...',
    this.onClear,
  });

  @override
  State<KanbanSearchBar> createState() => _KanbanSearchBarState();
}

class _KanbanSearchBarState extends State<KanbanSearchBar> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController =
        TextEditingController(text: widget.controller.searchQuery);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(Dimensions.m),
      child: TextField(
        controller: _textController,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: widget.controller.isSearchActive
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _textController.clear();
                    widget.controller.clearSearch();
                    widget.onClear?.call();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        onChanged: (value) {
          widget.controller.updateSearchQuery(value);
        },
        onSubmitted: (value) {
          widget.controller.updateSearchQuery(value);
        },
      ),
    );
  }
}

/// Filter panel widget for advanced filtering
class KanbanFilterPanel extends StatelessWidget {
  final KanbanSearchController controller;
  final List<String> availableGenres;
  final VoidCallback? onFiltersChanged;

  const KanbanFilterPanel({
    super.key,
    required this.controller,
    this.availableGenres = const [],
    this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.l),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  controller.clearAllFilters();
                  onFiltersChanged?.call();
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.m),

          // Content Type Filter
          _buildContentTypeFilter(context),
          const SizedBox(height: Dimensions.m),

          // Rating Filter
          _buildRatingFilter(context),
          const SizedBox(height: Dimensions.m),

          // Year Filter
          _buildYearFilter(context),
          const SizedBox(height: Dimensions.m),

          // Genre Filter
          if (availableGenres.isNotEmpty) ...[
            _buildGenreFilter(context),
            const SizedBox(height: Dimensions.m),
          ],
        ],
      ),
    );
  }

  Widget _buildContentTypeFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content Type',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: Dimensions.s),
        Wrap(
          spacing: Dimensions.s,
          children: [
            FilterChip(
              label: const Text('All'),
              selected: controller.contentTypeFilter == null,
              onSelected: (selected) {
                controller.setContentTypeFilter(null);
                onFiltersChanged?.call();
              },
            ),
            FilterChip(
              label: const Text('Movies'),
              selected: controller.contentTypeFilter == ContentType.movie,
              onSelected: (selected) {
                controller.setContentTypeFilter(
                  selected ? ContentType.movie : null,
                );
                onFiltersChanged?.call();
              },
            ),
            FilterChip(
              label: const Text('TV Shows'),
              selected: controller.contentTypeFilter == ContentType.tvShow,
              onSelected: (selected) {
                controller.setContentTypeFilter(
                  selected ? ContentType.tvShow : null,
                );
                onFiltersChanged?.call();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rating Range',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: Dimensions.s),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Min Rating',
                  hintText: '0.0',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final rating = double.tryParse(value);
                  controller.setRatingRange(rating, controller.maxRating);
                  onFiltersChanged?.call();
                },
              ),
            ),
            const SizedBox(width: Dimensions.m),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Max Rating',
                  hintText: '10.0',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final rating = double.tryParse(value);
                  controller.setRatingRange(controller.minRating, rating);
                  onFiltersChanged?.call();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildYearFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Release Year Range',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: Dimensions.s),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Start Year',
                  hintText: '1900',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final year = int.tryParse(value);
                  controller.setYearRange(year, controller.endYear);
                  onFiltersChanged?.call();
                },
              ),
            ),
            const SizedBox(width: Dimensions.m),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'End Year',
                  hintText: '2025',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final year = int.tryParse(value);
                  controller.setYearRange(controller.startYear, year);
                  onFiltersChanged?.call();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenreFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Genres',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: Dimensions.s),
        Wrap(
          spacing: Dimensions.s,
          runSpacing: Dimensions.s,
          children: availableGenres.map((genre) {
            return FilterChip(
              label: Text(genre),
              selected: controller.selectedGenres.contains(genre),
              onSelected: (selected) {
                controller.toggleGenre(genre);
                onFiltersChanged?.call();
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Search utility functions
class KanbanSearchUtils {
  /// Extract unique genres from a list of movies
  static List<String> extractGenresFromMovies(List<Movie> movies) {
    final genreIds = <int>{};
    for (final movie in movies) {
      genreIds.addAll(movie.genreIds);
    }
    return genreIds.map((id) => id.toString()).toList()..sort();
  }

  /// Get search suggestions based on current query and movie list
  static List<String> getSearchSuggestions(
    String query,
    List<Movie> movies, {
    int maxSuggestions = 5,
  }) {
    if (query.isEmpty) return [];

    final suggestions = <String>{};
    final lowerQuery = query.toLowerCase();

    for (final movie in movies) {
      // Title suggestions
      if (movie.title.toLowerCase().contains(lowerQuery)) {
        suggestions.add(movie.title);
      }

      // Stop when we have enough suggestions
      if (suggestions.length >= maxSuggestions) break;
    }

    return suggestions.toList()..sort();
  }

  /// Highlight search terms in text
  static TextSpan highlightSearchTerm(
    String text,
    String searchTerm,
    TextStyle? normalStyle,
    TextStyle? highlightStyle,
  ) {
    if (searchTerm.isEmpty) {
      return TextSpan(text: text, style: normalStyle);
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerSearchTerm = searchTerm.toLowerCase();

    int start = 0;
    int index = lowerText.indexOf(lowerSearchTerm);

    while (index != -1) {
      // Add text before the match
      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: normalStyle,
          ),
        );
      }

      // Add the highlighted match
      spans.add(
        TextSpan(
          text: text.substring(index, index + searchTerm.length),
          style: highlightStyle,
        ),
      );

      start = index + searchTerm.length;
      index = lowerText.indexOf(lowerSearchTerm, start);
    }

    // Add any remaining text
    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: normalStyle,
        ),
      );
    }

    return TextSpan(children: spans);
  }
}
