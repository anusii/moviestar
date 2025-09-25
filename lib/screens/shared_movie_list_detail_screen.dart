/// Shared Movie List Detail Screen for MovieStar using decomposed components.
/// Facade screen delegating to specialized operation classes.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/shared/widgets/shared_movie_list_detail/data_loader.dart';
import 'package:moviestar/shared/widgets/shared_movie_list_detail/movie_processor.dart';
import 'package:moviestar/shared/widgets/shared_movie_list_detail/navigation_handler.dart';
import 'package:moviestar/widgets/base_screen.dart';

/// Screen to display movies within a shared movie list using decomposed components.
/// Facade screen delegating to specialized operation classes.

class SharedMovieListDetailScreen extends ConsumerStatefulWidget {
  final String listName;
  final String listDescription;
  final String owner;
  final String ownerWebId;
  final String sharedBy;
  final String sharedByWebId;
  final List<Map<String, dynamic>> movies;
  final String permissions;

  const SharedMovieListDetailScreen({
    super.key,
    required this.listName,
    required this.listDescription,
    required this.owner,
    required this.ownerWebId,
    required this.sharedBy,
    required this.sharedByWebId,
    required this.movies,
    required this.permissions,
  });

  @override
  ConsumerState<SharedMovieListDetailScreen> createState() =>
      _SharedMovieListDetailScreenState();
}

class _SharedMovieListDetailScreenState
    extends ConsumerState<SharedMovieListDetailScreen> with ScreenStateMixin {
  Map<String, String> _movieTitles = {}; // Cache for movie titles.
  bool _loadingTitles = true;

  // Decomposed operation classes.

  late final SharedListDataLoader _dataLoader;
  late final SharedListNavigationHandler _navigationHandler;

  @override
  void initState() {
    super.initState();
    _initializeComponents();
    _loadMovieTitles();
  }

  /// Initialize decomposed components.

  void _initializeComponents() {
    _dataLoader = SharedListDataLoader(
      ref: ref,
      context: context,
      widget: widget,
      ownerWebId: widget.ownerWebId,
      sharedByWebId: widget.sharedByWebId,
    );
    _navigationHandler = SharedListNavigationHandler(
      ref: ref,
      context: context,
      widget: widget,
      screenStateMixin: this,
      dataLoader: _dataLoader,
      favoritesService: null, // Will use fallback for shared context
    );
  }

  /// Load movie titles using data loader.

  Future<void> _loadMovieTitles() async {
    try {
      final titles = await _dataLoader.loadMovieTitles(widget.movies);

      if (mounted) {
        safeSetState(() {
          _movieTitles = titles;
          _loadingTitles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        safeSetState(() {
          _loadingTitles = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: widget.listName,
      automaticallyImplyLeading: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // List metadata header using decomposed component.

          SharedListMovieProcessor.buildListHeader(
            context: context,
            listName: widget.listName,
            listDescription: widget.listDescription,
            owner: widget.owner,
            sharedBy: widget.sharedBy,
            permissions: widget.permissions,
            movieCount: widget.movies.length,
          ),

          // Movies list.

          Expanded(
            child: widget.movies.isEmpty
                ? SharedListMovieProcessor.buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.movies.length,
                    itemBuilder: (context, index) {
                      final movieData = widget.movies[index];
                      final movieId = movieData['movieId']?.toString() ?? '0';
                      final movieTitle = _loadingTitles
                          ? 'Loading...'
                          : (_movieTitles[movieId] ??
                              movieData['fileName'] ??
                              'Unknown Movie');

                      return SharedListMovieProcessor.buildMovieCard(
                        context: context,
                        movieData: movieData,
                        movieTitle: movieTitle,
                        onTap: () => _navigationHandler
                            .navigateToMovieDetails(movieData),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
