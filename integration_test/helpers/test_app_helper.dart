/// Shared helper for initializing the app in integration tests.
///
/// Provides common app initialization logic including:
/// - SharedPreferences setup
/// - CacheSettingsService initialization
/// - Hive adapter registration
/// - ProviderScope with common overrides
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moviestar/core/services/cache/settings_service.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/moviestar.dart';
import 'package:moviestar/providers/theme_provider.dart';

/// Helper class for common app initialization in integration tests.

class TestAppHelper {
  /// Initialize app with all required Hive adapters and providers.
  ///
  /// [tester] - The WidgetTester instance from the test.
  /// [prefValues] - Optional initial SharedPreferences values.
  /// [settleDuration] - Duration to wait for app to settle (default 5 seconds).

  static Future<void> initializeApp(
    WidgetTester tester, {
    Map<String, Object>? prefValues,
    Duration settleDuration = const Duration(seconds: 5),
  }) async {
    // Set up SharedPreferences with test values.

    SharedPreferences.setMockInitialValues(prefValues ?? {});
    final prefs = await SharedPreferences.getInstance();

    // Initialize cache settings service.

    await CacheSettingsService.instance.initialize();

    // Initialize Hive with all required adapters.

    await initializeHive();

    // Pump the app with ProviderScope.

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MovieStar(),
      ),
    );

    // Wait for app to settle.

    await tester.pumpAndSettle(settleDuration);
  }

  /// Register all Hive adapters with idempotent checks.
  ///
  /// Safe to call multiple times - will skip already registered adapters.

  static Future<void> initializeHive() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MovieAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CustomListAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ContentItemAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ContentTypeAdapter());
    }
  }

  /// Standard teardown - close all Hive boxes.

  static Future<void> teardown() async {
    await Hive.close();
  }
}
