/// Solid Navigation Bar.
///
// Time-stamp: <Friday 2025-08-05 16:00:00 +1000 Tony Chen>
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
/// Authors: Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:moviestar/constants/navigation_constants.dart';
import 'package:moviestar/widgets/solid_nav_models.dart';

/// A reusable navigation rail component designed for Solid POD applications.
///
/// This widget provides a left-side navigation rail that can be easily
/// integrated into different applications and eventually migrated to the
/// solidpod library.

class SolidNavBar extends StatelessWidget {
  /// List of navigation tabs to display.

  final List<SolidNavTab> tabs;

  /// Currently selected tab index.

  final int selectedIndex;

  /// Callback when a tab is selected.

  final void Function(int) onTabSelected;

  /// Optional callback to show alert dialogs.

  final void Function(BuildContext, String, String?)? onShowAlert;

  /// Optional custom minimum width for the navigation rail.

  final double? minWidth;

  /// Optional custom group alignment for navigation items.

  final double? groupAlignment;

  /// Optional custom icon size.

  final double? iconSize;

  /// Optional custom label font size.

  final double? labelFontSize;

  /// Creates a [SolidNavBar] with the specified configuration.

  const SolidNavBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    this.onShowAlert,
    this.minWidth,
    this.groupAlignment,
    this.iconSize,
    this.labelFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: Container(
        color: theme.colorScheme.surface,
        child: NavigationRail(
          backgroundColor: theme.colorScheme.surface,
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => _handleTabSelection(index, context),
          labelType: NavigationRailLabelType.all,
          minWidth: minWidth ?? NavigationConstants.navRailMinWidth,
          groupAlignment:
              groupAlignment ?? NavigationConstants.navRailGroupAlignment,
          destinations: tabs.map((tab) {
            final tooltipMessage = tab.tooltip ?? tab.message;

            Widget iconWidget = Icon(
              tab.icon,
              size: iconSize ?? NavigationConstants.navIconSize,
              color: tab.color ?? theme.colorScheme.primary,
            );

            // Wrap with tooltip if available.

            if (tooltipMessage != null) {
              iconWidget = MarkdownTooltip(
                message: tooltipMessage,
                child: iconWidget,
              );
            }

            return NavigationRailDestination(
              icon: iconWidget,
              label: Text(
                tab.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize:
                      labelFontSize ?? NavigationConstants.navLabelFontSize,
                  fontWeight: FontWeight.w500,
                  letterSpacing: NavigationConstants.navLabelLetterSpacing,
                ),
                textAlign: TextAlign.center,
                maxLines: NavigationConstants.navLabelMaxLines,
                overflow: TextOverflow.ellipsis,
              ),
              padding: const EdgeInsets.symmetric(
                vertical: NavigationConstants.navDestinationVerticalPadding,
              ),
            );
          }).toList(),
          selectedLabelTextStyle: theme.textTheme.bodySmall?.copyWith(
            fontSize: labelFontSize ?? NavigationConstants.navLabelFontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: NavigationConstants.navLabelLetterSpacing,
            color: theme.colorScheme.primary,
          ),
          unselectedLabelTextStyle: theme.textTheme.bodySmall?.copyWith(
            fontSize: labelFontSize ?? NavigationConstants.navLabelFontSize,
            fontWeight: FontWeight.w400,
            letterSpacing: NavigationConstants.navLabelLetterSpacing,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  void _handleTabSelection(int index, BuildContext context) {
    onTabSelected(index);

    final tab = tabs[index];

    // Handle special tab actions.

    if (tab.message != null && onShowAlert != null) {
      onShowAlert!(
        context,
        tab.message!,
        tab.dialogTitle,
      );
    } else if (tab.action != null) {
      tab.action!(context);
    }
  }
}
