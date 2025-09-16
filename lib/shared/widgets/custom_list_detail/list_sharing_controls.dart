/// List Sharing Controls Component - POD-based Sharing and Batch Sharing UI
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solidpod/solidpod.dart';

import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/core/services/favorites/favorites_service_adapter.dart';
import 'package:moviestar/utils/turtle_serializer.dart';
import 'package:moviestar/widgets/moviestar_batch_sharing_ui.dart';

class ListSharingControls extends ConsumerStatefulWidget {
  final CustomList customList;
  final Map<int, Movie> moviesMap;
  final FavoritesServiceAdapter favoritesService;
  final Function(String message) onShowError;
  final Widget parentWidget;

  const ListSharingControls({
    super.key,
    required this.customList,
    required this.moviesMap,
    required this.favoritesService,
    required this.onShowError,
    required this.parentWidget,
  });

  @override
  ConsumerState<ListSharingControls> createState() => _ListSharingControlsState();
}

class _ListSharingControlsState extends ConsumerState<ListSharingControls> {
  bool _isSharing = false;

  void _showSharingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Preparing to share...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'This may take a few seconds',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareCustomList() async {
    if (widget.customList.movieIds.isEmpty) {
      widget.onShowError('No movies to share');
      return;
    }

    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    _showSharingDialog();

    try {
      // Get all loaded movies from the current list
      final moviesToShare = <Movie>[];
      for (final movieId in widget.customList.movieIds) {
        final movie = widget.moviesMap[movieId];
        if (movie != null) {
          moviesToShare.add(movie);

          // Create movie file if it doesn't exist
          await _createMovieFileIfNotExists(movie);
        }
      }

      if (moviesToShare.isEmpty) {
        widget.onShowError('No loaded movies to share');
        return;
      }

      // Generate a simple list ID from the custom list name
      final listId = widget.customList.id;

      final theme = Theme.of(context);

      // Dismiss loading dialog before navigating
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Navigate to the batch sharing UI
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => MovieStarBatchSharingUi(
              listId: listId,
              listName: widget.customList.name,
              movies: moviesToShare,
              backgroundColor: theme.scaffoldBackgroundColor,
              onSharingComplete: () {
                // Handle completion callback if needed
              },
              child: widget.parentWidget,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        widget.onShowError('Error sharing list: $e');
      }
    } finally {
      setState(() {
        _isSharing = false;
      });

      // Dismiss loading dialog if still showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _createMovieFileIfNotExists(Movie movie) async {
    try {
      final movieFileName = 'movies/Movie-${movie.id}.ttl';

      // Check if the file already exists
      try {
        if (!mounted) return;
        final existingContent = await readPod(
          movieFileName,
          context,
          widget.parentWidget,
        );
        if (existingContent.isNotEmpty) {
          return;
        }
      } catch (e) {
        // File doesn't exist, we'll create it
      }

      // Get current rating and comments from favorites service
      final currentRating = await widget.favoritesService.getPersonalRating(movie);
      final currentComments = await widget.favoritesService.getMovieComments(movie);

      // Create the movie TTL content with any existing user data
      final ttlContent = TurtleSerializer.movieWithUserDataToTurtleOntology(
        movie,
        currentRating,
        currentComments,
      );

      // Write the movie file to POD
      if (!mounted) return;
      final result = await writePod(
        movieFileName,
        ttlContent,
        context,
        widget.parentWidget,
        encrypted: false,
      );

      if (result != SolidFunctionCallStatus.success) {
        throw Exception('Failed to write movie file to POD');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canShare = widget.customList.movieIds.isNotEmpty &&
                    widget.favoritesService.isPodStorageEnabled;

    return IconButton(
      icon: _isSharing
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          )
        : const Icon(Icons.share),
      onPressed: canShare && !_isSharing ? _shareCustomList : null,
      tooltip: canShare
        ? 'Share list via POD'
        : widget.customList.movieIds.isEmpty
          ? 'Add movies to share'
          : 'POD storage required',
    );
  }
}