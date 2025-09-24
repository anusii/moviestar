/// Kanban Column Skeleton - Loading placeholder for kanban columns.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:moviestar/constants/dimensions.dart';

/// A skeleton placeholder for kanban columns during loading.
/// Provides visual feedback that a column will appear while maintaining layout.
class KanbanColumnSkeleton extends StatefulWidget {
  /// Optional skeleton title text.
  final String? title;

  /// Number of skeleton items to show in the column.
  final int itemCount;

  /// Width of the skeleton column.
  final double width;

  const KanbanColumnSkeleton({
    super.key,
    this.title,
    this.itemCount = 3,
    this.width = 280.0,
  });

  @override
  State<KanbanColumnSkeleton> createState() => _KanbanColumnSkeletonState();
}

class _KanbanColumnSkeletonState extends State<KanbanColumnSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: widget.width,
      margin: const EdgeInsets.only(right: Dimensions.m),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton.

          Container(
            padding: const EdgeInsets.all(Dimensions.m),
            child: Row(
              children: [
                // Title skeleton.

                Expanded(
                  child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: _animation.value,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: widget.title != null
                            ? Center(
                                child: Text(
                                  widget.title!,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color:
                                        theme.colorScheme.onSurface.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ),
                const Gap(Dimensions.s),
                // Count badge skeleton.

                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: _animation.value * 0.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const SizedBox(
                        width: 16,
                        height: 16,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Skeleton movie items content.

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: widget.itemCount,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildSkeletonMovieItem(theme),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build a skeleton movie item placeholder.
  Widget _buildSkeletonMovieItem(ThemeData theme) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Poster skeleton.

          Container(
            width: 50,
            height: 70,
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Gap(8),
          // Text content skeleton.

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title skeleton.

                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Gap(4),
                // Subtitle skeleton.

                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const Gap(8),
        ],
      ),
    );
  }
}
