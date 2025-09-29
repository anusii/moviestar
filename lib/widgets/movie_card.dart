/// Reusable movie card widget with cache status indicators.
///
// Time-stamp: <Friday 2025-08-22 05:51:08 +1000 Graham Williams>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Ashley Tang.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/widgets/movie_card/card_style_builders.dart';
import 'package:moviestar/widgets/movie_card/hover_interaction_handler.dart';

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

  /// Whether to show the rating in list items.

  final bool showRating;

  /// Whether to show the content type indicator.

  final bool showContentType;

  /// Whether to show the release year.

  final bool showYear;

  /// Whether to enable quick actions on hover.

  final bool enableQuickActions;

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
    this.showRating = true,
    this.showContentType = true,
    this.showYear = false,
    this.enableQuickActions = true,
  });

  /// Creates a poster-style movie card.

  const MovieCard.poster({
    super.key,
    required this.movie,
    this.fromCache = false,
    this.cacheAge,
    this.cacheOnlyMode,
    required this.onTap,
    this.width = 130,
    this.height,
    this.favoritesService,
    this.parentWidget,
    this.showContentType = true,
    this.enableQuickActions = true,
  })  : style = MovieCardStyle.poster,
        trailing = null,
        customSubtitle = null,
        showRating = false,
        showYear = false;

  /// Creates a list item-style movie card.

  const MovieCard.listItem({
    super.key,
    required this.movie,
    this.fromCache,
    this.cacheAge,
    this.cacheOnlyMode,
    required this.onTap,
    this.trailing,
    this.customSubtitle,
    this.favoritesService,
    this.parentWidget,
    this.showRating = true,
    this.showContentType = true,
    this.showYear = false,
    this.enableQuickActions = true,
  })  : style = MovieCardStyle.listItem,
        width = 50,
        height = 75;

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  HoverInteractionHandler? _hoverHandler;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.enableQuickActions && widget.favoritesService != null) {
      _hoverHandler = HoverInteractionHandler(
        context: context,
        movie: widget.movie,
        favoritesService: widget.favoritesService,
        parentWidget: widget.parentWidget,
      );
    }
  }

  @override
  void dispose() {
    _hoverHandler?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.style) {
      case MovieCardStyle.poster:
        return MouseRegion(
          onEnter: widget.enableQuickActions
              ? (_) => _hoverHandler?.onCardMouseEnter()
              : null,
          onExit: widget.enableQuickActions
              ? (_) => _hoverHandler?.onCardMouseExit()
              : null,
          child: CardStyleBuilders.buildPosterCard(
            movie: widget.movie,
            width: widget.width,
            height: widget.height,
            fromCache: widget.fromCache,
            cacheAge: widget.cacheAge,
            cacheOnlyMode: widget.cacheOnlyMode,
            showContentType: widget.showContentType,
            onTap: widget.onTap,
          ),
        );
      case MovieCardStyle.listItem:
        return MouseRegion(
          onEnter: widget.enableQuickActions
              ? (_) => _hoverHandler?.onCardMouseEnter()
              : null,
          onExit: widget.enableQuickActions
              ? (_) => _hoverHandler?.onCardMouseExit()
              : null,
          child: CardStyleBuilders.buildListItemCard(
            context: context,
            movie: widget.movie,
            width: widget.width,
            height: widget.height,
            fromCache: widget.fromCache,
            cacheAge: widget.cacheAge,
            cacheOnlyMode: widget.cacheOnlyMode,
            trailing: widget.trailing,
            customSubtitle: widget.customSubtitle,
            showRating: widget.showRating,
            showContentType: widget.showContentType,
            showYear: widget.showYear,
            onTap: widget.onTap,
          ),
        );
    }
  }
}
