/// Shared Movies Screen for MovieStar.
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

import 'package:gap/gap.dart';

import 'package:solidpod/solidpod.dart';

import 'package:moviestar/widgets/list_shared_movies.dart';

class SharedMoviesScreen extends StatefulWidget {
  const SharedMoviesScreen({super.key});

  @override
  State<SharedMoviesScreen> createState() => _SharedMoviesScreenState();
}

class _SharedMoviesScreenState extends State<SharedMoviesScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  Future<Map<String, dynamic>?>? _sharedWithMeData;
  Future<Map<String, dynamic>?>? _mySharedData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _refreshData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This gets called when returning from a route.

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshData();
      }
    });
  }

  void _refreshData() {
    setState(() {
      _sharedWithMeData = _getMoviesSharedWithMe();
      _mySharedData = _getMyRatedMovies();
    });
  }

  // Fetch movies that others have shared with me.

  Future<Map<String, dynamic>?> _getMoviesSharedWithMe() async {
    try {
      if (!mounted) return null;

      // Get shared resources from POD.

      final sharedResourcesResult = await sharedResources(context, widget);

      if (sharedResourcesResult == SolidFunctionCallStatus.notLoggedIn) {
        debugPrint('❌ User not logged in to POD');
        return null;
      }

      if (sharedResourcesResult is! Map) {
        debugPrint('❌ Invalid shared resources data: $sharedResourcesResult');
        return null;
      }

      final Map<String, dynamic> movieData = {};

      // Filter for movie files and fetch their content.

      for (final entry in sharedResourcesResult.entries) {
        final resourceUrl = entry.key as String;
        final resourceInfo = entry.value as Map;

        // Check if this is a movie file.

        if (resourceUrl.contains('/movies/') && resourceUrl.endsWith('.ttl')) {
          try {
            if (!mounted) break;

            // Read the movie file content.

            final movieContent =
                await readExternalPod(resourceUrl, context, widget);

            if (movieContent != null &&
                movieContent != SolidFunctionCallStatus.notLoggedIn) {
              // Parse the movie data from TTL content.

              final movieInfo = await _parseMovieData(
                  movieContent, resourceUrl, resourceInfo);
              if (movieInfo != null) {
                movieData[resourceUrl] = movieInfo;
              }
            }
          } catch (e) {
            debugPrint('Error reading movie file $resourceUrl: $e');
            // Continue with other files even if one fails.
          }
        }
      }

      return movieData.isNotEmpty ? movieData : null;
    } catch (e) {
      debugPrint('Error fetching shared movies: $e');
      return null;
    }
  }

  // Helper function to extract a friendly name from a WebID.

  String _formatWebId(String? webId) {
    if (webId == null || webId.isEmpty) return 'Unknown';

    // Extract the username from URLs like:
    // https://pods.dev.solidcommunity.au/my-moviestar/profile/card#me -> my-moviestar
    // https://pods.dev.solidcommunity.au/my-healthpod/profile/card#me -> my-healthpod

    final match = RegExp(r'://[^/]+/([^/]+)/').firstMatch(webId);
    if (match != null) {
      return match.group(1) ?? 'Unknown';
    }

    return webId.length > 20 ? '${webId.substring(0, 20)}...' : webId;
  }

  // Extract movie ID from resource URL.

  String _extractMovieIdFromUrl(String resourceUrl) {
    // Extract from URLs like "https://pods.dev.solidcommunity.au/my-moviestar/moviestar/data/movies/Movie-846422.ttl".

    final fileName = resourceUrl.split('/').last;
    final match =
        RegExp(r'Movie-(\w+)\.ttl', caseSensitive: false).firstMatch(fileName);
    return match?.group(1) ?? 'unknown';
  }

  // Parse movie data from TTL content.

  Future<Map<String, dynamic>?> _parseMovieData(
      String ttlContent, String resourceUrl, Map resourceInfo) async {
    try {
      String? movieTitle;
      String? movieId;
      String? posterUrl;
      String? backdropUrl;
      String? overview;
      String? releaseDate;
      double? voteAverage;
      List<int>? genreIds;
      double? rating;
      String? comments;

      // Extract movie ID from URL (e.g. Movie-123.ttl -> 123).

      final urlParts = resourceUrl.split('/');
      final fileName = urlParts.last;
      final idMatch = RegExp(r'Movie-(\w+)\.ttl', caseSensitive: false)
          .firstMatch(fileName);
      if (idMatch != null) {
        movieId = idMatch.group(1);
      }

      // Try to parse JSON backup data first (more reliable).

      final movieJsonMatch =
          RegExp(r'# JSON_MOVIE_DATA: (.+)').firstMatch(ttlContent);
      final userJsonMatch =
          RegExp(r'# JSON_USER_DATA: (.+)').firstMatch(ttlContent);

      if (movieJsonMatch != null) {
        final movieJsonData = movieJsonMatch.group(1)!;
        final movieData = jsonDecode(movieJsonData) as Map<String, dynamic>;

        // Extract all movie metadata.

        movieTitle = movieData['title'] as String?;
        movieId ??= movieData['id']?.toString();
        posterUrl = movieData['posterUrl'] as String?;
        backdropUrl = movieData['backdropUrl'] as String?;
        overview = movieData['overview'] as String?;
        releaseDate = movieData['releaseDate'] as String?;
        voteAverage = (movieData['voteAverage'] as num?)?.toDouble();
        genreIds =
            (movieData['genreIds'] as List?)?.map((e) => e as int).toList();
      }

      if (userJsonMatch != null) {
        final userJsonData = userJsonMatch.group(1)!;
        final userData = jsonDecode(userJsonData) as Map<String, dynamic>;
        rating = userData['rating'] as double?;
        comments = userData['comment'] as String?;
      }

      // Fallback to TTL parsing if JSON backup is not available.

      if (movieTitle == null || posterUrl == null || voteAverage == null) {
        final lines = ttlContent.split('\n');
        for (final line in lines) {
          final trimmedLine = line.trim();

          // Extract movie title (schema:name predicate).

          if (movieTitle == null &&
              (trimmedLine.contains('schema:name') ||
                  trimmedLine.contains(':name'))) {
            final match = RegExp(r'"([^"]*)"').firstMatch(trimmedLine);
            if (match != null) {
              movieTitle = match.group(1);
            }
          }

          // Extract poster URL (schema:image predicate).

          if (posterUrl == null &&
              (trimmedLine.contains('schema:image') ||
                  trimmedLine.contains(':image'))) {
            final match = RegExp(r'"([^"]*)"').firstMatch(trimmedLine);
            if (match != null) {
              posterUrl = match.group(1);
            }
          }

          // Extract backdrop URL (schema:thumbnailUrl predicate).

          if (backdropUrl == null &&
              (trimmedLine.contains('schema:thumbnailUrl') ||
                  trimmedLine.contains(':thumbnailUrl'))) {
            final match = RegExp(r'"([^"]*)"').firstMatch(trimmedLine);
            if (match != null) {
              backdropUrl = match.group(1);
            }
          }

          // Extract overview/description (schema:description predicate).

          if (overview == null &&
              (trimmedLine.contains('schema:description') ||
                  trimmedLine.contains(':description'))) {
            final match = RegExp(r'"([^"]*)"').firstMatch(trimmedLine);
            if (match != null) {
              overview = match.group(1);
            }
          }

          // Extract aggregated rating (schema:aggregateRating predicate).

          if (voteAverage == null &&
              (trimmedLine.contains('schema:aggregateRating') ||
                  trimmedLine.contains(':aggregateRating'))) {
            final match = RegExp(r'(\d+\.?\d*)').firstMatch(trimmedLine);
            if (match != null) {
              voteAverage = double.tryParse(match.group(1) ?? '');
            }
          }

          // Extract release date (schema:datePublished predicate).

          if (releaseDate == null &&
              (trimmedLine.contains('schema:datePublished') ||
                  trimmedLine.contains(':datePublished'))) {
            final match = RegExp(r'"([^"]*)"').firstMatch(trimmedLine);
            if (match != null) {
              releaseDate = match.group(1);
            }
          }

          // Extract personal rating (look for rating value in user data).

          if (rating == null && trimmedLine.contains(':value')) {
            final match = RegExp(r'(\d+\.?\d*)').firstMatch(trimmedLine);
            if (match != null) {
              rating = double.tryParse(match.group(1) ?? '');
            }
          }

          // Extract comments (look for comment text).

          if (comments == null && trimmedLine.contains(':text')) {
            final match = RegExp(r'"([^"]*)"').firstMatch(trimmedLine);
            if (match != null) {
              comments = match.group(1);
            }
          }
        }
      }

      // If we still couldn't parse the title, use a fallback.

      movieTitle ??= 'Movie ${movieId ?? 'Unknown'}';

      final rawOwner = resourceInfo['owner'] ?? resourceInfo['ownerWebId'];
      final rawSharedBy =
          resourceInfo['granter'] ?? resourceInfo['granterWebId'];

      final result = {
        'fileName': movieTitle,
        'owner': _formatWebId(rawOwner),
        'sharedBy': _formatWebId(rawSharedBy),
        'permissions': resourceInfo['permissions'] ??
            resourceInfo['permissionList'] ??
            'read',
        'movieId': movieId ?? 'unknown',
        'rating': rating,
        'comments': comments ?? '',
        'resourceUrl': resourceUrl,
        // Movie metadata fields.

        'posterUrl': posterUrl ?? '',
        'backdropUrl': backdropUrl ?? posterUrl ?? '',
        'overview': overview ?? 'Shared movie',
        'releaseDate': releaseDate,
        'voteAverage': voteAverage ?? 0.0,
        'genreIds': genreIds ?? <int>[],
      };

      return result;
    } catch (e) {
      debugPrint('❌ Error parsing movie data: $e');
      return null;
    }
  }

  // Fetch movies that I have rated or commented on.
  // Shows all movies with user data (rating/comments) that can be shared.

  Future<Map<String, dynamic>?> _getMyRatedMovies() async {
    try {
      if (!mounted) return null;

      // Get current user's WebID.

      final currentWebId = await getWebId();

      if (currentWebId == null) {
        debugPrint('❌ No WebID found - user not logged in');
        return {};
      }

      // List all movie files in our POD that have ratings/comments.

      Map<String, dynamic> ratedMoviesMap = {};

      try {
        // Get the movies directory URL.

        final webIdWithoutCard =
            currentWebId.replaceAll('/profile/card#me', '');
        final moviesDir = '$webIdWithoutCard/moviestar/data/movies/';

        // Try to get resources in the movies container.

        final resources = await getResourcesInContainer(moviesDir);

        // Process each movie file.

        for (final fileName in resources.files) {
          if (!fileName.endsWith('.ttl') || !fileName.contains('Movie-')) {
            continue;
          }

          final resourceUrl = '$moviesDir$fileName';

          try {
            // Read the movie file content.

            if (!mounted) break;

            final movieContent = await readPod(
                'moviestar/data/movies/$fileName', context, widget);

            if (movieContent.isNotEmpty &&
                movieContent !=
                    SolidFunctionCallStatus.notLoggedIn.toString() &&
                movieContent != SolidFunctionCallStatus.fail.toString()) {
              // Create movie entry for display.

              ratedMoviesMap[resourceUrl] = {
                'movieContent': movieContent,
                'movieFileName': fileName,
                'movieUrl': resourceUrl,
                'isUserRatedMovie': true,
              };
            }
          } catch (e) {
            debugPrint('⚠️ Could not read movie file $fileName: $e');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Could not enumerate movie files: $e');
        return {};
      }

      if (ratedMoviesMap.isEmpty) {
        return {};
      }

      // Now process the rated movies to get full movie metadata.

      Map<String, dynamic> enrichedMoviesMap = {};

      for (final entry in ratedMoviesMap.entries) {
        final resourceUrl = entry.key;
        final movieEntry = entry.value as Map<String, dynamic>;
        final movieContent = movieEntry['movieContent'] as String;
        final fileName = movieEntry['movieFileName'] as String;

        try {
          // Create a basic resource info for parsing.

          final basicResourceInfo = {
            'movieUrl': resourceUrl,
            'movieFileName': fileName,
            'owner': currentWebId,
            'granter': currentWebId,
          };

          // Parse the movie data from TTL content.

          final movieData = await _parseMovieData(
              movieContent, resourceUrl, basicResourceInfo);

          if (movieData != null) {
            // Update to show this is user's own rated movie.

            movieData['owner'] = 'ME';
            movieData['sharedBy'] = 'ME';
            movieData['isUserRatedMovie'] = true;
            movieData['canShare'] = true;
            movieData['recipient'] = 'Not shared yet';

            enrichedMoviesMap[resourceUrl] = movieData;
          }
        } catch (e) {
          debugPrint('❌ Error processing movie file $fileName: $e');

          // Create a fallback entry.

          enrichedMoviesMap[resourceUrl] = {
            'fileName':
                fileName.replaceAll('.ttl', '').replaceAll('Movie-', 'Movie '),
            'owner': 'ME',
            'sharedBy': 'ME',
            'permissions': 'read',
            'movieId': _extractMovieIdFromUrl(resourceUrl),
            'rating': null,
            'comments': '',
            'resourceUrl': resourceUrl,
            'isUserRatedMovie': true,
            'canShare': true,
            'recipient': 'Not shared yet',
          };
        }
      }

      return enrichedMoviesMap;
    } catch (e) {
      debugPrint('❌ Error fetching movies I shared: $e');
      return null;
    }
  }

  Widget _buildLoadedScreen(Map<String, dynamic> sharedMoviesMap) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListSharedMovies(
        sharedMoviesMap: sharedMoviesMap,
        onDataChanged: _refreshData,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
            const Gap(16),
            Text(
              'No Shared Movies',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const Gap(8),
            Text(
              'Movies shared with you will appear here.\nStart sharing movies with friends to see them!\n\nMake sure you have POD storage enabled in Settings.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const Gap(16),
            Text(
              'Unable to Load Shared Movies',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const Gap(8),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const Gap(16),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Shared Movies'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Shared with Me'),
            Tab(text: 'My Rated Movies'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Movies shared with me.

          _buildSharedWithMeTab(),
          // Tab 2: My rated movies.

          _buildMySharedTab(),
        ],
      ),
    );
  }

  Widget _buildSharedWithMeTab() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _sharedWithMeData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                Gap(16),
                Text('Loading shared movies...'),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return _buildErrorState();
        } else if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return _buildEmptyState();
        } else {
          return _buildLoadedScreen(snapshot.data!);
        }
      },
    );
  }

  Widget _buildMySharedTab() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _mySharedData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                Gap(16),
                Text('Loading your shared movies...'),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return _buildErrorState();
        } else if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return _buildMySharedEmptyState();
        } else {
          return _buildLoadedScreen(snapshot.data!);
        }
      },
    );
  }

  Widget _buildMySharedEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_rate_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
            const Gap(16),
            Text(
              'No Rated Movies Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const Gap(8),
            Text(
              'Movies you\'ve rated or commented on will appear here.\n\nTo rate a movie:\n1. Go to any movie details\n2. Add a rating or comment\n3. Save your review\n\nYou can then share your rated movies with friends.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
