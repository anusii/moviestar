/// Basic movie info builder for movie info section.
/// Extracted to reduce file size and improve organization.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';

/// Builds basic movie information widgets.
class MovieInfoBuilder {
  /// Build the movie title.
  static Widget buildTitle(BuildContext context, Movie movie) {
    return Text(
      movie.title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Get content type text and color.
  static Map<String, dynamic> getContentTypeInfo(Movie movie) {
    final isTV = movie.contentType == ContentType.tvShow;
    return {
      'text': isTV ? '📺 TV Show' : '🎬 Movie',
      'color': isTV ? Colors.blue : Colors.green,
    };
  }

  /// Get formatted release date.
  static String getFormattedReleaseDate(Movie movie) {
    try {
      final year = movie.releaseDate.year;
      return year.toString();
    } catch (e) {
      return '';
    }
  }

  /// Get shared by text from shared movie data.
  static String getSharedByText(Map<String, dynamic>? sharedMovieData) {
    if (sharedMovieData == null) return 'someone';

    final sharedBy = sharedMovieData['sharedBy'] as String?;
    final sharedByWebId = sharedMovieData['sharedByWebId'] as String?;

    if (sharedBy != null && sharedBy.isNotEmpty) {
      return sharedBy;
    }

    if (sharedByWebId != null && sharedByWebId.isNotEmpty) {
      // Extract friendly name from WebID.

      final match = RegExp(r'://[^/]+/([^/]+)/').firstMatch(sharedByWebId);
      if (match != null) {
        return match.group(1) ?? 'someone';
      }
    }

    return 'someone';
  }
}
