/// Data structure for shared MovieList information.
///
// Time-stamp: <Thursday 2025-04-10 11:47:48 +1000 Graham Williams>
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

import 'package:moviestar/models/movie.dart';

/// Data structure representing a shared MovieList.

class SharedMovieList {
  final String id;
  final String name;
  final String? description;
  final String? filePath;
  final List<Movie> movies;
  final String resourceUrl;
  final Map<String, dynamic> resourceInfo;
  final String listContent;
  final bool isSharedWithMe;
  final Map<String, String>? sharedWith;
  final DateTime? sharedDate;

  const SharedMovieList({
    required this.id,
    required this.name,
    this.description,
    this.filePath,
    required this.movies,
    required this.resourceUrl,
    required this.resourceInfo,
    required this.listContent,
    required this.isSharedWithMe,
    this.sharedWith,
    this.sharedDate,
  });

  /// Creates a SharedMovieList from a `Map<String, dynamic>` (for migration).

  factory SharedMovieList.fromMap(
    String resourceUrl,
    Map<String, dynamic> map,
  ) {
    return SharedMovieList(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unknown List',
      description: map['description'],
      filePath: map['filePath'],
      movies: (map['movies'] as List<dynamic>?)?.cast<Movie>().toList() ?? [],
      resourceUrl: map['resourceUrl'] ?? resourceUrl,
      resourceInfo: map['resourceInfo'] ?? {},
      listContent: map['listContent'] ?? '',
      isSharedWithMe: map['isSharedWithMe'] ?? false,
      sharedWith: map['sharedWith']?.cast<String, String>(),
      sharedDate: map['sharedDate'] != null
          ? DateTime.tryParse(map['sharedDate'].toString())
          : null,
    );
  }

  /// Converts the SharedMovieList to a `Map<String, dynamic>`.

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'filePath': filePath,
      'movies': movies,
      'resourceUrl': resourceUrl,
      'resourceInfo': resourceInfo,
      'listContent': listContent,
      'isSharedWithMe': isSharedWithMe,
      'sharedWith': sharedWith,
      'sharedDate': sharedDate?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'SharedMovieList{id: $id, name: $name, moviesCount: ${movies.length}, isSharedWithMe: $isSharedWithMe}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SharedMovieList &&
        other.id == id &&
        other.resourceUrl == resourceUrl;
  }

  @override
  int get hashCode => Object.hash(id, resourceUrl);
}

/// Data structure representing a MovieList that the current user has shared with others.

class MySharedMovieList {
  final String id;
  final String name;
  final String? description;
  final String? filePath;
  final List<Movie> movies;
  final String fileName;
  final String resourceUrl;
  final bool isMySharedList;
  final Map<String, String>? sharedWith;
  final DateTime? sharedDate;

  const MySharedMovieList({
    required this.id,
    required this.name,
    this.description,
    this.filePath,
    required this.movies,
    required this.fileName,
    required this.resourceUrl,
    required this.isMySharedList,
    this.sharedWith,
    this.sharedDate,
  });

  /// Creates a MySharedMovieList from a `Map<String, dynamic>` (for migration).

  factory MySharedMovieList.fromMap(String listId, Map<String, dynamic> map) {
    return MySharedMovieList(
      id: map['id'] ?? listId,
      name: map['name'] ?? 'Unknown List',
      description: map['description'],
      filePath: map['filePath'],
      movies: (map['movies'] as List<dynamic>?)?.cast<Movie>().toList() ?? [],
      fileName: map['fileName'] ?? '',
      resourceUrl: map['resourceUrl'] ?? '',
      isMySharedList: map['isMySharedList'] ?? true,
      sharedWith: map['sharedWith']?.cast<String, String>(),
      sharedDate: map['sharedDate'] != null
          ? DateTime.tryParse(map['sharedDate'].toString())
          : null,
    );
  }

  /// Converts the MySharedMovieList to a `Map<String, dynamic>`.

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'filePath': filePath,
      'movies': movies,
      'fileName': fileName,
      'resourceUrl': resourceUrl,
      'isMySharedList': isMySharedList,
      'sharedWith': sharedWith,
      'sharedDate': sharedDate?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'MySharedMovieList{id: $id, name: $name, moviesCount: ${movies.length}, sharedWithCount: ${sharedWith?.length ?? 0}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MySharedMovieList &&
        other.id == id &&
        other.resourceUrl == resourceUrl;
  }

  @override
  int get hashCode => Object.hash(id, resourceUrl);
}
