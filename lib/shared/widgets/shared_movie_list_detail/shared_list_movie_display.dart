/// Shared List Movie Display Component - Movie Grid with Ratings, Error States, and Navigation
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solidpod/solidpod.dart';

import 'package:moviestar/core/services/favorites/favorites_service_adapter.dart';
import 'package:moviestar/core/services/favorites/favorites_service_manager.dart';
import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/screens/movie_details_screen.dart';

class SharedListMovieDisplay extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> movies;
  final Map<String, String> movieTitles;
  final bool loadingTitles;
  final Widget parentWidget;
  final String ownerWebId;
  final String sharedByWebId;

  const SharedListMovieDisplay({
    super.key,
    required this.movies,
    required this.movieTitles,
    required this.loadingTitles,
    required this.parentWidget,
    required this.ownerWebId,
    required this.sharedByWebId,
  });

  @override
  ConsumerState<SharedListMovieDisplay> createState() =>
      _SharedListMovieDisplayState();
}

class _SharedListMovieDisplayState extends ConsumerState<SharedListMovieDisplay>
    with ScreenStateMixin {
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
      if (movieId <= 0) return;

      // Get enhanced data with proper content type detection
      final enhancedData = await _fetchIndividualMovieData(movieData);
      final contentType = enhancedData['content_type'] ?? 'movie';

      Movie movie;
      final cachedMovieService = ref.read(cachedMovieServiceProvider);

      if (contentType == 'tv') {
        // For TV shows, create a basic Movie object with available data
        movie = Movie(
          id: movieId,
          title: enhancedData['title'] as String? ?? 'TV Show $movieId',
          overview: 'This is a TV show shared via POD.',
          releaseDate: DateTime.now(),
          posterUrl: '',
          backdropUrl: '',
          voteAverage: 0.0,
          genreIds: const [],
          contentType: ContentType.tvShow,
        );
      } else {
        // For movies, fetch from API
        movie = await cachedMovieService.getMovieDetails(movieId);
      }

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      final favoritesServiceManager = FavoritesServiceManager(
        prefs,
        context,
        widget.parentWidget,
      );
      final favoritesService = FavoritesServiceAdapter(favoritesServiceManager);

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MovieDetailsScreen(
            movie: movie,
            favoritesService: favoritesService,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to movie details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading movie details: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
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

      // Try both Movie and TVShow patterns on both PODs
      final movieFileName = 'movies/Movie-$movieId.ttl';
      final tvShowFileName = 'movies/TVShow-$movieId.ttl';

      final ownerBaseUrl = _extractBaseUrlFromWebId(ownerWebId);
      final sharerBaseUrl = _extractBaseUrlFromWebId(sharedByWebId);

      if (ownerBaseUrl == null && sharerBaseUrl == null) {
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
          if (!mounted) return movieData;

          movieFileContent =
              await readExternalPod(resourceUrl, context, widget.parentWidget);

          if (movieFileContent != null &&
              movieFileContent != SolidFunctionCallStatus.notLoggedIn &&
              movieFileContent is String &&
              movieFileContent.isNotEmpty) {
            isTvShow = providedFilePath.startsWith('TVShow-');
            break;
          }
        }
      } else {
        final baseUrlsToTry = <String>[];
        if (ownerBaseUrl != null) baseUrlsToTry.add(ownerBaseUrl);
        if (sharerBaseUrl != null && sharerBaseUrl != ownerBaseUrl) {
          baseUrlsToTry.add(sharerBaseUrl);
        }

        for (final baseUrl in baseUrlsToTry) {
          if (!mounted) return movieData;

          // Try Movie file first
          final movieResourceUrl = '${baseUrl}moviestar/data/$movieFileName';
          movieFileContent = await readExternalPod(
              movieResourceUrl, context, widget.parentWidget,);

          if (movieFileContent != null &&
              movieFileContent != SolidFunctionCallStatus.notLoggedIn &&
              movieFileContent is String &&
              movieFileContent.isNotEmpty) {
            isTvShow = false;
            break;
          } else {
            // Try TVShow file
            final tvShowResourceUrl =
                '${baseUrl}moviestar/data/$tvShowFileName';
            if (!mounted) return movieData;

            movieFileContent = await readExternalPod(
                tvShowResourceUrl, context, widget.parentWidget,);

            if (movieFileContent != null &&
                movieFileContent != SolidFunctionCallStatus.notLoggedIn &&
                movieFileContent is String &&
                movieFileContent.isNotEmpty) {
              isTvShow = true;
              break;
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

      final parsedData = await _parseIndividualMovieData(movieFileContent);

      if (parsedData != null || isTvShow) {
        final enhancedData = Map<String, dynamic>.from(movieData);
        if (parsedData != null) {
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
        }

        enhancedData['content_type'] = isTvShow ? 'tv' : 'movie';
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
      double? rating;
      String? comments;
      String? title;

      final movieJsonMatch =
          RegExp(r'# JSON_MOVIE_DATA: (.+)').firstMatch(ttlContent);

      if (movieJsonMatch != null) {
        final movieJsonData = movieJsonMatch.group(1)!;
        final movieData = jsonDecode(movieJsonData) as Map<String, dynamic>;
        title = movieData['title'] as String?;
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
            }
          }

          if (rating == null &&
              (trimmedLine.contains('schema:ratingValue') ||
                  trimmedLine.contains('sdo:ratingValue') ||
                  trimmedLine.contains(':ratingValue'))) {
            final match = RegExp(r'(\d+\.?\d*)').firstMatch(trimmedLine);
            if (match != null) {
              rating = double.tryParse(match.group(1)!);
            }
          }

          if (comments == null &&
              (trimmedLine.contains('schema:reviewBody') ||
                  trimmedLine.contains('sdo:reviewBody') ||
                  trimmedLine.contains(':reviewBody'))) {
            final match = RegExp(r'"([^"]*)"').firstMatch(trimmedLine);
            if (match != null) {
              comments = match.group(1);
            }
          }
        }
      }

      if (title != null || rating != null || comments != null) {
        return {
          'title': title,
          'rating': rating,
          'comments': comments,
        };
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error parsing individual movie data: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.movies.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.movie_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No movies in this list',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.movies.length,
      itemBuilder: (context, index) {
        final movieData = widget.movies[index];
        final movieId = movieData['movieId']?.toString() ?? '0';
        final movieTitle = widget.loadingTitles
            ? 'Loading...'
            : (widget.movieTitles[movieId] ??
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
                  // Movie header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.movie,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movieTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
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
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),

                  // Movie comments
                  if (comments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.comment,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Review:',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comments,
                            style: theme.textTheme.bodySmall?.copyWith(
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
    );
  }
}
