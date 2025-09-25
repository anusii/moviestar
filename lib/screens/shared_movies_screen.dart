/// Shared Movies Screen for MovieStar.
/// Decomposed version using helper classes to reduce file size.
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

import 'package:gap/gap.dart';

import 'package:moviestar/mixins/screen_state_mixin.dart';
import 'package:moviestar/screens/shared_movies/data_fetcher.dart';
import 'package:moviestar/screens/shared_movies/ui_builder.dart';
import 'package:moviestar/widgets/base_screen.dart';
import 'package:moviestar/widgets/list_shared_movies.dart';

class SharedMoviesScreen extends StatefulWidget {
  const SharedMoviesScreen({super.key});

  @override
  State<SharedMoviesScreen> createState() => _SharedMoviesScreenState();
}

class _SharedMoviesScreenState extends State<SharedMoviesScreen>
    with WidgetsBindingObserver, ScreenStateMixin {
  Future<Map<String, dynamic>?>? _sharedWithMeData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This gets called when returning from a route.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshData();
      }
    });
  }

  void _refreshData() {
    safeSetState(() {
      _sharedWithMeData = SharedMoviesDataFetcher.getMoviesSharedWithMe(
        context,
        widget,
      );
    });
  }

  Widget _buildLoadedScreen(Map<String, dynamic> sharedMoviesMap) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListSharedMovies(
        sharedMoviesMap: sharedMoviesMap,
        onDataChanged: _refreshData,
      ),
    );
  }

  Widget _buildErrorStateWithRetry() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SharedMoviesUIBuilder.buildErrorState(),
          const Gap(16),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Shared Movies',
      body: _buildSharedWithMeTab(),
    );
  }

  Widget _buildSharedWithMeTab() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _sharedWithMeData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                Gap(16),
                Text('Loading shared movies...'),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          return _buildErrorStateWithRetry();
        } else if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return SharedMoviesUIBuilder.buildEmptyState();
        } else {
          return _buildLoadedScreen(snapshot.data!);
        }
      },
    );
  }
}
