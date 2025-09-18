/// Timing constants for the Movie Star application.
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
/// Authors: Ashley Tang.

library;

/// Timing constants for animations, delays, and user feedback.

class TimingConstants {
  /// Movie rating/comments feedback display duration (2 seconds).
  ///
  /// Used for hiding saved confirmation banners in movie details screen.

  static const Duration ratingFeedbackDuration = Duration(seconds: 2);

  /// Movie card hover show delay (1 second).
  ///
  /// Delay before showing hover effects on movie cards.

  static const Duration movieCardHoverShowDelay = Duration(milliseconds: 1000);

  /// Movie card hover hide delay (100 milliseconds).
  ///
  /// Delay before hiding hover effects on movie cards.

  static const Duration movieCardHoverHideDelay = Duration(milliseconds: 100);

  /// Standard container animation duration (200 milliseconds).
  ///
  /// Duration for smooth container transitions and animations.

  static const Duration containerAnimationDuration =
      Duration(milliseconds: 200);

  /// Auto-remove operation delay (2 seconds).
  ///
  /// Delay for automatically removing completed operations from kanban board.

  static const Duration autoRemoveDelay = Duration(seconds: 2);

  /// Search input debounce delay (500 milliseconds).
  ///
  /// Delay for debouncing search input to reduce API calls.

  static const Duration searchDebounceDelay = Duration(milliseconds: 500);

  /// Short SnackBar display duration (2 seconds).

  static const Duration snackbarShortDuration = Duration(seconds: 2);

  /// Standard SnackBar display duration (3 seconds).

  static const Duration snackbarStandardDuration = Duration(seconds: 3);

  /// API key cache valid duration (24 hours).
  ///
  /// Duration for which cached API keys remain valid.

  static const int cacheValidHours = 24;

  /// Long SnackBar display duration (4 seconds).

  static const Duration snackbarLongDuration = Duration(seconds: 4);

  /// Extended SnackBar display duration (5 seconds).

  static const Duration snackbarExtendedDuration = Duration(seconds: 5);

  /// Very long SnackBar display duration (10 seconds).

  static const Duration snackbarVeryLongDuration = Duration(seconds: 10);

  /// File propagation delay (2 seconds).
  ///
  /// Delay to allow file operations to propagate before checking status.

  static const Duration filePropagationDelay = Duration(milliseconds: 2000);

  /// POD service operation delay (500 milliseconds).
  ///
  /// Standard delay for POD service operations.

  static const Duration podOperationDelay = Duration(milliseconds: 500);

  /// Solid login redirect delay (1.5 seconds).
  ///
  /// Delay before redirecting after login initialization.

  static const Duration loginRedirectDelay = Duration(milliseconds: 1500);

  /// Home screen loading animation duration (500 milliseconds).
  ///
  /// Total time for home screen loading animations.

  static const Duration homeLoadingAnimationDuration =
      Duration(milliseconds: 500);
}

/// Network timing constants.

class NetworkTimingConstants {
  /// Default network request timeout (10 seconds).

  static const Duration defaultTimeout = Duration(seconds: 10);

  /// Quick connectivity check timeout (5 seconds).

  static const Duration quickCheckTimeout = Duration(seconds: 5);

  /// DNS lookup timeout (8 seconds).

  static const Duration dnsLookupTimeout = Duration(seconds: 8);

  /// API key cache duration (10 seconds).

  static const Duration apiKeyCacheDuration = Duration(seconds: 10);

  /// User data TTL (5 minutes).

  static const Duration userDataTtl = Duration(minutes: 5);

  /// Retry operation base delay (500 milliseconds).
  ///
  /// Base delay for exponential backoff in retry operations.

  static const Duration retryBaseDelay = Duration(milliseconds: 500);
}
