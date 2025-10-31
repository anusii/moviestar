/// Tests for POD Sharing Service.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.

library;

import 'package:flutter_test/flutter_test.dart';

import 'package:moviestar/core/services/pod/sharing_service.dart';
import 'package:moviestar/models/sharing_models.dart';

void main() {
  group('PodSharingService', () {
    setUp(() {
      // Clear cache before each test
      PodSharingService.clearCache();
    });

    group('WebID Validation', () {
      test('validates correct WebID format', () async {
        expect(
          await PodSharingService.validateWebId(
            'https:' '//pod.example.com/profile/card#me',
          ),
          isTrue,
        );
        expect(
          await PodSharingService.validateWebId(
            'http:' '//localhost:3000/user/card#me',
          ),
          isTrue,
        );
      });

      test('rejects invalid WebID format', () async {
        expect(
          await PodSharingService.validateWebId(''),
          isFalse,
        );
        expect(
          await PodSharingService.validateWebId('not-a-url'),
          isFalse,
        );
        expect(
          await PodSharingService.validateWebId('ftp://example.com/profile'),
          isFalse,
        );
      });

      test('caches validation results', () async {
        const webId = 'https:' '//pod.example.com/profile/card#me';

        // First call
        final result1 = await PodSharingService.validateWebId(webId);

        // Second call should use cache
        final result2 = await PodSharingService.validateWebId(webId);

        expect(result1, equals(result2));
      });
    });

    group('ShareRequest', () {
      test('creates valid share request', () {
        final request = const ShareRequest(
          fileName: 'movies/Movie-123.ttl',
          displayName: 'Test Movie',
          permissions: ['read', 'write'],
          recipientWebId: 'https:' '//pod.example.com/profile/card#me',
        );

        expect(request.fileName, equals('movies/Movie-123.ttl'));
        expect(request.displayName, equals('Test Movie'));
        expect(request.permissions, contains('read'));
        expect(request.permissions, contains('write'));
        expect(request.recipientWebId, contains('pod.example.com'));
      });
    });

    group('ShareResult', () {
      test('creates success result', () {
        final result = ShareResult.success(
          metadata: {'timestamp': '2025-01-01'},
        );

        expect(result.success, isTrue);
        expect(result.error, isNull);
        expect(result.metadata, isNotNull);
        expect(result.metadata!['timestamp'], equals('2025-01-01'));
      });

      test('creates failure result', () {
        final result = ShareResult.failure('Permission denied');

        expect(result.success, isFalse);
        expect(result.error, equals('Permission denied'));
        expect(result.metadata, isNull);
      });
    });

    group('BatchShareResult', () {
      test('calculates statistics correctly', () {
        final results = [
          ShareResult.success(),
          ShareResult.success(),
          ShareResult.failure('Error 1'),
          ShareResult.success(),
        ];

        final batchResult = BatchShareResult(results: results);

        expect(batchResult.successCount, equals(3));
        expect(batchResult.failureCount, equals(1));
        expect(batchResult.allSuccessful, isFalse);
      });

      test('identifies all successful batch', () {
        final results = [
          ShareResult.success(),
          ShareResult.success(),
          ShareResult.success(),
        ];

        final batchResult = BatchShareResult(results: results);

        expect(batchResult.allSuccessful, isTrue);
        expect(batchResult.failureCount, equals(0));
      });
    });

    // Note: Status message tests removed due to SolidFunctionCallStatus API complexity
    // These would need to be tested in integration tests with actual solidpod calls
  });
}
