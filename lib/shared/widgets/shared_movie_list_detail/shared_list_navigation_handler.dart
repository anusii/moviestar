/// Navigation handling for shared movie list detail screen.
/// Handles movie details navigation and error handling.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/screens/movie_details_screen.dart';
import 'package:moviestar/core/services/favorites/favorites_service_adapter.dart';
import 'package:moviestar/core/services/favorites/favorites_service_manager.dart';
import 'package:moviestar/shared/widgets/shared_movie_list_detail/shared_list_data_loader.dart';

/// Handles navigation operations for shared movie list detail screen.
class SharedListNavigationHandler {
  final WidgetRef ref;
  final BuildContext context;
  final StatefulWidget widget;
  final ScreenStateMixin screenStateMixin;
  final SharedListDataLoader dataLoader;

  SharedListNavigationHandler({
    required this.ref,
    required this.context,
    required this.widget,
    required this.screenStateMixin,
    required this.dataLoader,
  });

  /// Navigate to movie details screen with enhanced data.
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

      // Fetch full movie details from TMDB API.
      final cachedMovieService = ref.read(cachedMovieServiceProvider);
      final movie = await cachedMovieService.getMovieDetails(movieId);

      // Try to fetch individual movie file data to get ratings and comments.
      final enhancedMovieData =
          await dataLoader.fetchIndividualMovieData(movieData);

      // Dismiss loading indicator.
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Get SharedPreferences and create FavoritesServiceManager.
      final prefs = await SharedPreferences.getInstance();
      if (!context.mounted) return;

      final favoritesServiceManager = FavoritesServiceManager(
        prefs,
        context,
        widget,
      );
      final favoritesService = FavoritesServiceAdapter(favoritesServiceManager);

      // Navigate to MovieDetailsScreen with enhanced shared movie data.
      if (context.mounted) {
        await screenStateMixin.safeNavigateTo(
          MaterialPageRoute(
            builder: (context) => MovieDetailsScreen(
              movie: movie,
              favoritesService: favoritesService,
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

    debugPrint('Error navigating to movie details: $error');
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