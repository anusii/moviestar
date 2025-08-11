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

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for managing security keys used for encrypting movie data.

class SecurityKeyService extends ChangeNotifier {
  static const String _securityKeySecureKey = 'movie_security_key';
  static const String _securityKeyStatusKey = 'movie_security_key_status';
  
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: const AndroidOptions(),
    iOptions: const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    mOptions: const MacOsOptions(
      synchronizable: false,
    ),
  );

  SecurityKeyService();

  /// Gets the current security key from secure storage.
  
  Future<String?> getSecurityKey() async {
    try {
      return await _secureStorage.read(key: _securityKeySecureKey);
    } catch (e) {
      debugPrint('Error reading security key from secure storage: $e');
      return null;
    }
  }

  /// Sets a new security key in secure storage.
  
  Future<void> setSecurityKey(String securityKey) async {
    try {
      await _secureStorage.write(key: _securityKeySecureKey, value: securityKey);
      await _secureStorage.write(key: _securityKeyStatusKey, value: 'saved');
      notifyListeners();
    } catch (e) {
      debugPrint('Error writing security key to secure storage: $e');
      rethrow;
    }
  }

  /// Removes the security key from secure storage.
  
  Future<void> clearSecurityKey() async {
    try {
      await _secureStorage.delete(key: _securityKeySecureKey);
      await _secureStorage.delete(key: _securityKeyStatusKey);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting security key from secure storage: $e');
      rethrow;
    }
  }

  /// Checks if a security key is currently saved.
  
  Future<bool> isKeySaved() async {
    try {
      final key = await _secureStorage.read(key: _securityKeySecureKey);
      final status = await _secureStorage.read(key: _securityKeyStatusKey);
      return key != null && key.isNotEmpty && status == 'saved';
    } catch (e) {
      debugPrint('Error checking security key status: $e');
      return false;
    }
  }

  /// Generates a new random security key.
  
  Future<String> generateSecurityKey() async {
    // Generate a secure random key (for demonstration)
    // In a real app, this would use proper cryptographic key generation
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.toString();
    return 'moviestar_key_$random';
  }

  /// Validates if a security key format is correct.
  
  bool isValidSecurityKey(String key) {
    // Basic validation.

    return key.isNotEmpty && key.length >= 8;
  }
}
