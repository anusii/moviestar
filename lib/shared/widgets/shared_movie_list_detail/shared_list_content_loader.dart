/// Shared List Content Loader Component - Movie Title Loading, API Integration, and Caching Logic
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solidpod/solidpod.dart';

import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';

class SharedListContentLoader extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> movies;
  final String ownerWebId;
  final String sharedByWebId;
  final Widget parentWidget;
  final Function(Map<String, String> movieTitles, bool isLoading)
      onTitlesLoaded;

  const SharedListContentLoader({
    super.key,
    required this.movies,
    required this.ownerWebId,
    required this.sharedByWebId,
    required this.parentWidget,
    required this.onTitlesLoaded,
  });

  @override
  ConsumerState<SharedListContentLoader> createState() =>
      _SharedListContentLoaderState();
}

class _SharedListContentLoaderState
    extends ConsumerState<SharedListContentLoader> with ScreenStateMixin {
  Map<String, String> _movieTitles = {};
  bool _loadingTitles = true;

  @override
  void initState() {
    super.initState();
    _loadMovieTitles();
  }

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
          debugPrint(
              '   - FilePath: ${movieData['filePath'] ?? "not provided"}',);

          try {
            final enhancedData = await _fetchIndividualMovieData(movieData);
            final contentType = enhancedData['content_type'] ?? 'movie';

            String? actualTitle =
                await _extractTitleFromEnhancedData(enhancedData);

            debugPrint('   - Enhanced content type: $contentType');
            debugPrint('   - Extracted title: ${actualTitle ?? "not found"}');

            if (actualTitle != null) {
              titles[movieId.toString()] = actualTitle;
            } else if (contentType == 'tv') {
              titles[movieId.toString()] = 'TV Show $movieId';
            } else {
              final movie = await cachedMovieService.getMovieDetails(movieId);
              titles[movieId.toString()] = movie.title;
            }
          } catch (e) {
            debugPrint('Error fetching title for content $movieId: $e');
            final enhancedData = await _fetchIndividualMovieData(movieData);
            final contentType = enhancedData['content_type'] ?? 'movie';

            titles[movieId.toString()] =
                contentType == 'tv' ? 'TV Show $movieId' : 'Movie $movieId';
          }
        }
      }

      if (mounted) {
        safeSetState(() {
          _movieTitles = titles;
          _loadingTitles = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onTitlesLoaded(_movieTitles, _loadingTitles);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading content titles: $e');
      if (mounted) {
        safeSetState(() {
          _loadingTitles = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onTitlesLoaded(_movieTitles, _loadingTitles);
          }
        });
      }
    }
  }

  Future<String?> _findIndividualFileInSharedResources(
      String movieId, String? providedFilePath,) async {
    try {
      final sharedResourcesResult =
          await sharedResources(context, widget.parentWidget);

      if (sharedResourcesResult == SolidFunctionCallStatus.notLoggedIn) {
        debugPrint('   ❌ Not logged in to check shared resources');
        return null;
      }

      if (sharedResourcesResult is! Map) {
        debugPrint('   ❌ Invalid shared resources data');
        return null;
      }

      for (final entry in sharedResourcesResult.entries) {
        final resourceUrl = entry.key as String;

        if (resourceUrl.contains('/movies/') && resourceUrl.endsWith('.ttl')) {
          if (resourceUrl.contains('Movie-$movieId.ttl') ||
              resourceUrl.contains('TVShow-$movieId.ttl')) {
            debugPrint(
                '   🔍 Found matching individual file by ID: $resourceUrl',);
            return resourceUrl;
          }

          if (providedFilePath != null &&
              resourceUrl.endsWith(providedFilePath)) {
            debugPrint(
                '   🔍 Found matching individual file by filePath: $resourceUrl',);
            return resourceUrl;
          }
        }
      }

      debugPrint(
          '   ❌ No individual file found in shared resources for movie $movieId',);
      return null;
    } catch (e) {
      debugPrint('   ❌ Error searching shared resources: $e');
      return null;
    }
  }

  String? _extractBaseUrlFromWebId(String webIdOrUsername) {
    if (webIdOrUsername.isEmpty) return null;

    try {
      if (webIdOrUsername.startsWith('http')) {
        final match =
            RegExp(r'(https?://[^/]+/[^/]+/)').firstMatch(webIdOrUsername);
        if (match != null) {
          return match.group(1);
        }
      } else {
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

  Future<Map<String, dynamic>> _fetchIndividualMovieData(
      Map<String, dynamic> movieData,) async {
    try {
      final movieId = movieData['movieId']?.toString() ?? '0';

      if (movieId == '0') {
        return movieData;
      }

      final ownerWebId = widget.ownerWebId;
      final sharedByWebId = widget.sharedByWebId;
      final providedFilePath = movieData['filePath'] as String?;

      String? actualSharedUrl =
          await _findIndividualFileInSharedResources(movieId, providedFilePath);

      if (actualSharedUrl != null) {
        debugPrint(
            '   - Found individual file in shared resources: $actualSharedUrl',);

        if (!mounted) return movieData;

        final movieFileContent = await readExternalPod(
          actualSharedUrl,
          context,
          widget.parentWidget,
        );

        if (movieFileContent != null &&
            movieFileContent != SolidFunctionCallStatus.notLoggedIn &&
            movieFileContent is String &&
            movieFileContent.isNotEmpty) {
          final isTvShow = actualSharedUrl.contains('TVShow-') ||
              (providedFilePath?.startsWith('TVShow-') ?? false);

          debugPrint(
              '   ✅ Successfully read shared individual file (${movieFileContent.length} chars)',);
          debugPrint('   - Detected as: ${isTvShow ? "TV Show" : "Movie"}');

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

      debugPrint('   - Falling back to manual URL construction...');

      final movieFileName = 'movies/Movie-$movieId.ttl';
      final tvShowFileName = 'movies/TVShow-$movieId.ttl';

      final ownerBaseUrl = _extractBaseUrlFromWebId(ownerWebId);
      final sharerBaseUrl = _extractBaseUrlFromWebId(sharedByWebId);

      debugPrint('   - Owner base URL: $ownerBaseUrl');
      debugPrint('   - Sharer base URL: $sharerBaseUrl');

      if (ownerBaseUrl == null && sharerBaseUrl == null) {
        debugPrint('   ❌ Could not extract base URLs from WebIDs');
        return movieData;
      }

      dynamic movieFileContent;
      bool isTvShow = false;

      if (providedFilePath != null) {
        final urlsToTry = <String>[];

        if (ownerBaseUrl != null) {
          urlsToTry
              .add('${ownerBaseUrl}moviestar/data/movies/$providedFilePath');
        }
        if (sharerBaseUrl != null && sharerBaseUrl != ownerBaseUrl) {
          urlsToTry
              .add('${sharerBaseUrl}moviestar/data/movies/$providedFilePath');
        }

        for (final resourceUrl in urlsToTry) {
          debugPrint('   - Trying URL: $resourceUrl');

          if (!mounted) return movieData;

          movieFileContent =
              await readExternalPod(resourceUrl, context, widget.parentWidget);

          if (movieFileContent != null &&
              movieFileContent != SolidFunctionCallStatus.notLoggedIn &&
              movieFileContent is String &&
              movieFileContent.isNotEmpty) {
            isTvShow = providedFilePath.startsWith('TVShow-');
            debugPrint(
                '   ✅ Successfully read file from $resourceUrl (${movieFileContent.length} chars)',);
            debugPrint('   - Detected as: ${isTvShow ? "TV Show" : "Movie"}');
            break;
          } else {
            debugPrint('   ❌ Failed to read file from $resourceUrl');
          }
        }
      } else {
        debugPrint(
            '   - Falling back to trying both Movie and TVShow patterns',);

        final baseUrlsToTry = <String>[];
        if (ownerBaseUrl != null) baseUrlsToTry.add(ownerBaseUrl);
        if (sharerBaseUrl != null && sharerBaseUrl != ownerBaseUrl) {
          baseUrlsToTry.add(sharerBaseUrl);
        }

        for (final baseUrl in baseUrlsToTry) {
          if (!mounted) return movieData;

          final movieResourceUrl = '${baseUrl}moviestar/data/$movieFileName';
          debugPrint('   - Trying Movie pattern: $movieResourceUrl');

          movieFileContent = await readExternalPod(
              movieResourceUrl, context, widget.parentWidget,);

          if (movieFileContent != null &&
              movieFileContent != SolidFunctionCallStatus.notLoggedIn &&
              movieFileContent is String &&
              movieFileContent.isNotEmpty) {
            isTvShow = false;
            break;
          } else {
            debugPrint('   ❌ Movie file not found at $movieResourceUrl');

            final tvShowResourceUrl =
                '${baseUrl}moviestar/data/$tvShowFileName';
            debugPrint('   - Trying TVShow pattern: $tvShowResourceUrl');

            if (!mounted) return movieData;

            movieFileContent = await readExternalPod(
                tvShowResourceUrl, context, widget.parentWidget,);

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

      debugPrint('   - Parsing TTL content to extract metadata...');
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

        if (isTvShow) {
          enhancedData['content_type'] = 'tv';
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
    } catch (e) {
      debugPrint('❌ Error fetching individual movie data: $e');
      return movieData;
    }
  }

  Future<Map<String, dynamic>?> _parseIndividualMovieData(
      String ttlContent,) async {
    try {
      debugPrint('   🔬 [ParseTTL] Starting TTL content parsing...');

      double? rating;
      String? comments;
      String? title;

      final movieJsonMatch =
          RegExp(r'# JSON_MOVIE_DATA: (.+)').firstMatch(ttlContent);

      if (movieJsonMatch != null) {
        debugPrint('   - Found JSON_MOVIE_DATA section');
        final movieJsonData = movieJsonMatch.group(1)!;
        final movieData = jsonDecode(movieJsonData) as Map<String, dynamic>;
        title = movieData['title'] as String?;
        debugPrint('   - JSON title: "$title"');
      } else {
        debugPrint('   - No JSON_MOVIE_DATA found, will try TTL parsing');
      }

      final userJsonMatch =
          RegExp(r'# JSON_USER_DATA: (.+)').firstMatch(ttlContent);

      if (userJsonMatch != null) {
        final userJsonData = userJsonMatch.group(1)!;
        final userData = jsonDecode(userJsonData) as Map<String, dynamic>;
        rating = userData['rating'] as double?;
        comments = userData['comment'] as String?;
      }

      if (title == null || rating == null || comments == null) {
        final lines = ttlContent.split('\n');
        for (final line in lines) {
          final trimmedLine = line.trim();

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

          if (rating == null &&
              (trimmedLine.contains('schema:ratingValue') ||
                  trimmedLine.contains('sdo:ratingValue') ||
                  trimmedLine.contains(':ratingValue'))) {
            final match = RegExp(r'(\d+\.?\d*)').firstMatch(trimmedLine);
            if (match != null) {
              rating = double.tryParse(match.group(1)!);
              debugPrint('   - Found rating in TTL: $rating');
            }
          }

          if (comments == null &&
              (trimmedLine.contains('schema:reviewBody') ||
                  trimmedLine.contains('sdo:reviewBody') ||
                  trimmedLine.contains(':reviewBody'))) {
            final match = RegExp(r'"([^"]*)"').firstMatch(trimmedLine);
            if (match != null) {
              comments = match.group(1);
              debugPrint(
                  '   - Found comments in TTL: "${comments?.substring(0, comments.length > 50 ? 50 : comments.length)}${comments != null && comments.length > 50 ? '...' : ''}"',);
            }
          }
        }
      }

      if (title != null || rating != null || comments != null) {
        debugPrint(
            '   ✅ [ParseTTL] Successfully parsed: title=${title != null ? '"$title"' : 'null'}, rating=$rating, comments=${comments != null ? 'present' : 'null'}',);
        return {
          'title': title,
          'rating': rating,
          'comments': comments,
        };
      } else {
        debugPrint('   ❌ [ParseTTL] No data extracted from TTL content');
        return null;
      }
    } catch (e) {
      debugPrint('❌ [ParseTTL] Error parsing individual movie data: $e');
      return null;
    }
  }

  Future<String?> _extractTitleFromEnhancedData(
      Map<String, dynamic> enhancedData,) async {
    final title = enhancedData['title'] as String?;
    if (title != null && title.isNotEmpty) {
      return title;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
