/// Fetch operations for shared movie list data loading.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:solidpod/solidpod.dart';

import 'data_parser.dart';
import 'url_handlers.dart';

/// Static helper class for fetch operations.
class FetchOperations {
  /// Attempts to fetch individual movie file data to get ratings and comments.
  /// First tries to find the file in shared resources, then falls back to constructing URLs.
  static Future<Map<String, dynamic>> fetchIndividualMovieData(
    BuildContext context,
    StatefulWidget widget,
    String ownerWebId,
    String sharedByWebId,
    Map<String, dynamic> movieData,
  ) async {
    try {
      // If we already have rating and comments, return as-is.
      if (movieData['rating'] != null &&
          movieData['comments'] != null &&
          movieData['comments'].isNotEmpty) {
        return movieData;
      }

      // Construct the expected individual movie file path.
      final movieId = movieData['movieId']?.toString() ?? '';
      if (movieId.isEmpty) {
        return movieData;
      }

      // Check if we have filePath information from the movie list
      final providedFilePath = movieData['filePath'] as String?;

      // First, try to find the individual file in the shared resources
      String? actualSharedUrl =
          await UrlHandlers.findIndividualFileInSharedResources(
              context, widget, movieId, providedFilePath,);

      if (actualSharedUrl != null) {
        if (!context.mounted) return {};

        final movieFileContent = await readExternalPod(
          actualSharedUrl,
          context,
          widget,
        );

        if (!context.mounted) return {};

        if (movieFileContent != null &&
            movieFileContent != SolidFunctionCallStatus.notLoggedIn &&
            movieFileContent is String &&
            movieFileContent.isNotEmpty) {
          final isTvShow = UrlHandlers.isTelevisionShow(providedFilePath, actualSharedUrl);

          // Parse and return the enhanced data
          final parsedData = await DataParser.parseIndividualMovieData(movieFileContent);

          if (parsedData != null || isTvShow) {
            final enhancedData = Map<String, dynamic>.from(movieData);
            if (parsedData != null) {
              // Add user-specific data
              if (parsedData['title'] != null) {
                enhancedData['title'] = parsedData['title'];
                enhancedData['fileName'] = parsedData['title'];
              }
              if (parsedData['rating'] != null) {
                enhancedData['rating'] = parsedData['rating'];
              }
              if (parsedData['comments'] != null) {
                enhancedData['comments'] = parsedData['comments'];
              }

              // Add TMDB metadata if available
              if (parsedData['posterUrl'] != null) {
                enhancedData['posterUrl'] = parsedData['posterUrl'];
              }
              if (parsedData['backdropUrl'] != null) {
                enhancedData['backdropUrl'] = parsedData['backdropUrl'];
              }
              if (parsedData['overview'] != null) {
                enhancedData['overview'] = parsedData['overview'];
              }
              if (parsedData['releaseDate'] != null) {
                enhancedData['releaseDate'] = parsedData['releaseDate'];
              }
              if (parsedData['voteAverage'] != null) {
                enhancedData['voteAverage'] = parsedData['voteAverage'];
              }
              if (parsedData['genreIds'] != null) {
                enhancedData['genreIds'] = parsedData['genreIds'];
              }
            }

            enhancedData['content_type'] = isTvShow ? 'tv' : 'movie';
            return enhancedData;
          }
        }
      }

      // Fallback: try to construct URLs manually
      if (!context.mounted) return movieData;
      return await fetchIndividualMovieDataFallback(
        context,
        widget,
        ownerWebId,
        sharedByWebId,
        movieData,
      );
    } catch (e) {
      return movieData; // Return original data if fetching fails.
    }
  }

  /// Fallback method for fetching individual movie data using manual URL construction.
  static Future<Map<String, dynamic>> fetchIndividualMovieDataFallback(
    BuildContext context,
    StatefulWidget widget,
    String ownerWebId,
    String sharedByWebId,
    Map<String, dynamic> movieData,
  ) async {
    final movieId = movieData['movieId']?.toString() ?? '';
    final providedFilePath = movieData['filePath'] as String?;

    // We'll try both the owner's and sharer's PODs
    final ownerBaseUrl = UrlHandlers.extractBaseUrlFromWebId(ownerWebId);
    final sharerBaseUrl = UrlHandlers.extractBaseUrlFromWebId(sharedByWebId);

    if (ownerBaseUrl == null && sharerBaseUrl == null) {
      return movieData;
    }

    // Generate list of URLs to try
    final urlsToTry = UrlHandlers.generateUrlsToTry(
      ownerBaseUrl,
      sharerBaseUrl,
      providedFilePath,
      movieId,
    );

    // Try to read the individual file from the generated URLs
    dynamic movieFileContent;
    bool isTvShow = false;

    for (final resourceUrl in urlsToTry) {
      movieFileContent = await readExternalPod(
        resourceUrl,
        context,
        widget,
      );

      if (!context.mounted) return {};

      if (movieFileContent != null &&
          movieFileContent != SolidFunctionCallStatus.notLoggedIn &&
          movieFileContent is String &&
          movieFileContent.isNotEmpty) {
        isTvShow = UrlHandlers.isTelevisionShow(providedFilePath, resourceUrl);
        break; // Success, stop trying other URLs
      }
    }

    if (movieFileContent == null ||
        movieFileContent == SolidFunctionCallStatus.notLoggedIn ||
        movieFileContent is! String ||
        movieFileContent.isEmpty) {
      return movieData;
    }

    // Parse the movie/TV show file content to extract rating and comments.
    final parsedData = await DataParser.parseIndividualMovieData(movieFileContent);

    if (parsedData != null || isTvShow) {
      // Merge the parsed data with the original movie data.
      final enhancedData = Map<String, dynamic>.from(movieData);
      if (parsedData != null) {
        // Add user-specific data
        if (parsedData['title'] != null) {
          enhancedData['title'] = parsedData['title'];
          // Also update the fileName with the actual title
          enhancedData['fileName'] = parsedData['title'];
        }
        if (parsedData['rating'] != null) {
          enhancedData['rating'] = parsedData['rating'];
        }
        if (parsedData['comments'] != null) {
          enhancedData['comments'] = parsedData['comments'];
        }

        // Add TMDB metadata if available
        if (parsedData['posterUrl'] != null) {
          enhancedData['posterUrl'] = parsedData['posterUrl'];
        }
        if (parsedData['backdropUrl'] != null) {
          enhancedData['backdropUrl'] = parsedData['backdropUrl'];
        }
        if (parsedData['overview'] != null) {
          enhancedData['overview'] = parsedData['overview'];
        }
        if (parsedData['releaseDate'] != null) {
          enhancedData['releaseDate'] = parsedData['releaseDate'];
        }
        if (parsedData['voteAverage'] != null) {
          enhancedData['voteAverage'] = parsedData['voteAverage'];
        }
        if (parsedData['genreIds'] != null) {
          enhancedData['genreIds'] = parsedData['genreIds'];
        }
      }

      // Update content type and display name based on what we found
      if (isTvShow) {
        enhancedData['content_type'] = 'tv';
        // Update the fileName to reflect it's a TV show if not already set properly
        // But only if we don't have a real title
        if (parsedData?['title'] == null &&
            enhancedData['fileName'] == 'Movie $movieId') {
          enhancedData['fileName'] = 'TV Show $movieId';
        }
      } else {
        enhancedData['content_type'] = 'movie';
      }

      return enhancedData;
    }

    return movieData;
  }
}