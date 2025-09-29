/// Utility functions for sorting movies.
///
// Time-stamp: <Thursday 2025-04-10 11:47:48 +1000 Graham Williams>
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
/// Authors: Kevin Wang.

library;

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/widgets/sort_controls.dart';

/// Sorts a list of movies based on the specified criteria.

List<Movie> sortMovies(List<Movie> movies, MovieSortCriteria criteria) {
  switch (criteria) {
    case MovieSortCriteria.nameAsc:
      movies.sort((a, b) => a.title.compareTo(b.title));
      break;
    case MovieSortCriteria.nameDesc:
      movies.sort((a, b) => b.title.compareTo(a.title));
      break;
    case MovieSortCriteria.ratingAsc:
      movies.sort((a, b) => a.voteAverage.compareTo(b.voteAverage));
      break;
    case MovieSortCriteria.ratingDesc:
      movies.sort((a, b) => b.voteAverage.compareTo(a.voteAverage));
      break;
    case MovieSortCriteria.dateAsc:
      movies.sort((a, b) => a.releaseDate.compareTo(b.releaseDate));
      break;
    case MovieSortCriteria.dateDesc:
      movies.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
      break;
  }
  return movies;
}
