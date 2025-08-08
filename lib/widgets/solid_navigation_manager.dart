/// Solid Navigation Manager for automatic layout switching.
///
// Time-stamp: <Tuesday 2025-08-06 16:30:00 +1000 Tony Chen>
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

import 'package:moviestar/constants/navigation_constants.dart';
import 'package:moviestar/widgets/solid_nav_bar.dart';
import 'package:moviestar/widgets/solid_nav_drawer.dart';

/// Configuration for the solid navigation manager.

class SolidNavigationConfig {
  /// The width threshold for determining wide screen layout.

  final double narrowScreenThreshold;

  /// Whether to automatically switch between nav bar and drawer based on screen width.

  final bool autoSwitch;

  /// Force wide screen layout regardless of screen width.

  final bool forceWideScreen;

  /// Force narrow screen layout regardless of screen width.

  final bool forceNarrowScreen;

  const SolidNavigationConfig({
    this.narrowScreenThreshold = NavigationConstants.narrowScreenThreshold,
    this.autoSwitch = true,
    this.forceWideScreen = false,
    this.forceNarrowScreen = false,
  }) : assert(!(forceWideScreen && forceNarrowScreen),
            'Cannot force both wide and narrow screen layouts');
}

/// A solid navigation manager that automatically switches between
/// navigation rail (wide screens) and navigation drawer (narrow screens).

class SolidNavigationManager extends StatelessWidget {
  /// Navigation configuration.

  final SolidNavigationConfig config;

  /// List of navigation tabs to display.

  final List<SolidNavTab> tabs;

  /// Currently selected tab index.

  final int selectedIndex;

  /// Callback when a tab is selected.

  final void Function(int) onTabSelected;

  /// User information for the drawer header (optional).

  final SolidNavUserInfo? userInfo;

  /// Optional logout callback.

  final void Function(BuildContext)? onLogout;

  /// Optional callback to show alert dialogs.

  final void Function(BuildContext, String, String?)? onShowAlert;

  /// The main content widget to display.

  final Widget content;

  /// Optional app bar for the scaffold.

  final PreferredSizeWidget? appBar;

  /// Optional background color for the scaffold.

  final Color? backgroundColor;

  /// Optional floating action button.

  final Widget? floatingActionButton;

  /// Optional additional drawer menu items.

  final List<Widget>? additionalDrawerItems;

  /// Optional custom navigation bar configuration.

  final double? navBarMinWidth;
  final double? navBarGroupAlignment;
  final double? navBarIconSize;
  final double? navBarLabelFontSize;

  /// Optional custom drawer configuration.

  final ShapeBorder? drawerShape;
  final IconData? logoutIcon;
  final String? logoutText;
  final bool showLogout;

  const SolidNavigationManager({
    super.key,
    this.config = const SolidNavigationConfig(),
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.content,
    this.userInfo,
    this.onLogout,
    this.onShowAlert,
    this.appBar,
    this.backgroundColor,
    this.floatingActionButton,
    this.additionalDrawerItems,
    this.navBarMinWidth,
    this.navBarGroupAlignment,
    this.navBarIconSize,
    this.navBarLabelFontSize,
    this.drawerShape,
    this.logoutIcon,
    this.logoutText,
    this.showLogout = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWideScreen = _determineLayoutMode(context);

    // Create a modified AppBar that handles automaticallyImplyLeading correctly

    PreferredSizeWidget? modifiedAppBar;
    if (appBar != null && appBar is AppBar) {
      final originalAppBar = appBar as AppBar;
      modifiedAppBar = AppBar(
        title: originalAppBar.title,
        backgroundColor: originalAppBar.backgroundColor,
        automaticallyImplyLeading: !isWideScreen,
        // Show hamburger menu.
        actions: originalAppBar.actions,
        elevation: originalAppBar.elevation,
        shadowColor: originalAppBar.shadowColor,
        surfaceTintColor: originalAppBar.surfaceTintColor,
        foregroundColor: originalAppBar.foregroundColor,
        iconTheme: originalAppBar.iconTheme,
        actionsIconTheme: originalAppBar.actionsIconTheme,
        primary: originalAppBar.primary,
        centerTitle: originalAppBar.centerTitle,
        excludeHeaderSemantics: originalAppBar.excludeHeaderSemantics,
        titleSpacing: originalAppBar.titleSpacing,
        toolbarOpacity: originalAppBar.toolbarOpacity,
        bottomOpacity: originalAppBar.bottomOpacity,
        toolbarHeight: originalAppBar.toolbarHeight,
        leadingWidth: originalAppBar.leadingWidth,
        toolbarTextStyle: originalAppBar.toolbarTextStyle,
        titleTextStyle: originalAppBar.titleTextStyle,
        systemOverlayStyle: originalAppBar.systemOverlayStyle,
        forceMaterialTransparency: originalAppBar.forceMaterialTransparency,
        clipBehavior: originalAppBar.clipBehavior,
      );
    } else {
      modifiedAppBar = appBar;
    }

    return Scaffold(
      appBar: modifiedAppBar,
      drawer: _shouldShowDrawer(isWideScreen) ? _buildDrawer() : null,
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      floatingActionButton: floatingActionButton,
      body: _buildBody(context, theme, isWideScreen),
    );
  }

  /// Determines the layout mode based on screen width and configuration.

  bool _determineLayoutMode(BuildContext context) {
    if (config.forceWideScreen) return true;
    if (config.forceNarrowScreen) return false;
    if (!config.autoSwitch) return true;

    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth > config.narrowScreenThreshold;
  }

  /// Determines whether to show the navigation drawer.

  bool _shouldShowDrawer(bool isWideScreen) {
    return !isWideScreen;
  }

  /// Builds the navigation drawer.

  Widget _buildDrawer() {
    return SolidNavDrawer(
      userInfo: userInfo,
      tabs: tabs,
      selectedIndex: selectedIndex,
      onTabSelected: onTabSelected,
      onLogout: onLogout,
      logoutIcon: logoutIcon,
      logoutText: logoutText,
      showLogout: showLogout,
      additionalMenuItems: additionalDrawerItems,
      drawerShape: drawerShape,
    );
  }

  /// Builds the navigation bar.

  Widget _buildNavBar() {
    return SolidNavBar(
      tabs: tabs,
      selectedIndex: selectedIndex,
      onTabSelected: onTabSelected,
      onShowAlert: onShowAlert,
    );
  }

  /// Builds the main body content.

  Widget _buildBody(BuildContext context, ThemeData theme, bool isWideScreen) {
    return Column(
      children: [
        Divider(height: 1, color: theme.dividerColor),
        Expanded(
          child: isWideScreen
              ? Row(
                  children: [
                    _buildNavBar(),
                    VerticalDivider(color: theme.dividerColor),
                    Expanded(child: content),
                  ],
                )
              : content,
        ),
      ],
    );
  }

  /// Creates a navigation manager with MovieStar-specific defaults.

  static SolidNavigationManager movieStar({
    Key? key,
    SolidNavigationConfig? config,
    required List<SolidNavTab> tabs,
    required int selectedIndex,
    required void Function(int) onTabSelected,
    required Widget content,
    SolidNavUserInfo? userInfo,
    void Function(BuildContext)? onLogout,
    void Function(BuildContext, String, String?)? onShowAlert,
    PreferredSizeWidget? appBar,
    Color? backgroundColor,
    Widget? floatingActionButton,
    List<Widget>? additionalDrawerItems,
  }) {
    return SolidNavigationManager(
      key: key,
      config: config ?? const SolidNavigationConfig(),
      tabs: tabs,
      selectedIndex: selectedIndex,
      onTabSelected: onTabSelected,
      content: content,
      userInfo: userInfo,
      onLogout: onLogout,
      onShowAlert: onShowAlert,
      appBar: appBar,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      additionalDrawerItems: additionalDrawerItems,
    );
  }
}
