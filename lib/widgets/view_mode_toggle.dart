/// View mode toggle widget for switching between different display modes.
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

import 'package:moviestar/providers/view_mode_provider.dart';

/// A toggle button widget for switching between view modes.

class ViewModeToggle extends ConsumerWidget {
  /// Whether to show as a compact single button or expanded row.
  
  final bool compact;
  
  /// Icon size for the buttons.
  
  final double iconSize;

  const ViewModeToggle({
    super.key,
    this.compact = true,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(viewModeProvider);
    final viewModeNotifier = ref.read(viewModeProvider.notifier);

    if (compact) {
      return _buildCompactToggle(context, currentMode, viewModeNotifier);
    } else {
      return _buildExpandedToggle(context, currentMode, viewModeNotifier);
    }
  }

  // Build a compact toggle that shows current mode and cycles on tap.
  
  Widget _buildCompactToggle(
    BuildContext context, 
    HomeViewMode currentMode, 
    ViewModeNotifier notifier,
  ) {
    return IconButton(
      onPressed: () => notifier.cycleViewMode(),
      icon: Icon(
        _getIconForMode(currentMode),
        size: iconSize,
      ),
      tooltip: 'View Mode: ${currentMode.displayName} (tap to cycle)',
      splashRadius: 20,
    );
  }

  // Build an expanded toggle with separate buttons for each mode.
  
  Widget _buildExpandedToggle(
    BuildContext context, 
    HomeViewMode currentMode, 
    ViewModeNotifier notifier,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: HomeViewMode.values.map((mode) {
        final isSelected = mode == currentMode;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: IconButton(
            onPressed: () => notifier.setViewMode(mode),
            icon: Icon(
              _getIconForMode(mode),
              size: iconSize,
              color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            tooltip: '${mode.displayName} View',
            splashRadius: 18,
          ),
        );
      }).toList(),
    );
  }

  // Get the appropriate icon for each view mode.
  
  IconData _getIconForMode(HomeViewMode mode) {
    switch (mode) {
      case HomeViewMode.grid:
        return Icons.grid_view;
      case HomeViewMode.kanban:
        return Icons.view_kanban;
      case HomeViewMode.list:
        return Icons.view_list;
    }
  }
}

/// A segmented button style toggle for view modes.

class ViewModeSegmentedToggle extends ConsumerWidget {
  const ViewModeSegmentedToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(viewModeProvider);
    final viewModeNotifier = ref.read(viewModeProvider.notifier);

    return SegmentedButton<HomeViewMode>(
      segments: HomeViewMode.values.map((mode) {
        return ButtonSegment<HomeViewMode>(
          value: mode,
          icon: Icon(_getIconForMode(mode)),
          label: Text(mode.displayName),
        );
      }).toList(),
      selected: {currentMode},
      onSelectionChanged: (Set<HomeViewMode> selection) {
        if (selection.isNotEmpty) {
          viewModeNotifier.setViewMode(selection.first);
        }
      },
      showSelectedIcon: false,
    );
  }

  // Get the appropriate icon for each view mode.
  
  IconData _getIconForMode(HomeViewMode mode) {
    switch (mode) {
      case HomeViewMode.grid:
        return Icons.grid_view;
      case HomeViewMode.kanban:
        return Icons.view_kanban;
      case HomeViewMode.list:
        return Icons.view_list;
    }
  }
}
