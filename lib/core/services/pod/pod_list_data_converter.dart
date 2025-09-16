/// Data conversion utilities for POD custom lists.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/models/custom_list.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/utils/turtle_serializer.dart';

/// Handles data conversion between MovieList and CustomList formats.
class PodListDataConverter {
  /// Converts MovieList data to CustomList format.
  static CustomList movieListToCustomList(
    String movieListId,
    Map<String, dynamic> movieListData,
  ) {
    final movies = List<Movie>.from(movieListData['movies'] ?? []);
    final movieIds = movies.map((m) => m.id).toList();

    return CustomList(
      id: movieListId,
      name: movieListData['name'] ?? 'Unnamed List',
      description: movieListData['description'],
      movieIds: movieIds,
      createdAt: DateTime.now(), // MovieList doesn't track creation time yet
      updatedAt: DateTime.now(),
    );
  }

  /// Creates TTL content for a MovieList with updated metadata.
  static String createMovieListTtl(
    String listId,
    String name,
    List<Movie> movies, {
    String? description,
  }) {
    return TurtleSerializer.createMovieList(
      listId,
      name,
      movies: movies,
      description: description,
    );
  }

  /// Filters out placeholder movies from a list.
  static List<Movie> filterValidMovies(List<Movie> movies) {
    return movies.where((movie) {
      final isMoviePlaceholder = RegExp(r'^Movie \d+$').hasMatch(movie.title);
      final isTVPlaceholder = RegExp(r'^TV Show \d+$').hasMatch(movie.title);
      final isValid = !isMoviePlaceholder && !isTVPlaceholder;

      if (!isValid) {
        debugPrint(
          '📁 [PodListDataConverter] Filtering out placeholder: ${movie.title}',
        );
      }

      return isValid;
    }).toList();
  }

  /// Creates a minimal Movie object for removal operations.
  static Movie createMinimalMovie(int movieId) {
    return Movie(
      id: movieId,
      title: '',
      overview: '',
      posterUrl: '',
      backdropUrl: '',
      voteAverage: 0,
      releaseDate: DateTime(1970),
      genreIds: [],
    );
  }

  /// Generates filename for a MovieList.
  static String generateFileName(String listId) {
    return 'user_lists/MovieList-$listId.ttl';
  }

  /// Creates an empty CustomList for fallback scenarios.
  static CustomList createEmptyCustomList() {
    return CustomList(
      id: '',
      name: '',
      movieIds: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
