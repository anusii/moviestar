/// Common Sharing UI Components for MovieStar.
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
/// Authors: Software Innovation Institute

library;

import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:solidpod/solidpod.dart' show GrantPermissionUi;

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/services/pod_sharing_service.dart';

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
    this.permissions = const ['read'],
  });

  ShareableFile copyWith({required List<String> permissions}) {
    return ShareableFile(
      fileName: fileName,
      displayName: displayName,
      fileType: fileType,
      movie: movie,
      permissions: permissions,
    );
  }
}

/// Reusable sharing dialog wrapper with consistent theming
class ShareDialogWrapper extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onCancel;
  final VoidCallback? onComplete;
  final Color? backgroundColor;
  final bool showCloseButton;

  const ShareDialogWrapper({
    super.key,
    required this.title,
    required this.child,
    this.onCancel,
    this.onComplete,
    this.backgroundColor,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(title),
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
            onCancel?.call();
            Navigator.of(context).pop(null);
          },
          tooltip: 'Back',
        ),
        actions: showCloseButton
            ? [
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () {
                    onCancel?.call();
                    Navigator.of(context).pop(null);
                  },
                  tooltip: 'Cancel',
                ),
              ]
            : null,
      ),
      body: child,
    );
  }
}

/// Permission selector widget for choosing access levels
class PermissionSelector extends StatefulWidget {
  final List<String> availablePermissions;
  final List<String> selectedPermissions;
  final ValueChanged<List<String>> onChanged;
  final bool readOnly;
  final String? label;
  final bool requireRead; // New parameter to enforce read permission

  const PermissionSelector({
    super.key,
    required this.availablePermissions,
    required this.selectedPermissions,
    required this.onChanged,
    this.readOnly = false,
    this.label,
    this.requireRead = false, // Default to false for backward compatibility
  });

  @override
  State<PermissionSelector> createState() => _PermissionSelectorState();
}

class _PermissionSelectorState extends State<PermissionSelector> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedPermissions);

    // Ensure read permission is always included if required
    if (widget.requireRead && !_selected.contains('read')) {
      _selected.add('read');
      // Notify parent of the change
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onChanged(_selected);
      });
    }
  }

  @override
  void didUpdateWidget(PermissionSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPermissions != oldWidget.selectedPermissions) {
      _selected = List.from(widget.selectedPermissions);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.readOnly) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            if (widget.label != null) ...[
              Text(
                widget.label!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 8),
            ],
            Chip(
              label: Text(
                widget.selectedPermissions.join(', ').toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.label!,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: widget.availablePermissions.map((permission) {
            final isSelected = _selected.contains(permission);
            final isReadRequired = widget.requireRead && permission == 'read';

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.5),
                  width: isSelected ? 2 : 1,
                ),
                color: isSelected
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: isReadRequired && isSelected
                    ? null // Don't allow deselecting required read permission
                    : () {
                        setState(() {
                          if (isSelected) {
                            _selected.remove(permission);
                          } else {
                            _selected.add(permission);
                          }
                          widget.onChanged(_selected);
                        });
                      },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        size: 18,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        permission.toUpperCase(),
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (isReadRequired)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.lock,
                            size: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// WebID input field with validation
class WebIdInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String?) onValidated;
  final String? initialValue;
  final String? label;
  final String? hint;

  const WebIdInput({
    super.key,
    required this.controller,
    required this.onValidated,
    this.initialValue,
    this.label,
    this.hint,
  });

  @override
  State<WebIdInput> createState() => _WebIdInputState();
}

class _WebIdInputState extends State<WebIdInput> {
  bool _isValidating = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      widget.controller.text = widget.initialValue!;
      _validateWebId(widget.initialValue!);
    }
  }

  Future<void> _validateWebId(String value) async {
    if (value.isEmpty) {
      setState(() {
        _validationError = null;
      });
      widget.onValidated(null);
      return;
    }

    setState(() {
      _isValidating = true;
      _validationError = null;
    });

    final isValid = await PodSharingService.validateWebId(value);

    if (mounted) {
      setState(() {
        _isValidating = false;
        _validationError = isValid ? null : 'Invalid WebID format';
      });
      widget.onValidated(isValid ? value : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.label ?? 'Recipient WebID',
        hintText: widget.hint ?? 'https://pod.example.com/profile/card#me',
        errorText: _validationError,
        suffixIcon: _isValidating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : _validationError == null && widget.controller.text.isNotEmpty
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: (value) {
        _validateWebId(value);
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a WebID';
        }
        return _validationError;
      },
    );
  }
}

/// Sharing status indicator
class SharingStatusIndicator extends StatelessWidget {
  final ShareStatus status;
  final String? message;
  final VoidCallback? onRetry;

  const SharingStatusIndicator({
    super.key,
    required this.status,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String defaultMessage;

    switch (status) {
      case ShareStatus.idle:
        icon = Icons.share;
        color = Theme.of(context).colorScheme.secondary;
        defaultMessage = 'Ready to share';
        break;
      case ShareStatus.sharing:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                message ?? 'Sharing...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      case ShareStatus.success:
        icon = Icons.check_circle;
        color = Colors.green;
        defaultMessage = 'Successfully shared';
        break;
      case ShareStatus.error:
        icon = Icons.error;
        color = Colors.red;
        defaultMessage = 'Sharing failed';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message ?? defaultMessage,
              style: TextStyle(color: color),
            ),
          ),
          if (status == ShareStatus.error && onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

/// Batch sharing item tile
class ShareableItemTile extends StatelessWidget {
  final ShareableFile file;
  final ValueChanged<List<String>> onPermissionsChanged;
  final bool isReadOnly;
  final VoidCallback? onRemove;

  const ShareableItemTile({
    super.key,
    required this.file,
    required this.onPermissionsChanged,
    this.isReadOnly = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isMovieList = file.fileType == 'movielist';
    final hasMovie = file.movie != null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icon or thumbnail
            if (hasMovie)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: file.movie!.posterUrl,
                  width: 40,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 40,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.movie, color: Colors.grey),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 40,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.movie, color: Colors.grey),
                  ),
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isMovieList
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  isMovieList ? Icons.list : Icons.movie,
                  color: isMovieList
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[600],
                ),
              ),
            const SizedBox(width: 12),
            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.displayName,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isMovieList ? Icons.folder : Icons.insert_drive_file,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isMovieList ? 'Movie List' : 'Movie File',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Permissions
            if (isReadOnly)
              Chip(
                label: Text(
                  file.permissions.join(', ').toUpperCase(),
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor: file.permissions.contains('write')
                    ? Colors.orange.withValues(alpha: 0.2)
                    : Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
              )
            else
              PermissionSelector(
                availablePermissions:
                    isMovieList ? const ['read', 'write'] : const ['read'],
                selectedPermissions: file.permissions,
                onChanged: onPermissionsChanged,
                readOnly: !isMovieList,
                requireRead: isMovieList, // Movie lists require read permission
              ),
            // Remove button
            if (onRemove != null)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: onRemove,
                color: Colors.red,
                tooltip: 'Remove from sharing',
              ),
          ],
        ),
      ),
    );
  }
}

/// Share status enum
enum ShareStatus {
  idle,
  sharing,
  success,
  error,
}

/// Navigate to GrantPermissionUi with consistent theming
Future<bool?> navigateToGrantPermissionUi({
  required BuildContext context,
  required String fileName,
  required String title,
  List<String> accessModeList = const ['read'],
  List<String> recipientTypeList = const ['indi'],
  Widget? returnWidget,
}) async {
  final currentContext = context;

  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (navContext) => Theme(
        data: Theme.of(currentContext).copyWith(),
        child: Scaffold(
          backgroundColor: Theme.of(currentContext).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(title),
            backgroundColor:
                Theme.of(currentContext).appBarTheme.backgroundColor,
            foregroundColor:
                Theme.of(currentContext).appBarTheme.foregroundColor,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(currentContext)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: Theme.of(currentContext).colorScheme.primary,
                  size: 20,
                ),
              ),
              onPressed: () {
                Navigator.of(navContext).pop(null);
              },
              tooltip: 'Back',
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: Theme.of(currentContext).colorScheme.onSurface,
                ),
                onPressed: () {
                  Navigator.of(navContext).pop(null);
                },
                tooltip: 'Cancel',
              ),
            ],
          ),
          body: GrantPermissionUi(
            fileName: fileName,
            title: '',
            accessModeList: accessModeList,
            recipientTypeList: recipientTypeList,
            showAppBar: false,
            backgroundColor: Theme.of(currentContext).scaffoldBackgroundColor,
            child: returnWidget ?? Container(),
          ),
        ),
      ),
    ),
  );

  return result as bool?;
}
