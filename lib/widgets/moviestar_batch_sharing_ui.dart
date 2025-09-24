/// Custom MovieStar Batch Sharing UI.
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
/// Authors: Ashley Tang.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/core/state/batch_sharing_state.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/widgets/sharing/collection_overview.dart';
import 'package:moviestar/widgets/sharing/permissions_panel.dart';
import 'package:moviestar/widgets/sharing/progress_tracker.dart';
import 'package:moviestar/widgets/sharing/recipient_section.dart';

/// Custom MovieStar batch sharing UI that shows all files to be shared.
/// and allows per-file permission configuration.
class MovieStarBatchSharingUi extends StatefulWidget {
  /// The movie list ID.
  final String listId;

  /// The movie list name.
  final String listName;

  /// List of movies in the collection.
  final List<Movie> movies;

  /// Widget to return to.
  final Widget child;

  /// Callback when sharing is complete.
  final VoidCallback onSharingComplete;

  /// Custom app bar.
  final PreferredSizeWidget? customAppBar;

  /// Background color.
  final Color backgroundColor;

  const MovieStarBatchSharingUi({
    required this.listId,
    required this.listName,
    required this.movies,
    required this.child,
    required this.onSharingComplete,
    this.customAppBar,
    this.backgroundColor = const Color.fromARGB(255, 240, 240, 240),
    super.key,
  });

  @override
  State<MovieStarBatchSharingUi> createState() =>
      _MovieStarBatchSharingUiState();
}

class _MovieStarBatchSharingUiState extends State<MovieStarBatchSharingUi> {
  late BatchSharingState _sharingState;

  @override
  void initState() {
    super.initState();
    _sharingState = BatchSharingState();
    _sharingState.initializeShareableFiles(
      widget.listId,
      widget.listName,
      widget.movies,
    );
    _sharingState.addListener(_onSharingStateChanged);
  }

  @override
  void dispose() {
    _sharingState.removeListener(_onSharingStateChanged);
    _sharingState.dispose();
    super.dispose();
  }

  void _onSharingStateChanged() {
    if (mounted) setState(() {});
  }

  /// Reset all file permissions to their defaults.
  void _resetPermissionsToDefaults() {
    _sharingState.resetPermissionsToDefaults();

    // Show confirmation.

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Permissions reset to defaults'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Start the batch sharing process using PodSharingService.
  Future<void> _startBatchSharing() async {
    final result = await _sharingState.startBatchSharing(context, widget);

    if (result.success) {
      if (result.isCompleteSuccess) {
        _showSuccessSnackBar(
          'Successfully shared "${widget.listName}" and ${widget.movies.length} movies!',
        );
      } else if (result.isPartialSuccess) {
        _showWarningSnackBar(
          'Shared ${result.completedCount}/${result.totalCount} files. Some files failed to share.',
        );
      }
      widget.onSharingComplete();
    } else {
      _showErrorSnackBar(result.errorMessage ?? 'Unknown error occurred');
    }
  }

  /// Show success snackbar.

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show warning snackbar.

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show error snackbar.

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: widget.customAppBar ??
          AppBar(
            title: Text('Share "${widget.listName}" Collection'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            leading: _sharingState.isSharing
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
          ),
      body: _sharingState.isSharing
          ? _buildSharingProgress()
          : _buildSharingSetup(),
    );
  }

  /// Build the sharing progress screen.
  Widget _buildSharingProgress() {
    return BatchSharingProgressTracker(
      currentOperation: _sharingState.currentOperation,
      shareableFiles: _sharingState.shareableFiles,
      sharingProgress: _sharingState.sharingProgress,
    );
  }

  /// Build the sharing setup screen.
  Widget _buildSharingSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _sharingState.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Collection overview.

            CollectionOverview(
              listName: widget.listName,
              movieCount: widget.movies.length,
            ),

            const SizedBox(height: 24),

            // Recipient section.

            RecipientSection(
              controller: _sharingState.webIdController,
              onValidated: _sharingState.updateWebId,
            ),

            const SizedBox(height: 24),

            // Files and permissions section.

            BatchSharingPermissionsPanel(
              shareableFiles: _sharingState.shareableFiles,
              onPermissionsChanged: _sharingState.updateFilePermissions,
              onResetPermissions: _resetPermissionsToDefaults,
            ),

            const SizedBox(height: 32),

            // Share button.

            _buildShareButton(),
          ],
        ),
      ),
    );
  }

  /// Build share button.
  Widget _buildShareButton() {
    final totalFiles = _sharingState.shareableFiles.length;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _sharingState.isReadyToShare ? _startBatchSharing : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Share $totalFiles Files',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}
