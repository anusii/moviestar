/// Service for validating API key status and configuration.
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

import 'package:moviestar/core/services/api/key_service.dart';

/// Result of API key validation.
class ApiKeyValidationResult {
  /// Whether an API key is configured.
  final bool isConfigured;

  /// Whether the configured API key is valid (if configured).
  final bool? isValid;

  /// Any error message from validation.
  final String? errorMessage;

  const ApiKeyValidationResult({
    required this.isConfigured,
    this.isValid,
    this.errorMessage,
  });

  /// Creates a result for when no API key is configured.
  static const ApiKeyValidationResult notConfigured = ApiKeyValidationResult(
    isConfigured: false,
  );

  /// Creates a result for a valid API key.
  static const ApiKeyValidationResult valid = ApiKeyValidationResult(
    isConfigured: true,
    isValid: true,
  );

  /// Creates a result for an invalid API key.
  static ApiKeyValidationResult invalid(String errorMessage) {
    return ApiKeyValidationResult(
      isConfigured: true,
      isValid: false,
      errorMessage: errorMessage,
    );
  }

  /// Creates a result for when validation couldn't be performed.
  static ApiKeyValidationResult unknown(String errorMessage) {
    return ApiKeyValidationResult(
      isConfigured: true,
      isValid: null,
      errorMessage: errorMessage,
    );
  }

  /// Whether the API key issue should be treated as the primary problem.
  bool get shouldShowApiKeyError {
    // Show API key error if:
    // 1. No API key is configured
    // 2. API key is configured but invalid
    return !isConfigured || (isValid == false);
  }

  /// Whether the API key status is unknown (couldn't validate).
  bool get isValidationUnknown => isConfigured && isValid == null;
}

/// Service for validating API key configuration and status.
class ApiKeyValidationService {
  final ApiKeyService? _apiKeyService;

  const ApiKeyValidationService(this._apiKeyService);

  /// Checks the current API key configuration and validity.
  Future<ApiKeyValidationResult> validateApiKey() async {
    try {
      if (_apiKeyService == null) {
        return ApiKeyValidationResult.unknown('API key service not available');
      }
      // First check if an API key is configured
      final apiKey = await _apiKeyService.getApiKey();

      if (apiKey == null || apiKey.trim().isEmpty) {
        return ApiKeyValidationResult.notConfigured;
      }

      // Basic format validation for TMDB API key
      if (!_isValidApiKeyFormat(apiKey)) {
        return ApiKeyValidationResult.invalid(
          'API key format appears invalid. TMDB API keys are typically 32 characters long.',
        );
      }

      // For now, assume the key is valid if it's properly formatted
      // In the future, this could be enhanced with actual API validation
      return ApiKeyValidationResult.valid;
    } catch (e) {
      return ApiKeyValidationResult.unknown(
        'Failed to validate API key: ${e.toString()}',
      );
    }
  }

  /// Quick check if API key is configured (no validation).
  Future<bool> hasApiKey() async {
    try {
      if (_apiKeyService == null) return false;
      final apiKey = await _apiKeyService.getApiKey();
      return apiKey != null && apiKey.trim().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Validates the basic format of a TMDB API key.
  bool _isValidApiKeyFormat(String apiKey) {
    // TMDB API keys are typically 32 character hexadecimal strings
    final apiKeyPattern = RegExp(r'^[a-fA-F0-9]{32}$');
    return apiKeyPattern.hasMatch(apiKey.trim());
  }

  /// Checks if the given error indicates an API key problem.
  static bool isApiKeyError(Object error) {
    final errorString = error.toString().toLowerCase();

    // Check for common API key error indicators
    return errorString.contains('api key') ||
        errorString.contains('unauthorized') ||
        errorString.contains('401') ||
        (errorString.contains('403') && errorString.contains('forbidden')) ||
        errorString.contains('invalid api key') ||
        errorString.contains('missing api key') ||
        errorString.contains('authentication') ||
        errorString.contains('access denied');
  }

  /// Provides user-friendly API key error messages.
  static String getApiKeyErrorMessage(Object error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'Your API key is unauthorized or invalid.';
    } else if (errorString.contains('403') ||
        errorString.contains('forbidden')) {
      return 'Access denied. Your API key may not have the required permissions.';
    } else if (errorString.contains('api key')) {
      return 'There is an issue with your API key configuration.';
    } else {
      return 'Authentication failed. Please check your API key.';
    }
  }
}
