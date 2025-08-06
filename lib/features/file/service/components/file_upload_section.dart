/// File upload section component for the file service feature.
///
// Time-stamp: <Thursday 2025-04-17 10:02:42 +1000 Graham Williams>
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

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:path/path.dart' as path;

import 'package:moviestar/features/file/service/providers/file_service_provider.dart';
import 'package:moviestar/theme/app_theme.dart';
import 'package:moviestar/utils/is_text_file.dart';

/// A widget that handles file upload functionality and preview.
///
/// This component provides UI elements for selecting and uploading files,
/// including a file picker button and upload status indicators.

class FileUploadSection extends ConsumerStatefulWidget {
  const FileUploadSection({super.key});

  @override
  ConsumerState<FileUploadSection> createState() => _FileUploadSectionState();
}

class _FileUploadSectionState extends ConsumerState<FileUploadSection> {
  String? filePreview;
  bool showPreview = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = ref.read(fileServiceProvider);

    // Update preview when a file is selected from browser or uploaded.

    if (state.filePreview != null) {
      setState(() {
        filePreview = state.filePreview;
        showPreview = true;
      });
    }
  }

  /// Handles file preview before upload to display its content or basic info.

  Future<void> handlePreview(String filePath) async {
    try {
      final file = File(filePath);
      String content;

      if (isTextFile(filePath)) {
        content = await file.readAsString();
        content =
            content.length > 500 ? '${content.substring(0, 500)}...' : content;
      } else {
        final bytes = await file.readAsBytes();
        content =
            'Binary file\nSize: ${(bytes.length / 1024).toStringAsFixed(2)} KB\nType: ${path.extension(filePath)}';
      }

      // Update both local state and provider state.

      setState(() {
        filePreview = content;
        showPreview = true;
      });
      ref.read(fileServiceProvider.notifier).setFilePreview(content);
    } catch (e) {
      debugPrint('Preview error: $e');
    }
  }

  /// Builds a preview card UI to show content or info of selected file.

  Widget _buildPreviewCard() {
    if (!showPreview || filePreview == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.defaultBorderRadius),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.preview,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Preview',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: AppTheme.primaryColor,
                  ),
                  onPressed: () => setState(() => showPreview = false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Text(
                filePreview!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  color: AppTheme.primaryTextColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fileServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title.
        Text(
          'Upload Files',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.headlineSmall?.color,
          ),
        ),
        const SizedBox(height: 16),

        // Display preview card if enabled.
        _buildPreviewCard(),
        if (showPreview) const SizedBox(height: 16),

        // Selected file indicator (the one showing in the upload area).
        if (state.remoteFileName != null &&
            state.remoteFileName != 'remoteFileName')
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.file_present,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.cleanFileName ?? '',
                    style: const TextStyle(
                      color: AppTheme.primaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
              ],
            ),
          ),

        // Upload and CSV buttons row.
        Row(
          children: [
            // Main upload button.
            Expanded(
              child: MarkdownTooltip(
                message: '''

                **Upload**: Tap here to upload a file to your Solid Movie Star.

                ''',
                child: ElevatedButton.icon(
                  onPressed: state.uploadInProgress
                      ? null
                      : () async {
                          final result = await FilePicker.platform.pickFiles();
                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.first;
                            if (file.path != null) {
                              ref
                                  .read(fileServiceProvider.notifier)
                                  .setUploadFile(file.path);
                              await handlePreview(file.path!);
                              if (!context.mounted) return;
                              await ref
                                  .read(fileServiceProvider.notifier)
                                  .handleUpload(context);
                              // Clear the upload file after successful upload.

                              ref
                                  .read(fileServiceProvider.notifier)
                                  .setUploadFile(null);
                              // Clear the preview.

                              setState(() {
                                filePreview = null;
                                showPreview = false;
                              });
                            }
                          }
                        },
                  icon: const Icon(Icons.file_upload, color: Colors.white),
                  label: const Text(
                    'Upload',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.defaultBorderRadius,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        MarkdownTooltip(
          message: '''

          **Visualize JSON**: Tap here to select and visualize a JSON file from your local machine.

          ''',
          child: TextButton.icon(
            onPressed: state.uploadInProgress
                ? null
                : () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['json'],
                    );
                    if (result != null && result.files.isNotEmpty) {
                      final file = result.files.first;
                      if (file.path != null) {
                        await handlePreview(file.path!);
                      }
                    }
                  },
            icon: const Icon(Icons.analytics, color: AppTheme.primaryColor),
            label: const Text(
              'Visualize JSON',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  AppTheme.defaultBorderRadius,
                ),
              ),
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            ),
          ),
        ),

        // Preview button.
        if (state.uploadFile != null) ...[
          const SizedBox(height: 12),
          MarkdownTooltip(
            message: '''

            **Preview File**: Tap here to preview the recently uploaded file.

            ''',
            child: TextButton.icon(
              onPressed: state.uploadInProgress
                  ? null
                  : () => handlePreview(state.uploadFile!),
              icon: const Icon(Icons.preview, color: AppTheme.primaryColor),
              label: const Text(
                'Preview File',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppTheme.defaultBorderRadius,
                  ),
                ),
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
