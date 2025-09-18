/// Custom MovieStar Single Movie Sharing UI
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';

import 'package:moviestar/core/services/pod/pod_sharing_service.dart';
import 'package:moviestar/models/content_item.dart';
import 'package:moviestar/models/movie.dart';
import 'package:moviestar/models/sharing_models.dart';
import 'package:moviestar/utils/movie_display_utils.dart';
import 'package:moviestar/widgets/common_sharing_ui.dart'
    show SharingStatusIndicator, WebIdInput, ShareStatus;

/// Custom single movie sharing UI with integrated design
class MovieSharingUI extends StatefulWidget {
  final Movie movie;
  final VoidCallback onSharingComplete;

  const MovieSharingUI({
    required this.movie,
    required this.onSharingComplete,
    super.key,
  });

  @override
  State<MovieSharingUI> createState() => _MovieSharingUIState();
}

class _MovieSharingUIState extends State<MovieSharingUI> {
  final _formKey = GlobalKey<FormState>();
  final _webIdController = TextEditingController();

  String? _validatedWebId;
  ShareStatus _shareStatus = ShareStatus.idle;
  String _statusMessage = '';

  @override
  void dispose() {
    _webIdController.dispose();
    super.dispose();
  }

  Future<void> _shareMovie() async {
    if (!_formKey.currentState!.validate() || _validatedWebId == null) return;

    setState(() {
      _shareStatus = ShareStatus.sharing;
      _statusMessage = 'Sharing "${widget.movie.title}"...';
    });

    try {
      // Construct file name based on content type
      final isTV = widget.movie.contentType == ContentType.tvShow;
      final filePrefix = isTV ? 'TVShow' : 'Movie';

      final request = ShareRequest(
        fileName: 'movies/$filePrefix-${widget.movie.id}.ttl',
        displayName: widget.movie.title,
        permissions: ['read'], // Movies are read-only for security
        recipientWebId: _validatedWebId!,
      );

      final result =
          await PodSharingService.shareFile(request, context, widget);

      setState(() {
        _shareStatus = result.success ? ShareStatus.success : ShareStatus.error;
        _statusMessage = result.success
            ? 'Successfully shared "${widget.movie.title}"!'
            : 'Failed to share: ${result.error ?? 'Unknown error'}';
      });

      if (result.success) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) widget.onSharingComplete();
        });
      }
    } catch (e) {
      setState(() {
        _shareStatus = ShareStatus.error;
        _statusMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Share "${widget.movie.title}"'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.arrow_back,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          tooltip: 'Back',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMovieOverview(),
              const SizedBox(height: 24),
              _buildWebIdInput(),
              const SizedBox(height: 24),
              _buildPermissionsInfo(),
              const SizedBox(height: 24),
              _buildShareButton(),
              if (_shareStatus != ShareStatus.idle) ...[
                const SizedBox(height: 16),
                SharingStatusIndicator(
                  status: _shareStatus,
                  message: _statusMessage,
                  onRetry:
                      _shareStatus == ShareStatus.error ? _shareMovie : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMovieOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (isValidImageUrl(widget.movie.posterUrl))
              SizedBox(
                width: 60,
                height: 90,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: widget.movie.posterUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.movie, size: 24),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.movie, size: 24),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 60,
                height: 90,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.movie,
                  color: Theme.of(context).colorScheme.primary,
                  size: 30,
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.movie.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.movie.releaseDate.year.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${widget.movie.contentType == ContentType.tvShow ? "TVShow" : "Movie"}-${widget.movie.id}.ttl',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                            color: Colors.blue[700],
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebIdInput() {
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
            WebIdInput(
              controller: _webIdController,
              onValidated: (webId) {
                setState(() {
                  _validatedWebId = webId;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permissions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: Colors.green[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Read-only Access',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          'Movies are shared with read-only permissions for security',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.green[700],
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton() {
    final canShare =
        _validatedWebId != null && _shareStatus != ShareStatus.sharing;

    return Center(
      child: SizedBox(
        width: 200, // Fixed width instead of full width
        child: ElevatedButton(
          onPressed: canShare ? _shareMovie : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _shareStatus == ShareStatus.sharing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sharing...',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                )
              : Text(
                  'Share Movie',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
        ),
      ),
    );
  }
}
