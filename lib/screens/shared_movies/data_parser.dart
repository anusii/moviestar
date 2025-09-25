/// Data parsing utilities for shared movies screen.
/// Extracted from SharedMoviesScreen to reduce file size.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'dart:convert';

/// Handles parsing of movie and movie list data from TTL content.

class SharedMoviesDataParser {
  /// Parse movie data from TTL content.

  static Future<Map<String, dynamic>?> parseMovieData(
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
        genreIds = (movieData['genreIds'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList();
      }

      // Extract user data (rating and comments) if available.

      if (userJsonMatch != null) {
        final userJsonData = userJsonMatch.group(1)!;
        final userData = jsonDecode(userJsonData) as Map<String, dynamic>;
        rating = (userData['rating'] as num?)?.toDouble();
        comments = userData['comments'] as String?;
      }

      // If JSON parsing failed, fall back to TTL parsing.

      if (movieTitle == null || movieId == null) {
        final titleMatch = RegExp(r':title\s+"([^"]+)"').firstMatch(ttlContent);
        if (titleMatch != null) {
          movieTitle = titleMatch.group(1);
        }

        if (movieId == null) {
          final idMatch =
              RegExp(r':movieId\s+"([^"]+)"').firstMatch(ttlContent);
          if (idMatch != null) {
            movieId = idMatch.group(1);
          }
        }

        if (posterUrl == null) {
          final posterMatch =
              RegExp(r':posterUrl\s+"([^"]+)"').firstMatch(ttlContent);
          if (posterMatch != null) {
            posterUrl = posterMatch.group(1);
          }
        }

        if (backdropUrl == null) {
          final backdropMatch =
              RegExp(r':backdropUrl\s+"([^"]+)"').firstMatch(ttlContent);
          if (backdropMatch != null) {
            backdropUrl = backdropMatch.group(1);
          }
        }

        if (overview == null) {
          final overviewMatch =
              RegExp(r':overview\s+"([^"]*)"').firstMatch(ttlContent);
          if (overviewMatch != null) {
            overview = overviewMatch.group(1);
          }
        }

        if (releaseDate == null) {
          final releaseDateMatch =
              RegExp(r':releaseDate\s+"([^"]+)"').firstMatch(ttlContent);
          if (releaseDateMatch != null) {
            releaseDate = releaseDateMatch.group(1);
          }
        }

        if (voteAverage == null) {
          final ratingMatch =
              RegExp(r':voteAverage\s+"([^"]+)"').firstMatch(ttlContent);
          if (ratingMatch != null) {
            final ratingStr = ratingMatch.group(1);
            voteAverage = double.tryParse(ratingStr ?? '');
          }
        }

        // Try to extract genre IDs if available.

        if (genreIds == null) {
          final genreMatches =
              RegExp(r':genreId\s+"([^"]+)"').allMatches(ttlContent);
          genreIds = genreMatches
              .map((match) => int.tryParse(match.group(1) ?? ''))
              .where((id) => id != null)
              .cast<int>()
              .toList();
        }

        // Extract user-specific data from TTL.

        final userRatingMatch =
            RegExp(r':userRating\s+"([^"]+)"').firstMatch(ttlContent);
        if (userRatingMatch != null) {
          rating = double.tryParse(userRatingMatch.group(1) ?? '');
        }

        final userCommentsMatch =
            RegExp(r':userComments\s+"([^"]*)"').firstMatch(ttlContent);
        if (userCommentsMatch != null) {
          comments = userCommentsMatch.group(1);
        }
      }

      if (movieTitle != null && movieId != null) {
        // Extract sharer info from resource info.

        final sharerWebId = resourceInfo['sharedBy'] as String? ?? '';
        final sharerId = Uri.tryParse(sharerWebId)?.pathSegments.last ?? '';

        return {
          'movieId': movieId,
          'title': movieTitle,
          'posterUrl': posterUrl ?? '',
          'backdropUrl': backdropUrl ?? posterUrl ?? '',
          'overview': overview ?? '',
          'releaseDate': releaseDate ?? '',
          'voteAverage': voteAverage ?? 0.0,
          'genreIds': genreIds ?? <int>[],
          'rating': rating,
          'comments': comments,
          'sharedBy': sharerId,
          'sharedByWebId': sharerWebId,
          'resourceUrl': resourceUrl,
          'fileName': fileName,
        };
      }
    } catch (e) {
      // Failed to parse movie data.
    }
    return null;
  }

  /// Parse movie list data from TTL content.

  static Future<Map<String, dynamic>?> parseMovieListData(
    String ttlContent,
    String resourceUrl,
    Map resourceInfo,
  ) async {
    try {
      String? listName;
      String? listDescription;
      final List<Map<String, dynamic>> movies = [];

      // Try JSON backup first.

      final listJsonMatch =
          RegExp(r'# JSON_LIST_DATA: (.+)').firstMatch(ttlContent);

      if (listJsonMatch != null) {
        final listJsonData = listJsonMatch.group(1)!;
        final listData = jsonDecode(listJsonData) as Map<String, dynamic>;

        listName = listData['name'] as String?;
        listDescription = listData['description'] as String?;

        final movieList = listData['movies'] as List<dynamic>? ?? [];
        for (final movieData in movieList) {
          if (movieData is Map<String, dynamic>) {
            movies.add(movieData);
          }
        }
      } else {
        // Fallback to TTL parsing.

        final nameMatch = RegExp(r':name\s+"([^"]+)"').firstMatch(ttlContent);
        if (nameMatch != null) {
          listName = nameMatch.group(1);
        }

        final descMatch =
            RegExp(r':description\s+"([^"]*)"').firstMatch(ttlContent);
        if (descMatch != null) {
          listDescription = descMatch.group(1);
        }

        // Extract movies from TTL.

        final movieMatches =
            RegExp(r':hasMovie\s+:movie-(\d+)\s*\.').allMatches(ttlContent);

        for (final match in movieMatches) {
          final movieId = match.group(1);
          if (movieId != null) {
            // Try to find movie details in the TTL.

            final movieSection = RegExp(
              ':movie-$movieId\\s+[^.]*\\.',
              multiLine: true,
              dotAll: true,
            ).firstMatch(ttlContent);

            if (movieSection != null) {
              final movieTtl = movieSection.group(0) ?? '';
              final title = RegExp(r':title\s+"([^"]+)"')
                      .firstMatch(movieTtl)
                      ?.group(1) ??
                  'Unknown';
              final posterUrl = RegExp(r':posterUrl\s+"([^"]+)"')
                      .firstMatch(movieTtl)
                      ?.group(1) ??
                  '';

              movies.add({
                'movieId': movieId,
                'title': title,
                'posterUrl': posterUrl,
              });
            }
          }
        }
      }

      if (listName != null) {
        // Extract sharer info.

        final sharerWebId = resourceInfo['sharedBy'] as String? ?? '';
        final sharerId = Uri.tryParse(sharerWebId)?.pathSegments.last ?? '';

        return {
          'name': listName,
          'description': listDescription ?? '',
          'movies': movies,
          'sharedBy': sharerId,
          'sharedByWebId': sharerWebId,
          'resourceUrl': resourceUrl,
        };
      }
    } catch (e) {
      // Failed to parse movie list data.
    }
    return null;
  }
}
