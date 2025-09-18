/// Utility class for formatting dates in a consistent and locale-aware manner.
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
/// Authors: Kevin Wang

library;

import 'package:intl/intl.dart';

/// A utility class for formatting dates in a consistent and locale-aware manner.

class DateFormatUtil {
  /// Formats a date in a short format (e.g., "Apr 10, 2025").

  static String formatShort(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  /// Formats a date in a long format (e.g., "April 10, 2025").

  static String formatLong(DateTime date) {
    return DateFormat.yMMMMd().format(date);
  }

  /// Formats a date in a numeric format (e.g., "10/04/2025").

  static String formatNumeric(DateTime date) {
    return DateFormat.yMd().format(date);
  }

  /// Formats a date in a relative format (e.g., "2 days ago", "in 3 months").

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Formats a date range (e.g., "Apr 10 - May 15, 2025").

  static String formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year) {
      if (start.month == end.month) {
        return '${DateFormat.MMMd().format(start)} - ${DateFormat.d().format(end)}, ${DateFormat.y().format(start)}';
      }
      return '${DateFormat.MMMd().format(start)} - ${DateFormat.MMMd().format(end)}, ${DateFormat.y().format(start)}';
    }
    return '${DateFormat.yMMMd().format(start)} - ${DateFormat.yMMMd().format(end)}';
  }
}
