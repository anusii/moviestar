/// Data fetching utilities for shared movies screen.
/// Extracted from SharedMoviesScreen to reduce file size.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'package:moviestar/screens/shared_movies/data_parser.dart';

/// Handles data fetching for shared movies screen.

class SharedMoviesDataFetcher {
  /// Fetch movies and movie lists that others have shared with me.

  static Future<Map<String, dynamic>?> getMoviesSharedWithMe(
    BuildContext context,
  ) async {
    // Store context locally to avoid async gap issues.

    final localContext = context;
    try {
      // Get shared resources from POD.

      final sharedResourcesResult = await sharedResources();

      if (sharedResourcesResult is! Map) {
        return null;
      }

      final Map<String, dynamic> movieData = {};
      final Map<String, dynamic> movieListData = {};

      // Filter for movie files and movie list files, then fetch their content.

      for (final entry in sharedResourcesResult.entries) {
        final resourceUrl = entry.key as String;
        final resourceInfo = entry.value as Map;

        try {
          // Check if this is a movie file.

          if (resourceUrl.contains('/movies/') &&
              resourceUrl.endsWith('.ttl')) {
            // Check if context is still valid.

            if (!localContext.mounted) continue;

            // Read the movie file content.

            final movieContent = await readExternalPod(resourceUrl);

            // Parse the movie data from TTL content.

            final movieInfo = await SharedMoviesDataParser.parseMovieData(
              movieContent,
              resourceUrl,
              resourceInfo,
            );
            if (movieInfo != null) {
              movieData[resourceUrl] = movieInfo;
            }
          }
          // Check if this is a movie list file.

          else if (resourceUrl.contains('user_lists/MovieList-') &&
              resourceUrl.endsWith('.ttl')) {
            // Check if context is still valid.

            if (!localContext.mounted) continue;

            // Read the movie list file content.

            final listContent = await readExternalPod(resourceUrl);

            // Parse the movie list data from TTL content.

            final listInfo = await SharedMoviesDataParser.parseMovieListData(
              listContent,
              resourceUrl,
              resourceInfo,
            );
            if (listInfo != null) {
              movieListData[resourceUrl] = listInfo;
            }
          }
        } catch (e) {
          // Skip this resource and continue with others.

          continue;
        }
      }

      // Combine movie data and movie list data.

      final combinedData = <String, dynamic>{};
      if (movieData.isNotEmpty) {
        combinedData['movies'] = movieData;
      }
      if (movieListData.isNotEmpty) {
        combinedData['movieLists'] = movieListData;
      }

      return combinedData.isNotEmpty ? combinedData : null;
    } catch (e) {
      return null;
    }
  }
}
