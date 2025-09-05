/// Reusable movie card widget with cache status indicators.
///
// Time-stamp: <Friday 2025-08-22 05:51:08 +1000 Graham Williams>
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
import 'package:gap/gap.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/constants/timing_constants.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/favorites_service.dart';
import 'package:moviestar/widgets/quick_actions_dialog.dart';

/// Different display modes for movie cards.

enum MovieCardStyle {
  /// Poster-style card (used in horizontal lists).
  poster,

  /// List item style card (used in vertical lists).
  listItem,
}

/// A reusable movie card widget with cache status indicators.

class MovieCard extends StatefulWidget {
  /// The movie to display.

  final Movie movie;

  /// Whether this movie data came from cache.

  final bool? fromCache;

  /// Age of cached data (if applicable).

  final Duration? cacheAge;

  /// Whether the app is in offline mode.

  final bool? cacheOnlyMode;

  /// Callback when the card is tapped.

  final VoidCallback? onTap;

  /// Style of the movie card.

  final MovieCardStyle style;

  /// Custom width for poster style.

  final double? width;

  /// Custom height for poster style.

  final double? height;

  /// Additional trailing widget for list items.

  final Widget? trailing;

  /// Custom subtitle widget for list items (overrides default rating).

  final Widget? customSubtitle;

  /// The favorites service for quick actions (optional).

  final FavoritesService? favoritesService;

  /// The parent widget for navigation when sharing (optional).

  final Widget? parentWidget;

  /// Creates a movie card widget.

  const MovieCard({
    super.key,
    required this.movie,
    this.fromCache,
    this.cacheAge,
    this.cacheOnlyMode,
    this.onTap,
    this.style = MovieCardStyle.poster,
    this.width,
    this.height,
    this.trailing,
    this.customSubtitle,
    this.favoritesService,
    this.parentWidget,
  });

  /// Creates a poster-style movie card.

  // ignore: avoid-unnecessary-nullable-parameters
  const MovieCard.poster({
    super.key,
    required this.movie,
    this.fromCache,
    this.cacheAge,
    this.cacheOnlyMode,
    this.onTap,
    this.width = 130,
    this.height,
    this.favoritesService,
    this.parentWidget,
  })  : style = MovieCardStyle.poster,
        trailing = null,
        customSubtitle = null;

  /// Creates a list item-style movie card.

  // ignore: avoid-unnecessary-nullable-parameters
  const MovieCard.listItem({
    super.key,
    required this.movie,
    this.fromCache,
    this.cacheAge,
    this.cacheOnlyMode,
    this.onTap,
    this.trailing,
    this.customSubtitle,
    this.favoritesService,
    this.parentWidget,
  })  : style = MovieCardStyle.listItem,
        width = 50,
        height = 75;

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  // Overlay entry for the quick actions dialog.

  OverlayEntry? _overlayEntry;

  // Validates if an image URL is valid and not empty.

  bool _isValidImageUrl(String url) {
    if (url.trim().isEmpty) {
      return false;
    }

    // Basic URL validation - must start with http:// or https://.

    return url.trim().startsWith('http://') ||
        url.trim().startsWith('https://');
  }

  // Whether the quick actions dialog is currently shown.

  bool _isDialogShown = false;

  // Timer for delayed hiding of the dialog.

  Timer? _hideTimer;

  // Timer for delayed showing of the dialog.

  Timer? _showTimer;

  @override
  void dispose() {
    _removeOverlay();
    _hideTimer?.cancel();
    _showTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.style) {
      case MovieCardStyle.poster:
        return MouseRegion(
          onEnter: _onCardMouseEnter,
          onExit: _onCardMouseExit,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: !_isValidImageUrl(widget.movie.posterUrl)
                      ? Container(
                          width: widget.width,
                          height: widget.height,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.movie,
                            size: 48,
                            color: Colors.grey,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: widget.movie.posterUrl.trim(),
                          width: widget.width,
                          height: widget.height,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                ),
                _buildCacheIndicator(context),
                if (widget.cacheOnlyMode == true)
                  _buildOfflineModeIndicator(context),
                if (widget.movie.contentType != null)
                  _buildContentTypeIndicator(context),
              ],
            ),
          ),
        );
      case MovieCardStyle.listItem:
        return MouseRegion(
          onEnter: _onCardMouseEnter,
          onExit: _onCardMouseExit,
          child: ListTile(
            leading: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: !_isValidImageUrl(widget.movie.posterUrl)
                      ? Container(
                          width: widget.width,
                          height: widget.height,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.movie,
                            size: 48,
                            color: Colors.grey,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: widget.movie.posterUrl.trim(),
                          width: widget.width,
                          height: widget.height,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                ),
                _buildCacheIndicator(context),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.movie.title,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                if (widget.cacheOnlyMode == true)
                  _buildOfflineModeIcon(context),
              ],
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: widget.customSubtitle ??
                      Row(
                        children: [
                          Text(
                            '⭐ ${widget.movie.voteAverage.toStringAsFixed(1)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (widget.movie.contentType != null) ...[
                            const Text(' • '),
                            Text(
                              widget.movie.contentType == ContentType.movie
                                  ? '🎬 Movie'
                                  : '📺 TV Show',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                            ),
                          ],
                        ],
                      ),
                ),
                if (widget.fromCache == true && widget.cacheAge != null)
                  _buildCacheAgeInfo(context),
              ],
            ),
            trailing: widget.trailing,
            onTap: widget.onTap,
          ),
        );
    }
  }

  // Shows the quick actions dialog if favoritesService is available.

  void _showQuickActions(BuildContext context) {
    if (widget.favoritesService == null || _isDialogShown) return;

    // Cancel any pending hide timer.

    _hideTimer?.cancel();

    _isDialogShown = true;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx + size.width + 8,
        top: position.dy,
        child: QuickActionsDialog(
          movie: widget.movie,
          favoritesService: widget.favoritesService!,
          parentWidget: widget.parentWidget,
          onClose: _hideQuickActions,
          onMouseEnter: _onDialogMouseEnter,
          onMouseExit: _onDialogMouseExit,
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  // Called when mouse enters the card area.

  void _onCardMouseEnter(_) {
    _hideTimer?.cancel();

    // Start a timer to show the dialog after a delay.
    // This prevents popups from appearing immediately when quickly moving the mouse.

    _showTimer?.cancel();
    _showTimer = Timer(TimingConstants.movieCardHoverShowDelay, () {
      _showQuickActions(context);
    });
  }

  // Called when mouse exits the card area.

  void _onCardMouseExit(_) {
    // Cancel the show timer if mouse exits before delay completes.

    _showTimer?.cancel();

    if (!_isDialogShown) return;

    // Start a timer to hide the dialog after a short delay.
    // This gives the user time to move to the dialog.

    _hideTimer?.cancel();
    _hideTimer = Timer(TimingConstants.movieCardHoverHideDelay, () {
      _hideQuickActions();
    });
  }

  // Called when mouse enters the dialog area.

  void _onDialogMouseEnter() {
    // Cancel both timers since mouse is over the dialog.

    _showTimer?.cancel();
    _hideTimer?.cancel();
  }

  // Called when mouse exits the dialog area.

  void _onDialogMouseExit() {
    // Start a timer to hide the dialog.

    _hideTimer?.cancel();
    _hideTimer = Timer(TimingConstants.movieCardHoverHideDelay, () {
      _hideQuickActions();
    });
  }

  // Hides the quick actions dialog.

  void _hideQuickActions() {
    if (!_isDialogShown) return;

    _hideTimer?.cancel();
    _removeOverlay();
    _isDialogShown = false;
  }

  // Removes the overlay entry.

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Builds cache status indicator overlay.

  Widget _buildCacheIndicator(BuildContext context) {
    if (widget.fromCache == null) return const SizedBox.shrink();

    return Positioned(
      top: 4,
      right: 4,
      child: Container(
        padding: const EdgeInsets.all(Dimensions.xs),
        decoration: BoxDecoration(
          color: widget.fromCache!
              ? Colors.green.withValues(alpha: 0.8)
              : Colors.blue.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          widget.fromCache! ? Icons.offline_bolt : Icons.wifi,
          size: 12,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Builds offline mode indicator for poster cards.

  Widget _buildOfflineModeIndicator(BuildContext context) {
    return Positioned(
      top: 4,
      left: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.s,
          vertical: Dimensions.xs,
        ),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.offline_pin, size: 10, color: Colors.white),
            Gap(Gaps.xs),
            Text(
              'OFFLINE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds content type indicator for poster style.

  Widget _buildContentTypeIndicator(BuildContext context) {
    if (widget.movie.contentType == null) return const SizedBox.shrink();

    final isMovie = widget.movie.contentType == ContentType.movie;
    final label = isMovie ? 'Movie' : 'TV Show';
    final icon = isMovie ? '🎬' : '📺';

    return Positioned(
      bottom: 4,
      left: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.ms,
          vertical: Dimensions.xs,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 10)),
            const Gap(Gaps.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds offline mode icon for list items.

  Widget _buildOfflineModeIcon(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.xs),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.offline_pin, size: 12, color: Colors.white),
    );
  }

  /// Builds cache age information for list items.

  Widget _buildCacheAgeInfo(BuildContext context) {
    final ageText = _formatCacheAge(widget.cacheAge!);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: Dimensions.s, vertical: 1),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        ageText,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10),
      ),
    );
  }

  /// Formats cache age into human-readable string.

  String _formatCacheAge(Duration age) {
    if (age.inDays > 0) {
      return '${age.inDays}d ago';
    } else if (age.inHours > 0) {
      return '${age.inHours}h ago';
    } else if (age.inMinutes > 0) {
      return '${age.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
