/// Data model representing a movie in the Movie Star application.
///
// Time-stamp: <Friday 2025-07-04 14:39:11 +1000 Graham Williams>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Kevin Wang, Ashley Tang.

library;

import 'package:hive/hive.dart';

import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/utils/tmdb_image_util.dart';

part 'movie.g.dart';

/// A class representing a movie with its details.

@HiveType(typeId: 0)
class Movie extends HiveObject {
  /// Unique identifier for the movie.

  @HiveField(0)
  final int id;

  /// Title of the movie.

  @HiveField(1)
  final String title;

  /// Overview or description of the movie.

  @HiveField(2)
  final String overview;

  /// URL for the movie's poster image.

  @HiveField(3)
  final String posterUrl;

  /// URL for the movie's backdrop image.

  @HiveField(4)
  final String backdropUrl;

  /// Average rating of the movie.

  @HiveField(5)
  final double voteAverage;

  /// Release date of the movie.

  @HiveField(6)
  final DateTime releaseDate;

  /// List of genre IDs associated with the movie.

  @HiveField(7)
  final List<int> genreIds;

  /// Content type - tracks whether this Movie was originally a TV show.
  /// Added to Hive persistence to fix label persistence issue.

  @HiveField(8)
  final ContentType? contentType;

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
    this.contentType,
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
      contentType: json['content_type'] != null
          ? (json['content_type'] == 'tv'
              ? ContentType.tvShow
              : ContentType.movie)
          : null,
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
      if (contentType != null)
        'content_type': contentType == ContentType.tvShow ? 'tv' : 'movie',
    };
  }

  /// Converts this Movie to a ContentItem for unified handling.

  ContentItem toContentItem() {
    return ContentItem(
      id: id,
      title: title,
      overview: overview,
      posterUrl: posterUrl,
      backdropUrl: backdropUrl,
      voteAverage: voteAverage,
      releaseDate: releaseDate,
      genreIds: genreIds,
      contentType: contentType ?? ContentType.movie,
    );
  }

  /// Creates a Movie from a ContentItem (for backward compatibility).
  ///
  /// Note: This also works for TV shows since they have the same structure.
  /// TV shows are treated as movies for list management purposes.

  factory Movie.fromContentItem(ContentItem contentItem) {
    return Movie(
      id: contentItem.id,
      title: contentItem.title,
      overview: contentItem.overview,
      posterUrl: contentItem.posterUrl,
      backdropUrl: contentItem.backdropUrl,
      voteAverage: contentItem.voteAverage,
      releaseDate: contentItem.releaseDate,
      genreIds: contentItem.genreIds,
      contentType: contentItem.contentType,
    );
  }
}
