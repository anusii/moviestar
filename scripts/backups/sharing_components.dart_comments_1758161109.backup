/// Core sharing components and models for MovieStar.
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

/// Share status enum
enum ShareStatus {
  idle,
  sharing,
  success,
  error,
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
