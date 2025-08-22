/// Moviestar - Manage and share ratings through private PODs.
///
// Time-stamp: <Sunday 2025-08-10 11:33:19 +1000 Graham Williams>
///
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html
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
/// Authors: Kevin Wang, Graham Williams, Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:solidui/solidui.dart';

/// A placeholder home page widget.

class HomePage extends StatelessWidget {
  /// Creates a new [HomePage] widget.

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SolidScaffold(
      appBar: AppBar(title: const Text('Movie Star'), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie, size: 100, color: Colors.blue),
            const Gap(20),
            Text(
              'Welcome to Movie Star',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Gap(10),
            Text(
              'Your ultimate movie companion',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
