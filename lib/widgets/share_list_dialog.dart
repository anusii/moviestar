/// Share List Dialog Widget
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

import 'package:solidpod/solidpod.dart';

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/movie_list_service.dart';

/// Permission level options for sharing
enum SharePermissionLevel {
  read('Read Only', 'read', 'Can view the list'),
  write('Read & Write', 'write', 'Can view and modify the list'),
  admin('Admin', 'control', 'Full control including sharing and deletion');

  const SharePermissionLevel(this.displayName, this.value, this.description);

  final String displayName;
  final String value;
  final String description;
}

/// A reusable dialog for sharing movie lists with other users
class ShareListDialog extends StatefulWidget {
  /// The ID of the movie list to share
  final String listId;

  /// The movie list service instance
  final MovieListService movieListService;

  /// Optional callback when sharing is completed successfully
  final VoidCallback? onShared;

  const ShareListDialog({
    super.key,
    required this.listId,
    required this.movieListService,
    this.onShared,
  });

  /// Shows the share list dialog
  static Future<bool?> show({
    required BuildContext context,
    required String listId,
    required MovieListService movieListService,
    VoidCallback? onShared,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => ShareListDialog(
        listId: listId,
        movieListService: movieListService,
        onShared: onShared,
      ),
    );
  }

  @override
  State<ShareListDialog> createState() => _ShareListDialogState();
}

class _ShareListDialogState extends State<ShareListDialog> {
  final TextEditingController _webIdController = TextEditingController();
  SharePermissionLevel _selectedPermission = SharePermissionLevel.read;

  Map<String, dynamic>? _movieListData;
  bool _isLoading = true;
  bool _isSharing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMovieListData();
  }

  @override
  void dispose() {
    _webIdController.dispose();
    super.dispose();
  }

  /// Load movie list data for preview
  Future<void> _loadMovieListData() async {
    try {
      final data = await widget.movieListService.getMovieList(widget.listId);
      if (mounted) {
        setState(() {
          _movieListData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load list data: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Handle sharing the list
  Future<void> _handleShare() async {
    final webId = _webIdController.text.trim();

    if (webId.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a WebID';
      });
      return;
    }

    // Basic WebID validation
    if (!webId.startsWith('https://') || !webId.contains('#')) {
      setState(() {
        _errorMessage =
            'Please enter a valid WebID (e.g., https://example.com/profile/card#me)';
      });
      return;
    }

    setState(() {
      _isSharing = true;
      _errorMessage = null;
    });

    try {
      // Check if the movie list can be shared
      final canShare =
          await widget.movieListService.canShareMovieList(widget.listId);
      if (!canShare) {
        setState(() {
          _errorMessage = 'Movie list not found or cannot be shared';
          _isSharing = false;
        });
        return;
      }

      // Get the file path for sharing
      final filePath =
          widget.movieListService.getMovieListFilePath(widget.listId);
      if (filePath == null) {
        setState(() {
          _errorMessage = 'Unable to get file path for sharing';
          _isSharing = false;
        });
        return;
      }

      // Navigate to GrantPermissionUi for sharing
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Theme(
            data: Theme.of(context),
            child: GrantPermissionUi(
              fileName: filePath,
              title: 'Share "${_movieListData?['name'] ?? 'Movie List'}"',
              accessModeList: [_selectedPermission.value],
              recipientTypeList: const ['indi'],
              showAppBar: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: widget,
            ),
          ),
        ),
      );

      // If we get here, the sharing UI has been completed
      if (mounted) {
        // Show success feedback
        if (widget.onShared != null) {
          widget.onShared!();
        }
        Navigator.of(context).pop(true);

        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('List sharing initiated for $webId'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error sharing list: $e';
          _isSharing = false;
        });
      }
    }
  }

  /// Build the list preview section
  Widget _buildListPreview() {
    if (_isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(
                'Loading list...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_movieListData == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Failed to load list data',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final listName = _movieListData!['name'] ?? 'Movie List';
    final description = _movieListData!['description'];
    final movies = _movieListData!['movies'] as List<Movie>? ?? [];
    final movieCount = movies.length;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                    Icons.list_alt,
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
                        listName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.movie,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$movieCount ${movieCount == 1 ? 'movie' : 'movies'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            if (movies.isNotEmpty && movies.length <= 3) ...[
              const SizedBox(height: 12),
              Text(
                'Movies:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 8),
              ...movies.map((movie) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 6,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            movie.title,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  /// Build permission selector
  Widget _buildPermissionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Permission Level',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: SharePermissionLevel.values.map((permission) {
              final isSelected = _selectedPermission == permission;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedPermission = permission;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1)
                        : null,
                    borderRadius:
                        permission == SharePermissionLevel.values.first
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              )
                            : permission == SharePermissionLevel.values.last
                                ? const BorderRadius.only(
                                    bottomLeft: Radius.circular(8),
                                    bottomRight: Radius.circular(8),
                                  )
                                : null,
                  ),
                  child: Row(
                    children: [
                      Radio<SharePermissionLevel>(
                        value: permission,
                        groupValue: _selectedPermission,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedPermission = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              permission.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              permission.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
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
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Share Movie List',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List Preview
            _buildListPreview(),

            const SizedBox(height: 24),

            // WebID Input
            Text(
              'Recipient WebID',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _webIdController,
              decoration: InputDecoration(
                hintText: 'https://example.com/profile/card#me',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person),
                suffixIcon: _webIdController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _webIdController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                errorText: _errorMessage,
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onChanged: (value) {
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
              onSubmitted: (_) => _handleShare(),
            ),

            const SizedBox(height: 24),

            // Permission Selector
            _buildPermissionSelector(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSharing ? null : () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isSharing || _movieListData == null ? null : _handleShare,
          child: _isSharing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Share'),
        ),
      ],
    );
  }
}
