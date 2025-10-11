/// Helper widgets for navigation integration tests.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter/material.dart';

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/widgets/movie_sharing_ui.dart';

import 'test_data_factory.dart';

/// Creates a test movie for navigation tests.
Movie createTestMovie() {
  return TestDataFactory.createMovie();
}

/// Intermediate screen used for testing navigation stack.
class IntermediateScreen extends StatelessWidget {
  const IntermediateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Intermediate')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MovieSharingUI(
                  movie: createTestMovie(),
                  onSharingComplete: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ),
            );
          },
          child: const Text('Open Sharing'),
        ),
      ),
    );
  }
}

/// Mock sharing screen for testing callback behavior.
class MockSharingScreen extends StatelessWidget {
  final VoidCallback onComplete;

  const MockSharingScreen({required this.onComplete, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mock Sharing')),
      body: Center(
        child: ElevatedButton(
          onPressed: onComplete,
          child: const Text('Complete'),
        ),
      ),
    );
  }
}

/// Stateful home screen for testing state preservation during navigation.
class StatefulHomeScreen extends StatefulWidget {
  const StatefulHomeScreen({super.key});

  @override
  State<StatefulHomeScreen> createState() => _StatefulHomeScreenState();
}

class _StatefulHomeScreenState extends State<StatefulHomeScreen> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stateful Home')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Count: $_counter'),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  setState(() {
                    _counter++;
                  });
                },
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieSharingUI(
                        movie: createTestMovie(),
                        onSharingComplete: () {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                      ),
                    ),
                  );
                },
                child: const Text('Open Sharing'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget for testing proper disposal during navigation.
class DisposableWidget extends StatefulWidget {
  const DisposableWidget({super.key});

  @override
  State<DisposableWidget> createState() => _DisposableWidgetState();
}

class _DisposableWidgetState extends State<DisposableWidget> {
  bool _isLoading = false;

  Future<void> _startAsync() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Disposable')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _startAsync,
                child: const Text('Start Async'),
              ),
      ),
    );
  }
}

/// Navigator observer for tracking navigation depth.
class DepthTrackingNavigatorObserver extends NavigatorObserver {
  final VoidCallback onPush;
  final VoidCallback onPop;

  DepthTrackingNavigatorObserver({
    required this.onPush,
    required this.onPop,
  });

  @override
  void didPush(Route route, Route? previousRoute) {
    onPush();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    onPop();
    super.didPop(route, previousRoute);
  }
}
