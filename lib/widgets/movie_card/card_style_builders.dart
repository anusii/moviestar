/// Style builders for different movie card layouts.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/utils/movie_display_utils.dart';

import 'cache_indicator_builders.dart';

/// Static helper class for building different movie card styles.
class CardStyleBuilders {
  /// Builds a poster-style movie card.
  static Widget buildPosterCard({
    required Movie movie,
    required double? width,
    required double? height,
    required bool? fromCache,
    required Duration? cacheAge,
    required bool? cacheOnlyMode,
    required bool showContentType,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: !isValidImageUrl(movie.posterUrl)
                ? Container(
                    width: width,
                    height: height,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.movie,
                      size: 48,
                      color: Colors.grey,
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: movie.posterUrl.trim(),
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
          ),
          CacheIndicatorBuilders.buildCacheIndicator(
            fromCache: fromCache,
          ),
          if (cacheOnlyMode == true)
            CacheIndicatorBuilders.buildOfflineModeIndicator(),
          if (showContentType && movie.contentType != null)
            CacheIndicatorBuilders.buildContentTypeIndicator(movie.contentType),
        ],
      ),
    );
  }

  /// Builds a list item-style movie card.
  static Widget buildListItemCard({
    required BuildContext context,
    required Movie movie,
    required double? width,
    required double? height,
    required bool? fromCache,
    required Duration? cacheAge,
    required bool? cacheOnlyMode,
    required Widget? trailing,
    required Widget? customSubtitle,
    required bool showRating,
    required bool showContentType,
    required bool showYear,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: !isValidImageUrl(movie.posterUrl)
                ? Container(
                    width: width,
                    height: height,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.movie,
                      size: 48,
                      color: Colors.grey,
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: movie.posterUrl.trim(),
                    width: width,
                    height: height,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
          ),
          CacheIndicatorBuilders.buildCacheIndicator(
            fromCache: fromCache,
          ),
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
          if (cacheOnlyMode == true)
            CacheIndicatorBuilders.buildOfflineModeIcon(),
        ],
      ),
      subtitle: customSubtitle ??
          _buildDefaultSubtitle(
            context: context,
            movie: movie,
            fromCache: fromCache,
            cacheAge: cacheAge,
            showRating: showRating,
            showContentType: showContentType,
            showYear: showYear,
          ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  /// Builds the default subtitle for list items.
  static Widget? _buildDefaultSubtitle({
    required BuildContext context,
    required Movie movie,
    required bool? fromCache,
    required Duration? cacheAge,
    required bool showRating,
    required bool showContentType,
    required bool showYear,
  }) {
    final parts = <Widget>[];

    // Add rating if enabled.

    if (showRating) {
      parts.add(
        Text(
          formatMovieRating(movie.voteAverage),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    // Add year if enabled.

    if (showYear) {
      final year = formatMovieYear(movie.releaseDate);
      if (year.isNotEmpty) {
        if (parts.isNotEmpty) parts.add(const Text(' • '));
        parts.add(
          Text(
            year,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        );
      }
    }

    // Add content type if enabled.

    if (showContentType && movie.contentType != null) {
      if (parts.isNotEmpty) parts.add(const Text(' • '));
      parts.add(
        Text(
          '${getContentTypeIcon(movie.contentType)} ${getContentTypeLabel(movie.contentType)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.7),
              ),
        ),
      );
    }

    if (parts.isEmpty) return null;

    return Row(
      children: [
        Expanded(
          child: Row(children: parts),
        ),
        if (fromCache == true && cacheAge != null)
          CacheIndicatorBuilders.buildCacheAgeInfo(cacheAge),
      ],
    );
  }
}
