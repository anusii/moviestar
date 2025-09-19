/// URL handling operations for shared movie list data loading.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

/// Static helper class for URL handling operations.
class UrlHandlers {
  /// Extracts base URL from WebID for constructing resource URLs.
  static String? extractBaseUrlFromWebId(String webIdOrUsername) {
    if (webIdOrUsername.isEmpty) return null;

    try {
      // Case 1: Full WebID like: https://pods.dev.solidcommunity.au/my-moviestar/profile/card#me.
      if (webIdOrUsername.startsWith('http')) {
        final match = RegExp(
          r'(https?://[^/]+/[^/]+/)',
        ).firstMatch(webIdOrUsername);
        if (match != null) {
          return match.group(1);
        }
      }

      // Case 2: Simple username like: my-moviestar
      // Construct the base URL with the default provider.
      return 'https://pods.dev.solidcommunity.au/$webIdOrUsername/';
    } catch (e) {
      return null;
    }
  }

  /// Find individual file in shared resources by movie ID or filePath.
  static Future<String?> findIndividualFileInSharedResources(
    BuildContext context,
    StatefulWidget widget,
    String movieId,
    String? providedFilePath,
  ) async {
    try {
      // Get the shared resources to look for individual files
      final sharedResourcesResult = await sharedResources(context, widget);

      if (sharedResourcesResult == SolidFunctionCallStatus.notLoggedIn) {
        return null;
      }

      if (sharedResourcesResult is! Map) {
        return null;
      }

      // Look for individual movie files that match our movie ID
      for (final entry in sharedResourcesResult.entries) {
        final resourceUrl = entry.key as String;

        // Check if this is an individual movie file that matches our ID
        if (resourceUrl.contains('/movies/') && resourceUrl.endsWith('.ttl')) {
          // Check if the URL contains our movie ID
          if (resourceUrl.contains('Movie-$movieId.ttl') ||
              resourceUrl.contains('TVShow-$movieId.ttl')) {
            return resourceUrl;
          }

          // If we have a providedFilePath, also check for that
          if (providedFilePath != null &&
              resourceUrl.endsWith(providedFilePath)) {
            return resourceUrl;
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Generate list of URLs to try for fetching movie data.
  static List<String> generateUrlsToTry(
    String? ownerBaseUrl,
    String? sharerBaseUrl,
    String? providedFilePath,
    String movieId,
  ) {
    final urlsToTry = <String>[];

    if (providedFilePath != null) {
      // We have the exact filePath from the movie list, try both PODs
      if (ownerBaseUrl != null) {
        urlsToTry.add('${ownerBaseUrl}moviestar/data/movies/$providedFilePath');
      }
      if (sharerBaseUrl != null && sharerBaseUrl != ownerBaseUrl) {
        urlsToTry.add('${sharerBaseUrl}moviestar/data/movies/$providedFilePath');
      }
    } else {
      // Fall back to trying both patterns on both PODs
      final movieFileName = 'movies/Movie-$movieId.ttl';
      final tvShowFileName = 'movies/TVShow-$movieId.ttl';

      final baseUrlsToTry = <String>[];
      if (ownerBaseUrl != null) baseUrlsToTry.add(ownerBaseUrl);
      if (sharerBaseUrl != null && sharerBaseUrl != ownerBaseUrl) {
        baseUrlsToTry.add(sharerBaseUrl);
      }

      for (final baseUrl in baseUrlsToTry) {
        // Try Movie file first
        urlsToTry.add('${baseUrl}moviestar/data/$movieFileName');
        // Try TVShow file
        urlsToTry.add('${baseUrl}moviestar/data/$tvShowFileName');
      }
    }

    return urlsToTry;
  }

  /// Check if the provided file path indicates a TV show.
  static bool isTelevisionShow(String? providedFilePath, String resourceUrl) {
    return (providedFilePath?.startsWith('TVShow-') ?? false) ||
        resourceUrl.contains('TVShow-');
  }
}