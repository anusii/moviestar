/// File service widget that provides file upload, download, and preview functionality.
///
// Time-stamp: <Monday 2025-05-13 10:00:00 +1000 Graham Williams>
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:solidpod/solidpod.dart';

import 'package:moviestar/constants/paths.dart';
import 'package:moviestar/features/file/browser/page.dart';
import 'package:moviestar/features/file/service/components/file_upload_section.dart';
import 'package:moviestar/features/file/service/providers/file_service_provider.dart';
import 'package:moviestar/theme/app_theme.dart';
import 'package:moviestar/utils/is_text_file.dart';

/// The main file service widget that provides file upload, download, and preview functionality.
///
/// This widget composes the individual components for file operations and provides
/// a unified interface for file management.

class FileServiceWidget extends ConsumerStatefulWidget {
  const FileServiceWidget({super.key});

  @override
  ConsumerState<FileServiceWidget> createState() => _FileServiceWidgetState();
}

class _FileServiceWidgetState extends ConsumerState<FileServiceWidget> {
  final _browserKey = GlobalKey<FileBrowserState>();

  /// Navigate to the appropriate folder based on the selected tab.

  // Helper function to get a user-friendly name from the path.

  String _getFriendlyFolderName(String pathValue) {
    const String root = basePath;
    if (pathValue.isEmpty || pathValue == root) {
      return 'Home Folder';
    }

    // Use path.basename to safely get the last component.

    final dirName = path.basename(pathValue);

    switch (dirName) {
      case 'diary':
        return 'Appointments Data';
      case 'blood_pressure':
        return 'Blood Pressure Data';
      case 'medication':
        return 'Medication Data';
      case 'vaccination':
        return 'Vaccination Data';
      case 'profile':
        return 'Profile Data';
      case 'health_plan':
        return 'Health Plan Data';
      case 'pathology':
        return 'Pathology Data';

      default:
        // Basic formatting for unknown folders: capitalize first letter, replace underscores.

        if (dirName.isEmpty) return 'Folder';
        String formattedName = dirName.replaceAll('_', ' ');
        formattedName =
            formattedName[0].toUpperCase() + formattedName.substring(1);
        return '$formattedName Data';
    }
  }

  @override
  void initState() {
    super.initState();
    // Set up the refresh callback after the widget is built.

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fileServiceProvider.notifier).setRefreshCallback(() {
        _browserKey.currentState?.refreshFiles();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we're on a wide screen.

    final isWideScreen = MediaQuery.of(context).size.width > 800;

    // Get current path and friendly name.

    final currentPath = ref.watch(fileServiceProvider).currentPath ?? basePath;
    final String friendlyFolderName = _getFriendlyFolderName(currentPath);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button to root folder (now only the button).
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: TextButton.icon(
            onPressed: () {
              const rootPath = basePath;
              if (ref.read(fileServiceProvider).currentPath != rootPath) {
                ref
                    .read(fileServiceProvider.notifier)
                    .updateCurrentPath(rootPath);
                _browserKey.currentState?.navigateToPath(rootPath);
              }
            },
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: Text(
              'Back to Home Folder',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppTheme.defaultBorderRadius,
                ),
              ),
            ),
          ),
        ),

        // Main content area.
        Expanded(
          child: SingleChildScrollView(
            child:
                isWideScreen
                    ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // File browser on the left.
                        Expanded(
                          flex: 2,
                          child: Card(
                            color: Theme.of(context).cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.defaultBorderRadius,
                              ),
                            ),
                            elevation: 4,
                            margin: const EdgeInsets.only(
                              right: AppTheme.defaultPadding / 2,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                AppTheme.defaultPadding / 2,
                              ),
                              child: FileBrowser(
                                key: _browserKey,
                                browserKey: _browserKey,
                                friendlyFolderName: friendlyFolderName,
                                onFileSelected: (name, filePath) async {
                                  setState(() {});

                                  try {
                                    // Read file content for preview.

                                    final content = await readPod(
                                      filePath,
                                      context,
                                      Container(),
                                    );
                                    String preview;

                                    if (isTextFile(name)) {
                                      // For text files, show the first 500 characters.

                                      preview =
                                          content.length > 500
                                              ? '${content.substring(0, 500)}...'
                                              : content;
                                    } else {
                                      // For binary files, show basic info.

                                      preview =
                                          'Binary file\nSize: ${(content.length / 1024).toStringAsFixed(2)} KB\nType: ${path.extension(name)}';
                                    }

                                    ref.read(fileServiceProvider.notifier)
                                      ..setDownloadFile(filePath)
                                      ..setFilePreview(preview)
                                      ..setRemoteFileName(path.basename(name));
                                  } catch (e) {
                                    debugPrint('Preview error: $e');
                                    ref.read(fileServiceProvider.notifier)
                                      ..setDownloadFile(filePath)
                                      ..setFilePreview('Error loading preview')
                                      ..setRemoteFileName(path.basename(name));
                                  }
                                },
                                onFileDownload: (name, filePath) async {
                                  ref.read(fileServiceProvider.notifier)
                                    ..setDownloadFile(filePath)
                                    ..setRemoteFileName(path.basename(name))
                                    ..handleDownload(context);
                                },
                                onFileDelete: (name, filePath) async {
                                  // Show confirmation dialog before deleting.

                                  final bool? confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        backgroundColor:
                                            Theme.of(
                                              context,
                                            ).dialogTheme.backgroundColor,
                                        title: Text(
                                          'Confirm Delete',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.titleLarge,
                                        ),
                                        content: Text(
                                          'Are you sure you want to delete "$name"?',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  AppTheme.primaryTextColor,
                                            ),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                            style: TextButton.styleFrom(
                                              foregroundColor:
                                                  AppTheme.primaryColor,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (!context.mounted) return;

                                  if (confirm == true) {
                                    ref.read(fileServiceProvider.notifier)
                                      ..setRemoteFileName(path.basename(name))
                                      ..handleDelete(context);
                                  }
                                },
                                onImportCsv: (name, filePath) {
                                  if (mounted) {
                                    // The provider doesn't have an importCsv method.
                                    // Just refresh the file list instead.

                                    ref
                                        .read(fileServiceProvider.notifier)
                                        .updateCurrentPath(filePath);
                                    _browserKey.currentState?.refreshFiles();
                                  }
                                },
                                onDirectoryChanged: (path) {
                                  if (mounted) {
                                    ref
                                        .read(fileServiceProvider.notifier)
                                        .updateCurrentPath(path);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),

                        // Upload section on the right.
                        Expanded(
                          flex: 1,
                          child: Card(
                            color: Theme.of(context).cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.defaultBorderRadius,
                              ),
                            ),
                            elevation: 4,
                            margin: const EdgeInsets.only(
                              left: AppTheme.defaultPadding / 2,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(
                                AppTheme.defaultPadding,
                              ),
                              child: FileUploadSection(),
                            ),
                          ),
                        ),
                      ],
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // File browser.
                        Card(
                          color: Theme.of(context).cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.defaultBorderRadius,
                            ),
                          ),
                          elevation: 4,
                          margin: const EdgeInsets.all(AppTheme.defaultPadding),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: FileBrowser(
                              key: _browserKey,
                              browserKey: _browserKey,
                              friendlyFolderName: friendlyFolderName,
                              onFileSelected: (name, filePath) async {
                                setState(() {});

                                try {
                                  // Read file content for preview.

                                  final content = await readPod(
                                    filePath,
                                    context,
                                    Container(),
                                  );
                                  String preview;

                                  if (isTextFile(name)) {
                                    // For text files, show the first 500 characters.

                                    preview =
                                        content.length > 500
                                            ? '${content.substring(0, 500)}...'
                                            : content;
                                  } else {
                                    // For binary files, show basic info.

                                    preview =
                                        'Binary file\nSize: ${(content.length / 1024).toStringAsFixed(2)} KB\nType: ${path.extension(name)}';
                                  }

                                  ref.read(fileServiceProvider.notifier)
                                    ..setDownloadFile(filePath)
                                    ..setFilePreview(preview)
                                    ..setRemoteFileName(path.basename(name));
                                } catch (e) {
                                  debugPrint('Preview error: $e');
                                  ref.read(fileServiceProvider.notifier)
                                    ..setDownloadFile(filePath)
                                    ..setFilePreview('Error loading preview')
                                    ..setRemoteFileName(path.basename(name));
                                }
                              },
                              onFileDownload: (name, filePath) async {
                                ref.read(fileServiceProvider.notifier)
                                  ..setDownloadFile(filePath)
                                  ..setRemoteFileName(path.basename(name))
                                  ..handleDownload(context);
                              },
                              onFileDelete: (name, filePath) async {
                                // Show confirmation dialog before deleting.

                                final bool? confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor:
                                          Theme.of(
                                            context,
                                          ).dialogTheme.backgroundColor,
                                      title: Text(
                                        'Confirm Delete',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                      ),
                                      content: Text(
                                        'Are you sure you want to delete "$name"?',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(false),
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                AppTheme.primaryTextColor,
                                          ),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(true),
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                AppTheme.primaryColor,
                                          ),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (!context.mounted) return;

                                if (confirm == true) {
                                  ref.read(fileServiceProvider.notifier)
                                    ..setRemoteFileName(path.basename(name))
                                    ..handleDelete(context);
                                }
                              },
                              onImportCsv: (name, filePath) {
                                if (mounted) {
                                  // The provider doesn't have an importCsv method.
                                  // Just refresh the file list instead.

                                  ref
                                      .read(fileServiceProvider.notifier)
                                      .updateCurrentPath(filePath);
                                  _browserKey.currentState?.refreshFiles();
                                }
                              },
                              onDirectoryChanged: (path) {
                                if (mounted) {
                                  ref
                                      .read(fileServiceProvider.notifier)
                                      .updateCurrentPath(path);
                                }
                              },
                            ),
                          ),
                        ),

                        // Upload section.
                        Card(
                          color: Theme.of(context).cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.defaultBorderRadius,
                            ),
                          ),
                          elevation: 4,
                          margin: const EdgeInsets.all(AppTheme.defaultPadding),
                          child: Padding(
                            padding: const EdgeInsets.all(
                              AppTheme.defaultPadding,
                            ),
                            child: FileUploadSection(),
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ],
    );
  }
}
