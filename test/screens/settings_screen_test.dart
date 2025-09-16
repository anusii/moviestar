/// Tests for Settings Screen.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moviestar/screens/settings_screen.dart';
import 'package:moviestar/core/services/api/api_key_service.dart';
import 'package:moviestar/core/services/favorites/favorites_service.dart';
import 'package:moviestar/core/services/favorites/favorites_service_manager.dart';

// Simple test that verifies the SettingsScreen class can be instantiated
void main() {
  group('SettingsScreen Basic Tests', () {
    testWidgets('SettingsScreen class can be instantiated', (WidgetTester tester) async {
      // Create simple mock services
      final mockFavoritesService = MockFavoritesService();
      final mockApiKeyService = MockApiKeyService();
      final mockFavoritesServiceManager = MockFavoritesServiceManager();

      // Test that we can create the widget
      final settingsScreen = SettingsScreen(
        favoritesService: mockFavoritesService,
        apiKeyService: mockApiKeyService,
        favoritesServiceManager: mockFavoritesServiceManager,
      );

      // Verify the widget was created
      expect(settingsScreen, isA<SettingsScreen>());
      expect(settingsScreen.favoritesService, equals(mockFavoritesService));
      expect(settingsScreen.apiKeyService, equals(mockApiKeyService));
      expect(settingsScreen.favoritesServiceManager, equals(mockFavoritesServiceManager));
    });

    testWidgets('SettingsScreen handles constructor parameters', (WidgetTester tester) async {
      final mockFavoritesService = MockFavoritesService();
      final mockApiKeyService = MockApiKeyService();
      final mockFavoritesServiceManager = MockFavoritesServiceManager();

      // Test with fromApiKeyPrompt = true
      final settingsScreenFromPrompt = SettingsScreen(
        favoritesService: mockFavoritesService,
        apiKeyService: mockApiKeyService,
        favoritesServiceManager: mockFavoritesServiceManager,
        fromApiKeyPrompt: true,
      );

      expect(settingsScreenFromPrompt.fromApiKeyPrompt, isTrue);

      // Test with fromApiKeyPrompt = false (default)
      final settingsScreenDefault = SettingsScreen(
        favoritesService: mockFavoritesService,
        apiKeyService: mockApiKeyService,
        favoritesServiceManager: mockFavoritesServiceManager,
      );

      expect(settingsScreenDefault.fromApiKeyPrompt, isFalse);
    });

    testWidgets('SettingsScreen creates state correctly', (WidgetTester tester) async {
      final mockFavoritesService = MockFavoritesService();
      final mockApiKeyService = MockApiKeyService();
      final mockFavoritesServiceManager = MockFavoritesServiceManager();

      final settingsScreen = SettingsScreen(
        favoritesService: mockFavoritesService,
        apiKeyService: mockApiKeyService,
        favoritesServiceManager: mockFavoritesServiceManager,
      );

      // Test that createState returns the correct state type
      final state = settingsScreen.createState();
      expect(state, isNotNull);
      expect(state.runtimeType.toString(), contains('SettingsScreenState'));
    });

    testWidgets('SettingsScreen handles different service combinations', (WidgetTester tester) async {
      final mockFavoritesService1 = MockFavoritesService();
      final mockApiKeyService1 = MockApiKeyService();
      final mockFavoritesServiceManager1 = MockFavoritesServiceManager();

      final mockFavoritesService2 = MockFavoritesService();
      final mockApiKeyService2 = MockApiKeyService();
      final mockFavoritesServiceManager2 = MockFavoritesServiceManager();

      // Test with different service instances
      final settingsScreen1 = SettingsScreen(
        favoritesService: mockFavoritesService1,
        apiKeyService: mockApiKeyService1,
        favoritesServiceManager: mockFavoritesServiceManager1,
      );

      final settingsScreen2 = SettingsScreen(
        favoritesService: mockFavoritesService2,
        apiKeyService: mockApiKeyService2,
        favoritesServiceManager: mockFavoritesServiceManager2,
      );

      expect(settingsScreen1.favoritesService, isNot(equals(settingsScreen2.favoritesService)));
      expect(settingsScreen1.apiKeyService, isNot(equals(settingsScreen2.apiKeyService)));
      expect(settingsScreen1.favoritesServiceManager, isNot(equals(settingsScreen2.favoritesServiceManager)));
    });

    testWidgets('SettingsScreen key parameter works', (WidgetTester tester) async {
      final mockFavoritesService = MockFavoritesService();
      final mockApiKeyService = MockApiKeyService();
      final mockFavoritesServiceManager = MockFavoritesServiceManager();

      const testKey = Key('test-settings-screen');

      final settingsScreen = SettingsScreen(
        key: testKey,
        favoritesService: mockFavoritesService,
        apiKeyService: mockApiKeyService,
        favoritesServiceManager: mockFavoritesServiceManager,
      );

      expect(settingsScreen.key, equals(testKey));
    });
  });

  group('SettingsScreen Widget Properties', () {
    testWidgets('SettingsScreen has correct widget type', (WidgetTester tester) async {
      final mockFavoritesService = MockFavoritesService();
      final mockApiKeyService = MockApiKeyService();
      final mockFavoritesServiceManager = MockFavoritesServiceManager();

      final settingsScreen = SettingsScreen(
        favoritesService: mockFavoritesService,
        apiKeyService: mockApiKeyService,
        favoritesServiceManager: mockFavoritesServiceManager,
      );

      expect(settingsScreen, isA<Widget>());
      expect(settingsScreen, isA<StatefulWidget>());
    });

    testWidgets('SettingsScreen maintains service references', (WidgetTester tester) async {
      final mockFavoritesService = MockFavoritesService();
      final mockApiKeyService = MockApiKeyService();
      final mockFavoritesServiceManager = MockFavoritesServiceManager();

      final settingsScreen = SettingsScreen(
        favoritesService: mockFavoritesService,
        apiKeyService: mockApiKeyService,
        favoritesServiceManager: mockFavoritesServiceManager,
        fromApiKeyPrompt: true,
      );

      // Verify all properties are accessible and correct
      expect(settingsScreen.favoritesService, isNotNull);
      expect(settingsScreen.apiKeyService, isNotNull);
      expect(settingsScreen.favoritesServiceManager, isNotNull);
      expect(settingsScreen.fromApiKeyPrompt, isTrue);
    });
  });
}

// Simple mock services that don't implement complex interfaces
class MockFavoritesService implements FavoritesService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockApiKeyService implements ApiKeyService {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockFavoritesServiceManager implements FavoritesServiceManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}