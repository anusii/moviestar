/// POD files management screen.
///
// Time-stamp: <Wednesday 2025-08-27 15:30:00 +1000 Tony Chen>
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
/// Authors: Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:solidui/solidui.dart';

import 'package:moviestar/constants/dimensions.dart';
import 'package:moviestar/constants/paths.dart';
import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/widgets/base_screen.dart';

/// Screen for managing POD files.

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> with ScreenStateMixin {
  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Files',
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxHeight <= 0 || constraints.maxWidth <= 0) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading file manager...'),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(Dimensions.xl),
              child: SolidFile(
                basePath: basePath,
              ),
            );
          },
        ),
      ),
    );
  }
}
