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
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/constants/timing_constants.dart';
import 'package:moviestar/models/app_error.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/screens/custom_list_detail_screen.dart';
import 'package:moviestar/screens/movie_category_screen.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/services/api_key_validation_service.dart';
import 'package:moviestar/services/error_mapper_service.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/services/favorites_service_adapter.dart';
import 'package:moviestar/services/network_connectivity_service.dart';
import 'package:moviestar/utils/movie_sort_util.dart';
import 'package:moviestar/widgets/error_display_widget.dart';
import 'package:moviestar/widgets/movie_card.dart';
import 'package:moviestar/widgets/sort_controls.dart';

import '../constants/ui_constants.dart';

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

/// Queue item for tracking pending operations.

class OperationQueueItem {
  final int id;
  final String description;
  final OperationStatus status;
  final DateTime startTime;

  OperationQueueItem({
    required this.id,
    required this.description,
    required this.status,
    required this.startTime,
  });

  OperationQueueItem copyWith({
    int? id,
    String? description,
    required OperationStatus status,
    DateTime? startTime,
  }) {
    return OperationQueueItem(
      id: id ?? this.id,
      description: description ?? this.description,
      status: status,
      startTime: startTime ?? this.startTime,
    );
  }
}

enum OperationStatus {
  pending,
  inProgress,
  completed,
  failed,
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
  late ScrollController _horizontalScrollController;

  // Optimistic UI state tracking.

  final Map<String, Set<int>> _pendingOperations = {};
  final Map<String, Movie> _optimisticMovies = {};
  final Set<String> _syncErrors = {};

  // Queue-based progress tracking.

  final List<OperationQueueItem> _operationQueue = [];
  int _nextOperationId = 0;

  // Sorting state for each column.

  final Map<String, MovieSortCriteria> _columnSortCriteria = {
    'popular': MovieSortCriteria.ratingDesc, // Default: by rating
    'towatch': MovieSortCriteria.nameAsc, // Default: alphabetical
    'watched': MovieSortCriteria.dateDesc, // Default: recent first
  };

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  // Get the key for tracking operations.

  String _getOperationKey(KanbanColumnType type, String id) {
    return '${type.name}_$id';
  }

  // Handle sort change for a column.

  void _onSortChanged(String columnId, MovieSortCriteria criteria) {
    setState(() {
      _columnSortCriteria[columnId] = criteria;
    });
  }

  // Queue management methods.

  int _addToQueue(String description) {
    final id = _nextOperationId++;
    _operationQueue.add(
      OperationQueueItem(
        id: id,
        description: description,
        status: OperationStatus.pending,
        startTime: DateTime.now(),
      ),
    );
    setState(() {});
    return id;
  }

  void _updateQueueStatus(int operationId, OperationStatus status) {
    final index = _operationQueue.indexWhere((op) => op.id == operationId);
    if (index != -1) {
      _operationQueue[index] = _operationQueue[index].copyWith(status: status);
      setState(() {});

      // Auto-remove completed/failed operations after delay.

      if (status == OperationStatus.completed ||
          status == OperationStatus.failed) {
        Future.delayed(TimingConstants.autoRemoveDelay, () {
          _operationQueue.removeWhere((op) => op.id == operationId);
          if (mounted) setState(() {});
        });
      }
    }
  }

  // Add movie optimistically to UI state.

  void _addOptimisticMovie(
    KanbanColumnType targetType,
    String targetId,
    Movie movie,
  ) {
    final key = _getOperationKey(targetType, targetId);
    _pendingOperations[key] ??= <int>{};
    _pendingOperations[key]!.add(movie.id);
    _optimisticMovies['${movie.id}_$key'] = movie;

    setState(() {});
  }

  // Remove movie optimistically from UI state.

  void _removeOptimisticMovie(
    KanbanColumnType sourceType,
    String sourceId,
    Movie movie,
  ) {
    final key = _getOperationKey(sourceType, sourceId);
    _pendingOperations[key] ??= <int>{};
    _pendingOperations[key]!.add(-movie.id); // Negative ID indicates removal
    setState(() {});
  }

  // Clear optimistic state after backend sync.

  void _clearOptimisticState(KanbanColumnType type, String id, int movieId) {
    final key = _getOperationKey(type, id);
    _pendingOperations[key]?.remove(movieId);
    _pendingOperations[key]?.remove(-movieId);
    if (_pendingOperations[key]?.isEmpty == true) {
      _pendingOperations.remove(key);
    }
    _optimisticMovies.remove('${movieId}_$key');
    _syncErrors.remove('${movieId}_$key');
    if (mounted) setState(() {});
  }

  // Mark sync error and revert optimistic state.

  void _markSyncError(KanbanColumnType type, String id, int movieId) {
    final key = _getOperationKey(type, id);
    _syncErrors.add('${movieId}_$key');
    // Remove the optimistic state to revert UI
    _clearOptimisticState(type, id, movieId);
  }

  // Get movies with optimistic updates applied.

  List<Movie> _getMoviesWithOptimisticUpdates(
    List<Movie> originalMovies,
    KanbanColumnType type,
    String id,
  ) {
    final key = _getOperationKey(type, id);
    final pendingOps = _pendingOperations[key];
    if (pendingOps == null || pendingOps.isEmpty) {
      return originalMovies;
    }

    debugPrint(
      '⚡ [OptimisticUI] Getting movies with optimistic updates for $type ($id):',
    );
    debugPrint('   Key: $key');
    debugPrint('   Pending ops: $pendingOps');
    debugPrint('   Original movies: ${originalMovies.length}');

    final result = List<Movie>.from(originalMovies);

    for (final opId in pendingOps) {
      if (opId > 0) {
        // Addition - add if not already present.
        final movieKey = '${opId}_$key';
        final movie = _optimisticMovies[movieKey];

        if (movie != null) {
          debugPrint(
            '⚡ [OptimisticUI] Found optimistic movie: ${movie.title} (contentType: ${movie.contentType})',
          );
          if (!result.any((m) => m.id == movie.id)) {
            result.add(movie);
          } else {
            debugPrint(
              '⚡ [OptimisticUI] Movie already exists in result, skipping',
            );
          }
        } else {
          debugPrint(
            '⚡ [OptimisticUI] Movie not found in _optimisticMovies for key: $movieKey',
          );
        }
      } else {
        // Removal - remove if present.

        final movieId = -opId;
        result.removeWhere((m) => m.id == movieId);
      }
    }

    return result;
  }

  // Get movie IDs with optimistic updates applied for custom lists.

  List<int> _getMovieIdsWithOptimisticUpdates(
    List<int> originalIds,
    KanbanColumnType type,
    String id,
  ) {
    final key = _getOperationKey(type, id);
    final pendingOps = _pendingOperations[key];
    if (pendingOps == null || pendingOps.isEmpty) {
      return originalIds;
    }

    final result = List<int>.from(originalIds);

    for (final opId in pendingOps) {
      if (opId > 0) {
        // Addition - add if not already present.

        if (!result.contains(opId)) {
          result.add(opId);
        }
      } else {
        // Removal - remove if present.

        final movieId = -opId;
        result.remove(movieId);
      }
    }

    return result;
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
      items.add(
        const PopupMenuItem(
          value: 'copy_to_watch',
          child: Row(
            children: [
              Icon(Icons.bookmark_add_outlined),
              Gap(Gaps.m),
              Text('Copy to To Watch'),
            ],
          ),
        ),
      );
    }

    if (sourceType != KanbanColumnType.watched) {
      items.add(
        const PopupMenuItem(
          value: 'copy_watched',
          child: Row(
            children: [
              Icon(Icons.check_circle_outline),
              Gap(Gaps.m),
              Text('Copy to Watched'),
            ],
          ),
        ),
      );
    }

    // Add custom list options.

    for (final customList in customLists) {
      // Skip if the movie is already in this custom list.

      if (sourceType == KanbanColumnType.customList &&
          sourceId == customList.id) {
        continue;
      }

      items.add(
        PopupMenuItem(
          value: 'copy_custom_${customList.id}',
          child: Row(
            children: [
              const Icon(Icons.playlist_add),
              const Gap(Gaps.m),
              Expanded(
                child: Text(
                  'Copy to ${customList.name}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Add divider before remove option (only for non-Popular movies).

    if (sourceType != KanbanColumnType.popular) {
      if (items.isNotEmpty) {
        items.add(const PopupMenuDivider());
      }
      items.add(
        PopupMenuItem(
          value: 'remove',
          child: Row(
            children: [
              Icon(
                Icons.remove_circle_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const Gap(Gaps.m),
              Text(
                'Remove from this list',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ),
        ),
      );
    }

    return items;
  }

  // Handle context menu action with optimistic UI updates

  Future<void> _handleContextMenuAction(
    String action,
    Movie movie,
    KanbanColumnType sourceType,
    String sourceId, {
    String contentType = 'movie',
  }) async {
    // Apply optimistic UI updates first.

    String? targetListId;
    KanbanColumnType? targetType;
    String successMessage = '';

    switch (action) {
      case 'copy_to_watch':
        targetType = KanbanColumnType.toWatch;
        targetListId = 'towatch';
        successMessage = 'Added "${movie.title}" to To Watch';
        _addOptimisticMovie(targetType, targetListId, movie);
        break;
      case 'copy_watched':
        targetType = KanbanColumnType.watched;
        targetListId = 'watched';
        successMessage = 'Added "${movie.title}" to Watched';
        _addOptimisticMovie(targetType, targetListId, movie);
        break;
      case 'remove':
        successMessage = 'Removed "${movie.title}" from list';
        _removeOptimisticMovie(sourceType, sourceId, movie);
        break;
      default:
        if (action.startsWith('copy_custom_')) {
          targetType = KanbanColumnType.customList;
          targetListId = action.substring('copy_custom_'.length);
          successMessage = 'Added "${movie.title}" to custom list';
          _addOptimisticMovie(targetType, targetListId, movie);
        }
    }

    // Add to queue for progress tracking.

    final operationId = _addToQueue(
      successMessage
          .replaceFirst('Added', 'Adding')
          .replaceFirst('Removed', 'Removing'),
    );

    // Perform background sync.

    _syncContextMenuAction(
      action,
      movie,
      sourceType,
      sourceId,
      targetType,
      targetListId,
      successMessage,
      contentType,
      operationId,
    );
  }

  // Background sync for context menu actions.

  Future<void> _syncContextMenuAction(
    String action,
    Movie movie,
    KanbanColumnType sourceType,
    String sourceId,
    KanbanColumnType? targetType,
    String? targetListId,
    String successMessage,
    String contentType,
    int operationId,
  ) async {
    _updateQueueStatus(operationId, OperationStatus.inProgress);
    try {
      // Ensure movie file exists for copy operations (especially from Popular).
      if (action != 'remove') {
        await _ensureMovieFileExists(movie);
      }

      switch (action) {
        case 'copy_to_watch':
          await widget.favoritesService
              .addToWatch(movie, contentType: contentType);
          break;
        case 'copy_watched':
          await widget.favoritesService
              .addToWatched(movie, contentType: contentType);
          break;
        case 'remove':
          await _removeFromCurrentList(movie, sourceType, sourceId);
          break;
        default:
          // Handle custom list copy operations.
          if (action.startsWith('copy_custom_')) {
            final listId = action.substring('copy_custom_'.length);
            await widget.favoritesService.addMovieToCustomList(
              listId,
              movie,
              contentType:
                  movie.contentType == ContentType.tvShow ? 'tv' : 'movie',
            );
          }
      }

      // Clear optimistic state and update queue status.

      if (targetType != null && targetListId != null) {
        _clearOptimisticState(targetType, targetListId, movie.id);
      } else if (action == 'remove') {
        _clearOptimisticState(sourceType, sourceId, movie.id);
      }
      _updateQueueStatus(operationId, OperationStatus.completed);
    } catch (e) {
      // Revert optimistic updates on error.

      if (targetType != null && targetListId != null) {
        _markSyncError(targetType, targetListId, movie.id);
      } else if (action == 'remove') {
        _markSyncError(sourceType, sourceId, movie.id);
      }

      _updateQueueStatus(operationId, OperationStatus.failed);
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
              content: Text('Removed "${movie.title}" from custom list'),
            ),
          );
        }
        break;
      case KanbanColumnType.popular:
        // Can't remove from popular.

        break;
    }
  }

  // Handle drop operation with optimistic UI updates

  Future<void> _handleDrop(
    MovieDragData dragData,
    KanbanColumnType targetType,
    String targetId,
    String targetName,
  ) async {
    debugPrint('   Drag Source: ${dragData.sourceType} (${dragData.sourceId})');
    debugPrint('   Drop Target: $targetType ($targetId)');
    debugPrint('   Movie: ${dragData.movie.title} (ID: ${dragData.movie.id})');
    debugPrint('   Movie ContentType: ${dragData.movie.contentType}');

    // Don't allow dropping on same column.

    if (dragData.sourceType == targetType && dragData.sourceId == targetId) {
      return;
    }

    // Determine if this is a copy or move operation.

    final isCopyOperation = dragData.sourceType == KanbanColumnType.popular;

    // Apply optimistic UI updates immediately.

    _addOptimisticMovie(targetType, targetId, dragData.movie);
    if (!isCopyOperation) {
      _removeOptimisticMovie(
        dragData.sourceType,
        dragData.sourceId,
        dragData.movie,
      );
    }

    // Add to queue for progress tracking.

    final operationDescription = isCopyOperation
        ? 'Copy ${dragData.movie.title} to $targetName'
        : 'Move ${dragData.movie.title} to $targetName';
    final operationId = _addToQueue(operationDescription);

    // Perform background sync.

    _syncDropOperation(
      dragData,
      targetType,
      targetId,
      targetName,
      isCopyOperation,
      operationId,
    );
  }

  // Background sync operation.

  Future<void> _syncDropOperation(
    MovieDragData dragData,
    KanbanColumnType targetType,
    String targetId,
    String targetName,
    bool isCopyOperation,
    int operationId,
  ) async {
    debugPrint('   Movie: ${dragData.movie.title} (ID: ${dragData.movie.id})');
    debugPrint('   ContentType: ${dragData.movie.contentType}');
    debugPrint('   Target: $targetType ($targetName)');
    debugPrint('   Copy operation: $isCopyOperation');

    _updateQueueStatus(operationId, OperationStatus.inProgress);
    try {
      // Ensure movie file exists before adding to user lists.
      await _ensureMovieFileExists(dragData.movie);

      // Add to target list.
      switch (targetType) {
        case KanbanColumnType.toWatch:
          final contentTypeString =
              dragData.movie.contentType == ContentType.tvShow ? 'tv' : 'movie';
          debugPrint(
            '🎬 [KanbanDrag] Adding to ToWatch with contentType string: $contentTypeString',
          );
          await widget.favoritesService
              .addToWatch(dragData.movie, contentType: contentTypeString);
          break;
        case KanbanColumnType.watched:
          final contentTypeString =
              dragData.movie.contentType == ContentType.tvShow ? 'tv' : 'movie';
          debugPrint(
            '🎬 [KanbanDrag] Adding to Watched with contentType string: $contentTypeString',
          );
          await widget.favoritesService
              .addToWatched(dragData.movie, contentType: contentTypeString);
          break;
        case KanbanColumnType.customList:
          final contentTypeString =
              dragData.movie.contentType == ContentType.tvShow ? 'tv' : 'movie';
          debugPrint(
            '🎬 [KanbanDrag] Adding to custom list with contentType string: $contentTypeString',
          );
          await widget.favoritesService.addMovieToCustomList(
            targetId,
            dragData.movie,
            contentType: contentTypeString,
          );
          break;
        case KanbanColumnType.popular:
        // Can't drop into popular.
      }

      // Only remove from source if it's a move operation (not from Popular).
      if (!isCopyOperation) {
        await _removeFromCurrentList(
          dragData.movie,
          dragData.sourceType,
          dragData.sourceId,
        );
      }

      // Clear optimistic state and update queue status.

      _clearOptimisticState(targetType, targetId, dragData.movie.id);
      if (!isCopyOperation) {
        _clearOptimisticState(
          dragData.sourceType,
          dragData.sourceId,
          dragData.movie.id,
        );
      }
      _updateQueueStatus(operationId, OperationStatus.completed);
    } catch (e) {
      // Revert optimistic updates on error.

      _markSyncError(targetType, targetId, dragData.movie.id);
      if (!isCopyOperation) {
        _markSyncError(
          dragData.sourceType,
          dragData.sourceId,
          dragData.movie.id,
        );
      }

      _updateQueueStatus(operationId, OperationStatus.failed);
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

        await Future.delayed(TimingConstants.movieCardHoverHideDelay);
      }
    } catch (e) {
      // If checking fails, continue anyway - the favorites service should handle creation.

      debugPrint(
        'Warning: Could not verify movie file existence for ${movie.title}: $e',
      );
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
    // Check if this movie has pending operations.

    final key = _getOperationKey(columnType, columnId);
    final hasPendingOp =
        (_pendingOperations[key]?.contains(movie.id) ?? false) ||
            (_pendingOperations[key]?.contains(-movie.id) ?? false);
    final hasError = _syncErrors.contains('${movie.id}_$key');

    final movieCard = Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Stack(
        children: [
          MovieCard.poster(
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
          // Show sync status indicator.

          if (hasPendingOp || hasError)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                  color: hasError
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: hasError
                    ? Icon(
                        Icons.error,
                        size: 12,
                        color: Theme.of(context).colorScheme.onError,
                      )
                    : SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
              ),
            ),
        ],
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
              opacity: UIConstants.highOpacity,
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
                  padding: const EdgeInsets.all(Dimensions.s),
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
        margin: const EdgeInsets.symmetric(
          horizontal: Dimensions.s,
          vertical: Dimensions.s,
        ),
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
    bool isLoading = false,
  }) {
    // Apply optimistic updates.

    final moviesWithOptimistic = _getMoviesWithOptimisticUpdates(
      movies,
      columnType,
      categoryId,
    );

    // Apply sorting based on column's sort criteria.

    final sortCriteria =
        _columnSortCriteria[categoryId] ?? MovieSortCriteria.nameAsc;
    final sortedMovies =
        sortMovies(List<Movie>.from(moviesWithOptimistic), sortCriteria);

    final displayMovies = sortedMovies.take(_maxItemsPerColumn).toList();
    final hasMore = sortedMovies.length > _maxItemsPerColumn;
    final canAcceptDrop = columnType != KanbanColumnType.popular;
    final hasPendingOps =
        _pendingOperations[_getOperationKey(columnType, categoryId)]
                ?.isNotEmpty ??
            false;

    Widget columnContent = Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: Dimensions.m),
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
            padding: const EdgeInsets.all(Dimensions.xl),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First row: Title + Count Badge + Sort button (always present).

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Count badge.

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${sortedMovies.length}${hasMore ? '+' : ''}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                          if (hasPendingOps) ...[
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 8,
                              height: 8,
                              child: CircularProgressIndicator(
                                strokeWidth: 1,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sort button.

                    MarkdownTooltip(
                      message:
                          '**Sort** movies in this column\n\nClick to choose from:\n• Name (A-Z / Z-A)\n• Rating (High-Low / Low-High)\n• Date (Newest / Oldest)',
                      child: PopupMenuButton<MovieSortCriteria>(
                        tooltip: 'Sort',
                        icon: Icon(
                          Icons.sort,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        onSelected: (criteria) =>
                            _onSortChanged(categoryId, criteria),
                        itemBuilder: (context) {
                          final currentSort = _columnSortCriteria[categoryId] ??
                              MovieSortCriteria.nameAsc;
                          return [
                            PopupMenuItem(
                              value: MovieSortCriteria.nameAsc,
                              child: Row(
                                children: [
                                  Icon(
                                    currentSort == MovieSortCriteria.nameAsc
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Name (A-Z)'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: MovieSortCriteria.nameDesc,
                              child: Row(
                                children: [
                                  Icon(
                                    currentSort == MovieSortCriteria.nameDesc
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Name (Z-A)'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: MovieSortCriteria.ratingDesc,
                              child: Row(
                                children: [
                                  Icon(
                                    currentSort == MovieSortCriteria.ratingDesc
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Rating (High to Low)'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: MovieSortCriteria.ratingAsc,
                              child: Row(
                                children: [
                                  Icon(
                                    currentSort == MovieSortCriteria.ratingAsc
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Rating (Low to High)'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: MovieSortCriteria.dateDesc,
                              child: Row(
                                children: [
                                  Icon(
                                    currentSort == MovieSortCriteria.dateDesc
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Date (Newest First)'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: MovieSortCriteria.dateAsc,
                              child: Row(
                                children: [
                                  Icon(
                                    currentSort == MovieSortCriteria.dateAsc
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Date (Oldest First)'),
                                ],
                              ),
                            ),
                          ];
                        },
                      ),
                    ),
                  ],
                ),
                // Second row: View More button (only when needed).

                if (hasMore) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Spacer(),
                      TextButton(
                        onPressed: () => _navigateToMovieCategory(
                          title,
                          sortedMovies,
                          fromCache,
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'View More',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 11,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Movie items.

          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const Gap(8),
                        Text(
                          'Loading $title...',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                        ),
                      ],
                    ),
                  )
                : displayMovies.isEmpty
                    ? Center(
                        child: Text(
                          'No movies',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
          duration: TimingConstants.containerAnimationDuration,
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
    String categoryName,
    List<Movie> movies,
    bool fromCache,
  ) {
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
    // Apply optimistic updates to movie IDs.

    final movieIdsWithOptimistic = _getMovieIdsWithOptimisticUpdates(
      customList.movieIds,
      KanbanColumnType.customList,
      customList.id,
    );
    final hasPendingOps = _pendingOperations[
                _getOperationKey(KanbanColumnType.customList, customList.id)]
            ?.isNotEmpty ??
        false;

    Widget columnContent = Container(
      width: 220,
      margin: const EdgeInsets.symmetric(horizontal: Dimensions.m),
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
            padding: const EdgeInsets.all(Dimensions.xl),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First row: Title + Count Badge + Sort button (always present).

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _navigateToCustomListDetail(customList),
                        child: Text(
                          customList.name,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Count badge.

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${movieIdsWithOptimistic.length}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                          if (hasPendingOps) ...[
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 8,
                              height: 8,
                              child: CircularProgressIndicator(
                                strokeWidth: 1,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sort button for custom list.

                    MarkdownTooltip(
                      message:
                          '**Sort** movies in this list\n\nClick to choose from:\n• Name (A-Z / Z-A)\n• Rating (High-Low / Low-High)\n• Date (Newest / Oldest)',
                      child: PopupMenuButton<MovieSortCriteria>(
                        tooltip: 'Sort',
                        icon: Icon(
                          Icons.sort,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        onSelected: (criteria) =>
                            _onSortChanged(customList.id, criteria),
                        itemBuilder: (context) {
                          final currentSort =
                              _columnSortCriteria[customList.id] ??
                                  MovieSortCriteria.nameAsc;
                          return [
                            PopupMenuItem(
                              value: MovieSortCriteria.nameAsc,
                              child: Row(
                                children: [
                                  Icon(
                                    currentSort == MovieSortCriteria.nameAsc
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Name (A-Z)'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: MovieSortCriteria.nameDesc,
                              child: Row(
                                children: [
                                  Icon(
                                    currentSort == MovieSortCriteria.nameDesc
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Name (Z-A)'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: MovieSortCriteria.ratingDesc,
                              child: Row(
                                children: [
                                  Icon(
                                    currentSort == MovieSortCriteria.ratingDesc
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Rating (High to Low)'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: MovieSortCriteria.ratingAsc,
                              child: Row(
                                children: [
                                  Icon(
                                    currentSort == MovieSortCriteria.ratingAsc
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Rating (Low to High)'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: MovieSortCriteria.dateDesc,
                              child: Row(
                                children: [
                                  Icon(
                                    currentSort == MovieSortCriteria.dateDesc
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Date (Newest First)'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: MovieSortCriteria.dateAsc,
                              child: Row(
                                children: [
                                  Icon(
                                    currentSort == MovieSortCriteria.dateAsc
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Date (Oldest First)'),
                                ],
                              ),
                            ),
                          ];
                        },
                      ),
                    ),
                  ],
                ),
                // Second row: View More button (only when needed).

                if (movieIdsWithOptimistic.length > _maxItemsPerColumn) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Spacer(),
                      TextButton(
                        onPressed: () =>
                            _navigateToCustomListDetail(customList),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'View More',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 11,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Movie items.

          Expanded(
            child: FutureBuilder<List<Movie>>(
              future:
                  widget.favoritesService.getMoviesInCustomList(customList.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Dimensions.xl),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Dimensions.xl),
                      child: Text(
                        'Error loading movies',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                    ),
                  );
                }

                final podMovies = snapshot.data ?? [];

                if (podMovies.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Dimensions.xl),
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
                  );
                }

                // Apply optimistic updates to the POD movies
                final movieIdsFromPod = podMovies.map((m) => m.id).toList();
                final optimisticMovieIds = _getMovieIdsWithOptimisticUpdates(
                  movieIdsFromPod,
                  KanbanColumnType.customList,
                  customList.id,
                );

                return _CustomListMoviesWidget(
                  movieIds: optimisticMovieIds,
                  customList: customList,
                  favoritesService: widget.favoritesService,
                  sortCriteria: _columnSortCriteria[customList.id] ??
                      MovieSortCriteria.nameAsc,
                  maxItems: _maxItemsPerColumn,
                  optimisticMovies: _optimisticMovies,
                  buildMovieItem: (movie, index) => _buildMovieItem(
                    movie,
                    customList.id,
                    fromCache: false,
                    columnType: KanbanColumnType.customList,
                    columnId: customList.id,
                    columnName: customList.name,
                  ),
                );
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
          duration: TimingConstants.containerAnimationDuration,
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

  Widget _buildCustomListLoadingColumn() {
    return Container(
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
                    'Custom Lists',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Count badge placeholder
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),

          // Loading content area - matching the exact style of To Watch/Watched
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Loading Custom Lists...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final pendingOps = _operationQueue
        .where(
          (op) =>
              op.status == OperationStatus.pending ||
              op.status == OperationStatus.inProgress,
        )
        .length;
    final completedOps = _operationQueue
        .where((op) => op.status == OperationStatus.completed)
        .length;
    final failedOps = _operationQueue
        .where((op) => op.status == OperationStatus.failed)
        .length;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.l,
        vertical: Dimensions.m,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pendingOps > 0) ...[
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                'Syncing',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pendingOps > 0) ...[
                _buildStatusChip(
                  '$pendingOps pending',
                  Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
              ],
              if (completedOps > 0) ...[
                _buildStatusChip(
                  '$completedOps done',
                  Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 4),
              ],
              if (failedOps > 0) ...[
                _buildStatusChip(
                  '$failedOps failed',
                  Theme.of(context).colorScheme.error,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.ms,
        vertical: Dimensions.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Builds a smart error widget that provides user-friendly error messages and actions.

  Widget _buildSmartErrorWidget(Object error, StackTrace stackTrace) {
    return FutureBuilder<UserFriendlyError>(
      future: _buildUserFriendlyError(error, stackTrace),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While processing, show a simple loading indicator.

          return const Center(
            child: Padding(
              padding: EdgeInsets.all(Dimensions.xl),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final userFriendlyError = snapshot.data;
        if (userFriendlyError != null) {
          return ErrorDisplayWidget.fromUserFriendlyError(
            error: userFriendlyError,
          );
        }

        // Fallback to basic error display if something went wrong.

        return ErrorDisplayWidget(
          message: 'Error loading movies: $error',
          onRetry: () => ref.invalidate(popularMoviesWithCacheInfoProvider),
        );
      },
    );
  }

  // Builds a user-friendly error with smart detection.

  Future<UserFriendlyError> _buildUserFriendlyError(
    Object error,
    StackTrace stackTrace,
  ) async {
    // Create services for smart detection.

    final apiKeyService = ref.read(apiKeyServiceProvider);
    final apiKeyValidationService = ApiKeyValidationService(apiKeyService);
    final networkConnectivityService = NetworkConnectivityService.forTMDB();

    // Create error context with available actions and services.

    final errorContext = ErrorContext(
      onRetry: () {
        // Refresh the provider to retry loading.

        ref.invalidate(popularMoviesWithCacheInfoProvider);
      },
      onConfigureApiKey: null,
      apiKeyValidationService: apiKeyValidationService,
      networkConnectivityService: networkConnectivityService,
    );

    try {
      // Use smart error mapping.

      return await ErrorMapperService.mapErrorSmart(
        error,
        stackTrace,
        context: errorContext,
      );
    } catch (e) {
      // If smart mapping fails, fall back to traditional mapping.

      return ErrorMapperService.mapError(
        error,
        stackTrace,
        context: errorContext,
      );
    }
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

                        return Stack(
                          children: [
                            Scrollbar(
                              controller: _horizontalScrollController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              thickness: 8,
                              radius: const Radius.circular(4),
                              child: SingleChildScrollView(
                                controller: _horizontalScrollController,
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
                                      isLoading: popularMovies.isEmpty &&
                                          !popularCacheResult.fromCache,
                                    ),

                                    // To Watch Column.

                                    _buildKanbanColumn(
                                      title: 'To Watch',
                                      movies: toWatchMovies,
                                      categoryId: 'towatch',
                                      fromCache: false,
                                      columnType: KanbanColumnType.toWatch,
                                      isLoading:
                                          toWatchSnapshot.connectionState ==
                                                  ConnectionState.waiting &&
                                              !toWatchSnapshot.hasData,
                                    ),

                                    // Watched Column.

                                    _buildKanbanColumn(
                                      title: 'Watched',
                                      movies: watchedMovies,
                                      categoryId: 'watched',
                                      fromCache: false,
                                      columnType: KanbanColumnType.watched,
                                      isLoading:
                                          watchedSnapshot.connectionState ==
                                                  ConnectionState.waiting &&
                                              !watchedSnapshot.hasData,
                                    ),

                                    // Custom List Columns.
                                    ...customLists.map(
                                      (customList) =>
                                          _buildCustomListColumn(customList),
                                    ),

                                    // Show loading placeholder for custom lists if they're still loading
                                    if (customListsSnapshot.connectionState ==
                                            ConnectionState.waiting &&
                                        customLists.isEmpty)
                                      _buildCustomListLoadingColumn(),
                                  ],
                                ),
                              ),
                            ),
                            // Progress indicator overlay.

                            if (_operationQueue.isNotEmpty)
                              Positioned(
                                bottom: 20,
                                right: 20,
                                child: _buildProgressIndicator(),
                              ),
                          ],
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
          error: (error, stack) => _buildSmartErrorWidget(error, stack),
        );
      },
    );
  }
}

// Helper widget to load and sort movies in a custom list.

class _CustomListMoviesWidget extends ConsumerStatefulWidget {
  final List<int> movieIds;
  final CustomList customList;
  final FavoritesService favoritesService;
  final MovieSortCriteria sortCriteria;
  final int maxItems;
  final Widget Function(Movie movie, int index) buildMovieItem;
  final Map<String, Movie> optimisticMovies;

  const _CustomListMoviesWidget({
    required this.movieIds,
    required this.customList,
    required this.favoritesService,
    required this.sortCriteria,
    required this.maxItems,
    required this.buildMovieItem,
    required this.optimisticMovies,
  });

  @override
  ConsumerState<_CustomListMoviesWidget> createState() =>
      _CustomListMoviesWidgetState();
}

class _CustomListMoviesWidgetState
    extends ConsumerState<_CustomListMoviesWidget> {
  final Map<int, Movie> _moviesMap = {};
  final Set<int> _loadingMovieIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  @override
  void didUpdateWidget(_CustomListMoviesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if we need to load new movies (only load missing ones, don't reload all)
    final newMovieIds = widget.movieIds.where((id) =>
        !oldWidget.movieIds.contains(id) &&
        !_moviesMap.containsKey(id) &&
        !widget.optimisticMovies.containsKey('${id}_customList_${widget.customList.id}')).toList();

    // If sort criteria changed, reload all
    if (oldWidget.sortCriteria != widget.sortCriteria) {
      _loadMovies();
    }
    // If we have new movie IDs from optimistic updates, load only those
    else if (newMovieIds.isNotEmpty) {
      _loadNewMovies(newMovieIds);
    }
    // If movies were removed or optimistic movies changed, just update the UI
    else if (oldWidget.movieIds.length != widget.movieIds.length ||
             oldWidget.optimisticMovies != widget.optimisticMovies) {
      setState(() {}); // Trigger rebuild with current data
    }
  }

  Future<Movie> _getContentAsMovieWithType(
    int contentId,
    String contentType,
  ) async {
    final cachedMovieService = ref.read(cachedMovieServiceProvider);
    final contentService = ref.read(contentServiceProvider);

    if (contentType == 'tv') {
      final tvShowContent = await contentService.getTVDetails(contentId);
      return Movie.fromContentItem(tvShowContent);
    } else {
      return await cachedMovieService.getMovieDetails(contentId);
    }
  }

  /// Load only specific new movies (for optimistic updates)
  Future<void> _loadNewMovies(List<int> movieIds) async {
    for (final movieId in movieIds) {
      if (_moviesMap.containsKey(movieId) || _loadingMovieIds.contains(movieId)) {
        continue;
      }

      _loadingMovieIds.add(movieId);
      try {
        final contentType = widget.customList.getContentTypeAt(
          widget.movieIds.indexOf(movieId),
        );
        final movie = await _getContentAsMovieWithType(movieId, contentType);
        if (mounted) {
          setState(() {
            _moviesMap[movieId] = movie;
            _loadingMovieIds.remove(movieId);
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _loadingMovieIds.remove(movieId);
          });
        }
      }
    }
  }

  Future<void> _loadMovies() async {
    setState(() {
      _isLoading = true;
    });

    // Try POD-first approach if POD storage is available
    if (widget.favoritesService is FavoritesServiceAdapter &&
        (widget.favoritesService as FavoritesServiceAdapter)
            .isPodStorageEnabled) {
      try {
        final podMovies = await widget.favoritesService
            .getMoviesInCustomList(widget.customList.id);

        if (podMovies.isNotEmpty) {
          if (mounted) {
            setState(() {
              _moviesMap.clear();
              for (final movie in podMovies) {
                _moviesMap[movie.id] = movie;
              }
              _isLoading = false;
            });
          }
          return;
        }
      } catch (e) {
        // Continue to fallback to API loading
      }
    }

    // Fallback to API loading (original method)
    await _loadMoviesFromAPI();
  }

  // Original API loading method
  Future<void> _loadMoviesFromAPI() async {
    // Load all movies needed for sorting.
    final moviesToLoad = widget.movieIds.take(widget.maxItems * 2).toList();

    for (int i = 0; i < moviesToLoad.length; i++) {
      final movieId = moviesToLoad[i];

      if (_moviesMap.containsKey(movieId) ||
          _loadingMovieIds.contains(movieId)) {
        continue;
      }

      _loadingMovieIds.add(movieId);

      try {
        final contentType = widget.customList.getContentTypeAt(
          widget.movieIds.indexOf(movieId),
        );
        final movie = await _getContentAsMovieWithType(movieId, contentType);

        if (mounted) {
          setState(() {
            _moviesMap[movieId] = movie;
            _loadingMovieIds.remove(movieId);
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _loadingMovieIds.remove(movieId);
          });
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Movie> _getSortedMovies() {
    // Get all loaded movies.

    final loadedMovies = <Movie>[];
    for (final movieId in widget.movieIds) {
      Movie? movie = _moviesMap[movieId];

      // If not found in loaded movies, check optimistic movies
      if (movie == null) {
        final optimisticKey = '${movieId}_customList_${widget.customList.id}';
        movie = widget.optimisticMovies[optimisticKey];
      }

      if (movie != null) {
        loadedMovies.add(movie);
      }
    }

    // Apply sorting.

    return sortMovies(loadedMovies, widget.sortCriteria);
  }

  @override
  Widget build(BuildContext context) {
    final sortedMovies = _getSortedMovies();

    // Only show loading if we have no movies at all (including optimistic ones)
    if (_isLoading && _moviesMap.isEmpty && sortedMovies.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(Dimensions.xl),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final displayMovies = sortedMovies.take(widget.maxItems).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: displayMovies.length,
      itemBuilder: (context, index) {
        return widget.buildMovieItem(displayMovies[index], index);
      },
    );
  }
}
