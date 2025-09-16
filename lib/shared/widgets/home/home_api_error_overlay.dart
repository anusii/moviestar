/// API Error Overlay for Home Screen
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
import 'package:moviestar/models/app_error.dart';
import 'package:moviestar/core/services/api/api_key_validation_service.dart';
import 'package:moviestar/core/services/network/network_connectivity_service.dart';
import 'package:moviestar/providers/cached_movie_service_provider.dart';
import 'package:moviestar/services/error_mapper_service.dart';
import 'package:moviestar/widgets/error_display_widget.dart';

/// A widget that displays an API key error overlay for the home screen.
/// This overlay appears when there's an API key configuration issue.
class HomeApiErrorOverlay extends ConsumerWidget {
  /// Whether there's an API key error.
  final bool hasApiKeyError;

  /// The API key error message.
  final String? apiKeyErrorMessage;

  /// Callback to handle error state reset.
  final VoidCallback onRetry;

  /// Creates a new [HomeApiErrorOverlay] widget.
  const HomeApiErrorOverlay({
    super.key,
    required this.hasApiKeyError,
    this.apiKeyErrorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!hasApiKeyError) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<UserFriendlyError>(
      future: _createUserFriendlyError(
        ref,
        apiKeyErrorMessage ?? 'API key error',
        StackTrace.current,
        () {
          // Retry by refreshing all providers.
          ref.invalidate(popularMoviesWithCacheInfoProvider);
          ref.invalidate(nowPlayingMoviesWithCacheInfoProvider);
          ref.invalidate(topRatedMoviesWithCacheInfoProvider);
          ref.invalidate(upcomingMoviesWithCacheInfoProvider);
          onRetry();
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

        // Fallback to basic error display.
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

  /// Creates a user-friendly error with smart detection services.
  Future<UserFriendlyError> _createUserFriendlyError(
    WidgetRef ref,
    Object error,
    StackTrace stackTrace,
    VoidCallback onRetry,
  ) async {
    // Create services for smart detection.
    final apiKeyService = ref.read(apiKeyServiceProvider);
    final apiKeyValidationService = ApiKeyValidationService(apiKeyService);
    final networkConnectivityService = NetworkConnectivityService.forTMDB();

    // Create error context with available actions and services.
    final errorContext = ErrorContext(
      onRetry: onRetry,
      onConfigureApiKey: null,
      apiKeyValidationService: apiKeyValidationService,
      networkConnectivityService: networkConnectivityService,
    );

    try {
      // Use smart error mapping.
      return await ErrorMapperService.mapErrorSmart(
        error,
        stackTrace,
        context: errorContext,
      );
    } catch (e) {
      // If smart mapping fails, fall back to traditional mapping.
      return ErrorMapperService.mapError(
        error,
        stackTrace,
        context: errorContext,
      );
    }
  }
}