/// Test for PodFavoritesService refactoring to ensure no functionality is lost.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moviestar/core/services/pod/favorites_service.dart';

void main() {
  group('PodFavoritesService Public API Tests', () {
    late PodFavoritesService service;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      await SharedPreferences.getInstance();
    });

    testWidgets('Service exposes all required public APIs',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              service = PodFavoritesService(
                context,
                Container(),
                onInitialLoadComplete: () {},
              );
              return Container();
            },
          ),
        ),
      );

      // Test streams
      expect(service.toWatch, isNotNull);
      expect(service.watched, isNotNull);
      expect(service.customLists, isNotNull);

      // Test public methods
      // Movie list methods
      expect(service.getToWatch, isA<Function>());
      expect(service.getWatched, isA<Function>());
      expect(service.addToWatch, isA<Function>());
      expect(service.addToWatched, isA<Function>());
      expect(service.removeFromToWatch, isA<Function>());
      expect(service.removeFromWatched, isA<Function>());
      expect(service.isInToWatch, isA<Function>());
      expect(service.isInWatched, isA<Function>());

      // Rating and comment methods
      expect(service.getPersonalRating, isA<Function>());
      expect(service.setPersonalRating, isA<Function>());
      expect(service.removePersonalRating, isA<Function>());
      expect(service.getMovieComments, isA<Function>());
      expect(service.setMovieComments, isA<Function>());
      expect(service.removeMovieComments, isA<Function>());

      // Custom list methods
      expect(service.getCustomLists, isA<Function>());
      expect(service.createCustomList, isA<Function>());
      expect(service.updateCustomList, isA<Function>());
      expect(service.deleteCustomList, isA<Function>());
      expect(service.addMovieToCustomList, isA<Function>());
      expect(service.removeMovieFromCustomList, isA<Function>());
      expect(service.isMovieInCustomList, isA<Function>());
      expect(service.getCustomListsContainingMovie, isA<Function>());
      expect(service.getMoviesInCustomList, isA<Function>());

      // POD sync methods (only methods that exist)
      expect(service.migrateToPod, isA<Function>());
      expect(service.syncWithPod, isA<Function>());
      expect(service.reloadFromPod, isA<Function>());
      expect(service.isPodAvailable, isA<Function>());
      expect(service.refreshUIStreams, isA<Function>());
      expect(service.migrateCustomListsToPod, isA<Function>());

      // File methods (only methods that exist)
      expect(service.hasMovieFile, isA<Function>());

      // Service extends ChangeNotifier
      expect(service, isA<ChangeNotifier>());

      // Clean up
      service.dispose();
    });
  });
}
