/// Persistence service for per-column / per-screen sort preferences.
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
/// Authors: Tony Chen

library;

import 'package:shared_preferences/shared_preferences.dart';

import 'package:moviestar/widgets/sort_controls.dart';

/// Persists and retrieves [MovieSortCriteria] selections using
/// [SharedPreferences] so they survive app restarts.

class SortPreferenceService {
  static const String _prefix = 'sort_pref_';

  /// Saves the chosen [criteria] for [columnId].

  static Future<void> save(
    String columnId,
    MovieSortCriteria criteria,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$columnId', criteria.name);
  }

  /// Loads the previously saved criteria for [columnId].
  /// Returns [fallback] when nothing has been persisted yet.

  static Future<MovieSortCriteria> load(
    String columnId, {
    MovieSortCriteria fallback = MovieSortCriteria.nameAsc,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('$_prefix$columnId');
    if (stored == null) return fallback;
    return MovieSortCriteria.values.firstWhere(
      (c) => c.name == stored,
      orElse: () => fallback,
    );
  }
}
