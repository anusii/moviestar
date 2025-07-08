/// Service for managing API keys in the Movie Star application.
///
// Time-stamp: <Thursday 2025-04-10 11:47:48 +1000 Graham Williams>
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
/// Authors: Kevin Wang

library;

import 'package:flutter/foundation.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiKeyService extends ChangeNotifier {
  static const String _apiKeySecureKey = 'movie_db_api_key';
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: const AndroidOptions(),
    iOptions: const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: const MacOsOptions(
      synchronizable: false,
    ),
  );

  ApiKeyService();

  Future<String?> getApiKey() async {
    try {
      return await _secureStorage.read(key: _apiKeySecureKey);
    } catch (e) {
      debugPrint('Error reading API key from secure storage: $e');
      return null;
    }
  }

  Future<void> setApiKey(String apiKey) async {
    try {
      await _secureStorage.write(key: _apiKeySecureKey, value: apiKey);
      notifyListeners();
    } catch (e) {
      debugPrint('Error writing API key to secure storage: $e');
      rethrow;
    }
  }

  Future<void> clearApiKey() async {
    try {
      await _secureStorage.delete(key: _apiKeySecureKey);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting API key from secure storage: $e');
      rethrow;
    }
  }
}
