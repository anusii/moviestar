/// Legacy error widget renderer for backward compatibility.
///
/// Copyright (C) 2024-2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';

import 'package:moviestar/constants/dimensions.dart';

/// Legacy error widget for backward compatibility.

class LegacyErrorRenderer extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final double iconSize;
  final double textSize;
  final bool isCompact;

  const LegacyErrorRenderer({
    super.key,
    required this.message,
    this.onRetry,
    required this.iconSize,
    required this.textSize,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? Dimensions.l : Dimensions.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: iconSize, color: errorColor),
            Gap(isCompact ? Gaps.m : Gaps.xxl),
            Text(
              message,
              style: TextStyle(color: errorColor, fontSize: textSize),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              Gap(isCompact ? Gaps.m : Gaps.xxl),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
