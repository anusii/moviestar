/// Data model representing a custom movie list in the Movie Star application.
///
// Time-stamp: <Monday 2025-08-18 10:00:00 +1000 Ashley Tang>
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

import 'package:hive/hive.dart';

part 'custom_list.g.dart';

/// A class representing a custom movie list.

@HiveType(typeId: 1)
class CustomList extends HiveObject {
  /// Unique identifier for the custom list.

  @HiveField(0)
  final String id;

  /// Name of the custom list.

  @HiveField(1)
  final String name;

  /// Description of the custom list (optional).

  @HiveField(2)
  final String? description;

  /// List of movie IDs in this custom list.

  @HiveField(3)
  final List<int> movieIds;

  /// Date when the list was created.

  @HiveField(4)
  final DateTime createdAt;

  /// Date when the list was last modified.

  @HiveField(5)
  final DateTime updatedAt;

  /// Creates a new [CustomList] instance.

  CustomList({
    required this.id,
    required this.name,
    this.description,
    required this.movieIds,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [CustomList] instance from a JSON map.

  factory CustomList.fromJson(Map<String, dynamic> json) {
    return CustomList(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      movieIds: List<int>.from(json['movieIds'] ?? []),
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Converts the [CustomList] instance to a JSON map.

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'movieIds': movieIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this custom list with optional field updates.

  CustomList copyWith({
    String? id,
    String? name,
    String? description,
    List<int>? movieIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomList(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      movieIds: movieIds ?? this.movieIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Returns the number of movies in this list.

  int get movieCount => movieIds.length;
}
