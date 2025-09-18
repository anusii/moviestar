/// Navigation handling for shared movie list detail screen.
/// Handles movie details navigation and error handling.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moviestar/core/services/favorites/service.dart';
import 'package:moviestar/core/services/favorites/service_adapter.dart';
import 'package:moviestar/core/services/favorites/service_manager.dart';
import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/shared/widgets/shared_movie_list_detail/data_loader.dart';

/// Handles navigation operations for shared movie list detail screen.
class SharedListNavigationHandler {
  final WidgetRef ref;
  final BuildContext context;
  final StatefulWidget widget;
  final ScreenStateMixin screenStateMixin;
  final SharedListDataLoader dataLoader;
  final FavoritesService? favoritesService;

  SharedListNavigationHandler({
    required this.ref,
    required this.context,
    required this.widget,
    required this.screenStateMixin,
    required this.dataLoader,
    this.favoritesService,
  });

  /// Navigate to movie details screen with enhanced data.
  /// Uses direct Movie creation approach (similar to working Shared tab logic).
  /// instead of TMDB API calls to avoid API key and network issues.
  Future<void> navigateToMovieDetails(Map<String, dynamic> movieData) async {
    try {
      final movieId =
          int.tryParse(movieData['movieId']?.toString() ?? '0') ?? 0;

      if (movieId == 0) {
        throw Exception('Invalid movie ID');
      }

      // Show loading indicator.
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Get enhanced movie data for ratings and comments
      final enhancedMovieData =
          await dataLoader.fetchIndividualMovieData(movieData);

      // Create Movie object directly from available data (like working Shared tab logic)
      // This avoids TMDB API calls and associated API key/network issues
      final movieTitle = enhancedMovieData['title'] ??
          enhancedMovieData['fileName'] ??
          'Unknown Movie';
      final posterUrl = enhancedMovieData['posterUrl'] ?? '';
      final backdropUrl = enhancedMovieData['backdropUrl'] ?? posterUrl ?? '';
      final overview = enhancedMovieData['overview'] ?? 'Shared movie';
      final releaseDate =
          DateTime.tryParse(enhancedMovieData['releaseDate'] ?? '') ??
              DateTime.now();
      final voteAverage =
          (enhancedMovieData['voteAverage'] as num?)?.toDouble() ??
              (enhancedMovieData['rating'] as num?)?.toDouble() ??
              0.0;
      final genreIds = (enhancedMovieData['genreIds'] as List?)
              ?.map((e) => e as int)
              .toList() ??
          <int>[];

      final movie = Movie(
        id: movieId,
        title: movieTitle,
        overview: overview,
        posterUrl: posterUrl,
        backdropUrl: backdropUrl,
        voteAverage: voteAverage,
        releaseDate: releaseDate,
        genreIds: genreIds,
      );

      // Dismiss loading indicator
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Use provided favorites service or create a minimal one for shared context.
      FavoritesService finalFavoritesService;
      if (favoritesService != null) {
        finalFavoritesService = favoritesService!;
      } else {
        // Create a minimal favorites service for shared viewing context
        final prefs = await SharedPreferences.getInstance();
        if (!context.mounted) return;

        final favoritesServiceManager = FavoritesServiceManager(
          prefs,
          context,
          widget,
        );
        finalFavoritesService =
            FavoritesServiceAdapter(favoritesServiceManager);
      }

      // Navigate to MovieDetailsScreen with enhanced shared movie data.
      if (context.mounted) {
        await screenStateMixin.safeNavigateTo(
          MaterialPageRoute(
            builder: (context) => MovieDetailsScreen(
              movie: movie,
              favoritesService: finalFavoritesService,
              sharedMovieData: enhancedMovieData,
            ),
          ),
        );
      }
    } catch (e) {
      await _handleNavigationError(e);
    }
  }

  /// Handle navigation errors with appropriate user feedback.
  Future<void> _handleNavigationError(dynamic error) async {
    // Dismiss loading indicator if it's showing.
    if (context.mounted) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).popUntil((route) => route.isFirst);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading movie details: ${error.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Show loading dialog during navigation.
  void showLoadingDialog() {
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }
  }

  /// Dismiss loading dialog.
  void dismissLoadingDialog() {
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  /// Show error message to user.
  void showErrorMessage(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Show success message to user.
  void showSuccessMessage(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }
}
