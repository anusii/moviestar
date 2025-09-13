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

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/widgets/base_screen.dart';
import 'package:moviestar/widgets/list_shared_movies.dart';

class SharedMoviesScreen extends StatefulWidget {
  const SharedMoviesScreen({super.key});

  @override
  State<SharedMoviesScreen> createState() => _SharedMoviesScreenState();
}

class _SharedMoviesScreenState extends State<SharedMoviesScreen>
    with WidgetsBindingObserver, ScreenStateMixin {
  Future<Map<String, dynamic>?>? _sharedWithMeData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    safeSetState(() {
      _sharedWithMeData = _getMoviesSharedWithMe();
    });
  }

  // Fetch movies and movie lists that others have shared with me.

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
      final Map<String, dynamic> movieListData = {};

      // Filter for movie files and movie list files, then fetch their content.

      debugPrint(
        '🔍 [SharedResources] Found ${sharedResourcesResult.length} shared resources:',
      );
      for (final entry in sharedResourcesResult.entries) {
        debugPrint('   - ${entry.key}');
      }

      for (final entry in sharedResourcesResult.entries) {
        final resourceUrl = entry.key as String;
        final resourceInfo = entry.value as Map;

        try {
          if (!mounted) break;

          // Check if this is a movie file.

          if (resourceUrl.contains('/movies/') &&
              resourceUrl.endsWith('.ttl')) {
            // Read the movie file content.

            final movieContent = await readExternalPod(
              resourceUrl,
              context,
              widget,
            );

            if (movieContent != null &&
                movieContent != SolidFunctionCallStatus.notLoggedIn) {
              // Parse the movie data from TTL content.

              final movieInfo = await _parseMovieData(
                movieContent,
                resourceUrl,
                resourceInfo,
              );
              if (movieInfo != null) {
                movieData[resourceUrl] = movieInfo;
              }
            }
          }
          // Check if this is a movie list file.
          else if (resourceUrl.contains('user_lists/MovieList-') &&
              resourceUrl.endsWith('.ttl')) {
            // Read the movie list file content.

            final listContent = await readExternalPod(
              resourceUrl,
              context,
              widget,
            );

            if (listContent != null &&
                listContent != SolidFunctionCallStatus.notLoggedIn) {
              // Parse the movie list data from TTL content.

              final listInfo = await _parseMovieListData(
                listContent,
                resourceUrl,
                resourceInfo,
              );
              if (listInfo != null) {
                movieListData[resourceUrl] = listInfo;
              }
            }
          }
        } catch (e) {
          if (e.toString().contains('enc-keys.ttl') ||
              e.toString().contains('Invalid content in file') ||
              e.toString().contains('Duplicated encryption key')) {
            debugPrint(
              '⚠️  Encryption key corruption detected for $resourceUrl: $e',
            );
            debugPrint(
              '   Skipping this resource - consider regenerating encryption keys in POD',
            );
          } else {
            debugPrint('Error reading resource file $resourceUrl: $e');
          }
          // Continue with other files even if one fails.
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
      debugPrint('Error fetching shared movies: $e');
      return null;
    }
  }

  // Helper function to extract a friendly name from a WebID.

  String _formatWebId(String webId) {
    if (webId.isEmpty) return 'Unknown';

    // Extract the username from URLs like:
    // https://pods.dev.solidcommunity.au/my-moviestar/profile/card#me -> my-moviestar
    // https://pods.dev.solidcommunity.au/my-healthpod/profile/card#me -> my-healthpod

    final match = RegExp(r'://[^/]+/([^/]+)/').firstMatch(webId);
    if (match != null) {
      return match.group(1) ?? 'Unknown';
    }

    return webId.length > 20 ? '${webId.substring(0, 20)}...' : webId;
  }

  // Parse movie data from TTL content.

  Future<Map<String, dynamic>?> _parseMovieData(
    String ttlContent,
    String resourceUrl,
    Map resourceInfo,
  ) async {
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

      // Extract movie/TV show ID from URL (e.g. Movie-123.ttl or TVShow-123.ttl -> 123).

      final urlParts = resourceUrl.split('/');
      final fileName = urlParts.last;
      final idMatch = RegExp(
        r'(?:Movie|TVShow)-(\w+)\.ttl',
        caseSensitive: false,
      ).firstMatch(fileName);
      if (idMatch != null) {
        movieId = idMatch.group(1);
      }

      // Try to parse JSON backup data first (more reliable).

      final movieJsonMatch = RegExp(
        r'# JSON_MOVIE_DATA: (.+)',
      ).firstMatch(ttlContent);
      final userJsonMatch = RegExp(
        r'# JSON_USER_DATA: (.+)',
      ).firstMatch(ttlContent);

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

      // If we still couldn't parse the title, use a fallback based on file type.

      if (movieTitle == null) {
        final isTvShow = fileName.toLowerCase().startsWith('tvshow-');
        movieTitle = isTvShow
            ? 'TV Show ${movieId ?? 'Unknown'}'
            : 'Movie ${movieId ?? 'Unknown'}';
      }

      final rawOwner = resourceInfo['owner'] ?? resourceInfo['ownerWebId'];
      final rawSharedBy =
          resourceInfo['granter'] ?? resourceInfo['granterWebId'];

      // Try to extract owner from resource URL if not found in resourceInfo.

      String finalOwner = rawOwner?.toString() ?? '';
      String finalSharedBy = rawSharedBy?.toString() ?? '';

      // Extract from resource URL for both owner and shared by if not found in metadata.

      final ownerMatch = RegExp(r'://[^/]+/([^/]+)/').firstMatch(resourceUrl);
      if (ownerMatch != null) {
        final username = ownerMatch.group(1);
        final webId =
            'https://pods.dev.solidcommunity.au/$username/profile/card#me';

        if (finalOwner.isEmpty) {
          finalOwner = webId;
        }
        if (finalSharedBy.isEmpty) {
          finalSharedBy =
              webId; // Use same WebID for shared by when not available.
        }
      }

      // Detect content type based on file name
      final isTvShow = fileName.toLowerCase().startsWith('tvshow-');

      final result = {
        'fileName': movieTitle,
        'owner': _formatWebId(finalOwner),
        'ownerWebId': finalOwner, // Store full WebID for URL construction.
        'sharedBy': _formatWebId(finalSharedBy),
        'sharedByWebId':
            finalSharedBy, // Store full WebID for URL construction.
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
        // Content type detection based on file prefix
        'content_type': isTvShow ? 'tv' : 'movie',
      };

      return result;
    } catch (e) {
      debugPrint('❌ Error parsing movie data: $e');
      return null;
    }
  }

  // Parse movie list data from TTL content.

  Future<Map<String, dynamic>?> _parseMovieListData(
    String ttlContent,
    String resourceUrl,
    Map resourceInfo,
  ) async {
    try {
      String? listName;
      String? listId;
      String? description;
      List<String> movieIds = [];
      Map<String, String> movieFilePaths =
          {}; // Store filePath for each movie ID

      // Extract list ID from URL (e.g. MovieList-abc123.ttl -> abc123).

      final urlParts = resourceUrl.split('/');
      final fileName = urlParts.last;
      final idMatch = RegExp(
        r'MovieList-(\w+)\.ttl',
        caseSensitive: false,
      ).firstMatch(fileName);
      if (idMatch != null) {
        listId = idMatch.group(1);
      }

      // Parse TTL content for movie list information.

      final lines = ttlContent.split('\n');
      for (final line in lines) {
        final trimmedLine = line.trim();

        // Extract list name (schema:name or sdo:name predicate).

        if (listName == null &&
            (trimmedLine.contains('sdo:name') ||
                trimmedLine.contains('schema:name') ||
                trimmedLine.contains(':name'))) {
          final match = RegExp(r'"([^"]*)"').firstMatch(trimmedLine);
          if (match != null) {
            listName = match.group(1);
          }
        }

        // Extract description (sdo:description predicate).

        if (description == null &&
            (trimmedLine.contains('sdo:description') ||
                trimmedLine.contains('schema:description') ||
                trimmedLine.contains(':description'))) {
          final match = RegExp(r'"([^"]*)"').firstMatch(trimmedLine);
          if (match != null) {
            description = match.group(1);
          }
        }

        // Extract movie references (moviestar-onto:hasMovie predicate).

        if (trimmedLine.contains('moviestar-onto:hasMovie') ||
            trimmedLine.contains(':hasMovie')) {
          // Extract movie IDs from the line like: moviestar-data:movie-5fc3b7da690126.

          final movieMatches = RegExp(
            r'moviestar-data:movie-(\w+)',
          ).allMatches(trimmedLine);
          for (final match in movieMatches) {
            final movieId = match.group(1);
            if (movieId != null && !movieIds.contains(movieId)) {
              movieIds.add(movieId);
            }
          }
        }

        // Extract filePath information for each movie
        if (trimmedLine.contains('moviestar-onto:filePath') ||
            trimmedLine.contains(':filePath')) {
          // Look for patterns like: moviestar-data:movie-1396 followed by filePath
          // or find the filePath and associate it with the most recent movie ID
          final filePathMatch = RegExp(
            r'"moviestar/data/movies/((?:Movie|TVShow)-(\w+)\.ttl)"',
          ).firstMatch(trimmedLine);
          if (filePathMatch != null) {
            final fullFileName =
                filePathMatch.group(1); // "TVShow-1396.ttl" or "Movie-1396.ttl"
            final movieId = filePathMatch.group(2); // "1396"
            if (movieId != null && fullFileName != null) {
              movieFilePaths[movieId] = fullFileName;
              debugPrint(
                '📁 [MovieList] Found filePath for movie $movieId: $fullFileName',
              );
            }
          }
        }
      }

      // Use fallback values if not found.

      listName ??= 'Movie List ${listId ?? 'Unknown'}';
      description ??= 'A shared movie list';

      final rawOwner = resourceInfo['owner'] ??
          resourceInfo['ownerWebId'] ??
          resourceInfo['webId'] ??
          resourceInfo['ownerId'];
      final rawSharedBy = resourceInfo['granter'] ??
          resourceInfo['granterWebId'] ??
          resourceInfo['sharedBy'] ??
          resourceInfo['sharer'];

      // Try to extract owner from resource URL if not found in resourceInfo.

      String finalOwner = rawOwner?.toString() ?? '';
      String finalSharedBy = rawSharedBy?.toString() ?? '';

      // Extract from resource URL for both owner and shared by if not found in metadata.

      final ownerMatch = RegExp(r'://[^/]+/([^/]+)/').firstMatch(resourceUrl);
      if (ownerMatch != null) {
        final username = ownerMatch.group(1);
        final webId =
            'https://pods.dev.solidcommunity.au/$username/profile/card#me';

        if (finalOwner.isEmpty) {
          finalOwner = webId;
        }
        if (finalSharedBy.isEmpty) {
          finalSharedBy =
              webId; // Use same WebID for shared by when not available.
        }
      }

      final result = {
        'listId': listId ?? 'unknown',
        'listName': listName,
        'description': description,
        'movieCount': movieIds.length, // Use extracted movie IDs count.

        'movieIds': movieIds,
        'movies': movieIds.map(
          (movieIdStr) {
            // Determine content type from filePath if available
            final filePath = movieFilePaths[movieIdStr];
            final isTvShow = filePath?.startsWith('TVShow-') ?? false;
            final contentType = isTvShow ? 'tv' : 'movie';
            final displayName =
                isTvShow ? 'TV Show $movieIdStr' : 'Movie $movieIdStr';

            debugPrint('🎬 [MovieList] Processing movie $movieIdStr:');
            debugPrint('   - FilePath: ${filePath ?? "not found"}');
            debugPrint('   - Content type: $contentType');
            debugPrint('   - Display name: $displayName');

            return {
              'movieId': movieIdStr,
              'fileName':
                  displayName, // Will be replaced with actual title in SharedMovieListDetailScreen
              'owner': _formatWebId(finalOwner),
              'ownerWebId': finalOwner, // Inherit from parent list.
              'sharedBy': _formatWebId(finalSharedBy),
              'sharedByWebId': finalSharedBy, // Inherit from parent list
              'content_type': contentType,
              'filePath': filePath, // Store the actual file path for reference
            };
          },
        ).toList(),
        'owner': _formatWebId(finalOwner),
        'ownerWebId': finalOwner, // Store full WebID for URL construction
        'sharedBy': _formatWebId(finalSharedBy),
        'sharedByWebId': finalSharedBy, // Store full WebID for URL construction
        'permissions': resourceInfo['permissions'] ??
            resourceInfo['permissionList'] ??
            'read',
        'resourceUrl': resourceUrl,
      };

      return result;
    } catch (e) {
      debugPrint('❌ Error parsing movie list data: $e');
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
        padding: const EdgeInsets.all(Dimensions.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const Gap(16),
            Text(
              'No Shared Movies',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            const Gap(8),
            Text(
              'Movies shared with you will appear here.\nStart sharing movies with friends to see them!\n\nMake sure you have POD storage enabled in Settings.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
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
        padding: const EdgeInsets.all(Dimensions.xxxl),
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
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
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
    return BaseScreen(
      title: 'Shared Movies',
      body: _buildSharedWithMeTab(),
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
}
