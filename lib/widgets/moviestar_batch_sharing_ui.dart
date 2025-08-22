/// Custom MovieStar Batch Sharing UI
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
/// Authors: Assistant

library;

import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:solidpod/solidpod.dart'
    show
        SolidFunctionCallStatus,
        grantPermission,
        getWebId,
        loginIfRequired,
        getKeyFromUserIfRequired;
// ignore: implementation_imports
import 'package:solidpod/src/solid/constants/web_acl.dart' show RecipientType;
import 'package:solidui/solidui.dart';

import 'package:moviestar/models/movie.dart';

/// File information for batch sharing
class ShareableFile {
  final String fileName;
  final String displayName;
  final String fileType; // 'movielist' or 'movie'
  final Movie? movie; // null for movie list
  List<String> permissions;

  ShareableFile({
    required this.fileName,
    required this.displayName,
    required this.fileType,
    this.movie,
    List<String>? permissions,
  }) : permissions = permissions ?? ['read'];

  ShareableFile copyWith({List<String>? permissions}) {
    return ShareableFile(
      fileName: fileName,
      displayName: displayName,
      fileType: fileType,
      movie: movie,
      permissions: permissions ?? this.permissions,
    );
  }
}

/// Custom MovieStar batch sharing UI that shows all files to be shared
/// and allows per-file permission configuration
class MovieStarBatchSharingUi extends StatefulWidget {
  /// The movie list ID
  final String listId;

  /// The movie list name
  final String listName;

  /// List of movies in the collection
  final List<Movie> movies;

  /// Widget to return to
  final Widget child;

  /// Optional callback when sharing is complete
  final VoidCallback? onSharingComplete;

  /// Custom app bar
  final PreferredSizeWidget? customAppBar;

  /// Background color
  final Color backgroundColor;

  const MovieStarBatchSharingUi({
    required this.listId,
    required this.listName,
    required this.movies,
    required this.child,
    this.onSharingComplete,
    this.customAppBar,
    this.backgroundColor = const Color.fromARGB(255, 240, 240, 240),
    super.key,
  });

  @override
  State<MovieStarBatchSharingUi> createState() =>
      _MovieStarBatchSharingUiState();
}

class _MovieStarBatchSharingUiState extends State<MovieStarBatchSharingUi> {
  // Form controllers
  final formKey = GlobalKey<FormState>();
  final webIdController = TextEditingController();

  // List of all files to be shared
  late List<ShareableFile> shareableFiles;

  // Sharing state
  bool isSharing = false;
  Map<String, String> sharingProgress = {}; // fileName -> status
  String currentOperation = '';

  // Results
  Map<String, SolidFunctionCallStatus> sharingResults = {};

  @override
  void initState() {
    super.initState();
    _initializeShareableFiles();
  }

  @override
  void dispose() {
    webIdController.dispose();
    super.dispose();
  }

  /// Initialize the list of files to be shared.
  /// Movie files are automatically set to read-only permissions.

  void _initializeShareableFiles() {
    shareableFiles = [
      // Movie list file
      ShareableFile(
        fileName: 'user_lists/MovieList-${widget.listId}.ttl',
        displayName: widget.listName,
        fileType: 'movielist',
        permissions: [], // Start with no permissions checked
      ),
      // Individual movie files with read-only permissions by default.

      ...widget.movies.map(
        (movie) => ShareableFile(
          fileName: 'movies/Movie-${movie.id}.ttl',
          displayName: movie.title,
          fileType: 'movie',
          movie: movie,
          permissions: ['read'], // Movie files default to read-only
        ),
      ),
    ];
  }

  /// Update permissions for a specific file.
  /// When updating movie list permissions, movie files stay read-only.

  void _updateFilePermissions(int index, List<String> newPermissions) {
    setState(() {
      final file = shareableFiles[index];
      if (file.fileType == 'movielist') {
        // Update movie list permissions normally.

        shareableFiles[index] = file.copyWith(permissions: newPermissions);
      } else {
        // Movie files always stay read-only.

        shareableFiles[index] = file.copyWith(permissions: ['read']);
      }
    });
  }

  /// Reset all file permissions to their defaults.
  /// Movie lists get the selected permissions, movie files stay read-only.

  void _resetPermissionsToDefaults() {
    setState(() {
      for (int i = 0; i < shareableFiles.length; i++) {
        final file = shareableFiles[i];
        if (file.fileType == 'movielist') {
          // Movie lists: read + write permissions by default.

          shareableFiles[i] = file.copyWith(permissions: ['read', 'write']);
        } else {
          // Individual movies: always read-only for security.

          shareableFiles[i] = file.copyWith(permissions: ['read']);
        }
      }
    });

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Permissions reset to defaults'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Start the batch sharing process.

  Future<void> _startBatchSharing() async {
    if (!formKey.currentState!.validate()) return;

    final webId = webIdController.text.trim();
    if (webId.isEmpty) {
      _showErrorSnackBar('Please enter a WebID');
      return;
    }

    setState(() {
      isSharing = true;
      sharingProgress.clear();
      sharingResults.clear();
      currentOperation = 'Initializing...';
    });

    try {
      // Get owner WebID
      final ownerWebId = await getWebId();
      if (ownerWebId == null) {
        throw Exception('Unable to get owner WebID');
      }

      // Check if logged in
      if (!mounted) return;
      final loggedIn = await loginIfRequired(context);
      if (!loggedIn) {
        throw Exception('Login required');
      }

      // Get encryption key if needed
      if (!mounted) return;
      await getKeyFromUserIfRequired(context, widget.child);

      // Prepare recipient list
      final recipientList = [webId];
      const recipientType = RecipientType.individual;

      int completedCount = 0;
      final totalCount = shareableFiles.length;

      // Share each file in sequence with progress updates
      for (int i = 0; i < shareableFiles.length; i++) {
        final file = shareableFiles[i];

        // Skip files with no permissions selected (except movie files which always get read).

        if (file.permissions.isEmpty && file.fileType == 'movielist') {
          setState(() {
            sharingProgress[file.fileName] = 'skipped';
            currentOperation =
                'Skipped ${file.displayName} (no permissions selected)';
          });
          continue;
        }

        setState(() {
          currentOperation =
              'Sharing ${file.displayName}... (${i + 1}/$totalCount)';
          sharingProgress[file.fileName] = 'sharing';
        });

        try {
          if (!mounted) break;

          // Determine permissions: movie files always get read-only.

          final permissionsToUse =
              file.fileType == 'movie' ? ['read'] : file.permissions;

          final result = await grantPermission(
            file.fileName,
            true, // fileFlag
            permissionsToUse,
            recipientType,
            recipientList,
            ownerWebId,
            context,
            widget.child,
            isExternalRes: false,
          );

          setState(() {
            sharingResults[file.fileName] = result;
            if (result == SolidFunctionCallStatus.success) {
              sharingProgress[file.fileName] = 'success';
              completedCount++;
            } else {
              sharingProgress[file.fileName] = 'failed';
            }
          });
        } catch (e) {
          setState(() {
            sharingResults[file.fileName] = SolidFunctionCallStatus.fail;
            sharingProgress[file.fileName] = 'error';
          });
        }

        // Small delay between operations for UI updates
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Show completion message
      setState(() {
        currentOperation =
            'Completed! Shared $completedCount/$totalCount files';
      });

      if (completedCount == totalCount) {
        _showSuccessSnackBar(
          'Successfully shared "${widget.listName}" and ${widget.movies.length} movies!',
        );
      } else {
        _showWarningSnackBar(
          'Shared $completedCount/$totalCount files. Some files failed to share.',
        );
      }

      // Call completion callback
      widget.onSharingComplete?.call();
    } catch (e) {
      setState(() {
        currentOperation = 'Error: $e';
      });
      _showErrorSnackBar('Error during sharing: $e');
    } finally {
      setState(() {
        isSharing = false;
      });
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
    return SolidScaffold(
      backgroundColor: widget.backgroundColor,
      appBar: widget.customAppBar ??
          AppBar(
            title: Text('Share "${widget.listName}" Collection'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            leading: isSharing
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
          ),
      body: isSharing ? _buildSharingProgress() : _buildSharingSetup(),
    );
  }

  /// Build the sharing progress screen
  Widget _buildSharingProgress() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    currentOperation,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Files progress list
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Files Progress',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: shareableFiles.length,
                        itemBuilder: (context, index) {
                          final file = shareableFiles[index];
                          final progress =
                              sharingProgress[file.fileName] ?? 'pending';

                          IconData icon;
                          Color iconColor;

                          switch (progress) {
                            case 'success':
                              icon = Icons.check_circle;
                              iconColor = Colors.green;
                              break;
                            case 'failed':
                            case 'error':
                              icon = Icons.error;
                              iconColor = Colors.red;
                              break;
                            case 'sharing':
                              icon = Icons.sync;
                              iconColor = Colors.blue;
                              break;
                            case 'skipped':
                              icon = Icons.skip_next;
                              iconColor = Colors.orange;
                              break;
                            default:
                              icon = Icons.pending;
                              iconColor = Colors.grey;
                          }

                          return ListTile(
                            leading: progress == 'sharing'
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        iconColor,
                                      ),
                                    ),
                                  )
                                : Icon(icon, color: iconColor),
                            title: Text(file.displayName),
                            subtitle: Text(
                              '${file.fileType} • ${file.permissions.join(", ")}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            trailing: file.movie != null &&
                                    file.movie!.posterUrl.isNotEmpty
                                ? SizedBox(
                                    width: 40,
                                    height: 60,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: CachedNetworkImage(
                                        imageUrl: file.movie!.posterUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                          color: Colors.grey[300],
                                          child:
                                              const Icon(Icons.movie, size: 16),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                          color: Colors.grey[300],
                                          child:
                                              const Icon(Icons.movie, size: 16),
                                        ),
                                      ),
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the sharing setup screen
  Widget _buildSharingSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Collection overview
            _buildCollectionOverview(),

            const SizedBox(height: 24),

            // Recipient section
            _buildRecipientSection(),

            const SizedBox(height: 24),

            // Files and permissions section
            _buildFilesPermissionsSection(),

            const SizedBox(height: 32),

            // Share button
            _buildShareButton(),
          ],
        ),
      ),
    );
  }

  /// Build collection overview section
  Widget _buildCollectionOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.movie_creation,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.listName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${widget.movies.length + 1} files will be shared',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build recipient input section
  Widget _buildRecipientSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share With',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: webIdController,
              decoration: const InputDecoration(
                labelText: 'Recipient WebID *',
                hintText: 'https://example.solid.com/profile/card#me',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                helperText:
                    'Enter the WebID of the person you want to share with',
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'WebID is required';
                }
                if (!value.startsWith('https://') || !value.contains('#')) {
                  return 'Please enter a valid WebID';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build files and permissions section
  Widget _buildFilesPermissionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Files & Permissions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure permissions for the movie list. Movie files are automatically set to read-only:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Movie files are automatically shared with read-only permissions for security. Only configure permissions for the movie list.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Reset button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _resetPermissionsToDefaults,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text(
                  'Reset to Defaults',
                  style: TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Files list with permission controls
            ...shareableFiles.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildFilePermissionItem(index, file),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Build individual file permission item.
  /// Movie files show read-only permissions that cannot be changed.

  Widget _buildFilePermissionItem(int index, ShareableFile file) {
    final isMovieFile = file.fileType == 'movie';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
        color: isMovieFile
            ? Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.3)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File header
          Row(
            children: [
              Icon(
                file.fileType == 'movielist' ? Icons.list_alt : Icons.movie,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      file.fileType == 'movielist'
                          ? 'Movie List'
                          : 'Movie File (Read-only)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              if (file.movie != null && file.movie!.posterUrl.isNotEmpty)
                SizedBox(
                  width: 30,
                  height: 45,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CachedNetworkImage(
                      imageUrl: file.movie!.posterUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.movie, size: 12),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.movie, size: 12),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Permission checkboxes or read-only indicator.

          if (isMovieFile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 14,
                    color: Colors.green[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Read-only access (automatic)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green[700],
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
            )
          else
            // Permission checkboxes for movie list only
            Wrap(
              spacing: 16,
              children: [
                _buildPermissionCheckbox(index, file, 'read', 'Read'),
                _buildPermissionCheckbox(index, file, 'write', 'Write'),
                _buildPermissionCheckbox(index, file, 'append', 'Append'),
                _buildPermissionCheckbox(index, file, 'control', 'Control'),
              ],
            ),
        ],
      ),
    );
  }

  /// Build permission checkbox.
  /// Only enables interaction for movie list files.

  Widget _buildPermissionCheckbox(
    int index,
    ShareableFile file,
    String permission,
    String label,
  ) {
    final isChecked = file.permissions.contains(permission);
    final isMovieFile = file.fileType == 'movie';

    return InkWell(
      onTap: isMovieFile
          ? null
          : () {
              final newPermissions = List<String>.from(file.permissions);
              if (isChecked) {
                newPermissions.remove(permission);
              } else {
                newPermissions.add(permission);
              }
              _updateFilePermissions(index, newPermissions);
            },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: isChecked,
            onChanged: isMovieFile
                ? null
                : (value) {
                    final newPermissions = List<String>.from(file.permissions);
                    if (value == true) {
                      newPermissions.add(permission);
                    } else {
                      newPermissions.remove(permission);
                    }
                    _updateFilePermissions(index, newPermissions);
                  },
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isMovieFile
                      ? Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5)
                      : null,
                ),
          ),
        ],
      ),
    );
  }

  /// Build share button
  Widget _buildShareButton() {
    final totalFiles = shareableFiles.length;
    final hasRecipient = webIdController.text.trim().isNotEmpty;
    final hasAnyPermissions =
        shareableFiles.any((file) => file.permissions.isNotEmpty);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            hasRecipient && hasAnyPermissions ? _startBatchSharing : null,
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
