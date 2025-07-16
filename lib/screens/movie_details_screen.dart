/// Screen displaying detailed information about a selected movie.
///
// Time-stamp: <Friday 2025-07-04 15:06:40 +1000 Graham Williams>
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
/// Authors: Kevin Wang

library;

import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/utils/date_format_util.dart';

/// A screen that displays detailed information about a selected movie.

class MovieDetailsScreen extends StatefulWidget {
  /// The movie to display details for.

  final Movie movie;

  /// Service for managing favorite movies.

  final FavoritesService favoritesService;

  /// Creates a new [MovieDetailsScreen] widget.

  const MovieDetailsScreen({
    super.key,
    required this.movie,
    required this.favoritesService,
  });

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

/// State class for the movie details screen.

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  /// Indicates whether the movie is in the to-watch list.

  bool _isInToWatch = false;

  /// Indicates whether the movie is in the watched list.

  bool _isInWatched = false;

  /// Personal rating for the movie.

  double? _personalRating;

  /// Indicates whether the personal rating is being loaded.

  bool _isLoadingRating = true;

  /// Personal comments for the movie.

  String? _personalComments;

  /// Controller for the comments text field.

  final TextEditingController _commentsController = TextEditingController();

  /// Indicates whether the comments are being loaded.

  bool _isLoadingComments = true;

  @override
  void initState() {
    super.initState();
    _checkListStatus();
    _loadPersonalRating();
    _loadPersonalComments();
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  /// Checks if the current movie is in either list.

  Future<void> _checkListStatus() async {
    final isInToWatch = await widget.favoritesService.isInToWatch(widget.movie);
    final isInWatched = await widget.favoritesService.isInWatched(widget.movie);
    setState(() {
      _isInToWatch = isInToWatch;
      _isInWatched = isInWatched;
    });
  }

  /// Toggles the to-watch status of the current movie.

  Future<void> _toggleToWatch() async {
    if (_isInToWatch) {
      await widget.favoritesService.removeFromToWatch(widget.movie);
    } else {
      await widget.favoritesService.addToWatch(widget.movie);
    }
    setState(() {
      _isInToWatch = !_isInToWatch;
    });
  }

  /// Toggles the watched status of the current movie.

  Future<void> _toggleWatched() async {
    if (_isInWatched) {
      await widget.favoritesService.removeFromWatched(widget.movie);
    } else {
      await widget.favoritesService.addToWatched(widget.movie);
    }
    setState(() {
      _isInWatched = !_isInWatched;
    });
  }

  Future<void> _loadPersonalRating() async {
    final rating = await widget.favoritesService.getPersonalRating(
      widget.movie,
    );
    setState(() {
      _personalRating = rating;
      _isLoadingRating = false;
    });
  }

  Future<void> _updateRating(double? rating) async {
    if (rating == null) {
      await widget.favoritesService.removePersonalRating(widget.movie);
    } else {
      await widget.favoritesService.setPersonalRating(widget.movie, rating);

      // We might want to automatically mark a movie as watched when a rating is
      // given. We would not expect a rating if the user has not watched a
      // movie, so this seems like a good (though opinionated)
      // behaviour. (20250704 gjw)

      if (!_isInWatched) {
        await widget.favoritesService.addToWatched(widget.movie);
      }
    }
    setState(() {
      _personalRating = rating;
      // Update watched status if rating was set.

      if (rating != null && !_isInWatched) {
        _isInWatched = true;
      }
    });
  }

  Future<void> _loadPersonalComments() async {
    final comments = await widget.favoritesService.getMovieComments(
      widget.movie,
    );
    setState(() {
      _personalComments = comments;
      _commentsController.text = comments ?? '';
      _isLoadingComments = false;
    });
  }

  Future<void> _updateComments(String? comments) async {
    if (comments == null || comments.trim().isEmpty) {
      await widget.favoritesService.removeMovieComments(widget.movie);
    } else {
      await widget.favoritesService.setMovieComments(widget.movie, comments);
    }
    setState(() {
      _personalComments = comments;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            iconTheme: const IconThemeData(
              color: Colors.white,
              size: 24,
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: widget.movie.backdropUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.movie.title,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isInToWatch
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: _isInToWatch
                                  ? Colors.blue
                                  : Theme.of(context).iconTheme.color,
                            ),
                            onPressed: _toggleToWatch,
                            tooltip: _isInToWatch
                                ? 'Remove from To Watch'
                                : 'Add to To Watch',
                          ),
                          IconButton(
                            icon: Icon(
                              _isInWatched
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              color: _isInWatched
                                  ? Colors.green
                                  : Theme.of(context).iconTheme.color,
                            ),
                            onPressed: _toggleWatched,
                            tooltip: _isInWatched
                                ? 'Remove from Watched'
                                : 'Add to Watched',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        widget.movie.voteAverage.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).iconTheme.color,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormatUtil.formatShort(widget.movie.releaseDate),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Personal Rating Section,
                  Text(
                    'Your Rating',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  _isLoadingRating
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: _personalRating ?? 0,
                                min: 0,
                                max: 10,
                                divisions: 100,
                                label: _personalRating?.toStringAsFixed(1) ??
                                    '0.0',
                                onChanged: (value) => _updateRating(value),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.clear,
                                  color: Theme.of(context).iconTheme.color),
                              onPressed: _personalRating == null
                                  ? null
                                  : () => _updateRating(null),
                              tooltip: 'Clear rating',
                            ),
                          ],
                        ),
                  Text(
                    _personalRating == null
                        ? 'No rating yet'
                        : 'Your rating: ${_personalRating!.toStringAsFixed(1)}/10',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),

                  // Personal Comments Section
                  Text(
                    'My Comments',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  _isLoadingComments
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _commentsController,
                              style: Theme.of(context).textTheme.bodyLarge,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText:
                                    'Add your thoughts about this movie...',
                                hintStyle: Theme.of(context)
                                    .inputDecorationTheme
                                    .hintStyle,
                                filled: true,
                                fillColor: Theme.of(context)
                                    .inputDecorationTheme
                                    .fillColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (value) => _updateComments(value),
                            ),
                            const SizedBox(height: 8),
                            if (_personalComments != null &&
                                _personalComments!.isNotEmpty)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Theme.of(context).iconTheme.color,
                                    ),
                                    label: Text(
                                      'Clear Comments',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge,
                                    ),
                                    onPressed: () {
                                      _commentsController.clear();
                                      _updateComments(null);
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                  const SizedBox(height: 16),
                  Text(
                    'Overview',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.movie.overview,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
