/// POD Settings Panel Component - Solid POD Storage Configuration and Management.
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

import 'package:moviestar/constants/timing_constants.dart';
import 'package:moviestar/core/services/favorites/service_manager.dart';
import 'package:moviestar/utils/is_logged_in.dart';

class PodSettingsPanel extends ConsumerStatefulWidget {
  final Function(String title, List<Widget> children) buildSection;
  final Function(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) buildSwitchTile;
  final FavoritesServiceManager favoritesServiceManager;
  final Function(String message) showSuccessSnackBar;
  final Function(String message) showErrorSnackBar;
  final VoidCallback hideCurrentSnackBar;

  const PodSettingsPanel({
    super.key,
    required this.buildSection,
    required this.buildSwitchTile,
    required this.favoritesServiceManager,
    required this.showSuccessSnackBar,
    required this.showErrorSnackBar,
    required this.hideCurrentSnackBar,
  });

  @override
  ConsumerState<PodSettingsPanel> createState() => _PodSettingsPanelState();
}

class _PodSettingsPanelState extends ConsumerState<PodSettingsPanel> {
  @override
  void initState() {
    super.initState();
    _initializePodStorageState();
  }

  /// Enable POD storage and migrate data.
  Future<void> _enablePodStorage() async {
    // Show loading indicator.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Gap(16),
              Text('Enabling POD storage...'),
            ],
          ),
          duration: TimingConstants.snackbarVeryLongDuration,
        ),
      );
    }

    try {
      final success = await widget.favoritesServiceManager.enablePodStorage();

      if (success) {
        widget.hideCurrentSnackBar();
        widget.showSuccessSnackBar(
          'POD storage enabled successfully! Your movie lists are now stored in your Solid POD.',
        );
      } else {
        widget.hideCurrentSnackBar();
        widget.showErrorSnackBar(
          'Failed to enable POD storage. Please check your Solid POD login and try again.',
        );
      }
    } catch (e) {
      widget.hideCurrentSnackBar();
      widget.showErrorSnackBar('Error enabling POD storage: $e');
    }
  }

  /// Disable POD storage and revert to local storage.
  Future<void> _disablePodStorage() async {
    try {
      await widget.favoritesServiceManager.disablePodStorage();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('POD storage disabled. Using local storage.'),
            backgroundColor: Colors.orange,
            duration: TimingConstants.snackbarStandardDuration,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error disabling POD storage: $e'),
            backgroundColor: Colors.red,
            duration: TimingConstants.snackbarStandardDuration,
          ),
        );
      }
    }
  }

  /// Initialises POD storage state, enabling by default for logged-in users.
  Future<void> _initializePodStorageState() async {
    // Check if user is logged in.
    final loggedIn = await isLoggedIn();

    // If user is logged in and POD storage is not explicitly disabled,
    // enable it by default.
    if (loggedIn && !widget.favoritesServiceManager.isPodStorageEnabled) {
      // Try to enable POD storage silently for logged-in users.
      try {
        await widget.favoritesServiceManager.enablePodStorage();
      } catch (e) {
        // If enabling fails, leave it disabled but don't show error
        // (user can manually enable if they want)
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the actual service state instead of local state
    final podStorageEnabled =
        widget.favoritesServiceManager.isPodStorageEnabled;

    return widget.buildSection('Data Storage', [
      widget.buildSwitchTile(
        'Use Solid POD Storage',
        'Store movie lists in your Solid POD instead of locally',
        podStorageEnabled,
        (value) async {
          if (value) {
            await _enablePodStorage();
          } else {
            await _disablePodStorage();
          }
        },
      ),
    ]);
  }
}
