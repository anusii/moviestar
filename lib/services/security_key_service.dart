/// Service for managing security keys in the Movie Star application.
///
// Time-stamp: <Monday 2025-08-11 16:30:00 +1000 Tony Chen>
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

import 'package:flutter/foundation.dart';

import 'package:solidpod/solidpod.dart' show KeyManager;

/// Service for managing security keys used for POD encryption in MovieStar.

class SecurityKeyService extends ChangeNotifier {
  SecurityKeyService();

  /// Checks if a security key is currently saved.
  
  Future<bool> isKeySaved() async {
    try {
      return await KeyManager.hasSecurityKey();
    } catch (e) {
      debugPrint('Error checking security key status: $e');
      return false;
    }
  }

  /// Fetches the security key status and optionally triggers a callback.
  
  Future<bool> fetchKeySavedStatus([Function(bool)? onKeyStatusChanged]) async {
    try {
      final hasKey = await KeyManager.hasSecurityKey();
      
      if (onKeyStatusChanged != null) {
        onKeyStatusChanged(hasKey);
      }
      
      // Notify listeners of status change.

      notifyListeners();
      
      return hasKey;
    } catch (e) {
      debugPrint('Error fetching security key status: $e');
      return false;
    }
  }

  /// Forces a refresh of the security key status.
  
  Future<void> refreshKeyStatus() async {
    await fetchKeySavedStatus();
  }
}
