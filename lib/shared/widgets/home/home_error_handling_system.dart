/// HomeScreen Error Handling System Component - Comprehensive error management and API key handling.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/core/services/api/api_key_validation_service.dart';
import 'package:moviestar/core/services/cache/hive_movie_cache_service.dart';
import 'package:moviestar/core/services/network/network_connectivity_service.dart';
import 'package:moviestar/models/app_error.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/services/error_mapper_service.dart';
import 'package:moviestar/widgets/error_display_widget.dart';

/// Component that handles comprehensive error management and API key validation for HomeScreen.
class HomeErrorHandlingSystem extends StatefulWidget {
  final WidgetRef ref;
  final bool mounted;
  final VoidCallback onStateUpdate;

  const HomeErrorHandlingSystem({
    super.key,
    required this.ref,
    required this.mounted,
    required this.onStateUpdate,
  });

  @override
  State<HomeErrorHandlingSystem> createState() =>
      _HomeErrorHandlingSystemState();
}

class _HomeErrorHandlingSystemState extends State<HomeErrorHandlingSystem> {
  // Track API key error state per view to show single error message
  bool _hasApiKeyError = false;
  String? _apiKeyErrorMessage;

  /// Checks all movie providers for API key errors and updates state.
  void checkForApiKeyErrors(
    AsyncValue<CacheResult<List<Movie>>> popularMovies,
    AsyncValue<CacheResult<List<Movie>>> nowPlayingMovies,
    AsyncValue<CacheResult<List<Movie>>> topRatedMovies,
    AsyncValue<CacheResult<List<Movie>>> upcomingMovies,
  ) {
    // Check if any provider has an API key error
    bool foundApiKeyError = false;
    String? errorMessage;

    final providers = [
      popularMovies,
      nowPlayingMovies,
      topRatedMovies,
      upcomingMovies,
    ];

    for (final provider in providers) {
      if (provider.hasError) {
        final error = provider.error!;
        // Check if this is an API key error
        if (_isApiKeyError(error)) {
          foundApiKeyError = true;
          errorMessage = error.toString();
          break;
        }
      }
    }

    // Update state if API key error status changed
    if (foundApiKeyError != _hasApiKeyError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.mounted && mounted) {
          setState(() {
            _hasApiKeyError = foundApiKeyError;
            _apiKeyErrorMessage = errorMessage;
          });
          widget.onStateUpdate();
        }
      });
    }
  }

  /// Checks if an error is an API key related error.
  bool _isApiKeyError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('401') ||
        errorString.contains('403') ||
        errorString.contains('unauthorized') ||
        errorString.contains('api key') ||
        errorString.contains('forbidden');
  }

  /// Invalidates all movie providers for refresh.
  void invalidateProviders() {
    widget.ref.invalidate(popularMoviesWithCacheInfoProvider);
    widget.ref.invalidate(nowPlayingMoviesWithCacheInfoProvider);
    widget.ref.invalidate(topRatedMoviesWithCacheInfoProvider);
    widget.ref.invalidate(upcomingMoviesWithCacheInfoProvider);
  }

  /// Builds a prominent API key error overlay for the entire view.
  Widget buildApiKeyErrorOverlay() {
    return FutureBuilder<UserFriendlyError>(
      future: _createUserFriendlyError(
        widget.ref,
        _apiKeyErrorMessage ?? 'API key error',
        StackTrace.current,
        () {
          // Retry by refreshing all providers
          if (widget.mounted && mounted) {
            widget.ref.invalidate(popularMoviesWithCacheInfoProvider);
            widget.ref.invalidate(nowPlayingMoviesWithCacheInfoProvider);
            widget.ref.invalidate(topRatedMoviesWithCacheInfoProvider);
            widget.ref.invalidate(upcomingMoviesWithCacheInfoProvider);
            setState(() {
              _hasApiKeyError = false;
              _apiKeyErrorMessage = null;
            });
            widget.onStateUpdate();
          }
        },
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userFriendlyError = snapshot.data;
        if (userFriendlyError != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.huge),
              child: ErrorDisplayWidget.fromUserFriendlyError(
                error: userFriendlyError,
              ),
            ),
          );
        }

        // Fallback to basic error display
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.huge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.vpn_key_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const Gap(16),
                Text(
                  'API Key Required',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
                const Gap(8),
                Text(
                  'Configure your API key to access movie information.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds a smart error widget that provides user-friendly error messages and actions.
  Widget buildSmartErrorWidget(
    Object error,
    StackTrace stackTrace,
  ) {
    return FutureBuilder<UserFriendlyError>(
      future: _buildUserFriendlyError(error, stackTrace),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(Dimensions.xl),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final userFriendlyError = snapshot.data;
        if (userFriendlyError != null) {
          return ErrorDisplayWidget.fromUserFriendlyError(
            error: userFriendlyError,
          );
        }

        // Fallback
        return ErrorDisplayWidget(
          message: 'Error loading movies: $error',
          onRetry: () =>
              widget.ref.invalidate(popularMoviesWithCacheInfoProvider),
        );
      },
    );
  }

  /// Builds a compact smart error widget for movie rows.
  Widget buildSmartErrorWidgetCompact(
    Object error,
    StackTrace stackTrace,
    String title,
    VoidCallback onRetry,
  ) {
    return FutureBuilder<UserFriendlyError>(
      future: _buildUserFriendlyErrorCompact(error, stackTrace, onRetry),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ErrorDisplayWidget.compact(
            message: 'Loading error details...',
          );
        }

        final userFriendlyError = snapshot.data;
        if (userFriendlyError != null) {
          return ErrorDisplayWidget.compactFromUserFriendlyError(
            error: userFriendlyError,
          );
        }

        // Fallback
        return ErrorDisplayWidget.compact(
          message: 'Failed to load $title',
          onRetry: onRetry,
        );
      },
    );
  }

  /// Builds a compact error widget with retry functionality.
  Widget buildSmartErrorWidgetCompactWithRetry(
    Object error,
    StackTrace stackTrace,
    String title,
    VoidCallback onRetry,
  ) {
    return buildSmartErrorWidgetCompact(error, stackTrace, title, onRetry);
  }

  /// Helper method to build user-friendly error for full widget.
  Future<UserFriendlyError> _buildUserFriendlyError(
    Object error,
    StackTrace stackTrace,
  ) async {
    return _createUserFriendlyError(
      widget.ref,
      error,
      stackTrace,
      () => widget.ref.invalidate(popularMoviesWithCacheInfoProvider),
    );
  }

  /// Helper method to build user-friendly error for compact widget.
  Future<UserFriendlyError> _buildUserFriendlyErrorCompact(
    Object error,
    StackTrace stackTrace,
    VoidCallback onRetry,
  ) async {
    return _createUserFriendlyError(widget.ref, error, stackTrace, onRetry);
  }

  /// Creates a user-friendly error with smart detection services.
  Future<UserFriendlyError> _createUserFriendlyError(
    WidgetRef ref,
    Object error,
    StackTrace stackTrace,
    VoidCallback onRetry,
  ) async {
    // Create services for smart detection
    final apiKeyService = ref.read(apiKeyServiceProvider);
    final apiKeyValidationService = ApiKeyValidationService(apiKeyService);
    final networkConnectivityService = NetworkConnectivityService.forTMDB();

    // Create error context with available actions and services
    final errorContext = ErrorContext(
      onRetry: onRetry,
      onConfigureApiKey: null,
      apiKeyValidationService: apiKeyValidationService,
      networkConnectivityService: networkConnectivityService,
    );

    try {
      // Use smart error mapping
      return await ErrorMapperService.mapErrorSmart(
        error,
        stackTrace,
        context: errorContext,
      );
    } catch (e) {
      // If smart mapping fails, fall back to traditional mapping
      return ErrorMapperService.mapError(
        error,
        stackTrace,
        context: errorContext,
      );
    }
  }

  // Getters for external access
  bool get hasApiKeyError => _hasApiKeyError;
  String? get apiKeyErrorMessage => _apiKeyErrorMessage;

  @override
  Widget build(BuildContext context) {
    // This component doesn't render anything visible - it's purely functional
    // It handles error management and provides methods for error display
    return const SizedBox.shrink();
  }
}

/// Static helper class for error handling functions outside of component context.
class ErrorHandlingHelper {
  /// Creates a user-friendly error with smart detection services.
  static Future<UserFriendlyError> createUserFriendlyError(
    WidgetRef ref,
    Object error,
    StackTrace stackTrace,
    VoidCallback onRetry,
  ) async {
    // Create services for smart detection
    final apiKeyService = ref.read(apiKeyServiceProvider);
    final apiKeyValidationService = ApiKeyValidationService(apiKeyService);
    final networkConnectivityService = NetworkConnectivityService.forTMDB();

    // Create error context with available actions and services
    final errorContext = ErrorContext(
      onRetry: onRetry,
      onConfigureApiKey: null,
      apiKeyValidationService: apiKeyValidationService,
      networkConnectivityService: networkConnectivityService,
    );

    try {
      // Use smart error mapping
      return await ErrorMapperService.mapErrorSmart(
        error,
        stackTrace,
        context: errorContext,
      );
    } catch (e) {
      // If smart mapping fails, fall back to traditional mapping
      return ErrorMapperService.mapError(
        error,
        stackTrace,
        context: errorContext,
      );
    }
  }

  /// Checks if an error is an API key related error.
  static bool isApiKeyError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('401') ||
        errorString.contains('403') ||
        errorString.contains('unauthorized') ||
        errorString.contains('api key') ||
        errorString.contains('forbidden');
  }
}
