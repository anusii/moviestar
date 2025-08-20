/// Movie Kanban Board Widget - Custom Implementation
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

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/screens/custom_list_detail_screen.dart';
import 'package:moviestar/screens/movie_category_screen.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/widgets/movie_card.dart';

/// Enum for different column types in the kanban board.

enum KanbanColumnType {
  popular,
  toWatch,
  watched,
  customList,
}

/// Data structure for drag and drop operations.

class MovieDragData {
  final Movie movie;
  final KanbanColumnType sourceType;
  final String sourceId;
  final String sourceName;

  const MovieDragData({
    required this.movie,
    required this.sourceType,
    required this.sourceId,
    required this.sourceName,
  });
}

/// A movie item wrapper for kanban board usage.

class MovieItem {
  final Movie movie;
  final bool fromCache;
  final Duration? cacheAge;

  const MovieItem({
    required this.movie,
    this.fromCache = false,
    this.cacheAge,
  });

  String get id => movie.id.toString();
}

/// Custom Kanban board widget for displaying movies in columns.

class MovieKanbanBoard extends ConsumerStatefulWidget {
  final FavoritesService favoritesService;

  const MovieKanbanBoard({
    super.key,
    required this.favoritesService,
  });

  @override
  ConsumerState<MovieKanbanBoard> createState() => _MovieKanbanBoardState();
}

class _MovieKanbanBoardState extends ConsumerState<MovieKanbanBoard> {
  final int _maxItemsPerColumn = 8;

  @override
  void initState() {
    super.initState();
  }

  // Show context menu for movie copy operations.

  void _showMovieContextMenu(
    Offset position,
    Movie movie,
    KanbanColumnType sourceType,
    String sourceId,
    String sourceName,
  ) {
    // Get current custom lists for dynamic menu.

    widget.favoritesService.customLists.first.then((customLists) {
      if (!mounted) return;
      showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(
          position.dx,
          position.dy,
          position.dx + 1,
          position.dy + 1,
        ),
        items: _buildContextMenuItems(movie, sourceType, sourceId, customLists),
      ).then((action) {
        if (action != null) {
          _handleContextMenuAction(action, movie, sourceType, sourceId);
        }
      });
    }).catchError((e) {
      // Fallback to basic menu if custom lists can't be loaded.

      if (!mounted) return;
      showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(
          position.dx,
          position.dy,
          position.dx + 1,
          position.dy + 1,
        ),
        items: _buildContextMenuItems(movie, sourceType, sourceId, []),
      ).then((action) {
        if (action != null) {
          _handleContextMenuAction(action, movie, sourceType, sourceId);
        }
      });
    });
  }

  // Build context menu items based on current movie location.

  List<PopupMenuEntry<String>> _buildContextMenuItems(
    Movie movie,
    KanbanColumnType sourceType,
    String sourceId,
    List<CustomList> customLists,
  ) {
    final items = <PopupMenuEntry<String>>[];

    // Add "Copy to..." options.

    if (sourceType != KanbanColumnType.toWatch) {
      items.add(const PopupMenuItem(
        value: 'copy_to_watch',
        child: Row(
          children: [
            Icon(Icons.bookmark_add_outlined),
            Gap(8),
            Text('Copy to To Watch'),
          ],
        ),
      ));
    }

    if (sourceType != KanbanColumnType.watched) {
      items.add(const PopupMenuItem(
        value: 'copy_watched',
        child: Row(
          children: [
            Icon(Icons.check_circle_outline),
            Gap(8),
            Text('Copy to Watched'),
          ],
        ),
      ));
    }

    // Add custom list options.

    for (final customList in customLists) {
      // Skip if the movie is already in this custom list.

      if (sourceType == KanbanColumnType.customList &&
          sourceId == customList.id) {
        continue;
      }

      items.add(PopupMenuItem(
        value: 'copy_custom_${customList.id}',
        child: Row(
          children: [
            const Icon(Icons.playlist_add),
            const Gap(8),
            Expanded(
              child: Text(
                'Copy to ${customList.name}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ));
    }

    // Add divider before remove option (only for non-Popular movies).

    if (sourceType != KanbanColumnType.popular) {
      if (items.isNotEmpty) {
        items.add(const PopupMenuDivider());
      }
      items.add(PopupMenuItem(
        value: 'remove',
        child: Row(
          children: [
            Icon(Icons.remove_circle_outline,
                color: Theme.of(context).colorScheme.error),
            const Gap(8),
            Text(
              'Remove from this list',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
      ));
    }

    return items;
  }

  // Handle context menu action.

  Future<void> _handleContextMenuAction(
    String action,
    Movie movie,
    KanbanColumnType sourceType,
    String sourceId,
  ) async {
    try {
      // Ensure movie file exists for copy operations (especially from Popular).

      if (action != 'remove') {
        await _ensureMovieFileExists(movie);
      }

      switch (action) {
        case 'copy_to_watch':
          await widget.favoritesService.addToWatch(movie);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Added "${movie.title}" to To Watch')),
            );
          }
          break;
        case 'copy_watched':
          await widget.favoritesService.addToWatched(movie);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Added "${movie.title}" to Watched')),
            );
          }
          break;
        case 'remove':
          await _removeFromCurrentList(movie, sourceType, sourceId);
          break;
        default:
          // Handle custom list copy operations.

          if (action.startsWith('copy_custom_')) {
            final listId = action.substring('copy_custom_'.length);
            await widget.favoritesService.addMovieToCustomList(listId, movie);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Added "${movie.title}" to custom list')),
              );
            }
          }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Remove movie from its current list.

  Future<void> _removeFromCurrentList(
    Movie movie,
    KanbanColumnType sourceType,
    String sourceId,
  ) async {
    switch (sourceType) {
      case KanbanColumnType.toWatch:
        await widget.favoritesService.removeFromToWatch(movie);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed "${movie.title}" from To Watch')),
          );
        }
        break;
      case KanbanColumnType.watched:
        await widget.favoritesService.removeFromWatched(movie);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed "${movie.title}" from Watched')),
          );
        }
        break;
      case KanbanColumnType.customList:
        await widget.favoritesService
            .removeMovieFromCustomList(sourceId, movie.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Removed "${movie.title}" from custom list')),
          );
        }
        break;
      case KanbanColumnType.popular:
        // Can't remove from popular.

        break;
    }
  }

  // Handle drop operation for moving/copying movies between lists.

  Future<void> _handleDrop(
    MovieDragData dragData,
    KanbanColumnType targetType,
    String targetId,
    String targetName,
  ) async {
    // Don't allow dropping on same column.

    if (dragData.sourceType == targetType && dragData.sourceId == targetId) {
      return;
    }

    // Determine if this is a copy or move operation.

    final isCopyOperation = dragData.sourceType == KanbanColumnType.popular;

    try {
      // Ensure movie file exists before adding to user lists.

      await _ensureMovieFileExists(dragData.movie);

      // Add to target list.

      switch (targetType) {
        case KanbanColumnType.toWatch:
          await widget.favoritesService.addToWatch(dragData.movie);
          break;
        case KanbanColumnType.watched:
          await widget.favoritesService.addToWatched(dragData.movie);
          break;
        case KanbanColumnType.customList:
          await widget.favoritesService
              .addMovieToCustomList(targetId, dragData.movie);
          break;
        case KanbanColumnType.popular:
        // Can't drop into popular.
      }

      // Only remove from source if it's a move operation (not from Popular).

      if (!isCopyOperation) {
        await _removeFromCurrentList(
            dragData.movie, dragData.sourceType, dragData.sourceId);
      }

      if (mounted) {
        final message = isCopyOperation
            ? 'Copied "${dragData.movie.title}" from ${dragData.sourceName} to $targetName'
            : 'Moved "${dragData.movie.title}" from ${dragData.sourceName} to $targetName';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error ${isCopyOperation ? "copying" : "moving"} movie: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Ensure a movie file exists for the given movie.
  // This is important for movies from the Popular list that might not have local files yet.

  Future<void> _ensureMovieFileExists(Movie movie) async {
    try {
      // Check if the movie file already exists.

      final hasFile = await widget.favoritesService.hasMovieFile(movie);

      if (!hasFile) {
        // For new movies (typically from Popular), we might need to create basic metadata.
        // The favorites service should handle this automatically when adding to lists,
        // but we can add a small delay to ensure the movie data is properly cached.

        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      // If checking fails, continue anyway - the favorites service should handle creation.

      debugPrint(
          'Warning: Could not verify movie file existence for ${movie.title}: $e');
    }
  }

  // Build a movie item widget for the kanban board with drag and context menu support.

  Widget _buildMovieItem(
    Movie movie,
    String category, {
    bool fromCache = false,
    required KanbanColumnType columnType,
    required String columnId,
    required String columnName,
  }) {
    // All movies can be dragged, but Popular will be copy operations.

    final canDrag = true;

    final movieCard = Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: MovieCard.poster(
        movie: movie,
        fromCache: fromCache,
        width: 100,
        height: 150,
        favoritesService: widget.favoritesService,
        onTap: () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MovieDetailsScreen(
                  movie: movie,
                  favoritesService: widget.favoritesService,
                ),
              ),
            );
          }
        },
      ),
    );

    // Wrap in context menu for copy operations.

    final contextMenuCard = GestureDetector(
      onSecondaryTapUp: (details) => _showMovieContextMenu(
        details.globalPosition,
        movie,
        columnType,
        columnId,
        columnName,
      ),
      child: movieCard,
    );

    // If not draggable, just return the context menu version.

    if (!canDrag) {
      return contextMenuCard;
    }

    // Wrap in Draggable for drag operations.

    return Draggable<MovieDragData>(
      data: MovieDragData(
        movie: movie,
        sourceType: columnType,
        sourceId: columnId,
        sourceName: columnName,
      ),
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Opacity(
              opacity: 0.8,
              child: SizedBox(
                width: 100,
                height: 150,
                child: MovieCard.poster(
                  movie: movie,
                  fromCache: fromCache,
                  width: 100,
                  height: 150,
                  favoritesService: widget.favoritesService,
                  onTap: () {}, // Disabled during drag.
                ),
              ),
            ),
            // Show copy indicator for Popular movies.

            if (columnType == KanbanColumnType.popular)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.copy,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
      childWhenDragging: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        width: 100,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            style: BorderStyle.solid,
            width: 2,
          ),
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
        ),
        child: Icon(
          Icons.movie_outlined,
          size: 40,
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: contextMenuCard,
    );
  }

  // Build a kanban column with drag target support.

  Widget _buildKanbanColumn({
    required String title,
    required List<Movie> movies,
    required String categoryId,
    required bool fromCache,
    required KanbanColumnType columnType,
  }) {
    final displayMovies = movies.take(_maxItemsPerColumn).toList();
    final hasMore = movies.length > _maxItemsPerColumn;
    final canAcceptDrop = columnType != KanbanColumnType.popular;

    Widget columnContent = Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header.

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${movies.length}${hasMore ? '+' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                if (hasMore) ...[
                  const Gap(4),
                  TextButton(
                    onPressed: () =>
                        _navigateToMovieCategory(title, movies, fromCache),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'View More',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 11,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Movie items.

          Expanded(
            child: displayMovies.isEmpty
                ? Center(
                    child: Text(
                      'No movies',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: displayMovies.length,
                    itemBuilder: (context, index) {
                      final movie = displayMovies[index];
                      return _buildMovieItem(
                        movie,
                        categoryId,
                        fromCache: fromCache,
                        columnType: columnType,
                        columnId: categoryId,
                        columnName: title,
                      );
                    },
                  ),
          ),
        ],
      ),
    );

    // Wrap in DragTarget if it can accept drops.

    if (!canAcceptDrop) {
      return columnContent;
    }

    return DragTarget<MovieDragData>(
      onAcceptWithDetails: (details) {
        _handleDrop(details.data, columnType, categoryId, title);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isHovering
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: columnContent,
        );
      },
    );
  }

  // Navigate to a dedicated page for viewing all movies in a category.

  void _navigateToMovieCategory(
      String categoryName, List<Movie> movies, bool fromCache) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieCategoryScreen(
          categoryName: categoryName,
          movies: movies,
          favoritesService: widget.favoritesService,
          fromCache: fromCache,
        ),
      ),
    );
  }

  // Build a custom list column that loads and displays movies from a CustomList.

  Widget _buildCustomListColumn(CustomList customList) {
    final movieIds = customList.movieIds;
    final displayMovieIds = movieIds.take(_maxItemsPerColumn).toList();

    Widget columnContent = Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header.

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _navigateToCustomListDetail(customList),
                    child: Text(
                      customList.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${movieIds.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                if (movieIds.length > _maxItemsPerColumn) ...[
                  const Gap(4),
                  TextButton(
                    onPressed: () => _navigateToCustomListDetail(customList),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'View More',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 11,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Movie items.

          Expanded(
            child: movieIds.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No movies',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                            ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: displayMovieIds.length,
                    itemBuilder: (context, index) {
                      final movieId = displayMovieIds[index];
                      return _buildCustomListMovieItem(
                          movieId, customList.id, customList);
                    },
                  ),
          ),
        ],
      ),
    );

    // Wrap in DragTarget for drop support.

    return DragTarget<MovieDragData>(
      onAcceptWithDetails: (details) {
        _handleDrop(
          details.data,
          KanbanColumnType.customList,
          customList.id,
          customList.name,
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isHovering
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: columnContent,
        );
      },
    );
  }

  // Build a movie item for a custom list (loading movie details on demand).

  Widget _buildCustomListMovieItem(
      int movieId, String categoryId, CustomList customList) {
    return Consumer(
      builder: (context, ref, child) {
        final cachedMovieService = ref.read(cachedMovieServiceProvider);

        return FutureBuilder<Movie>(
          future: cachedMovieService.getMovieDetails(movieId),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                width: 100,
                height: 150,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      size: 24,
                    ),
                    const Gap(4),
                    Text(
                      'Error',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting ||
                !snapshot.hasData) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                width: 100,
                height: 150,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            }

            final movie = snapshot.data!;
            return _buildMovieItem(
              movie,
              categoryId,
              fromCache: false,
              columnType: KanbanColumnType.customList,
              columnId: customList.id,
              columnName: customList.name,
            );
          },
        );
      },
    );
  }

  // Navigate to custom list detail screen.

  void _navigateToCustomListDetail(CustomList customList) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomListDetailScreen(
          customList: customList,
          favoritesService: widget.favoritesService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        // Watch the popular movies data.

        final popularMoviesAsync =
            ref.watch(popularMoviesWithCacheInfoProvider);

        return popularMoviesAsync.when(
          data: (popularCacheResult) {
            return StreamBuilder<List<Movie>>(
              stream: widget.favoritesService.toWatchMovies,
              builder: (context, toWatchSnapshot) {
                return StreamBuilder<List<Movie>>(
                  stream: widget.favoritesService.watchedMovies,
                  builder: (context, watchedSnapshot) {
                    return StreamBuilder<List<CustomList>>(
                      stream: widget.favoritesService.customLists,
                      builder: (context, customListsSnapshot) {
                        final popularMovies = popularCacheResult.data;
                        final toWatchMovies = toWatchSnapshot.data ?? [];
                        final watchedMovies = watchedSnapshot.data ?? [];
                        final customLists = customListsSnapshot.data ?? [];

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Popular Movies Column.

                              _buildKanbanColumn(
                                title: 'Popular',
                                movies: popularMovies,
                                categoryId: 'popular',
                                fromCache: popularCacheResult.fromCache,
                                columnType: KanbanColumnType.popular,
                              ),

                              // To Watch Column.

                              _buildKanbanColumn(
                                title: 'To Watch',
                                movies: toWatchMovies,
                                categoryId: 'towatch',
                                fromCache: false,
                                columnType: KanbanColumnType.toWatch,
                              ),

                              // Watched Column.

                              _buildKanbanColumn(
                                title: 'Watched',
                                movies: watchedMovies,
                                categoryId: 'watched',
                                fromCache: false,
                                columnType: KanbanColumnType.watched,
                              ),

                              // Custom List Columns.
                              ...customLists.map(
                                (customList) =>
                                    _buildCustomListColumn(customList),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Error loading movies: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        );
      },
    );
  }
}
