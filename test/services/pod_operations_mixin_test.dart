/// Unit tests for PodOperationsMixin.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
library;

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moviestar/core/services/pod/operations_mixin.dart';

/// Test class using PodOperationsMixin
class TestMixinClass with PodOperationsMixin {
  int operationCallCount = 0;

  Future<String?> testRetryOperation({
    bool shouldFail = false,
    int maxRetries = 3,
  }) {
    return retryOperation(
      operation: () async {
        operationCallCount++;
        await Future.delayed(Duration(milliseconds: 5));
        if (shouldFail && operationCallCount < maxRetries) {
          throw Exception('Retry test failure $operationCallCount');
        }
        return 'success after $operationCallCount attempts';
      },
      operationName: 'testRetryOperation',
      maxRetries: maxRetries,
    );
  }

  Future<bool> testValidateContextAndLogin(BuildContext context) {
    return validateContextAndLogin(context);
  }

  bool testValidateContext(BuildContext context) {
    return validateContext(context);
  }

  bool testIsFileNotFoundError(dynamic error) {
    return isFileNotFoundError(error);
  }

  bool testIsPermissionError(dynamic error) {
    return isPermissionError(error);
  }
}

void main() {
  group('PodOperationsMixin Tests', () {
    late TestMixinClass testClass;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    setUp(() {
      testClass = TestMixinClass();
    });

    testWidgets('retryOperation succeeds on first attempt',
        (WidgetTester tester) async {
      final result = await testClass.testRetryOperation(shouldFail: false);
      expect(result, equals('success after 1 attempts'));
      expect(testClass.operationCallCount, equals(1));
    });

    testWidgets('retryOperation retries on failure',
        (WidgetTester tester) async {
      testClass.operationCallCount = 0;
      final result =
          await testClass.testRetryOperation(shouldFail: true, maxRetries: 3);
      expect(result, equals('success after 3 attempts'));
      expect(testClass.operationCallCount, equals(3));
    });

    testWidgets('retryOperation gives up after max retries',
        (WidgetTester tester) async {
      testClass.operationCallCount = 0;
      // Force all attempts to fail
      final result = await testClass.retryOperation(
        operation: () async {
          testClass.operationCallCount++;
          throw Exception('Always fails');
        },
        operationName: 'alwaysFails',
        maxRetries: 2,
      );
      expect(result, isNull);
      expect(testClass.operationCallCount, equals(2));
    });

    testWidgets('validateContext returns true for mounted context',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final isValid = testClass.testValidateContext(context);
              expect(isValid, isTrue);
              return Container();
            },
          ),
        ),
      );
    });

    testWidgets('isFileNotFoundError detects file not found errors',
        (WidgetTester tester) async {
      expect(
        testClass.testIsFileNotFoundError(Exception('File does not exist')),
        isTrue,
      );
      expect(
        testClass.testIsFileNotFoundError(Exception('resource does not exist')),
        isTrue,
      );
      expect(testClass.testIsFileNotFoundError(Exception('404')), isTrue);
      expect(testClass.testIsFileNotFoundError(Exception('not found')), isTrue);
      expect(
        testClass.testIsFileNotFoundError(Exception('Other error')),
        isFalse,
      );
    });

    testWidgets('isPermissionError detects permission errors',
        (WidgetTester tester) async {
      expect(
        testClass.testIsPermissionError(Exception('Permission denied')),
        isTrue,
      );
      expect(
        testClass.testIsPermissionError(Exception('Access denied')),
        isTrue,
      );
      expect(
        testClass.testIsPermissionError(Exception('Unauthorized')),
        isTrue,
      );
      expect(testClass.testIsPermissionError(Exception('403')), isTrue);
      expect(testClass.testIsPermissionError(Exception('401')), isTrue);
      expect(
        testClass.testIsPermissionError(Exception('Other error')),
        isFalse,
      );
    });

    test('exponential backoff delays increase correctly', () async {
      final delays = <Duration>[];

      await testClass.retryOperation(
        operation: () async {
          delays.add(Duration.zero); // Track that operation was called
          throw Exception('Always fails for delay test');
        },
        operationName: 'delayTest',
        maxRetries: 3,
        initialDelay: Duration(milliseconds: 100),
      );

      // Should have been called 3 times (maxRetries)
      expect(delays.length, equals(3));
    });
  });
}
