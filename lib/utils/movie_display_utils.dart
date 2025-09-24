/// Utility functions for formatting and displaying movie information.
///
// Time-stamp: <Friday 2025-09-10 05:51:08 +1000 Graham Williams>
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
/// Authors: Ashley Tang.

library;

import 'package:moviestar/models/content_item.dart';

/// Formats a movie rating with a star emoji.
///
/// Returns a string with a star emoji followed by the rating to 1 decimal place.
/// Example: "⭐ 7.5".
String formatMovieRating(double rating) {
  return '⭐ ${rating.toStringAsFixed(1)}';
}

/// Extracts and formats the year from a release date.
///
/// Accepts either a DateTime or String and returns the year.
/// Example: DateTime(2024, 12, 25) -> "2024".
String formatMovieYear(dynamic releaseDate) {
  if (releaseDate == null) {
    return '';
  }

  if (releaseDate is DateTime) {
    return releaseDate.year.toString();
  }

  if (releaseDate is String) {
    if (releaseDate.isEmpty) {
      return '';
    }
    // Extract year from ISO date format (YYYY-MM-DD).

    final parts = releaseDate.split('-');
    if (parts.isNotEmpty) {
      return parts[0];
    }
  }

  return '';
}

/// Returns just the content type icon without label.
///
/// Returns "🎬" for movies and "📺" for TV shows.
String getContentTypeIcon(ContentType? contentType) {
  if (contentType == null) return '';
  return contentType == ContentType.movie ? '🎬' : '📺';
}

/// Returns just the content type label without icon.
///
/// Returns "Movie" for movies and "TV Show" for TV shows.
String getContentTypeLabel(ContentType? contentType) {
  if (contentType == null) return '';
  return contentType == ContentType.movie ? 'Movie' : 'TV Show';
}

/// Validates if an image URL is valid and not empty.
///
/// Returns true if the URL starts with http:// or https://.
bool isValidImageUrl(String url) {
  if (url.trim().isEmpty) {
    return false;
  }

  final trimmedUrl = url.trim();
  return trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://');
}

/// Formats cache age into a human-readable string.
///
/// Example: Duration(hours: 2) -> "2h ago".
String formatCacheAge(Duration age) {
  if (age.inDays > 0) {
    return '${age.inDays}d ago';
  } else if (age.inHours > 0) {
    return '${age.inHours}h ago';
  } else if (age.inMinutes > 0) {
    return '${age.inMinutes}m ago';
  } else {
    return 'just now';
  }
}
