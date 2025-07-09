/// Data model representing a movie in the Movie Star application.
///
// Time-stamp: <Friday 2025-07-04 14:39:11 +1000 Graham Williams>
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
/// Authors: Kevin Wang, Ashley Tang

library;

import 'package:moviestar/utils/tmdb_image_util.dart';

/// A class representing a movie with its details.
class Movie {
  /// Unique identifier for the movie.

  final int id;

  /// Title of the movie.

  final String title;

  /// Overview or description of the movie.

  final String overview;

  /// URL for the movie's poster image.

  final String posterUrl;

  /// URL for the movie's backdrop image.

  final String backdropUrl;

  /// Average rating of the movie.

  final double voteAverage;

  /// Release date of the movie.

  final DateTime releaseDate;

  /// List of genre IDs associated with the movie.

  final List<int> genreIds;

  /// Creates a new [Movie] instance.

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterUrl,
    required this.backdropUrl,
    required this.voteAverage,
    required this.releaseDate,
    required this.genreIds,
  });

  /// Creates a [Movie] instance from a JSON map.

  factory Movie.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse release date.

    DateTime parseReleaseDate(dynamic dateValue) {
      if (dateValue == null || dateValue.toString().isEmpty) {
        // Default to current date if no release date.

        return DateTime.now();
      }

      try {
        return DateTime.parse(dateValue.toString());
      } catch (e) {
        // If parsing fails, return current date as fallback.

        return DateTime.now();
      }
    }

    return Movie(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unknown Title',
      overview: json['overview'] ?? '',
      posterUrl: TmdbImageUtil.getPosterUrl(json['poster_path'] ?? ''),
      backdropUrl: TmdbImageUtil.getBackdropUrl(json['backdrop_path'] ?? ''),
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      releaseDate: parseReleaseDate(json['release_date']),
      genreIds: List<int>.from(json['genre_ids'] ?? []),
    );
  }

  /// Converts the [Movie] instance to a JSON map.

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'overview': overview,
      'poster_path': TmdbImageUtil.extractPath(
        posterUrl,
      ).replaceAll('/p/w500/', ''),
      'backdrop_path': TmdbImageUtil.extractPath(
        backdropUrl,
      ).replaceAll('/original/', ''),
      'vote_average': voteAverage,
      'release_date': releaseDate.toIso8601String(),
      'genre_ids': genreIds,
    };
  }
}
