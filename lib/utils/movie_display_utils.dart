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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:moviestar/models/content_item.dart';

/// Formats a movie rating with a star emoji.
///
/// Returns a string with a star emoji followed by the rating to 1 decimal place.
/// Example: "⭐ 7.5"
String formatMovieRating(double rating) {
  return '⭐ ${rating.toStringAsFixed(1)}';
}

/// Extracts and formats the year from a release date.
///
/// Accepts either a DateTime or String and returns the year.
/// Example: DateTime(2024, 12, 25) -> "2024"
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
    // Extract year from ISO date format (YYYY-MM-DD)
    final parts = releaseDate.split('-');
    if (parts.isNotEmpty) {
      return parts[0];
    }
  }

  return '';
}

/// Formats runtime from minutes to a human-readable format.
///
/// Converts runtime in minutes to "Xh Ym" format.
/// Example: 135 -> "2h 15m"
String formatRuntime(int? runtime) {
  if (runtime == null || runtime <= 0) {
    return '';
  }

  final hours = runtime ~/ 60;
  final minutes = runtime % 60;

  if (hours > 0 && minutes > 0) {
    return '${hours}h ${minutes}m';
  } else if (hours > 0) {
    return '${hours}h';
  } else {
    return '${minutes}m';
  }
}

/// Returns a widget displaying the content type with an appropriate icon.
///
/// Shows "🎬 Movie" for movies and "📺 TV Show" for TV shows.
Widget getContentTypeDisplay(
  ContentType? contentType, {
  TextStyle? textStyle,
}) {
  if (contentType == null) {
    return const SizedBox.shrink();
  }

  final isMovie = contentType == ContentType.movie;
  final icon = isMovie ? '🎬' : '📺';
  final label = isMovie ? 'Movie' : 'TV Show';

  return Text(
    '$icon $label',
    style: textStyle,
  );
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

/// Formats a list of genres into a comma-separated string.
///
/// Returns a string with genres separated by commas.
/// Example: ["Action", "Drama", "Thriller"] -> "Action, Drama, Thriller"
String formatGenres(List<String>? genres) {
  if (genres == null || genres.isEmpty) {
    return '';
  }

  return genres.join(', ');
}

/// Validates if an image URL is valid and not empty.
///
/// Returns true if the URL starts with http:// or https://.
bool isValidImageUrl(String? url) {
  if (url == null || url.trim().isEmpty) {
    return false;
  }

  final trimmedUrl = url.trim();
  return trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://');
}

/// Formats cache age into a human-readable string.
///
/// Example: Duration(hours: 2) -> "2h ago"
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

/// Builds a standardized rating widget with optional customization.
Widget buildRatingWidget(
  double rating, {
  TextStyle? textStyle,
  bool showIcon = true,
}) {
  return Text(
    showIcon ? formatMovieRating(rating) : rating.toStringAsFixed(1),
    style: textStyle,
  );
}

/// Builds a metadata widget combining multiple movie properties.
///
/// Can display rating, year, runtime, and content type in a single row.
Widget buildMovieMetadata({
  double? rating,
  dynamic releaseDate,
  int? runtime,
  ContentType? contentType,
  TextStyle? textStyle,
  String separator = ' • ',
}) {
  final parts = <String>[];

  if (rating != null) {
    parts.add(formatMovieRating(rating));
  }

  final year = formatMovieYear(releaseDate);
  if (year.isNotEmpty) {
    parts.add(year);
  }

  final runtimeStr = formatRuntime(runtime);
  if (runtimeStr.isNotEmpty) {
    parts.add(runtimeStr);
  }

  if (contentType != null) {
    parts.add(
        '${getContentTypeIcon(contentType)} ${getContentTypeLabel(contentType)}',
    );
  }

  if (parts.isEmpty) {
    return const SizedBox.shrink();
  }

  return Text(
    parts.join(separator),
    style: textStyle,
  );
}
