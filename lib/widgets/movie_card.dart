/// Reusable movie card widget with cache status indicators.
///
// Time-stamp: <Thursday 2025-04-10 11:47:48 +1000 Graham Williams>
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

import 'package:cached_network_image/cached_network_image.dart';

import 'package:moviestar/models/movie.dart';

/// Different display modes for movie cards.

enum MovieCardStyle {
  /// Poster-style card (used in horizontal lists).
  poster,

  /// List item style card (used in vertical lists).
  listItem,
}

/// A reusable movie card widget with cache status indicators.

class MovieCard extends StatelessWidget {
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
  });

  /// Creates a poster-style movie card.

  const MovieCard.poster({
    super.key,
    required this.movie,
    this.fromCache,
    this.cacheAge,
    this.cacheOnlyMode,
    this.onTap,
    this.width = 130,
    this.height,
  })  : style = MovieCardStyle.poster,
        trailing = null,
        customSubtitle = null;

  /// Creates a list item-style movie card.

  const MovieCard.listItem({
    super.key,
    required this.movie,
    this.fromCache,
    this.cacheAge,
    this.cacheOnlyMode,
    this.onTap,
    this.trailing,
    this.customSubtitle,
  })  : style = MovieCardStyle.listItem,
        width = 50,
        height = 75;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case MovieCardStyle.poster:
        return _buildPosterCard(context);
      case MovieCardStyle.listItem:
        return _buildListItemCard(context);
    }
  }

  /// Builds a poster-style card.

  Widget _buildPosterCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CachedNetworkImage(
              imageUrl: movie.posterUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
          _buildCacheIndicator(context),
          if (cacheOnlyMode == true) _buildOfflineModeIndicator(context),
        ],
      ),
    );
  }

  /// Builds a list item-style card.

  Widget _buildListItemCard(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CachedNetworkImage(
              imageUrl: movie.posterUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
          _buildCacheIndicator(context),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              movie.title,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          if (cacheOnlyMode == true) _buildOfflineModeIcon(context),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: customSubtitle ??
                Text(
                  '⭐ ${movie.voteAverage.toStringAsFixed(1)}',
                  style: const TextStyle(color: Colors.grey),
                ),
          ),
          if (fromCache == true && cacheAge != null)
            _buildCacheAgeInfo(context),
        ],
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  /// Builds cache status indicator overlay.

  Widget _buildCacheIndicator(BuildContext context) {
    if (fromCache == null) return const SizedBox.shrink();

    return Positioned(
      top: 4,
      right: 4,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: fromCache!
              ? Colors.green.withValues(alpha: 0.8)
              : Colors.blue.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          fromCache! ? Icons.offline_bolt : Icons.wifi,
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.offline_pin, size: 10, color: Colors.white),
            SizedBox(width: 2),
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

  /// Builds offline mode icon for list items.

  Widget _buildOfflineModeIcon(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.offline_pin, size: 12, color: Colors.white),
    );
  }

  /// Builds cache age information for list items.

  Widget _buildCacheAgeInfo(BuildContext context) {
    final ageText = _formatCacheAge(cacheAge!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        ageText,
        style: const TextStyle(fontSize: 10, color: Colors.grey),
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
