/// Recipient Section Widget for Batch Sharing.
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
/// Authors: Ashley Tang.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/widgets/common_sharing_ui.dart';

/// A widget that displays the recipient input section for batch sharing.
/// Handles WebID input and validation.
class RecipientSection extends StatelessWidget {
  /// Controller for the WebID input field.
  final TextEditingController controller;

  /// Callback when WebID is validated.
  final void Function(String?) onValidated;

  /// Creates a new [RecipientSection].
  const RecipientSection({
    super.key,
    required this.controller,
    required this.onValidated,
  });

  @override
  Widget build(BuildContext context) {
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
              controller: controller,
              onValidated: onValidated,
              label: 'Recipient WebID *',
              hint: 'https://example.solid.com/profile/card#me',
            ),
          ],
        ),
      ),
    );
  }
}
