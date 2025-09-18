/// Universal content model representing both movies and TV shows.
///
// Time-stamp: <Friday 2025-01-17 19:45:00 +1000 Assistant>
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
/// Authors: Assistant.

library;

import 'package:hive/hive.dart';

import 'package:moviestar/utils/tmdb_image_util.dart';

part 'content_item.g.dart';

/// Enum representing the type of content.

@HiveType(typeId: 3)
enum ContentType {
  @HiveField(0)
  movie,
  @HiveField(1)
  tvShow,
}

/// A class representing a content item (movie or TV show) with its details.

@HiveType(typeId: 2)
class ContentItem extends HiveObject {
  /// Unique identifier for the content.

  @HiveField(0)
  final int id;

  /// Title of the content (movie title or TV show name).

  @HiveField(1)
  final String title;

  /// Overview or description of the content.

  @HiveField(2)
  final String overview;

  /// URL for the content's poster image.

  @HiveField(3)
  final String posterUrl;

  /// URL for the content's backdrop image.

  @HiveField(4)
  final String backdropUrl;

  /// Average rating of the content.

  @HiveField(5)
  final double voteAverage;

  /// Release date of the content (movie release or TV show first air date).

  @HiveField(6)
  final DateTime releaseDate;

  /// List of genre IDs associated with the content.

  @HiveField(7)
  final List<int> genreIds;

  /// Type of content (movie or TV show).

  @HiveField(8)
  final ContentType contentType;

  /// Creates a new [ContentItem] instance.

  ContentItem({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterUrl,
    required this.backdropUrl,
    required this.voteAverage,
    required this.releaseDate,
    required this.genreIds,
    required this.contentType,
  });

  /// Creates a [ContentItem] instance from a JSON map for movies.

  factory ContentItem.fromMovieJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Unknown Title',
      overview: json['overview'] ?? '',
      posterUrl: TmdbImageUtil.getPosterUrl(json['poster_path'] ?? ''),
      backdropUrl: TmdbImageUtil.getBackdropUrl(json['backdrop_path'] ?? ''),
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      releaseDate: _parseReleaseDate(json['release_date']),
      genreIds: List<int>.from(json['genre_ids'] ?? []),
      contentType: ContentType.movie,
    );
  }

  /// Creates a [ContentItem] instance from a JSON map for TV shows.

  factory ContentItem.fromTVJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id'] ?? 0,
      title:
          json['name'] ?? 'Unknown Title', // TV shows use 'name' not 'title'.
      overview: json['overview'] ?? '',
      posterUrl: TmdbImageUtil.getPosterUrl(json['poster_path'] ?? ''),
      backdropUrl: TmdbImageUtil.getBackdropUrl(json['backdrop_path'] ?? ''),
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      releaseDate: _parseReleaseDate(
        json['first_air_date'],
      ), // TV shows use 'first_air_date'
      genreIds: List<int>.from(json['genre_ids'] ?? []),
      contentType: ContentType.tvShow,
    );
  }

  /// Helper function to safely parse release date.

  static DateTime _parseReleaseDate(dynamic dateValue) {
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

  /// Converts the [ContentItem] instance to a JSON map.

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (contentType == ContentType.movie) 'title': title else 'name': title,
      'overview': overview,
      'poster_path': TmdbImageUtil.extractPath(
        posterUrl,
      ).replaceAll('/p/w500/', ''),
      'backdrop_path': TmdbImageUtil.extractPath(
        backdropUrl,
      ).replaceAll('/original/', ''),
      'vote_average': voteAverage,
      if (contentType == ContentType.movie)
        'release_date': releaseDate.toIso8601String()
      else
        'first_air_date': releaseDate.toIso8601String(),
      'genre_ids': genreIds,
      'content_type': contentType.name,
    };
  }

  /// Gets a display-friendly release year.

  String get releaseYear => releaseDate.year.toString();

  /// Gets a display-friendly content type label.

  String get contentTypeLabel =>
      contentType == ContentType.movie ? 'Movie' : 'TV Show';

  /// Gets an appropriate icon for the content type.

  String get contentTypeIcon => contentType == ContentType.movie ? '🎬' : '📺';
}
