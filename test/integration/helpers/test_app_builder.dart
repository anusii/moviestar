/// Test app builder utilities for integration testing.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moviestar/core/services/favorites/service.dart';

import 'mock_services.dart';

/// Builds a test app with necessary providers and configuration.
///
/// This function wraps your widget tree with ProviderScope and MaterialApp,
/// and optionally injects mock services for testing.
///
/// Example usage:
/// ```dart
/// await tester.pumpWidget(
///   buildTestApp(
///     home: MyTestScreen(),
///     favoritesService: MockFavoritesService(),
///   ),
/// );
/// ```

Widget buildTestApp({
  Widget? home,
  String? initialRoute,
  Map<String, WidgetBuilder>? routes,
  MockFavoritesService? favoritesService,
  MockMovieService? movieService,
  ThemeData? theme,
}) {
  return ProviderScope(
    overrides: const [],
    child: MaterialApp(
      theme: theme,
      home: home,
      initialRoute: initialRoute,
      routes: routes ?? {},
    ),
  );
}

/// Builds a test app wrapped in a Scaffold.
///
/// This is useful when you need ScaffoldMessenger for snackbars or
/// other Scaffold-dependent features.
///
/// Example usage:
/// ```dart
/// await tester.pumpWidget(
///   buildTestAppWithScaffold(
///     body: MyTestWidget(),
///   ),
/// );
/// ```

Widget buildTestAppWithScaffold({
  Widget? body,
  AppBar? appBar,
  MockFavoritesService? favoritesService,
  MockMovieService? movieService,
}) {
  return buildTestApp(
    favoritesService: favoritesService,
    movieService: movieService,
    home: Scaffold(
      appBar: appBar,
      body: body ?? Container(),
    ),
  );
}

/// Initializes SharedPreferences with mock values for testing.
///
/// Call this in setUpAll() or setUp() before using services that
/// depend on SharedPreferences.
///
/// Example usage:
/// ```dart
/// setUpAll(() async {
///   await initMockSharedPreferences();
/// });
/// ```

Future<void> initMockSharedPreferences([
  Map<String, Object>? initialValues,
]) async {
  SharedPreferences.setMockInitialValues(initialValues ?? {});
  await SharedPreferences.getInstance();
}

/// Creates a FavoritesService with mock SharedPreferences.
///
/// Useful when you need a real FavoritesService (not mock) but
/// don't want to set up actual storage.
///
/// Example usage:
/// ```dart
/// final service = await createTestFavoritesService();
/// ```

Future<FavoritesService> createTestFavoritesService([
  Map<String, Object>? initialValues,
]) async {
  SharedPreferences.setMockInitialValues(initialValues ?? {});
  final prefs = await SharedPreferences.getInstance();
  return FavoritesService(prefs);
}

/// Test app builder with navigation observer for tracking navigation events.
///
/// Useful for testing navigation flows and verifying navigation state.
///
/// Example usage:
/// ```dart
/// final observer = NavigationTestObserver();
/// await tester.pumpWidget(
///   buildTestAppWithNavigationObserver(
///     home: MyScreen(),
///     observer: observer,
///   ),
/// );
/// // Later: verify navigation events
/// expect(observer.pushedRoutes.length, equals(2));
/// ```

Widget buildTestAppWithNavigationObserver({
  required NavigatorObserver observer,
  Widget? home,
  String? initialRoute,
  Map<String, WidgetBuilder>? routes,
  MockFavoritesService? favoritesService,
  MockMovieService? movieService,
}) {
  return buildTestApp(
    home: home,
    initialRoute: initialRoute,
    routes: routes,
    favoritesService: favoritesService,
    movieService: movieService,
  );
}

/// Navigation observer for tracking navigation events in tests.
///
/// Tracks push and pop operations for verification in tests.

class NavigationTestObserver extends NavigatorObserver {
  /// Routes that were pushed.

  final List<Route<dynamic>> pushedRoutes = [];

  /// Routes that were popped.

  final List<Route<dynamic>> poppedRoutes = [];

  /// Number of routes currently in the stack.

  int get routeCount => pushedRoutes.length - poppedRoutes.length;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    poppedRoutes.add(route);
    super.didPop(route, previousRoute);
  }

  /// Resets all tracked navigation events.

  void reset() {
    pushedRoutes.clear();
    poppedRoutes.clear();
  }
}
