/// Shared Movie List Detail Screen for MovieStar.
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
/// Authors: Ashley Tang

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solidpod/solidpod.dart';

import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/services/favorites_service_adapter.dart';
import 'package:moviestar/services/favorites_service_manager.dart';
import 'package:moviestar/widgets/base_screen.dart';

/// Screen to display movies within a shared movie list.
///
/// Shows the list metadata and all movies within the shared list,
/// allowing users to view individual movie details.

class SharedMovieListDetailScreen extends ConsumerStatefulWidget {
  final String listName;
  final String listDescription;
  final String owner;
  final String ownerWebId;
  final String sharedBy;
  final String sharedByWebId;
  final List<Map<String, dynamic>> movies;
  final String permissions;

  const SharedMovieListDetailScreen({
    super.key,
    required this.listName,
    required this.listDescription,
    required this.owner,
    required this.ownerWebId,
    required this.sharedBy,
    required this.sharedByWebId,
    required this.movies,
    required this.permissions,
  });

  @override
  ConsumerState<SharedMovieListDetailScreen> createState() =>
      _SharedMovieListDetailScreenState();
}

class _SharedMovieListDetailScreenState
    extends ConsumerState<SharedMovieListDetailScreen> with ScreenStateMixin {
  Map<String, String> _movieTitles = {}; // Cache for movie titles.
  bool _loadingTitles = true;

  @override
  void initState() {
    super.initState();
    _loadMovieTitles();
  }

  /// Load movie titles from TMDB API for all movies in the list.
  /// This will also detect and update content types.

  Future<void> _loadMovieTitles() async {
    try {
      final cachedMovieService = ref.read(cachedMovieServiceProvider);
      final Map<String, String> titles = {};

      for (final movieData in widget.movies) {
        final movieId =
            int.tryParse(movieData['movieId']?.toString() ?? '0') ?? 0;
        if (movieId > 0) {
          debugPrint('🔍 [LoadTitles] Loading title for movie ID: $movieId');
          debugPrint('   - Initial data: ${movieData['fileName']}');
          debugPrint('   - FilePath: ${movieData['filePath'] ?? "not provided"}');

          try {
            // First try to fetch enhanced data that includes content type detection and actual title
            final enhancedData = await _fetchIndividualMovieData(movieData);
            final contentType = enhancedData['content_type'] ?? 'movie';

            // Check if we got an actual title from the TTL file
            String? actualTitle = await _extractTitleFromEnhancedData(enhancedData);

            debugPrint('   - Enhanced content type: $contentType');
            debugPrint('   - Extracted title: ${actualTitle ?? "not found"}');

            if (actualTitle != null) {
              // We have the actual title from the shared file
              titles[movieId.toString()] = actualTitle;
              debugPrint('   ✅ Using actual title: $actualTitle');
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
            final enhancedData = await _fetchIndividualMovieData(movieData);
            final contentType = enhancedData['content_type'] ?? 'movie';

            titles[movieId.toString()] = contentType == 'tv'
                ? 'TV Show $movieId'
                : 'Movie $movieId'; // Fallback
          }
        }
      }

      if (mounted) {
        safeSetState(() {
          _movieTitles = titles;
          _loadingTitles = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading content titles: $e');
      if (mounted) {
        safeSetState(() {
          _loadingTitles = false;
        });
      }
    }
  }

  // Find individual file in shared resources by movie ID or filePath.

  Future<String?> _findIndividualFileInSharedResources(String movieId, String? providedFilePath) async {
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
          if (resourceUrl.contains('Movie-$movieId.ttl') || resourceUrl.contains('TVShow-$movieId.ttl')) {
            debugPrint('   🔍 Found matching individual file by ID: $resourceUrl');
            return resourceUrl;
          }

          // If we have a providedFilePath, also check for that
          if (providedFilePath != null && resourceUrl.endsWith(providedFilePath)) {
            debugPrint('   🔍 Found matching individual file by filePath: $resourceUrl');
            return resourceUrl;
          }
        }
      }

      debugPrint('   ❌ No individual file found in shared resources for movie $movieId');
      return null;
    } catch (e) {
      debugPrint('   ❌ Error searching shared resources: $e');
      return null;
    }
  }

  // Extract title from enhanced movie data.

  Future<String?> _extractTitleFromEnhancedData(
    Map<String, dynamic> enhancedData,
  ) async {
    // Check if we have a title field in the enhanced data
    final title = enhancedData['title'] as String?;
    if (title != null && title.isNotEmpty) {
      return title;
    }
    return null;
  }

  // Extract owner name from WebID.

  String _getOwnerName(String webId) {
    if (webId.isEmpty) return 'Unknown';

    try {
      // For WebIDs like: https://pods.dev.solidcommunity.au/my-moviestar/profile/card#me.

      final match = RegExp(r'://[^/]+/([^/]+)/').firstMatch(webId);
      if (match != null) {
        final username = match.group(1) ?? 'Unknown';
        return username.replaceAll('-', ' ');
      }

      // If it doesn't match the expected pattern, return the full WebID.

      return webId.length > 30 ? '${webId.substring(0, 30)}...' : webId;
    } catch (e) {
      return webId.length > 30 ? '${webId.substring(0, 30)}...' : webId;
    }
  }

  // Extracts base URL from WebID for constructing resource URLs.

  String? _extractBaseUrlFromWebId(String webIdOrUsername) {
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

  // Build rating display.

  Widget _buildRatingDisplay(dynamic rating) {
    if (rating == null) return const SizedBox.shrink();

    final ratingValue =
        rating is double ? rating : double.tryParse(rating.toString()) ?? 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 16),
        const SizedBox(width: 4),
        Text(
          ratingValue.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }

  Future<void> _navigateToMovieDetails(Map<String, dynamic> movieData) async {
    try {
      final movieId =
          int.tryParse(movieData['movieId']?.toString() ?? '0') ?? 0;

      if (movieId == 0) {
        throw Exception('Invalid movie ID');
      }

      // Show loading indicator.

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Fetch full movie details from TMDB API.

      final cachedMovieService = ref.read(cachedMovieServiceProvider);
      final movie = await cachedMovieService.getMovieDetails(movieId);

      // Try to fetch individual movie file data to get ratings and comments.

      final enhancedMovieData = await _fetchIndividualMovieData(movieData);

      // Dismiss loading indicator.

      if (mounted) {
        Navigator.pop(context);
      }

      // Get SharedPreferences and create FavoritesServiceManager.

      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      final favoritesServiceManager = FavoritesServiceManager(
        prefs,
        context,
        widget,
      );
      final favoritesService = FavoritesServiceAdapter(favoritesServiceManager);

      // Navigate to MovieDetailsScreen with enhanced shared movie data.

      if (mounted) {
        await safeNavigateTo(
          MaterialPageRoute(
            builder: (context) => MovieDetailsScreen(
              movie: movie,
              favoritesService: favoritesService,
              sharedMovieData: enhancedMovieData,
            ),
          ),
        );
      }
    } catch (e) {
      // Dismiss loading indicator if it's showing.

      if (mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).popUntil((route) => route.isFirst);
      }

      debugPrint('Error navigating to movie details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading movie details: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // Attempts to fetch individual movie file data to get ratings and comments.
  // First tries to find the file in shared resources, then falls back to constructing URLs.

  Future<Map<String, dynamic>> _fetchIndividualMovieData(
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

      final ownerWebId = widget.ownerWebId;
      final sharedByWebId = widget.sharedByWebId;

      // Check if we have filePath information from the movie list
      final providedFilePath = movieData['filePath'] as String?;

      debugPrint('📂 [FetchIndividual] Fetching data for movie $movieId');
      debugPrint('   - Provided filePath: ${providedFilePath ?? "none"}');
      debugPrint('   - Owner WebId: $ownerWebId');
      debugPrint('   - SharedBy WebId: $sharedByWebId');

      // First, try to find the individual file in the shared resources
      String? actualSharedUrl = await _findIndividualFileInSharedResources(movieId, providedFilePath);

      if (actualSharedUrl != null) {
        debugPrint('   - Found individual file in shared resources: $actualSharedUrl');

        if (!mounted) return movieData;

        final movieFileContent = await readExternalPod(
          actualSharedUrl,
          context,
          widget,
        );

        if (movieFileContent != null &&
            movieFileContent != SolidFunctionCallStatus.notLoggedIn &&
            movieFileContent is String &&
            movieFileContent.isNotEmpty) {

          final isTvShow = actualSharedUrl.contains('TVShow-') || (providedFilePath?.startsWith('TVShow-') ?? false);

          debugPrint('   ✅ Successfully read shared individual file (${movieFileContent.length} chars)');
          debugPrint('   - Detected as: ${isTvShow ? "TV Show" : "Movie"}');

          // Parse and return the enhanced data
          final parsedData = await _parseIndividualMovieData(movieFileContent);

          if (parsedData != null || isTvShow) {
            final enhancedData = Map<String, dynamic>.from(movieData);
            if (parsedData != null) {
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
            }

            enhancedData['content_type'] = isTvShow ? 'tv' : 'movie';
            return enhancedData;
          }
        }
      }

      // Fallback: try to construct URLs manually (existing logic)
      debugPrint('   - Falling back to manual URL construction...');

      // If we have a filePath from the movie list, use it directly
      // Otherwise, try both Movie and TVShow file patterns
      final movieFileName = 'movies/Movie-$movieId.ttl';
      final tvShowFileName = 'movies/TVShow-$movieId.ttl';

      // We'll try both the owner's and sharer's PODs
      final ownerBaseUrl = _extractBaseUrlFromWebId(ownerWebId);
      final sharerBaseUrl = _extractBaseUrlFromWebId(sharedByWebId);

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
          urlsToTry.add('${sharerBaseUrl}moviestar/data/movies/$providedFilePath');
        }

        for (final resourceUrl in urlsToTry) {
          debugPrint('   - Trying URL: $resourceUrl');

          if (!mounted) return movieData;

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
            debugPrint('   ✅ Successfully read file from $resourceUrl (${movieFileContent.length} chars)');
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
          if (!mounted) return movieData;

          // Try Movie file first
          final movieResourceUrl = '${baseUrl}moviestar/data/$movieFileName';
          debugPrint('   - Trying Movie pattern: $movieResourceUrl');

          movieFileContent = await readExternalPod(
            movieResourceUrl,
            context,
            widget,
          );

          if (movieFileContent != null &&
              movieFileContent != SolidFunctionCallStatus.notLoggedIn &&
              movieFileContent is String &&
              movieFileContent.isNotEmpty) {
            isTvShow = false;
            debugPrint('   ✅ Found Movie file at $movieResourceUrl');
            break;
          } else {
            debugPrint('   ❌ Movie file not found at $movieResourceUrl');

            // Try TVShow file
            final tvShowResourceUrl = '${baseUrl}moviestar/data/$tvShowFileName';
            debugPrint('   - Trying TVShow pattern: $tvShowResourceUrl');

            if (!mounted) return movieData;

            movieFileContent = await readExternalPod(
              tvShowResourceUrl,
              context,
              widget,
            );

            if (movieFileContent != null &&
                movieFileContent != SolidFunctionCallStatus.notLoggedIn &&
                movieFileContent is String &&
                movieFileContent.isNotEmpty) {
              isTvShow = true;
              debugPrint('   ✅ Found TVShow file at $tvShowResourceUrl');
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
      final parsedData = await _parseIndividualMovieData(movieFileContent);

      if (parsedData != null || isTvShow) {
        // Merge the parsed data with the original movie data.

        final enhancedData = Map<String, dynamic>.from(movieData);
        if (parsedData != null) {
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
        }

        // Update content type and display name based on what we found
        if (isTvShow) {
          enhancedData['content_type'] = 'tv';
          // Update the fileName to reflect it's a TV show if not already set properly
          // But only if we don't have a real title
          if (parsedData?['title'] == null && enhancedData['fileName'] == 'Movie $movieId') {
            enhancedData['fileName'] = 'TV Show $movieId';
          }
        } else {
          enhancedData['content_type'] = 'movie';
        }

        return enhancedData;
      }

      return movieData;
    } catch (e) {
      debugPrint('❌ Error fetching individual movie data: $e');
      return movieData; // Return original data if fetching fails.
    }
  }

  // Parses individual movie file content to extract title, rating and comments.

  Future<Map<String, dynamic>?> _parseIndividualMovieData(
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

      if (movieJsonMatch != null) {
        debugPrint('   - Found JSON_MOVIE_DATA section');
        final movieJsonData = movieJsonMatch.group(1)!;
        final movieData = jsonDecode(movieJsonData) as Map<String, dynamic>;
        title = movieData['title'] as String?;
        debugPrint('   - JSON title: "$title"');
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

      if (title != null || rating != null || (comments != null && comments.isNotEmpty)) {
        debugPrint('   - Parse results: title="$title", rating=$rating, hasComments=${comments != null && comments.isNotEmpty}');
        return {'title': title, 'rating': rating, 'comments': comments};
      }

      debugPrint('   - No data extracted from TTL content');
      return null;
    } catch (e) {
      debugPrint('❌ Error parsing individual movie data: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: widget.listName,
      automaticallyImplyLeading: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // List metadata header.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.playlist_play,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.listName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.movies.length} movies',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.listDescription.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    widget.listDescription,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 16,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Owner: ${_getOwnerName(widget.owner)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.share,
                                size: 16,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Shared by: ${_getOwnerName(widget.sharedBy)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.permissions.contains('read')
                            ? Theme.of(
                                context,
                              ).colorScheme.tertiary.withValues(alpha: 0.1)
                            : Theme.of(
                                context,
                              ).colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: widget.permissions.contains('read')
                              ? Theme.of(context).colorScheme.tertiary
                              : Theme.of(context).colorScheme.error,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.permissions.contains('read')
                                ? Icons.visibility
                                : Icons.visibility_off,
                            size: 14,
                            color: widget.permissions.contains('read')
                                ? Theme.of(context).colorScheme.tertiary
                                : Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.permissions.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: widget.permissions.contains('read')
                                  ? Theme.of(context).colorScheme.tertiary
                                  : Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Movies list.
          Expanded(
            child: widget.movies.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'No movies in this list',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.movies.length,
                    itemBuilder: (context, index) {
                      final movieData = widget.movies[index];
                      final movieId = movieData['movieId']?.toString() ?? '0';
                      final movieTitle = _loadingTitles
                          ? 'Loading...'
                          : (_movieTitles[movieId] ??
                              movieData['fileName'] ??
                              'Unknown Movie');
                      final rating = movieData['rating'];
                      final comments = movieData['comments'] ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _navigateToMovieDetails(movieData),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Movie header.
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(
                                          8,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.movie,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            movieTitle,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          if (rating != null) ...[
                                            const SizedBox(height: 4),
                                            _buildRatingDisplay(rating),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),

                                // Movie comments.
                                if (comments.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.comment,
                                              size: 14,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Review:',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          comments,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.copyWith(
                                                fontStyle: FontStyle.italic,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
