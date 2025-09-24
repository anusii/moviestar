/// User-friendly error widget renderer for ErrorDisplayWidget.
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gap/gap.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/models/app_error.dart';

import 'action_button_builder.dart';

/// Renders UserFriendlyError with full functionality.
class UserFriendlyErrorRenderer extends StatefulWidget {
  final UserFriendlyError error;
  final double iconSize;
  final double textSize;
  final bool isCompact;
  final bool showTechnicalDetailsInitially;

  const UserFriendlyErrorRenderer({
    super.key,
    required this.error,
    required this.iconSize,
    required this.textSize,
    required this.isCompact,
    required this.showTechnicalDetailsInitially,
  });

  @override
  State<UserFriendlyErrorRenderer> createState() =>
      _UserFriendlyErrorRendererState();
}

class _UserFriendlyErrorRendererState extends State<UserFriendlyErrorRenderer> {
  late bool _showTechnicalDetails;

  @override
  void initState() {
    super.initState();
    _showTechnicalDetails = widget.showTechnicalDetailsInitially;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = widget.error.color ?? theme.colorScheme.error;
    final surfaceColor = theme.colorScheme.surface;
    final onSurfaceColor = theme.colorScheme.onSurface;

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: widget.isCompact ? 300 : 400,
          maxHeight: MediaQuery.of(context).size.height *
              0.8, // Prevent full-screen overflow.
        ),
        margin: EdgeInsets.all(widget.isCompact ? Dimensions.l : Dimensions.xl),
        padding: EdgeInsets.all(widget.isCompact ? 16.0 : Dimensions.xxl),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(Dimensions.l),
          border: Border.all(
            color: errorColor.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: errorColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error icon and title.

              Row(
                children: [
                  Icon(
                    widget.error.icon,
                    size: widget.iconSize,
                    color: errorColor,
                  ),
                  Gap(widget.isCompact ? Gaps.m : Gaps.xl),
                  Expanded(
                    child: Text(
                      widget.error.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: errorColor,
                        fontWeight: FontWeight.bold,
                        fontSize: widget.textSize + (widget.isCompact ? 0 : 2),
                      ),
                    ),
                  ),
                ],
              ),

              Gap(widget.isCompact ? Gaps.m : Gaps.xl),

              // Error message.

              Text(
                widget.error.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: onSurfaceColor,
                  fontSize: widget.textSize - (widget.isCompact ? 1 : 0),
                ),
                textAlign: TextAlign.start,
              ),

              // Additional details.

              Gap(widget.isCompact ? Dimensions.ms : Gaps.m),
              Text(
                widget.error.details,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: onSurfaceColor.withValues(alpha: 0.8),
                  fontSize: widget.textSize - (widget.isCompact ? 2 : 1),
                ),
                textAlign: TextAlign.start,
              ),

              // Action buttons.

              if (widget.error.actions.isNotEmpty) ...[
                Gap(widget.isCompact ? Gaps.xl : Gaps.xxl),
                ActionButtonBuilder.buildActionButtons(widget.error.actions),
              ],

              // Technical details section (expandable).

              if (widget.error.hasTechnicalDetails) ...[
                Gap(widget.isCompact ? Gaps.m : Gaps.xl),
                _buildTechnicalDetailsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechnicalDetailsSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Expandable header.

        InkWell(
          onTap: () {
            setState(() {
              _showTechnicalDetails = !_showTechnicalDetails;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  _showTechnicalDetails ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const Gap(Gaps.s),
                Text(
                  'Technical Details',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Technical details content (expandable).

        if (_showTechnicalDetails) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(Dimensions.l),
            constraints: const BoxConstraints(
              maxHeight: 200, // Limit height to prevent overflow.
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(Dimensions.m),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Technical details text with scrolling.

                Expanded(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      widget.error.technicalDetails,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),

                const Gap(Gaps.m),

                // Copy to clipboard button with scroll hint.

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Scroll hint text.

                    Expanded(
                      child: Text(
                        'Scroll to view all details',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                      ),
                    ),
                    // Copy button.

                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: widget.error.technicalDetails),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Technical details copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
