/// Kanban Settings Panel - Configuration UI
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/widgets/sort_controls.dart';

/// Configuration settings for the kanban board
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
      'popular': MovieSortCriteria.ratingDesc,
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

/// Controller for managing kanban settings
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

/// Settings panel widget for kanban board configuration
class KanbanSettingsPanel extends StatelessWidget {
  final KanbanSettingsController controller;
  final VoidCallback? onClose;
  final VoidCallback? onReset;

  const KanbanSettingsPanel({
    super.key,
    required this.controller,
    this.onClose,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(Dimensions.l),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kanban Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      controller.resetToDefaults();
                      onReset?.call();
                    },
                    child: const Text('Reset'),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ],
          ),
          const Divider(),

          // Settings content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDisplaySettings(context),
                  const SizedBox(height: Dimensions.l),
                  _buildBehaviorSettings(context),
                  const SizedBox(height: Dimensions.l),
                  _buildCardSettings(context),
                  const SizedBox(height: Dimensions.l),
                  _buildDefaultSortSettings(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplaySettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Display Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: Dimensions.m),

        // Max items per column
        Row(
          children: [
            Expanded(
              child: Text(
                'Max items per column',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            SizedBox(
              width: 80,
              child: TextField(
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.all(8),
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(
                  text: controller.settings.maxItemsPerColumn.toString(),
                ),
                onSubmitted: (value) {
                  final maxItems = int.tryParse(value) ?? 8;
                  controller.updateMaxItemsPerColumn(maxItems.clamp(1, 20));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: Dimensions.m),

        // Show movie posters
        SwitchListTile(
          title: const Text('Show movie posters'),
          subtitle: const Text('Display poster images on movie cards'),
          value: controller.settings.showMoviePosters,
          onChanged: controller.updateShowMoviePosters,
          contentPadding: EdgeInsets.zero,
        ),

        // Show sync indicators
        SwitchListTile(
          title: const Text('Show sync indicators'),
          subtitle: const Text('Display loading and error indicators'),
          value: controller.settings.showSyncIndicators,
          onChanged: controller.updateShowSyncIndicators,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildBehaviorSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Behavior Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: Dimensions.m),

        // Enable drag and drop
        SwitchListTile(
          title: const Text('Enable drag and drop'),
          subtitle: const Text('Allow moving movies between columns'),
          value: controller.settings.enableDragAndDrop,
          onChanged: controller.updateEnableDragAndDrop,
          contentPadding: EdgeInsets.zero,
        ),

        // Enable optimistic updates
        SwitchListTile(
          title: const Text('Enable optimistic updates'),
          subtitle: const Text('Show changes immediately before sync'),
          value: controller.settings.enableOptimisticUpdates,
          onChanged: controller.updateEnableOptimisticUpdates,
          contentPadding: EdgeInsets.zero,
        ),

        // Auto refresh
        SwitchListTile(
          title: const Text('Auto refresh'),
          subtitle: const Text('Automatically refresh content'),
          value: controller.settings.autoRefresh,
          onChanged: controller.updateAutoRefresh,
          contentPadding: EdgeInsets.zero,
        ),

        // Refresh interval (only if auto refresh is enabled)
        if (controller.settings.autoRefresh) ...[
          const SizedBox(height: Dimensions.s),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Refresh interval (minutes)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              SizedBox(
                width: 80,
                child: TextField(
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.all(8),
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(
                    text: controller.settings.refreshIntervalMinutes.toString(),
                  ),
                  onSubmitted: (value) {
                    final interval = int.tryParse(value) ?? 5;
                    controller.updateRefreshInterval(interval.clamp(1, 60));
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCardSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Card Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: Dimensions.m),

        // Card width
        Row(
          children: [
            Expanded(
              child: Text(
                'Card width',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            SizedBox(
              width: 80,
              child: TextField(
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.all(8),
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(
                  text: controller.settings.cardWidth.toString(),
                ),
                onSubmitted: (value) {
                  final width = double.tryParse(value) ?? 100;
                  controller.updateCardSize(
                    width.clamp(80, 200),
                    controller.settings.cardHeight,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: Dimensions.m),

        // Card height
        Row(
          children: [
            Expanded(
              child: Text(
                'Card height',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            SizedBox(
              width: 80,
              child: TextField(
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.all(8),
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(
                  text: controller.settings.cardHeight.toString(),
                ),
                onSubmitted: (value) {
                  final height = double.tryParse(value) ?? 150;
                  controller.updateCardSize(
                    controller.settings.cardWidth,
                    height.clamp(120, 250),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDefaultSortSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Default Sort Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: Dimensions.m),

        // Popular movies sort
        _buildSortDropdown(
          context,
          'Popular movies',
          'popular',
          controller.settings.defaultSortCriteria['popular'] ??
              MovieSortCriteria.ratingDesc,
        ),

        // To Watch sort
        _buildSortDropdown(
          context,
          'To Watch',
          'towatch',
          controller.settings.defaultSortCriteria['towatch'] ??
              MovieSortCriteria.nameAsc,
        ),

        // Watched sort
        _buildSortDropdown(
          context,
          'Watched',
          'watched',
          controller.settings.defaultSortCriteria['watched'] ??
              MovieSortCriteria.dateDesc,
        ),
      ],
    );
  }

  Widget _buildSortDropdown(
    BuildContext context,
    String label,
    String columnId,
    MovieSortCriteria currentCriteria,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.m),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          DropdownButton<MovieSortCriteria>(
            value: currentCriteria,
            items: const [
              DropdownMenuItem(
                value: MovieSortCriteria.nameAsc,
                child: Text('Name (A-Z)'),
              ),
              DropdownMenuItem(
                value: MovieSortCriteria.nameDesc,
                child: Text('Name (Z-A)'),
              ),
              DropdownMenuItem(
                value: MovieSortCriteria.ratingDesc,
                child: Text('Rating (High-Low)'),
              ),
              DropdownMenuItem(
                value: MovieSortCriteria.ratingAsc,
                child: Text('Rating (Low-High)'),
              ),
              DropdownMenuItem(
                value: MovieSortCriteria.dateDesc,
                child: Text('Date (Newest)'),
              ),
              DropdownMenuItem(
                value: MovieSortCriteria.dateAsc,
                child: Text('Date (Oldest)'),
              ),
            ],
            onChanged: (criteria) {
              if (criteria != null) {
                final newCriteria = Map<String, MovieSortCriteria>.from(
                  controller.settings.defaultSortCriteria,
                );
                newCriteria[columnId] = criteria;
                controller.updateDefaultSortCriteria(newCriteria);
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Quick settings toolbar for common kanban adjustments
class KanbanQuickSettings extends StatelessWidget {
  final KanbanSettingsController controller;
  final VoidCallback? onOpenFullSettings;

  const KanbanQuickSettings({
    super.key,
    required this.controller,
    this.onOpenFullSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.m,
        vertical: Dimensions.s,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Max items quick adjuster
          IconButton(
            onPressed: () {
              final current = controller.settings.maxItemsPerColumn;
              if (current > 1) {
                controller.updateMaxItemsPerColumn(current - 1);
              }
            },
            icon: const Icon(Icons.remove),
            tooltip: 'Show fewer items',
          ),
          Text(
            '${controller.settings.maxItemsPerColumn}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          IconButton(
            onPressed: () {
              final current = controller.settings.maxItemsPerColumn;
              if (current < 20) {
                controller.updateMaxItemsPerColumn(current + 1);
              }
            },
            icon: const Icon(Icons.add),
            tooltip: 'Show more items',
          ),

          const VerticalDivider(),

          // Drag and drop toggle
          IconButton(
            onPressed: () {
              controller.updateEnableDragAndDrop(
                  !controller.settings.enableDragAndDrop,);
            },
            icon: Icon(
              controller.settings.enableDragAndDrop
                  ? Icons.open_with
                  : Icons.lock,
            ),
            tooltip: controller.settings.enableDragAndDrop
                ? 'Disable drag & drop'
                : 'Enable drag & drop',
          ),

          // Auto refresh toggle
          IconButton(
            onPressed: () {
              controller.updateAutoRefresh(!controller.settings.autoRefresh);
            },
            icon: Icon(
              controller.settings.autoRefresh
                  ? Icons.refresh
                  : Icons.refresh_outlined,
            ),
            tooltip: controller.settings.autoRefresh
                ? 'Disable auto refresh'
                : 'Enable auto refresh',
          ),

          const VerticalDivider(),

          // Full settings button
          IconButton(
            onPressed: onOpenFullSettings,
            icon: const Icon(Icons.settings),
            tooltip: 'Open full settings',
          ),
        ],
      ),
    );
  }
}
