/// Kanban Search & Filter - Search and Filtering Logic.
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

/// Search and filter controller for kanban board.
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

  /// Update search query.
  void updateSearchQuery(String query) {
    _searchQuery = query.trim();
    _isSearchActive = _searchQuery.isNotEmpty;
    notifyListeners();
  }

  /// Toggle genre filter.
  void toggleGenre(String genre) {
    if (_selectedGenres.contains(genre)) {
      _selectedGenres.remove(genre);
    } else {
      _selectedGenres.add(genre);
    }
    notifyListeners();
  }

  /// Set rating range filter.
  void setRatingRange(double? min, double? max) {
    _minRating = min;
    _maxRating = max;
    notifyListeners();
  }

  /// Set year range filter.
  void setYearRange(int? start, int? end) {
    _startYear = start;
    _endYear = end;
    notifyListeners();
  }

  /// Set content type filter.
  void setContentTypeFilter(ContentType? contentType) {
    _contentTypeFilter = contentType;
    notifyListeners();
  }

  /// Clear all filters.
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

  /// Clear only search query.
  void clearSearch() {
    _searchQuery = '';
    _isSearchActive = false;
    notifyListeners();
  }

  /// Check if any filters are active (excluding search).
  bool _hasAnyFilters() {
    return _selectedGenres.isNotEmpty ||
        _minRating != null ||
        _maxRating != null ||
        _startYear != null ||
        _endYear != null ||
        _contentTypeFilter != null;
  }

  /// Filter movies based on current criteria.
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

/// Search bar widget for kanban board.
class KanbanSearchBar extends StatefulWidget {
  final KanbanSearchController controller;
  final String hintText;
  final VoidCallback onClear;

  const KanbanSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Search movies...',
    required this.onClear,
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
                    widget.onClear();
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
