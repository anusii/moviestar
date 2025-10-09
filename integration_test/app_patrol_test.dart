/// Basic Patrol E2E test for Movie Star application.
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
/// Authors: Ashley Tang.
///
/// NOTE: This test uses Patrol's patrolTest() which requires running with:
/// `patrol test` command on mobile/desktop devices, NOT `flutter test`.
///
/// To run this test:
/// - Android: `patrol test -t integration_test/app_patrol_test.dart`
/// - iOS: `patrol test -t integration_test/app_patrol_test.dart`
///
/// For development/CI on Windows/Web, use standard integration_test instead.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:patrol/patrol.dart';

import 'package:moviestar/moviestar.dart';

void main() {
  patrolTest(
    'app loads and shows home screen',
    ($) async {
      // Pump the full app widget tree
      await $.pumpWidgetAndSettle(
        const ProviderScope(
          child: MovieStar(),
        ),
      );

      // Verify app loaded successfully
      // Basic smoke test - just ensure the app builds without errors
      // Adjust this based on actual home screen elements
      expect($('Movie Star').visible, isTrue);
    },
  );
}
