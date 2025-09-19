/// Comments section builder for movie info section.
/// Extracted to reduce file size and improve organization.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:moviestar/constants/dimensions.dart';

/// Builds the comments section for movie details.
class CommentsSection {
  /// Build the comments section with text field and controls.
  static Widget buildCommentsSection(
    BuildContext context, {
    required bool isSharedMovie,
    required String? comments,
    required TextEditingController commentsController,
    required bool commentsSaved,
    required VoidCallback onSaveComments,
    required VoidCallback onClearComments,
    required bool hasTextInField, // Add this parameter to track text changes
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              isSharedMovie ? 'Shared Comments' : 'Your Comments',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (commentsSaved)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green, width: 1),
                ),
                child: const Text(
                  'Saved',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const Gap(Gaps.s),
        if (isSharedMovie && comments != null && comments.isNotEmpty)
          // Display shared comments (read-only)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            child: Text(
              comments,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else if (!isSharedMovie)
          // Editable comments for own movies
          Column(
            children: [
              TextField(
                controller: commentsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add your thoughts about this movie...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const Gap(Gaps.s),
              Row(
                children: [
                  if (hasTextInField)
                    ElevatedButton.icon(
                      onPressed: onSaveComments,
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  if (hasTextInField) const Gap(Gaps.s),
                  if (comments != null && comments.isNotEmpty)
                    TextButton.icon(
                      onPressed: onClearComments,
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          )
        else
          // No shared comments available
          Text(
            'No comments shared',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
          ),
      ],
    );
  }
}
