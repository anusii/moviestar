/// Widget for sorting movies.
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

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:moviestar/constants/dimensions.dart';

/// Enum representing different sort criteria for movies.

enum MovieSortCriteria {
  nameAsc,
  nameDesc,
  ratingAsc,
  ratingDesc,
  dateAsc,
  dateDesc,
}

/// A widget that displays sorting controls for movie lists.

class SortControls extends StatelessWidget {
  /// The currently selected sort criteria.

  final MovieSortCriteria selectedCriteria;

  /// Callback when sort criteria changes.

  final ValueChanged<MovieSortCriteria> onSortChanged;

  /// Creates a new [SortControls] widget.

  const SortControls({
    super.key,
    required this.selectedCriteria,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: Row(
        children: [
          Text('Sort by:', style: Theme.of(context).textTheme.bodyLarge),
          const Gap(Gaps.m),
          DropdownButton<MovieSortCriteria>(
            value: selectedCriteria,
            dropdownColor: Theme.of(context).cardTheme.color,
            underline: const SizedBox(),
            icon: Icon(Icons.sort, color: Theme.of(context).iconTheme.color),
            style: Theme.of(context).textTheme.bodyLarge,
            onChanged: (MovieSortCriteria? newValue) {
              if (newValue != null) {
                onSortChanged(newValue);
              }
            },
            items: MovieSortCriteria.values.map((MovieSortCriteria criteria) {
              String label;
              switch (criteria) {
                case MovieSortCriteria.nameAsc:
                  label = 'Name (A-Z)';
                  break;
                case MovieSortCriteria.nameDesc:
                  label = 'Name (Z-A)';
                  break;
                case MovieSortCriteria.ratingAsc:
                  label = 'Rating (Low to High)';
                  break;
                case MovieSortCriteria.ratingDesc:
                  label = 'Rating (High to Low)';
                  break;
                case MovieSortCriteria.dateAsc:
                  label = 'Date (Oldest First)';
                  break;
                case MovieSortCriteria.dateDesc:
                  label = 'Date (Newest First)';
                  break;
              }
              return DropdownMenuItem<MovieSortCriteria>(
                value: criteria,
                child: Text(label),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
