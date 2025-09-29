/// Kanban Card Widget - Movie Card Within Kanban with Drag Support.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/constants/ui_constants.dart';
import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/widgets/movie_card.dart';

import 'board_controller.dart';

/// Kanban card widget with drag functionality and status indicators.

class KanbanCardWidget extends StatelessWidget {
  final Movie movie;
  final String category;
  final bool fromCache;
  final KanbanColumnType columnType;
  final String columnId;
  final String columnName;
  final FavoritesService favoritesService;
  final KanbanBoardController controller;
  final Function(Offset, Movie, KanbanColumnType, String, String)
      onShowContextMenu;

  const KanbanCardWidget({
    super.key,
    required this.movie,
    required this.category,
    required this.fromCache,
    required this.columnType,
    required this.columnId,
    required this.columnName,
    required this.favoritesService,
    required this.controller,
    required this.onShowContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    // Check if this movie has pending operations.

    final hasPendingOp =
        controller.isPendingOperation(columnType, columnId, movie.id);
    final hasError = controller.hasSyncError(columnType, columnId, movie.id);

    final movieCard = Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Stack(
        children: [
          MovieCard.poster(
            movie: movie,
            fromCache: fromCache,
            width: 100,
            height: 150,
            favoritesService: favoritesService,
            onTap: () => _navigateToMovieDetails(context),
          ),
          // Show sync status indicator.

          if (hasPendingOp || hasError)
            Positioned(
              bottom: 4,
              right: 4,
              child: _buildStatusIndicator(context, hasError),
            ),
        ],
      ),
    );

    // Wrap in context menu for copy operations.

    final contextMenuCard = GestureDetector(
      onSecondaryTapUp: (details) => onShowContextMenu(
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
      feedback: _buildDragFeedback(context),
      childWhenDragging: _buildDragPlaceholder(context),
      child: DragTarget<MovieDragData>(
        onWillAcceptWithDetails: (details) => false, // Cards don't accept drops
        builder: (context, candidateData, rejectedData) => contextMenuCard,
      ),
    );
  }

  void _navigateToMovieDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailsScreen(
          movie: movie,
          favoritesService: favoritesService,
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context, bool hasError) {
    return Container(
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
    );
  }

  Widget _buildDragFeedback(BuildContext context) {
    return Material(
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
                favoritesService: favoritesService,
                onTap: () {}, // Disabled during drag
              ),
            ),
          ),
          // Show copy indicator for Recommended movies.

          if (columnType == KanbanColumnType.recommended)
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
    );
  }

  Widget _buildDragPlaceholder(BuildContext context) {
    return Container(
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
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: 40,
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
