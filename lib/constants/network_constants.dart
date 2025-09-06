/// Network constants for the Movie Star application.
///
// Time-stamp: <Tuesday 2025-09-03 16:00:00 +1100 Ashley Tang>
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
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

/// Network operation constants for retry logic and timeouts.

class NetworkConstants {
  /// Maximum number of retry attempts.

  static const int maxRetryAttempts = 3;

  /// Base delay for exponential backoff (500 milliseconds).
  ///
  /// Used in retry logic: delay = baseDelay * attempt

  static const int backoffBaseDelayMs = 500;
}
