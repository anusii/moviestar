/// Service for checking network connectivity and internet access.
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
/// Authors: Claude Code

library;

import 'dart:io';

import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

/// Result of network connectivity check.
class NetworkConnectivityResult {
  /// Whether the device has internet access.
  final bool hasInternetAccess;

  /// Whether the check was successful (no errors occurred).
  final bool checkSuccessful;

  /// Any error that occurred during the check.
  final String? errorMessage;

  /// Response time for connectivity check (if available).
  final Duration? responseTime;

  const NetworkConnectivityResult({
    required this.hasInternetAccess,
    required this.checkSuccessful,
    this.errorMessage,
    this.responseTime,
  });

  /// Creates a successful result with internet access.
  static NetworkConnectivityResult connected({Duration? responseTime}) {
    return NetworkConnectivityResult(
      hasInternetAccess: true,
      checkSuccessful: true,
      responseTime: responseTime,
    );
  }

  /// Creates a successful result without internet access.
  static NetworkConnectivityResult disconnected({Duration? responseTime}) {
    return NetworkConnectivityResult(
      hasInternetAccess: false,
      checkSuccessful: true,
      responseTime: responseTime,
    );
  }

  /// Creates a result for when the check failed.
  static NetworkConnectivityResult error(String errorMessage) {
    return NetworkConnectivityResult(
      hasInternetAccess: false,
      checkSuccessful: false,
      errorMessage: errorMessage,
    );
  }

  /// Whether this result indicates a definitive network problem.
  bool get isNetworkProblem => checkSuccessful && !hasInternetAccess;

  /// Whether the check was inconclusive (error occurred).
  bool get isInconclusive => !checkSuccessful;
}

/// Service for checking network connectivity and internet access.
class NetworkConnectivityService {
  static const Duration _defaultTimeout = Duration(seconds: 10);

  final InternetConnection _internetConnection;

  /// Creates a new NetworkConnectivityService.
  NetworkConnectivityService({
    InternetConnection? internetConnection,
  }) : _internetConnection = internetConnection ?? InternetConnection();

  /// Creates a service with custom check options for TMDB endpoints.
  factory NetworkConnectivityService.forTMDB() {
    // Create custom checker that tests TMDB endpoints specifically
    final customConnection = InternetConnection.createInstance(
      customCheckOptions: [
        InternetCheckOption(
          uri: Uri.parse('https://api.themoviedb.org'),
        ),
        InternetCheckOption(
          uri: Uri.parse('https://www.google.com'),
        ),
      ],
      useDefaultOptions: false,
    );

    return NetworkConnectivityService(internetConnection: customConnection);
  }

  /// Checks if the device has internet connectivity.
  Future<NetworkConnectivityResult> checkConnectivity({
    Duration? timeout,
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      final hasInternet = await _internetConnection.hasInternetAccess
          .timeout(timeout ?? _defaultTimeout);

      stopwatch.stop();

      return hasInternet
          ? NetworkConnectivityResult.connected(responseTime: stopwatch.elapsed)
          : NetworkConnectivityResult.disconnected(
              responseTime: stopwatch.elapsed);
    } catch (e) {
      if (e.toString().contains('timeout')) {
        return NetworkConnectivityResult.error(
          'Network check timed out. Connection may be very slow.',
        );
      } else if (e is SocketException) {
        return NetworkConnectivityResult.error(
          'Network unreachable. Please check your connection.',
        );
      } else {
        return NetworkConnectivityResult.error(
          'Failed to check network connectivity: ${e.toString()}',
        );
      }
    }
  }

  /// Quick connectivity check with shorter timeout.
  Future<NetworkConnectivityResult> quickCheck() async {
    return checkConnectivity(timeout: const Duration(seconds: 5));
  }

  /// Stream of connectivity status changes.
  Stream<InternetStatus> get onStatusChange {
    return _internetConnection.onStatusChange;
  }

  /// Checks if the device can reach TMDB servers specifically.
  Future<NetworkConnectivityResult> checkTMDBConnectivity() async {
    try {
      final stopwatch = Stopwatch()..start();

      // Try to resolve TMDB domain
      final lookupResult = await InternetAddress.lookup(
        'api.themoviedb.org',
      ).timeout(const Duration(seconds: 8));

      stopwatch.stop();

      if (lookupResult.isNotEmpty && lookupResult[0].rawAddress.isNotEmpty) {
        return NetworkConnectivityResult.connected(
          responseTime: stopwatch.elapsed,
        );
      } else {
        return NetworkConnectivityResult.disconnected(
          responseTime: stopwatch.elapsed,
        );
      }
    } catch (e) {
      if (e is SocketException) {
        return NetworkConnectivityResult.error(
          'Cannot reach TMDB servers. Check your internet connection.',
        );
      } else if (e.toString().contains('timeout')) {
        return NetworkConnectivityResult.error(
          'TMDB servers are unreachable (timeout). Connection may be slow.',
        );
      } else {
        return NetworkConnectivityResult.error(
          'Failed to reach TMDB: ${e.toString()}',
        );
      }
    }
  }

  /// Determines if an error is likely due to network connectivity issues.
  static bool isNetworkError(Object error) {
    final errorString = error.toString().toLowerCase();

    return errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('unreachable') ||
        errorString.contains('timeout') ||
        errorString.contains('dns') ||
        errorString.contains('host not found') ||
        errorString.contains('no route to host') ||
        errorString.contains('connection refused') ||
        errorString.contains('connection timed out');
  }

  /// Gets a user-friendly message for network errors.
  static String getNetworkErrorMessage(Object error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout')) {
      return 'The request timed out. Your connection may be slow.';
    } else if (errorString.contains('dns') ||
        errorString.contains('host not found')) {
      return 'Cannot resolve server address. Check your DNS settings.';
    } else if (errorString.contains('connection refused')) {
      return 'Server refused connection. The service may be down.';
    } else if (errorString.contains('unreachable') ||
        errorString.contains('no route')) {
      return 'Network unreachable. Check your internet connection.';
    } else if (errorString.contains('socket') ||
        errorString.contains('connection')) {
      return 'Connection failed. Please check your internet connection.';
    } else {
      return 'Network error occurred. Please check your connection.';
    }
  }

  /// Provides suggestions for resolving network issues.
  static List<String> getNetworkTroubleshootingTips() {
    return [
      'Check if you are connected to Wi-Fi or mobile data',
      'Try turning airplane mode on and off',
      'Restart your Wi-Fi connection',
      'Check if other apps can access the internet',
      'Contact your internet service provider if the problem persists',
    ];
  }

  /// Dispose of resources (if needed in the future).
  void dispose() {
    // Currently no resources to dispose, but keeping for future use
  }
}
