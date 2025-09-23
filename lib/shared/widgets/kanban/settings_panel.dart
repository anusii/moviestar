/// Kanban Settings Panel - Configuration UI.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/widgets/sort_controls.dart';

/// Configuration settings for the kanban board.
class KanbanSettings {
  final int maxItemsPerColumn;
  final bool showMoviePosters;
  final bool enableDragAndDrop;
  final bool showSyncIndicators;
  final bool enableOptimisticUpdates;
  final bool autoRefresh;
  final int refreshIntervalMinutes;
  final double cardWidth;
  final double cardHeight;
  final Map<String, MovieSortCriteria> defaultSortCriteria;

  const KanbanSettings({
    this.maxItemsPerColumn = 8,
    this.showMoviePosters = true,
    this.enableDragAndDrop = true,
    this.showSyncIndicators = true,
    this.enableOptimisticUpdates = true,
    this.autoRefresh = false,
    this.refreshIntervalMinutes = 5,
    this.cardWidth = 100,
    this.cardHeight = 150,
    this.defaultSortCriteria = const {
      'recommended': MovieSortCriteria.ratingDesc,
      'towatch': MovieSortCriteria.nameAsc,
      'watched': MovieSortCriteria.dateDesc,
    },
  });

  KanbanSettings copyWith({
    int? maxItemsPerColumn,
    bool? showMoviePosters,
    bool? enableDragAndDrop,
    bool? showSyncIndicators,
    bool? enableOptimisticUpdates,
    bool? autoRefresh,
    int? refreshIntervalMinutes,
    double? cardWidth,
    double? cardHeight,
    Map<String, MovieSortCriteria>? defaultSortCriteria,
  }) {
    return KanbanSettings(
      maxItemsPerColumn: maxItemsPerColumn ?? this.maxItemsPerColumn,
      showMoviePosters: showMoviePosters ?? this.showMoviePosters,
      enableDragAndDrop: enableDragAndDrop ?? this.enableDragAndDrop,
      showSyncIndicators: showSyncIndicators ?? this.showSyncIndicators,
      enableOptimisticUpdates:
          enableOptimisticUpdates ?? this.enableOptimisticUpdates,
      autoRefresh: autoRefresh ?? this.autoRefresh,
      refreshIntervalMinutes:
          refreshIntervalMinutes ?? this.refreshIntervalMinutes,
      cardWidth: cardWidth ?? this.cardWidth,
      cardHeight: cardHeight ?? this.cardHeight,
      defaultSortCriteria: defaultSortCriteria ?? this.defaultSortCriteria,
    );
  }
}

/// Controller for managing kanban settings.
class KanbanSettingsController extends ChangeNotifier {
  KanbanSettings _settings = const KanbanSettings();

  KanbanSettings get settings => _settings;

  void updateSettings(KanbanSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  void updateMaxItemsPerColumn(int maxItems) {
    _settings = _settings.copyWith(maxItemsPerColumn: maxItems);
    notifyListeners();
  }

  void updateShowMoviePosters(bool show) {
    _settings = _settings.copyWith(showMoviePosters: show);
    notifyListeners();
  }

  void updateEnableDragAndDrop(bool enable) {
    _settings = _settings.copyWith(enableDragAndDrop: enable);
    notifyListeners();
  }

  void updateShowSyncIndicators(bool show) {
    _settings = _settings.copyWith(showSyncIndicators: show);
    notifyListeners();
  }

  void updateEnableOptimisticUpdates(bool enable) {
    _settings = _settings.copyWith(enableOptimisticUpdates: enable);
    notifyListeners();
  }

  void updateAutoRefresh(bool enable) {
    _settings = _settings.copyWith(autoRefresh: enable);
    notifyListeners();
  }

  void updateRefreshInterval(int minutes) {
    _settings = _settings.copyWith(refreshIntervalMinutes: minutes);
    notifyListeners();
  }

  void updateCardSize(double width, double height) {
    _settings = _settings.copyWith(cardWidth: width, cardHeight: height);
    notifyListeners();
  }

  void updateDefaultSortCriteria(Map<String, MovieSortCriteria> criteria) {
    _settings = _settings.copyWith(defaultSortCriteria: criteria);
    notifyListeners();
  }

  void resetToDefaults() {
    _settings = const KanbanSettings();
    notifyListeners();
  }
}
