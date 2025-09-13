/// Models for list operation results in POD storage.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:moviestar/models/custom_list.dart';

/// Result model for list operations.
class ListOperationResult {
  final bool success;
  final String? error;
  final CustomList? list;
  final List<CustomList>? lists;

  const ListOperationResult({
    required this.success,
    this.error,
    this.list,
    this.lists,
  });

  factory ListOperationResult.success({
    CustomList? list,
    List<CustomList>? lists,
  }) {
    return ListOperationResult(
      success: true,
      list: list,
      lists: lists,
    );
  }

  factory ListOperationResult.failure(String error) {
    return ListOperationResult(
      success: false,
      error: error,
    );
  }
}
