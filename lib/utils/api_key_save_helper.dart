/// Helper function for saving API keys with proper provider invalidation.
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
/// Authors: Ashley Tang, Kevin Wang

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moviestar/core/services/api/key_service.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';

/// Saves an API key and properly invalidates all dependent providers.
///
/// This function should be used by both the API key dialog and the settings
/// panel to ensure consistent behavior when saving API keys.
///
/// Parameters:
/// - [apiKeyService]: The API key service to save the key to
/// - [apiKey]: The API key to save
/// - [ref]: The Riverpod WidgetRef for provider invalidation
/// - [mounted]: Callback to check if the widget is still mounted
///
/// Returns true if the save was successful, false otherwise.

Future<bool> saveApiKeyWithProviderInvalidation({
  required ApiKeyService apiKeyService,
  required String apiKey,
  required WidgetRef ref,
  required bool Function() mounted,
}) async {
  try {
    // Save the API key to storage.

    await apiKeyService.setApiKey(apiKey);

    if (!mounted()) return false;

    // Invalidate providers in correct order for immediate effect.
    // IMPORTANT: Invalidate core providers first, then dependent ones.

    ref.invalidate(directApiKeyProvider);
    ref.invalidate(apiKeyProvider);

    // Allow time for core providers to refresh.

    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted()) return false;

    // Clear cache to force fresh data with new API key.

    try {
      final cachedService = ref.read(configuredCachedMovieServiceProvider);
      await cachedService.clearAllCache();
    } catch (e) {
      // Log but don't fail - provider invalidation will still work.
    }

    // Now invalidate all dependent movie providers.

    ref.invalidate(movieServiceProvider);
    ref.invalidate(contentServiceProvider);
    ref.invalidate(recommendedMoviesWithCacheInfoProvider);
    ref.invalidate(nowPlayingMoviesWithCacheInfoProvider);
    ref.invalidate(topRatedMoviesWithCacheInfoProvider);
    ref.invalidate(upcomingMoviesWithCacheInfoProvider);
    ref.invalidate(configuredCachedMovieServiceProvider);

    // Give providers time to refresh for immediate UI update.

    await Future.delayed(const Duration(milliseconds: 150));

    return mounted();
  } catch (e) {
    debugPrint('Error saving API key: $e');
    return false;
  }
}

/// Shows a success message after saving the API key.

void showApiKeySaveSuccessMessage(
  BuildContext context, {
  required bool isEmpty,
}) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEmpty
              ? 'API key cleared - movie data will no longer load'
              : 'API key saved successfully',
        ),
        backgroundColor: isEmpty ? Colors.orange : Colors.green,
      ),
    );
  }
}

/// Shows an error message if saving the API key failed.

void showApiKeySaveErrorMessage(
  BuildContext context,
  String error,
) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to save API key: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
