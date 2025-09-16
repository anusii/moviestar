/// Unit tests for BasePodService infrastructure.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moviestar/services/base_pod_service.dart';

/// Test implementation of BasePodService for testing
class TestPodService extends BasePodService {
  TestPodService(BuildContext context, Widget child) : super(context, child);

  /// Test method that uses executePodOperation
  Future<String?> testOperation(String input) {
    return executePodOperation(
      operation: () async {
        await Future.delayed(Duration(milliseconds: 10));
        if (input == 'error') throw Exception('Test error');
        return 'success: $input';
      },
      operationName: 'testOperation',
    );
  }

  /// Test method that requires login
  Future<String?> testRequiresLogin() {
    return executePodOperation(
      operation: () async => 'logged in',
      operationName: 'testRequiresLogin',
      requiresLogin: true,
    );
  }

  /// Test method that checks context
  Future<String?> testRequiresContext() {
    return executePodOperation(
      operation: () async => 'context valid',
      operationName: 'testRequiresContext',
      checkContext: true,
    );
  }
}

void main() {
  group('BasePodService Tests', () {
    late TestPodService service;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Service implements ChangeNotifier pattern', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              service = TestPodService(context, Container());
              return Container();
            },
          ),
        ),
      );

      expect(service, isA<ChangeNotifier>());
    });

    testWidgets('executePodOperation handles successful operations', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              service = TestPodService(context, Container());
              return Container();
            },
          ),
        ),
      );

      final result = await service.testOperation('test');
      expect(result, equals('success: test'));
    });

    testWidgets('executePodOperation handles errors gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              service = TestPodService(context, Container());
              return Container();
            },
          ),
        ),
      );

      final result = await service.testOperation('error');
      expect(result, isNull);
    });

    testWidgets('Service disposes properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              service = TestPodService(context, Container());
              return Container();
            },
          ),
        ),
      );

      expect(() => service.dispose(), returnsNormally);
    });

    testWidgets('Service provides context and child getters', (WidgetTester tester) async {
      Widget testChild = Container();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              service = TestPodService(context, testChild);
              return Container();
            },
          ),
        ),
      );

      expect(service.context, isNotNull);
      expect(service.child, equals(testChild));
    });
  });
}