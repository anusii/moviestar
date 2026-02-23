/// Custom List Builder for Home Screen.
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
/// Authors: Ashley Tang, Kevin Wang

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/shared/widgets/home/custom_list_row.dart';
import 'package:moviestar/shared/widgets/home/custom_list_section.dart';
import 'package:moviestar/shared/widgets/home/custom_list_states.dart';

/// A widget that builds custom list sections for the home screen.
/// This component handles both grid view (horizontal scroll) and list view layouts.

class HomeCustomListBuilder extends ConsumerWidget {
  /// Service for managing favorite movies.

  final FavoritesService favoritesService;

  /// Parent widget for navigation context.

  final StatefulWidget parentWidget;

  /// Callback for safe navigation.

  final void Function(Route<dynamic> route) onNavigate;

  /// Map of scroll controllers for each custom list.

  final Map<String, ScrollController> scrollControllers;

  /// Whether to show as list sections (for list view) or movie rows (for grid view).

  final bool showAsListSections;

  /// Creates a new [HomeCustomListBuilder] widget.

  const HomeCustomListBuilder({
    super.key,
    required this.favoritesService,
    required this.parentWidget,
    required this.onNavigate,
    required this.scrollControllers,
    this.showAsListSections = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<CustomList>>(
      stream: favoritesService.customLists,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const CustomListLoadingState();
        }

        final customLists = snapshot.data ?? [];
        if (customLists.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: customLists.map((customList) {
            if (showAsListSections) {
              return CustomListSection(
                customList: customList,
                favoritesService: favoritesService,
                parentWidget: parentWidget,
                onNavigate: onNavigate,
              );
            } else {
              return CustomListRow(
                customList: customList,
                favoritesService: favoritesService,
                parentWidget: parentWidget,
                onNavigate: onNavigate,
                scrollController: scrollControllers[customList.id],
              );
            }
          }).toList(),
        );
      },
    );
  }
}
