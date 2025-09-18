/// Data loading operations for shared movie list detail screen.
/// Handles movie title loading, content fetching, and data parsing.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solidpod/solidpod.dart';

import 'package:moviestar/providers/cached_movie_service_provider.dart';

/// Handles data loading operations for shared movie list detail screen.
class SharedListDataLoader {
  final WidgetRef ref;
  final BuildContext context;
  final StatefulWidget widget;
  final String ownerWebId;
  final String sharedByWebId;

  SharedListDataLoader({
    required this.ref,
    required this.context,
    required this.widget,
    required this.ownerWebId,
    required this.sharedByWebId,
  });

  /// Load movie titles from TMDB API for all movies in the list.
  /// This will also detect and update content types.
  Future<Map<String, String>> loadMovieTitles(
    List<Map<String, dynamic>> movies,
  ) async {
    try {
      final cachedMovieService = ref.read(cachedMovieServiceProvider);
      final Map<String, String> titles = {};

      for (final movieData in movies) {
        final movieId =
            int.tryParse(movieData['movieId']?.toString() ?? '0') ?? 0;
        if (movieId > 0) {
          debugPrint('🔍 [LoadTitles] Loading title for movie ID: $movieId');
          debugPrint('   - Initial data: ${movieData['fileName']}');
          debugPrint(
            '   - FilePath: ${movieData['filePath'] ?? "not provided"}',
          );

          try {
            // First try to fetch enhanced data that includes content type detection and actual title
            final enhancedData = await fetchIndividualMovieData(movieData);
            final contentType = enhancedData['content_type'] ?? 'movie';

            // Check if we got an actual title from the TTL file
            String? actualTitle = extractTitleFromEnhancedData(enhancedData);

            debugPrint('   - Enhanced content type: $contentType');
            debugPrint('   - Extracted title: ${actualTitle ?? "not found"}');

            if (actualTitle != null) {
              // We have the actual title from the shared file
              titles[movieId.toString()] = actualTitle;
            } else if (contentType == 'tv') {
              // For TV shows without a parsed title, use a generic title since the cachedMovieService doesn't support TV shows yet
              titles[movieId.toString()] = 'TV Show $movieId';
            } else {
              // For movies without a parsed title, use the TMDB API
              final movie = await cachedMovieService.getMovieDetails(movieId);
              titles[movieId.toString()] = movie.title;
            }
          } catch (e) {
            debugPrint('Error fetching title for content $movieId: $e');
            // Use content type from enhanced data if available
            final enhancedData = await fetchIndividualMovieData(movieData);
            final contentType = enhancedData['content_type'] ?? 'movie';

            titles[movieId.toString()] = contentType == 'tv'
                ? 'TV Show $movieId'
                : 'Movie $movieId'; // Fallback
          }
        }
      }

      return titles;
    } catch (e) {
      debugPrint('Error loading content titles: $e');
      return {};
    }
  }

  /// Find individual file in shared resources by movie ID or filePath.
  Future<String?> findIndividualFileInSharedResources(
    String movieId,
    String? providedFilePath,
  ) async {
    try {
      // Get the shared resources to look for individual files
      final sharedResourcesResult = await sharedResources(context, widget);

      if (sharedResourcesResult == SolidFunctionCallStatus.notLoggedIn) {
        debugPrint('   ❌ Not logged in to check shared resources');
        return null;
      }

      if (sharedResourcesResult is! Map) {
        debugPrint('   ❌ Invalid shared resources data');
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
            debugPrint(
              '   🔍 Found matching individual file by ID: $resourceUrl',
            );
            return resourceUrl;
          }

          // If we have a providedFilePath, also check for that
          if (providedFilePath != null &&
              resourceUrl.endsWith(providedFilePath)) {
            debugPrint(
              '   🔍 Found matching individual file by filePath: $resourceUrl',
            );
            return resourceUrl;
          }
        }
      }

      debugPrint(
        '   ❌ No individual file found in shared resources for movie $movieId',
      );
      return null;
    } catch (e) {
      debugPrint('   ❌ Error searching shared resources: $e');
      return null;
    }
  }

  /// Extract title from enhanced movie data.
  String? extractTitleFromEnhancedData(Map<String, dynamic> enhancedData) {
    // Check if we have a title field in the enhanced data
    final title = enhancedData['title'] as String?;
    if (title != null && title.isNotEmpty) {
      return title;
    }
    return null;
  }

  /// Extracts base URL from WebID for constructing resource URLs.
  String? extractBaseUrlFromWebId(String webIdOrUsername) {
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
      // Case 2: Just username like: my-moviestar.
      // Need to construct the full URL - assume same POD service as current user.
      else {
        // For now, assume pods.dev.solidcommunity.au since that's what the logs show.
        final constructedUrl =
            'https://pods.dev.solidcommunity.au/$webIdOrUsername/';
        return constructedUrl;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error extracting base URL from WebID: $e');
      return null;
    }
  }

  /// Attempts to fetch individual movie file data to get ratings and comments.
  /// First tries to find the file in shared resources, then falls back to constructing URLs.
  Future<Map<String, dynamic>> fetchIndividualMovieData(
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
          await findIndividualFileInSharedResources(movieId, providedFilePath);

      if (actualSharedUrl != null) {
        debugPrint(
          '   - Found individual file in shared resources: $actualSharedUrl',
        );

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
          final isTvShow = actualSharedUrl.contains('TVShow-') ||
              (providedFilePath?.startsWith('TVShow-') ?? false);

          debugPrint(
            '   ✅ Successfully read shared individual file (${movieFileContent.length} chars)',
          );
          debugPrint('   - Detected as: ${isTvShow ? "TV Show" : "Movie"}');

          // Parse and return the enhanced data
          final parsedData = await parseIndividualMovieData(movieFileContent);

          if (parsedData != null || isTvShow) {
            final enhancedData = Map<String, dynamic>.from(movieData);
            if (parsedData != null) {
              // Add user-specific data
              if (parsedData['title'] != null) {
                enhancedData['title'] = parsedData['title'];
                enhancedData['fileName'] = parsedData['title'];
                debugPrint('   📝 Extracted title: "${parsedData['title']}"');
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
      return await _fetchIndividualMovieDataFallback(movieData);
    } catch (e) {
      debugPrint('❌ Error fetching individual movie data: $e');
      return movieData; // Return original data if fetching fails.
    }
  }

  /// Fallback method for fetching individual movie data using manual URL construction.
  Future<Map<String, dynamic>> _fetchIndividualMovieDataFallback(
    Map<String, dynamic> movieData,
  ) async {
    debugPrint('   - Falling back to manual URL construction...');

    final movieId = movieData['movieId']?.toString() ?? '';
    final providedFilePath = movieData['filePath'] as String?;

    // If we have a filePath from the movie list, use it directly
    // Otherwise, try both Movie and TVShow file patterns
    final movieFileName = 'movies/Movie-$movieId.ttl';
    final tvShowFileName = 'movies/TVShow-$movieId.ttl';

    // We'll try both the owner's and sharer's PODs
    final ownerBaseUrl = extractBaseUrlFromWebId(ownerWebId);
    final sharerBaseUrl = extractBaseUrlFromWebId(sharedByWebId);

    debugPrint('   - Owner base URL: $ownerBaseUrl');
    debugPrint('   - Sharer base URL: $sharerBaseUrl');

    if (ownerBaseUrl == null && sharerBaseUrl == null) {
      debugPrint('   ❌ Could not extract base URLs from WebIDs');
      return movieData;
    }

    // Try to read the individual file from the owner's POD.
    // Use provided filePath if available, otherwise try both Movie and TVShow patterns.
    dynamic movieFileContent;
    bool isTvShow = false;

    if (providedFilePath != null) {
      // We have the exact filePath from the movie list, try both PODs
      final urlsToTry = <String>[];

      if (ownerBaseUrl != null) {
        urlsToTry.add('${ownerBaseUrl}moviestar/data/movies/$providedFilePath');
      }
      if (sharerBaseUrl != null && sharerBaseUrl != ownerBaseUrl) {
        urlsToTry
            .add('${sharerBaseUrl}moviestar/data/movies/$providedFilePath');
      }

      for (final resourceUrl in urlsToTry) {
        debugPrint('   - Trying URL: $resourceUrl');

        movieFileContent = await readExternalPod(
          resourceUrl,
          context,
          widget,
        );

        if (movieFileContent != null &&
            movieFileContent != SolidFunctionCallStatus.notLoggedIn &&
            movieFileContent is String &&
            movieFileContent.isNotEmpty) {
          isTvShow = providedFilePath.startsWith('TVShow-');
          debugPrint(
            '   ✅ Successfully read file from $resourceUrl (${movieFileContent.length} chars)',
          );
          debugPrint('   - Detected as: ${isTvShow ? "TV Show" : "Movie"}');
          break; // Success, stop trying other URLs
        } else {
          debugPrint('   ❌ Failed to read file from $resourceUrl');
        }
      }
    } else {
      // Fall back to trying both patterns on both PODs
      debugPrint('   - Falling back to trying both Movie and TVShow patterns');

      final baseUrlsToTry = <String>[];
      if (ownerBaseUrl != null) baseUrlsToTry.add(ownerBaseUrl);
      if (sharerBaseUrl != null && sharerBaseUrl != ownerBaseUrl) {
        baseUrlsToTry.add(sharerBaseUrl);
      }

      for (final baseUrl in baseUrlsToTry) {
        // Try Movie file first
        final movieResourceUrl = '${baseUrl}moviestar/data/$movieFileName';
        debugPrint('   - Trying Movie pattern: $movieResourceUrl');

        movieFileContent = await readExternalPod(
          movieResourceUrl,
          context,
          widget,
        );

        if (!context.mounted) return {};

        if (movieFileContent != null &&
            movieFileContent != SolidFunctionCallStatus.notLoggedIn &&
            movieFileContent is String &&
            movieFileContent.isNotEmpty) {
          isTvShow = false;
          break;
        } else {
          debugPrint('   ❌ Movie file not found at $movieResourceUrl');

          // Try TVShow file
          final tvShowResourceUrl = '${baseUrl}moviestar/data/$tvShowFileName';
          debugPrint('   - Trying TVShow pattern: $tvShowResourceUrl');

          movieFileContent = await readExternalPod(
            tvShowResourceUrl,
            context,
            widget,
          );

          if (!context.mounted) return {};

          if (movieFileContent != null &&
              movieFileContent != SolidFunctionCallStatus.notLoggedIn &&
              movieFileContent is String &&
              movieFileContent.isNotEmpty) {
            isTvShow = true;
            break;
          } else {
            debugPrint('   ❌ TVShow file not found at $tvShowResourceUrl');
          }
        }
      }
    }

    if (movieFileContent == null ||
        movieFileContent == SolidFunctionCallStatus.notLoggedIn ||
        movieFileContent is! String ||
        movieFileContent.isEmpty) {
      return movieData;
    }

    // Parse the movie/TV show file content to extract rating and comments.
    debugPrint('   - Parsing TTL content to extract metadata...');
    final parsedData = await parseIndividualMovieData(movieFileContent);

    if (parsedData != null || isTvShow) {
      // Merge the parsed data with the original movie data.
      final enhancedData = Map<String, dynamic>.from(movieData);
      if (parsedData != null) {
        // Add user-specific data
        if (parsedData['title'] != null) {
          enhancedData['title'] = parsedData['title'];
          // Also update the fileName with the actual title
          enhancedData['fileName'] = parsedData['title'];
          debugPrint('   📝 Extracted title: "${parsedData['title']}"');
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

  /// Parses individual movie file content to extract title, rating and comments.
  Future<Map<String, dynamic>?> parseIndividualMovieData(
    String ttlContent,
  ) async {
    try {
      debugPrint('   🔬 [ParseTTL] Starting TTL content parsing...');

      double? rating;
      String? comments;
      String? title;

      // Try to parse JSON backup data first (more reliable)
      final movieJsonMatch = RegExp(
        r'# JSON_MOVIE_DATA: (.+)',
      ).firstMatch(ttlContent);

      Map<String, dynamic>? movieMetadata;
      if (movieJsonMatch != null) {
        debugPrint('   - Found JSON_MOVIE_DATA section');
        final movieJsonData = movieJsonMatch.group(1)!;
        movieMetadata = jsonDecode(movieJsonData) as Map<String, dynamic>;
        title = movieMetadata['title'] as String?;
        debugPrint('   - JSON title: "$title"');
        debugPrint(
          '   - JSON metadata available: ${movieMetadata.keys.toList()}',
        );
      } else {
        debugPrint('   - No JSON_MOVIE_DATA found, will try TTL parsing');
      }

      final userJsonMatch = RegExp(
        r'# JSON_USER_DATA: (.+)',
      ).firstMatch(ttlContent);

      if (userJsonMatch != null) {
        final userJsonData = userJsonMatch.group(1)!;
        final userData = jsonDecode(userJsonData) as Map<String, dynamic>;
        rating = userData['rating'] as double?;
        comments = userData['comment'] as String?;
      }

      // If no JSON backup, try TTL parsing (fallback).
      if (title == null || rating == null || comments == null) {
        final lines = ttlContent.split('\n');
        for (final line in lines) {
          final trimmedLine = line.trim();

          // Extract title.
          if (title == null &&
              (trimmedLine.contains('schema:name') ||
                  trimmedLine.contains('sdo:name') ||
                  trimmedLine.contains(':name'))) {
            final match = RegExp(r'"([^"]*)"').firstMatch(trimmedLine);
            if (match != null) {
              title = match.group(1);
              debugPrint('   - Found title in TTL: "$title"');
            }
          }

          // Extract rating.
          if (rating == null && trimmedLine.contains('schema:ratingValue')) {
            final match = RegExp(r'"?([0-9.]+)"?').firstMatch(trimmedLine);
            if (match != null) {
              rating = double.tryParse(match.group(1)!);
            }
          }

          // Extract comments.
          if (comments == null && trimmedLine.contains('schema:reviewBody')) {
            final match = RegExp(r'"([^"]*)"').firstMatch(trimmedLine);
            if (match != null) {
              comments = match.group(1);
            }
          }
        }
      }

      // Build comprehensive result with TMDB metadata if available
      final result = <String, dynamic>{};

      if (title != null) result['title'] = title;
      if (rating != null) result['rating'] = rating;
      if (comments != null && comments.isNotEmpty) {
        result['comments'] = comments;
      }

      // Include TMDB metadata from JSON backup if available
      if (movieMetadata != null) {
        // Add poster and backdrop URLs
        if (movieMetadata['poster_path'] != null) {
          result['posterUrl'] =
              'https://image.tmdb.org/t/p/w500${movieMetadata['poster_path']}';
        }
        if (movieMetadata['backdrop_path'] != null) {
          result['backdropUrl'] =
              'https://image.tmdb.org/t/p/w1280${movieMetadata['backdrop_path']}';
        }

        // Add other TMDB fields
        if (movieMetadata['overview'] != null) {
          result['overview'] = movieMetadata['overview'];
        }
        if (movieMetadata['release_date'] != null) {
          result['releaseDate'] = movieMetadata['release_date'];
        }
        if (movieMetadata['first_air_date'] != null) {
          result['releaseDate'] =
              movieMetadata['first_air_date']; // For TV shows
        }
        if (movieMetadata['vote_average'] != null) {
          result['voteAverage'] = movieMetadata['vote_average'];
        }
        if (movieMetadata['genre_ids'] != null) {
          result['genreIds'] = movieMetadata['genre_ids'];
        }

        debugPrint(
          '   - Added TMDB metadata: posterUrl=${result['posterUrl'] != null}, backdropUrl=${result['backdropUrl'] != null}, voteAverage=${result['voteAverage']}',
        );
      }

      if (result.isNotEmpty) {
        debugPrint(
          '   - Parse results: title="$title", rating=$rating, hasComments=${comments != null && comments.isNotEmpty}, tmdbFields=${result.keys.where(
                (k) => ![
                  'title',
                  'rating',
                  'comments',
                ].contains(k),
              ).toList()}',
        );
        return result;
      }

      debugPrint('   - No data extracted from TTL content');
      return null;
    } catch (e) {
      debugPrint('❌ Error parsing individual movie data: $e');
      return null;
    }
  }
}
