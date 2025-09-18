/// View Mode Provider - App-specific navigation setup.
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
/// Authors: Ashley Tang.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enum representing different view modes for the home screen.

enum HomeViewMode {
  grid('Grid', 'grid'),
  kanban('Kanban', 'kanban'),
  list('List', 'list');

  const HomeViewMode(this.displayName, this.value);

  final String displayName;
  final String value;

  // Get HomeViewMode from string value.

  static HomeViewMode fromValue(String value) {
    switch (value) {
      case 'grid':
        return HomeViewMode.grid;
      case 'kanban':
        return HomeViewMode.kanban;
      case 'list':
        return HomeViewMode.list;
      default:
        return HomeViewMode.grid; // Default fallback.
    }
  }
}

/// StateNotifier for managing view mode state with persistence.

class ViewModeNotifier extends StateNotifier<HomeViewMode> {
  static const String _key = 'home_view_mode';

  ViewModeNotifier() : super(HomeViewMode.grid) {
    _loadViewMode();
  }

  // Load the view mode from shared preferences.

  Future<void> _loadViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_key);
      if (savedMode != null) {
        state = HomeViewMode.fromValue(savedMode);
      }
    } catch (e) {
      // If loading fails, keep the default.
    }
  }

  // Set the view mode and persist it.

  Future<void> setViewMode(HomeViewMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.value);
    } catch (e) {
      // If saving fails, at least the state is updated.
    }
  }

  // Cycle to the next view mode.

  Future<void> cycleViewMode() async {
    final modes = HomeViewMode.values;
    final currentIndex = modes.indexOf(state);
    final nextIndex = (currentIndex + 1) % modes.length;
    await setViewMode(modes[nextIndex]);
  }
}

/// Provider for the view mode state.

final viewModeProvider =
    StateNotifierProvider<ViewModeNotifier, HomeViewMode>((ref) {
  return ViewModeNotifier();
});
