/// Action button builder for error display widgets.
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
import 'package:moviestar/models/app_error.dart';

/// Static helper class for building action buttons in error displays.

class ActionButtonBuilder {
  /// Builds action buttons based on the number and type of actions.

  static Widget buildActionButtons(List<ErrorAction> actions) {
    if (actions.length == 1) {
      // Single action - full width button.

      return _buildSingleActionButton(actions.first);
    } else if (actions.length == 2) {
      // Two actions - side by side with equal heights.

      return _buildTwoActionButtons(actions);
    } else {
      // Multiple actions - wrap them.

      return _buildMultipleActionButtons(actions);
    }
  }

  static Widget _buildSingleActionButton(ErrorAction action) {
    return SizedBox(
      width: double.infinity,
      child: action.isPrimary
          ? ElevatedButton.icon(
              onPressed: action.onPressed,
              icon: Icon(action.icon),
              label: Text(action.label),
            )
          : OutlinedButton.icon(
              onPressed: action.onPressed,
              icon: Icon(action.icon),
              label: Text(action.label),
            ),
    );
  }

  static Widget _buildTwoActionButtons(List<ErrorAction> actions) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: actions[1].isPrimary
                ? ElevatedButton.icon(
                    onPressed: actions[1].onPressed,
                    icon: Icon(actions[1].icon),
                    label: Text(
                      actions[1].label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      minimumSize: const Size(0, 48),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: actions[1].onPressed,
                    icon: Icon(actions[1].icon),
                    label: Text(
                      actions[1].label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      minimumSize: const Size(0, 48),
                    ),
                  ),
          ),
          const Gap(Gaps.m),
          Expanded(
            child: actions[0].isPrimary
                ? ElevatedButton.icon(
                    onPressed: actions[0].onPressed,
                    icon: Icon(actions[0].icon),
                    label: Text(
                      actions[0].label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      minimumSize: const Size(0, 48),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: actions[0].onPressed,
                    icon: Icon(actions[0].icon),
                    label: Text(
                      actions[0].label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      minimumSize: const Size(0, 48),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static Widget _buildMultipleActionButtons(List<ErrorAction> actions) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: actions.map((action) {
        return action.isPrimary
            ? ElevatedButton.icon(
                onPressed: action.onPressed,
                icon: Icon(action.icon),
                label: Text(action.label),
              )
            : OutlinedButton.icon(
                onPressed: action.onPressed,
                icon: Icon(action.icon),
                label: Text(action.label),
              );
      }).toList(),
    );
  }
}
