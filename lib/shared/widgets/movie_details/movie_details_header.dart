/// Movie Details Header Component - Poster, Title, Rating Display and Action Buttons
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gap/gap.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/core/services/favorites/favorites_service.dart';
import 'package:moviestar/core/services/favorites/favorites_service_adapter.dart';
import 'package:moviestar/utils/date_format_util.dart';
import 'package:moviestar/utils/movie_display_utils.dart';

class MovieDetailsHeader extends StatelessWidget {
  final Movie movie;
  final ContentType contentType;
  final bool isInToWatch;
  final bool isInWatched;
  final bool isSharedMovie;
  final double? personalRating;
  final bool hasMovieFile;
  final FavoritesService favoritesService;
  final VoidCallback onToggleToWatch;
  final VoidCallback onToggleWatched;
  final VoidCallback onShowAddToCustomLists;
  final VoidCallback onShareMovie;
  final Map<String, dynamic>? sharedMovieData;

  const MovieDetailsHeader({
    super.key,
    required this.movie,
    required this.contentType,
    required this.isInToWatch,
    required this.isInWatched,
    required this.isSharedMovie,
    required this.personalRating,
    required this.hasMovieFile,
    required this.favoritesService,
    required this.onToggleToWatch,
    required this.onToggleWatched,
    required this.onShowAddToCustomLists,
    required this.onShareMovie,
    this.sharedMovieData,
  });

  String _getSharedByText() {
    if (!isSharedMovie || sharedMovieData == null) return 'Unknown';

    final sharedBy = sharedMovieData!['sharedBy'] as String?;
    final sharedByWebId = sharedMovieData!['sharedByWebId'] as String?;

    if (sharedBy != null && sharedBy.isNotEmpty && sharedBy != 'Unknown') {
      return sharedBy;
    }

    if (sharedByWebId != null && sharedByWebId.isNotEmpty) {
      return sharedByWebId;
    }

    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: Container(
        margin: const EdgeInsets.all(Dimensions.m),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surface
              .withValues(alpha: 0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: isValidImageUrl(movie.backdropUrl)
            ? CachedNetworkImage(
                imageUrl: movie.backdropUrl.trim(),
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.error),
              )
            : Container(
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: Center(
                  child: Icon(
                    Icons.movie,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
      ),
    );
  }
}

class MovieDetailsHeaderContent extends StatelessWidget {
  final Movie movie;
  final ContentType contentType;
  final bool isInToWatch;
  final bool isInWatched;
  final bool isSharedMovie;
  final double? personalRating;
  final bool hasMovieFile;
  final FavoritesService favoritesService;
  final VoidCallback onToggleToWatch;
  final VoidCallback onToggleWatched;
  final VoidCallback onShowAddToCustomLists;
  final VoidCallback onShareMovie;
  final Map<String, dynamic>? sharedMovieData;

  const MovieDetailsHeaderContent({
    super.key,
    required this.movie,
    required this.contentType,
    required this.isInToWatch,
    required this.isInWatched,
    required this.isSharedMovie,
    required this.personalRating,
    required this.hasMovieFile,
    required this.favoritesService,
    required this.onToggleToWatch,
    required this.onToggleWatched,
    required this.onShowAddToCustomLists,
    required this.onShareMovie,
    this.sharedMovieData,
  });

  String _getSharedByText() {
    if (!isSharedMovie || sharedMovieData == null) return 'Unknown';

    final sharedBy = sharedMovieData!['sharedBy'] as String?;
    final sharedByWebId = sharedMovieData!['sharedByWebId'] as String?;

    if (sharedBy != null && sharedBy.isNotEmpty && sharedBy != 'Unknown') {
      return sharedBy;
    }

    if (sharedByWebId != null && sharedByWebId.isNotEmpty) {
      return sharedByWebId;
    }

    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                movie.title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isInToWatch
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: isInToWatch
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: onToggleToWatch,
                  tooltip: isInToWatch
                      ? 'Remove from To Watch'
                      : 'Add to To Watch',
                ),
                IconButton(
                  icon: Icon(
                    isInWatched
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    color: isInWatched
                        ? Theme.of(context).colorScheme.tertiary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: onToggleWatched,
                  tooltip: isInWatched
                      ? 'Remove from Watched'
                      : 'Add to Watched',
                ),
                if (!isSharedMovie)
                  MarkdownTooltip(
                    message: '''

**Add to Custom List**

Add this movie to one of your custom lists or create a new list.
Organize your movies the way you want!

                    ''',
                    child: IconButton(
                      icon: Icon(
                        Icons.playlist_add,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: onShowAddToCustomLists,
                    ),
                  ),
                if (hasMovieFile &&
                    favoritesService is FavoritesServiceAdapter &&
                    (favoritesService as FavoritesServiceAdapter)
                        .isPodStorageEnabled)
                  MarkdownTooltip(
                    message: '''

**Share this movie and my review**

Share your rating and comments for this movie with friends via their WebID.
Your shared movies will appear in their "Shared with Me" tab.

                    ''',
                    child: IconButton(
                      icon: Icon(
                        Icons.share,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: onShareMovie,
                    ),
                  ),
              ],
            ),
          ],
        ),
        const Gap(Gaps.m),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: movie.contentType == ContentType.tvShow
                    ? Colors.blue.withValues(alpha: 0.2)
                    : Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: movie.contentType == ContentType.tvShow
                      ? Colors.blue
                      : Colors.green,
                  width: 1,
                ),
              ),
              child: Text(
                movie.contentType == ContentType.tvShow
                    ? '📺 TV Show'
                    : '🎬 Movie',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: movie.contentType == ContentType.tvShow
                          ? Colors.blue
                          : Colors.green,
                    ),
              ),
            ),
            const Gap(12),
            Icon(
              Icons.star,
              color: isSharedMovie && personalRating != null
                  ? Theme.of(context).colorScheme.primary
                  : Colors.amber,
              size: 20,
            ),
            const Gap(4),
            Text(
              isSharedMovie && personalRating != null
                  ? personalRating!.toStringAsFixed(1)
                  : movie.voteAverage.toStringAsFixed(1),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
            if (isSharedMovie && personalRating != null)
              Text(
                ' (shared)',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const Gap(16),
            Icon(
              Icons.calendar_today,
              color: Theme.of(context).colorScheme.onSurface,
              size: 20,
            ),
            const Gap(4),
            Text(
              DateFormatUtil.formatShort(movie.releaseDate),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const Gap(16),
        if (isSharedMovie)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.share,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const Gap(Gaps.m),
                Text(
                  'This movie was shared by ${_getSharedByText()}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}