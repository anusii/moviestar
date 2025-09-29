/// Hover interaction handler for movie cards.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:moviestar/constants/timing_constants.dart';
import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/widgets/quick_actions_dialog.dart';

/// Handles mouse hover interactions and quick actions overlay for movie cards.

class HoverInteractionHandler {
  final BuildContext context;
  final Movie movie;
  final FavoritesService? favoritesService;
  final Widget? parentWidget;

  // Overlay entry for the quick actions dialog.

  OverlayEntry? _overlayEntry;

  // Whether the quick actions dialog is currently shown.

  bool _isDialogShown = false;

  // Timer for delayed hiding of the dialog.

  Timer? _hideTimer;

  // Timer for delayed showing of the dialog.

  Timer? _showTimer;

  HoverInteractionHandler({
    required this.context,
    required this.movie,
    this.favoritesService,
    this.parentWidget,
  });

  /// Dispose of timers and overlay.

  void dispose() {
    _removeOverlay();
    _hideTimer?.cancel();
    _showTimer?.cancel();
  }

  /// Called when mouse enters the card area.

  void onCardMouseEnter() {
    _hideTimer?.cancel();

    // Start a timer to show the dialog after a delay.
    // This prevents popups from appearing immediately when quickly moving the mouse.

    _showTimer?.cancel();
    _showTimer = Timer(TimingConstants.movieCardHoverShowDelay, () {
      _showQuickActions();
    });
  }

  /// Called when mouse exits the card area.

  void onCardMouseExit() {
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

  /// Called when mouse enters the dialog area.

  void onDialogMouseEnter() {
    // Cancel both timers since mouse is over the dialog.

    _showTimer?.cancel();
    _hideTimer?.cancel();
  }

  /// Called when mouse exits the dialog area.

  void onDialogMouseExit() {
    // Start a timer to hide the dialog.

    _hideTimer?.cancel();
    _hideTimer = Timer(TimingConstants.movieCardHoverHideDelay, () {
      _hideQuickActions();
    });
  }

  /// Shows the quick actions dialog if favoritesService is available.

  void _showQuickActions() {
    if (favoritesService == null || _isDialogShown) return;

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
          movie: movie,
          favoritesService: favoritesService!,
          parentWidget: parentWidget,
          onClose: _hideQuickActions,
          onMouseEnter: onDialogMouseEnter,
          onMouseExit: onDialogMouseExit,
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Hides the quick actions dialog.

  void _hideQuickActions() {
    if (!_isDialogShown) return;

    _hideTimer?.cancel();
    _removeOverlay();
    _isDialogShown = false;
  }

  /// Removes the overlay entry.

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
