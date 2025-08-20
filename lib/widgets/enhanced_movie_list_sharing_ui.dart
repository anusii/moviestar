/// Enhanced Movie List Sharing UI for MovieStar.
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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:solidpod/solidpod.dart' show 
    SolidFunctionCallStatus, readPod, writePod, grantPermission, 
    getWebId;
// ignore: implementation_imports
import 'package:solidpod/src/solid/constants/web_acl.dart' show RecipientType;

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/movie_list_service.dart';
import 'package:moviestar/services/user_profile_service.dart';
import 'package:moviestar/utils/turtle_serializer.dart';

/// Enhanced UI for sharing movie lists with all their individual movies.
/// This provides a unified experience where users can see both the list
/// and all movies in one screen, with the ability to grant permissions
/// for the list while automatically setting read-only permissions for movies.
class EnhancedMovieListSharingUi extends StatefulWidget {
  /// The movie list ID to share
  final String listId;

  /// The movie list name
  final String listName;

  /// The list of movies in the list
  final List<Movie> movies;

  /// The child widget to return to
  final Widget child;

  /// Custom app bar
  final PreferredSizeWidget? customAppBar;

  /// Background color
  final Color backgroundColor;

  const EnhancedMovieListSharingUi({
    required this.listId,
    required this.listName,
    required this.movies,
    required this.child,
    this.customAppBar,
    this.backgroundColor = const Color.fromARGB(255, 210, 210, 210),
    super.key,
  });

  @override
  State<EnhancedMovieListSharingUi> createState() =>
      _EnhancedMovieListSharingUiState();
}

class _EnhancedMovieListSharingUiState
    extends State<EnhancedMovieListSharingUi> {
  /// Permission states
  bool readChecked = false;
  bool writeChecked = false;
  bool controlChecked = false;
  bool appendChecked = false;

  /// Recipient states - only individual sharing is supported
  bool individualChecked = true; // Only individual sharing is available

  /// Form controllers
  final formKey = GlobalKey<FormState>();
  final webIdController = TextEditingController();

  /// Selected recipient type
  RecipientType selectedRecipient =
      RecipientType.individual; // Default to individual
  String selectedRecipientDetails = 'Individual (WebID required)';

  /// Selected permissions
  List<String> selectedPermList = [];

  /// Owner WebID
  String ownerWebId = '';

  /// Loading states
  bool isSharing = false;
  String sharingStatus = '';

  /// Current sharing information
  Map<String, String>? _currentSharingInfo;
  bool _isLoadingSharingInfo = true;

  /// Small vertical spacing
  final smallGapV = const SizedBox(height: 10.0);
  final largeGapV = const SizedBox(height: 40.0);

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // Get current user's WebID
      final userWebId = await getWebId();
      if (userWebId != null) {
        setState(() {
          ownerWebId = userWebId;
        });
      }

      // Set default recipient type
      _updateSelectedRecipient();

      // Load current sharing information
      await _loadCurrentSharingInfo();
    } catch (e) {
      debugPrint('Error initializing data: $e');
    }
  }

  @override
  void dispose() {
    webIdController.dispose();
    super.dispose();
  }

  // Update selected permissions based on checkboxes.

  void _updateSelectedPermissions() {
    selectedPermList.clear();
    if (readChecked) selectedPermList.add('read');
    if (writeChecked) selectedPermList.add('write');
    if (appendChecked) selectedPermList.add('append');
    if (controlChecked) selectedPermList.add('control');
  }

  // Update selected recipient - only individual sharing is supported.

  void _updateSelectedRecipient() {
    selectedRecipient = RecipientType.individual;
    selectedRecipientDetails = webIdController.text.isNotEmpty
        ? 'Individual: ${webIdController.text}'
        : 'Individual (WebID required)';
  }

  // Load current sharing information for this movie list.

  Future<void> _loadCurrentSharingInfo() async {
    try {
      debugPrint(
        '🔄 Loading current sharing info for listId: ${widget.listId}',
      );

      // Create a temporary MovieListService to get sharing information
      final userProfileService = UserProfileService(context, widget.child);
      final movieListService = MovieListService(
        context,
        widget.child,
        userProfileService,
      );

      // Get the movie list data
      debugPrint('📖 Getting movie list data...');
      final movieList = await movieListService.getMovieList(widget.listId);

      if (movieList != null) {
        debugPrint('✅ Found movie list: ${movieList['name']}');
        final sharedWith = movieList['sharedWith'] as Map<String, String>?;
        debugPrint('📋 Retrieved sharedWith from TTL: $sharedWith');

        // If TTL metadata is missing or corrupted, try alternative approach
        Map<String, String>? finalSharingInfo = sharedWith;
        if (sharedWith == null || sharedWith.isEmpty) {
          debugPrint(
            '🔍 TTL metadata empty, trying alternative permission detection...',
          );

          // Alternative: Check if we can detect shared permissions through POD queries
          // This is a fallback approach when TTL metadata is corrupted
          try {
            final alternativeSharing = await _detectAlternativeSharing();
            if (alternativeSharing != null && alternativeSharing.isNotEmpty) {
              debugPrint(
                '✅ Found alternative sharing info: $alternativeSharing',
              );
              finalSharingInfo = alternativeSharing;
            }
          } catch (e) {
            debugPrint('⚠️ Alternative sharing detection failed: $e');
          }
        }

        if (mounted) {
          setState(() {
            _currentSharingInfo = finalSharingInfo;
            _isLoadingSharingInfo = false;
          });
          debugPrint('✅ Updated UI with sharing info: $_currentSharingInfo');
        }
      } else {
        debugPrint('❌ Movie list not found');
        if (mounted) {
          setState(() {
            _currentSharingInfo = null;
            _isLoadingSharingInfo = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading current sharing info: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _currentSharingInfo = null;
          _isLoadingSharingInfo = false;
        });
      }
    }
  }

  // Alternative method to detect sharing when TTL metadata is corrupted.
  // This is a fallback approach that doesn't rely on TTL parsing.

  Future<Map<String, String>?> _detectAlternativeSharing() async {
    try {
      debugPrint('🔍 Attempting alternative sharing detection...');

      // For now, return null - this would need POD-level ACL reading
      // which isn't directly available in the solidpod package
      // This is a placeholder for future enhancement

      // Potential approaches:
      // 1. Query POD ACL files directly (requires ACL file access)
      // 2. Use SharedResourcesUi data if available
      // 3. Maintain a separate sharing log file

      debugPrint('⚠️ Alternative sharing detection not yet implemented');
      return null;
    } catch (e) {
      debugPrint('❌ Error in alternative sharing detection: $e');
      return null;
    }
  }

  // Update the movie list file with sharing metadata directly (V3).

  Future<void> _updateMovieListWithSharingMetadataV2() async {
    try {
      debugPrint(
        '🔄 Starting to update movie list with sharing metadata (V3 - Direct TTL update)...',
      );

      // Create a temporary MovieListService to get current data
      final userProfileService = UserProfileService(context, widget.child);
      final movieListService = MovieListService(
        context,
        widget.child,
        userProfileService,
      );

      // Get the current movie list data
      debugPrint(
        '📖 Getting current movie list data for listId: ${widget.listId}',
      );
      final movieList = await movieListService.getMovieList(widget.listId);

      if (movieList != null) {
        debugPrint('✅ Found movie list: ${movieList['name']}');

        // Get current sharing metadata
        final sharedWith = Map<String, String>.from(
          movieList['sharedWith'] ?? {},
        );
        debugPrint('📋 Current sharedWith: $sharedWith');

        // Add the new recipient with the selected permissions
        final permissions = selectedPermList.join(',');
        final newWebId = webIdController.text;
        sharedWith[newWebId] = permissions;
        debugPrint(
          '➕ Adding new recipient: $newWebId with permissions: $permissions',
        );
        debugPrint('📋 Updated sharedWith: $sharedWith');

        // Create updated TTL content with new sharing metadata
        debugPrint('🔧 Creating updated TTL content...');
        final updatedTtl = TurtleSerializer.createMovieList(
          widget.listId,
          movieList['name'],
          movies: List<Movie>.from(movieList['movies'] ?? []),
          description: movieList['description'],
          sharedWith: sharedWith.isNotEmpty ? sharedWith : null,
          sharedDate: DateTime.now(),
        );

        debugPrint('📄 Generated TTL content length: ${updatedTtl.length}');
        debugPrint('📄 Generated TTL content (first 500 chars):');
        debugPrint(
          updatedTtl.length > 500 ? updatedTtl.substring(0, 500) : updatedTtl,
        );
        debugPrint('📄 Generated TTL content (last 500 chars):');
        debugPrint(
          updatedTtl.length > 500
              ? updatedTtl.substring(updatedTtl.length - 500)
              : updatedTtl,
        );

        // Write the updated movie list file
        debugPrint('💾 Writing updated movie list file...');
        if (!mounted) return;
        final result = await writePod(
          'user_lists/MovieList-${widget.listId}.ttl',
          updatedTtl,
          context,
          widget.child,
          encrypted: false,
        );

        if (!mounted) return;

        if (result == SolidFunctionCallStatus.success) {
          debugPrint(
            '✅ Successfully updated movie list with sharing metadata (V3)',
          );

          // Clear the cache so it reloads fresh data
          movieListService.clearCache();

          // Longer delay to ensure file is fully written and propagated
          debugPrint('⏳ Waiting for file propagation...');
          await Future.delayed(const Duration(milliseconds: 2000));

          // Verify the file was written correctly by reading it back
          debugPrint('🔍 Verifying written file...');
          try {
            if (!mounted) return;
            final verifyContent = await readPod(
              'user_lists/MovieList-${widget.listId}.ttl',
              context,
              widget.child,
            );

            if (!mounted) return;

            if (verifyContent.length == updatedTtl.length) {
              debugPrint('✅ File verification successful - lengths match');
            } else {
              debugPrint(
                '⚠️ File verification warning - length mismatch: expected ${updatedTtl.length}, got ${verifyContent.length}',
              );
            }

            // Check if sharing metadata is present in TTL
            if (verifyContent.contains('moviestar-onto:sharedWith')) {
              debugPrint('✅ Sharing metadata found in written file');
            } else {
              debugPrint('⚠️ Sharing metadata missing from written file');
            }
          } catch (e) {
            debugPrint('❌ Error verifying written file: $e');
          }
        } else {
          debugPrint(
            '❌ Failed to update movie list with sharing metadata. Result: $result',
          );
        }
      } else {
        debugPrint('❌ Movie list not found for listId: ${widget.listId}');
      }
    } catch (e) {
      debugPrint('❌ Error updating movie list with sharing metadata (V3): $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
    }
  }

  // Share the movie list and all individual movies.

  Future<void> _shareMovieListAndMovies() async {
    // Store context reference before async operations.
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (selectedRecipient == RecipientType.none) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Please select a recipient type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedPermList.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Please select at least one permission'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate recipient details
    if (webIdController.text.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Please enter a WebID for sharing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSharing = true;
      sharingStatus = 'Preparing to share...';
    });

    try {
      // Prepare recipient list - only individual sharing is supported
      List<dynamic> recipientList = [webIdController.text];

      // Share the movie list first
      setState(() {
        sharingStatus = 'Sharing movie list...';
      });

      final listResult = await grantPermission(
        'user_lists/MovieList-${widget.listId}.ttl',
        true, // fileFlag
        selectedPermList,
        RecipientType.individual,
        recipientList,
        ownerWebId,
        context,
        widget.child,
      );

      if (listResult != SolidFunctionCallStatus.success) {
        throw Exception('Failed to share movie list');
      }

      // Update the movie list TTL metadata for persistence using MovieListService.

      await _updateMovieListWithSharingMetadataV2();

      // Share individual movies with read-only permissions by default.
      // Movie files always get read-only access regardless of list permissions.

      if (widget.movies.isNotEmpty) {
        setState(() {
          sharingStatus = 'Sharing individual movies (read-only)...';
        });

        int sharedCount = 0;
        for (final movie in widget.movies) {
          try {
            // First, ensure the individual movie file exists.

            await _createMovieFileIfNotExists(movie);

            // Then share the movie file with read-only permissions.
            // Movie files are always shared with read-only access for security.

            if (!mounted) return;
            final movieResult = await grantPermission(
              'movies/Movie-${movie.id}.ttl',
              true, // fileFlag
              ['read'], // Only read permission for movies
              RecipientType.individual,
              recipientList,
              ownerWebId,
              context,
              widget.child,
            );

            if (!mounted) return;

            if (movieResult == SolidFunctionCallStatus.success) {
              sharedCount++;
            } else {
              debugPrint(
                '❌ Failed to share movie ${movie.title}: $movieResult',
              );
            }
          } catch (e) {
            debugPrint('❌ Error sharing movie ${movie.title}: $e');
          }
        }

        setState(() {
          sharingStatus =
              'Shared $sharedCount out of ${widget.movies.length} movies';
        });
      }

      // Show success message
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Successfully shared "${widget.listName}" and ${widget.movies.length} movies!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Show that sharing was successful (even if TTL metadata isn't updated)
        if (mounted) {
          setState(() {
            _currentSharingInfo = {
              webIdController.text: selectedPermList.join(','),
            };
            _isLoadingSharingInfo = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error sharing movie list and movies: $e');
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSharing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: widget.customAppBar ??
          AppBar(
            title: Text('Share "${widget.listName}"'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
      body: isSharing ? _buildSharingProgress() : _buildSharingForm(),
    );
  }

  Widget _buildSharingProgress() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            sharingStatus,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSharingForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Movie List Preview
            _buildMovieListPreview(),
            largeGapV,

            // Permissions Section
            _buildPermissionsSection(),
            largeGapV,

            // Recipients Section
            _buildRecipientsSection(),
            largeGapV,

            // Share Button
            _buildShareButton(),
            largeGapV,

            // Existing Sharing Section
            _buildExistingSharingSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieListPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.list_alt,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Movie List: ${widget.listName}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.movies.length} movie${widget.movies.length == 1 ? '' : 's'} will be shared',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (widget.movies.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Movies in this list:',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.movies.length,
                  itemBuilder: (context, index) {
                    final movie = widget.movies[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        width: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Movie poster
                            Container(
                              width: 50,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: Theme.of(context).colorScheme.surface,
                              ),
                              child: movie.posterUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: CachedNetworkImage(
                                        imageUrl: movie.posterUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                          child: Icon(
                                            Icons.movie,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            size: 16,
                                          ),
                                        ),
                                        errorWidget: (
                                          context,
                                          url,
                                          error,
                                        ) =>
                                            Container(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                          child: Icon(
                                            Icons.movie,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      child: Icon(
                                        Icons.movie,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        size: 16,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 4),
                            // Movie title
                            Text(
                              movie.title,
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permissions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Select permissions for the movie list. Individual movies will automatically be shared with read-only access.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            smallGapV,
            CheckboxListTile(
              title: const Text('Read'),
              subtitle: const Text('Allow recipient to view the movie list'),
              value: readChecked,
              onChanged: (value) {
                setState(() {
                  readChecked = value ?? false;
                  _updateSelectedPermissions();
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Write'),
              subtitle: const Text('Allow recipient to modify the movie list'),
              value: writeChecked,
              onChanged: (value) {
                setState(() {
                  writeChecked = value ?? false;
                  _updateSelectedPermissions();
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Append'),
              subtitle: const Text('Allow recipient to add movies to the list'),
              value: appendChecked,
              onChanged: (value) {
                setState(() {
                  appendChecked = value ?? false;
                  _updateSelectedPermissions();
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('Control'),
              subtitle: const Text('Allow recipient to manage permissions'),
              value: controlChecked,
              onChanged: (value) {
                setState(() {
                  controlChecked = value ?? false;
                  _updateSelectedPermissions();
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recipient',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            smallGapV,

            // Individual sharing only
            Text(
              'Share with a specific person',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: webIdController,
              decoration: const InputDecoration(
                labelText: 'Recipient WebID *',
                hintText: 'https://example.solid.com/profile/card#me',
                border: OutlineInputBorder(),
                helperText:
                    'Enter the WebID of the person you want to share with',
              ),
              onChanged: (value) => _updateSelectedRecipient(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'WebID is required for sharing';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: selectedRecipient != RecipientType.none &&
                selectedPermList.isNotEmpty
            ? _shareMovieListAndMovies
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          'Share "${widget.listName}" with Individual Recipient',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }

  Widget _buildExistingSharingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Sharing Status',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'This movie list is currently shared with:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Note: Sharing status is based on recent sharing activity, not TTL metadata',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
            ),
            const SizedBox(height: 12),
            if (_isLoadingSharingInfo)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading sharing information...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              )
            else if (_currentSharingInfo == null ||
                _currentSharingInfo!.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Not currently shared with anyone',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shared with ${_currentSharingInfo!.length} recipient${_currentSharingInfo!.length == 1 ? '' : 's'}:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...(_currentSharingInfo!.entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.8),
                                          fontFamily: 'monospace',
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    entry.value.toUpperCase(),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList()),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Creates an individual movie file if it doesn't exist.

  Future<void> _createMovieFileIfNotExists(Movie movie) async {
    try {
      final movieFileName = 'movies/Movie-${movie.id}.ttl';

      // Check if the file already exists
      try {
        final existingContent = await readPod(
          movieFileName,
          context,
          widget.child,
        );
        if (existingContent.isNotEmpty) {
          return;
        }
      } catch (e) {
        // File doesn't exist, we'll create it.
      }

      // Create the movie TTL content with full data.

      final ttlContent = TurtleSerializer.movieWithUserDataToTurtleOntology(
        movie,
        null, // No rating initially
        null, // No comment initially
      );

      // Write the movie file to POD.

      if (!mounted) return;
      final result = await writePod(
        movieFileName,
        ttlContent,
        context,
        widget.child,
        encrypted: false,
      );

      if (!mounted) return;

      if (result != SolidFunctionCallStatus.success) {
        throw Exception('Failed to create movie file');
      }
    } catch (e) {
      rethrow;
    }
  }
}
