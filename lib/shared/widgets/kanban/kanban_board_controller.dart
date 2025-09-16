/// Kanban Board Controller - State Management Logic
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';
import 'package:moviestar/constants/timing_constants.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/utils/movie_sort_util.dart';
import 'package:moviestar/widgets/sort_controls.dart';

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

/// Controller for managing kanban board state, optimistic updates, and operations.
class KanbanBoardController extends ChangeNotifier {
  // Optimistic UI state tracking
  final Map<String, Set<int>> _pendingOperations = {};
  final Map<String, Movie> _optimisticMovies = {};
  final Set<String> _syncErrors = {};

  // Queue-based progress tracking
  final List<OperationQueueItem> _operationQueue = [];
  int _nextOperationId = 0;

  // Sorting state for each column
  final Map<String, MovieSortCriteria> _columnSortCriteria = {
    'popular': MovieSortCriteria.ratingDesc, // Default: by rating
    'towatch': MovieSortCriteria.nameAsc, // Default: alphabetical
    'watched': MovieSortCriteria.dateDesc, // Default: recent first
  };

  // Getters
  List<OperationQueueItem> get operationQueue => List.unmodifiable(_operationQueue);
  Map<String, MovieSortCriteria> get columnSortCriteria => Map.unmodifiable(_columnSortCriteria);

  /// Get the key for tracking operations.
  String _getOperationKey(KanbanColumnType type, String id) {
    return '${type.name}_$id';
  }

  /// Handle sort change for a column.
  void onSortChanged(String columnId, MovieSortCriteria criteria) {
    _columnSortCriteria[columnId] = criteria;
    notifyListeners();
  }

  /// Add operation to queue and return operation ID.
  int addToQueue(String description) {
    final id = _nextOperationId++;
    _operationQueue.add(
      OperationQueueItem(
        id: id,
        description: description,
        status: OperationStatus.pending,
        startTime: DateTime.now(),
      ),
    );
    notifyListeners();
    return id;
  }

  /// Update operation status in queue.
  void updateQueueStatus(int operationId, OperationStatus status) {
    final index = _operationQueue.indexWhere((op) => op.id == operationId);
    if (index != -1) {
      _operationQueue[index] = _operationQueue[index].copyWith(status: status);
      notifyListeners();

      // Auto-remove completed/failed operations after delay
      if (status == OperationStatus.completed || status == OperationStatus.failed) {
        Future.delayed(TimingConstants.autoRemoveDelay, () {
          _operationQueue.removeWhere((op) => op.id == operationId);
          notifyListeners();
        });
      }
    }
  }

  /// Add movie optimistically to UI state.
  void addOptimisticMovie(
    KanbanColumnType targetType,
    String targetId,
    Movie movie,
  ) {
    final key = _getOperationKey(targetType, targetId);
    _pendingOperations[key] ??= <int>{};
    _pendingOperations[key]!.add(movie.id);
    _optimisticMovies['${movie.id}_$key'] = movie;
    notifyListeners();
  }

  /// Remove movie optimistically from UI state.
  void removeOptimisticMovie(
    KanbanColumnType sourceType,
    String sourceId,
    Movie movie,
  ) {
    final key = _getOperationKey(sourceType, sourceId);
    _pendingOperations[key] ??= <int>{};
    _pendingOperations[key]!.add(-movie.id); // Negative ID indicates removal
    notifyListeners();
  }

  /// Clear optimistic state after backend sync.
  void clearOptimisticState(KanbanColumnType type, String id, int movieId) {
    final key = _getOperationKey(type, id);
    _pendingOperations[key]?.remove(movieId);
    _pendingOperations[key]?.remove(-movieId);
    if (_pendingOperations[key]?.isEmpty == true) {
      _pendingOperations.remove(key);
    }
    _optimisticMovies.remove('${movieId}_$key');
    _syncErrors.remove('${movieId}_$key');
    notifyListeners();
  }

  /// Mark sync error and revert optimistic state.
  void markSyncError(KanbanColumnType type, String id, int movieId) {
    final key = _getOperationKey(type, id);
    _syncErrors.add('${movieId}_$key');
    // Remove the optimistic state to revert UI
    clearOptimisticState(type, id, movieId);
  }

  /// Get movies with optimistic updates applied.
  List<Movie> getMoviesWithOptimisticUpdates(
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
        // Addition - add if not already present
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
        }
      } else {
        // Removal - remove from result
        final movieId = -opId;
        result.removeWhere((m) => m.id == movieId);
        debugPrint('⚡ [OptimisticUI] Removed movie ID: $movieId');
      }
    }

    debugPrint('   Result movies: ${result.length}');
    return result;
  }

  /// Check if operation has sync error.
  bool hasSyncError(KanbanColumnType type, String id, int movieId) {
    final key = _getOperationKey(type, id);
    return _syncErrors.contains('${movieId}_$key');
  }

  /// Check if movie is pending operation.
  bool isPendingOperation(KanbanColumnType type, String id, int movieId) {
    final key = _getOperationKey(type, id);
    final pendingOps = _pendingOperations[key];
    return pendingOps?.contains(movieId) == true || pendingOps?.contains(-movieId) == true;
  }

  /// Clear all state (for cleanup).
  void clearAll() {
    _pendingOperations.clear();
    _optimisticMovies.clear();
    _syncErrors.clear();
    _operationQueue.clear();
    _nextOperationId = 0;
    notifyListeners();
  }
}