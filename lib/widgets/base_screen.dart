/// Base screen widget providing common functionality for all screens.
///
// Time-stamp: <Tuesday 2025-09-09 15:30:00 +1000 Claude>
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

import 'package:flutter/material.dart';

import 'package:moviestar/widgets/error_display_widget.dart';

/// Base screen widget that provides common functionality for all screens.
///
/// This widget eliminates boilerplate by providing:.
/// - Consistent Scaffold structure with themed AppBar.
/// - Built-in loading overlay functionality.
/// - Error display integration.
/// - RefreshIndicator support.
/// - Navigation safety.

class BaseScreen extends StatelessWidget {
  /// The title to display in the AppBar.

  final String? title;

  /// Custom title widget to display instead of text title.

  final Widget? titleWidget;

  /// The main body content of the screen.

  final Widget body;

  /// Whether to show a loading overlay.

  final bool isLoading;

  /// Custom loading widget to show instead of default CircularProgressIndicator.

  final Widget? loadingWidget;

  /// Error message to display if there's an error state.

  final String? error;

  /// Callback when error retry button is tapped.

  final VoidCallback? onErrorRetry;

  /// Whether to enable pull-to-refresh functionality.

  final bool enableRefresh;

  /// Callback when pull-to-refresh is triggered.

  final Future<void> Function()? onRefresh;

  /// Custom actions to show in the AppBar.

  final List<Widget>? actions;

  /// Custom leading widget for the AppBar.

  final Widget? leading;

  /// Whether to automatically add a back button if applicable.

  final bool automaticallyImplyLeading;

  /// Background color of the AppBar.

  final Color? appBarBackgroundColor;

  /// Foreground color of the AppBar.

  final Color? appBarForegroundColor;

  /// Elevation of the AppBar.

  final double? appBarElevation;

  /// Whether to show the AppBar.

  final bool showAppBar;

  /// Bottom widget for the AppBar.

  final PreferredSizeWidget? appBarBottom;

  /// Background color of the screen body.

  final Color? backgroundColor;

  /// Floating action button for the screen.

  final Widget? floatingActionButton;

  /// Bottom navigation bar or persistent bottom widget.

  final Widget? bottomNavigationBar;

  /// Drawer widget.

  final Widget? drawer;

  /// End drawer widget.

  final Widget? endDrawer;

  /// Creates a new [BaseScreen].

  const BaseScreen({
    super.key,
    this.title,
    this.titleWidget,
    required this.body,
    this.isLoading = false,
    this.loadingWidget,
    this.error,
    this.onErrorRetry,
    this.enableRefresh = false,
    this.onRefresh,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.appBarBackgroundColor,
    this.appBarForegroundColor,
    this.appBarElevation,
    this.showAppBar = true,
    this.appBarBottom,
    this.backgroundColor,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
  }) : assert(
          title != null || titleWidget != null || !showAppBar,
          'Either title or titleWidget must be provided when showAppBar is true',
        );

  @override
  Widget build(BuildContext context) {
    Widget content = body;

    // Wrap with error display if there's an error.

    if (error != null) {
      content = ErrorDisplayWidget(
        message: error!,
        onRetry: onErrorRetry,
      );
    } else {
      // Wrap with RefreshIndicator if enabled.

      if (enableRefresh && onRefresh != null) {
        content = RefreshIndicator(
          onRefresh: onRefresh!,
          child: content,
        );
      }
    }

    return Scaffold(
      appBar: showAppBar ? _buildAppBar(context) : null,
      body: Stack(
        children: [
          content,
          if (isLoading) _buildLoadingOverlay(context),
        ],
      ),
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
    );
  }

  /// Builds the AppBar with consistent theming.

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor:
          appBarBackgroundColor ?? Theme.of(context).colorScheme.surface,
      foregroundColor:
          appBarForegroundColor ?? Theme.of(context).colorScheme.onSurface,
      elevation: appBarElevation,
      bottom: appBarBottom,
    );
  }

  /// Builds the loading overlay.

  Widget _buildLoadingOverlay(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: loadingWidget ??
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

/// Convenient factory constructors for common screen patterns.

class BaseScreenFactory {
  /// Creates a BaseScreen with a search bar as the title.

  static BaseScreen withSearchBar({
    Key? key,
    required Widget body,
    required TextEditingController searchController,
    String hintText = 'Search...',
    required VoidCallback onClear,
    required ValueChanged<String> onChanged,
    required ValueChanged<String> onSubmitted,
    bool isLoading = false,
    String? error,
    VoidCallback? onErrorRetry,
    List<Widget>? actions,
    bool enableRefresh = false,
    Future<void> Function()? onRefresh,
  }) {
    return BaseScreen(
      key: key,
      titleWidget: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          final appBarTheme = theme.appBarTheme;

          // Use app bar's foreground color, falling back to onSurface.

          final textColor =
              appBarTheme.foregroundColor ?? colorScheme.onSurface;

          return TextField(
            controller: searchController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: textColor.withValues(alpha: 0.7),
              ),
              border: InputBorder.none,
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                      onPressed: onClear,
                    )
                  : null,
            ),
            onChanged: onChanged,
            onSubmitted: onSubmitted,
          );
        },
      ),
      body: body,
      isLoading: isLoading,
      error: error,
      onErrorRetry: onErrorRetry,
      actions: actions,
      enableRefresh: enableRefresh,
      onRefresh: onRefresh,
    );
  }

  /// Creates a BaseScreen with a settings-style layout.

  static BaseScreen forSettings({
    Key? key,
    String title = 'Settings',
    required Widget body,
    bool isLoading = false,
    String? error,
    VoidCallback? onErrorRetry,
    List<Widget>? actions,
  }) {
    return BaseScreen(
      key: key,
      title: title,
      body: body,
      isLoading: isLoading,
      error: error,
      onErrorRetry: onErrorRetry,
      actions: actions,
    );
  }
}
