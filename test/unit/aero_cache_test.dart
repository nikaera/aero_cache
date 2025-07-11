import 'dart:io';
import 'dart:typed_data';

import 'package:aero_cache/aero_cache.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() {
  setUpAll(() {
    TestSetupHelper.setupPathProvider();
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('AeroCache', () {
    late AeroCache aeroCache;
    late MockHttpClient mockHttpClient;
    late Directory tempDir;

    setUp(() async {
      mockHttpClient = MockHttpClient();
      tempDir = await TestSetupHelper.createTempDirectory();
      aeroCache = await TestSetupHelper.createAeroCache(
        httpClient: mockHttpClient,
        cacheDirPath: tempDir.path,
      );
    });

    tearDown(() async {
      aeroCache.dispose();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should initialize successfully', () async {
      await aeroCache.initialize();
      expect(aeroCache, isNotNull);
    });

    test('should download and cache data', () async {
      await aeroCache.initialize();

      const url = 'https://example.com/test.jpg';
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

      mockHttpClient.setResponse(url, testData, {
        'etag': '"abc123"',
        'last-modified': 'Wed, 09 Jul 2025 12:00:00 GMT',
      });

      final result = await aeroCache.get(url);
      expect(result, testData);
    });

    test('should return cached data on subsequent requests', () async {
      await aeroCache.initialize();

      const url = 'https://example.com/test.jpg';
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

      mockHttpClient.setResponse(url, testData, {
        'cache-control': 'max-age=3600',
      });

      final result1 = await aeroCache.get(url);
      final result2 = await aeroCache.get(url);

      expect(result1, testData);
      expect(result2, testData);
      expect(mockHttpClient.requestCount, 1);
    });

    test('should handle 304 Not Modified response', () async {
      await aeroCache.initialize();

      const url = 'https://example.com/test.jpg';
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

      mockHttpClient.setResponse(url, testData, {
        'etag': '"abc123"',
        'cache-control': 'max-age=0',
      });

      final result1 = await aeroCache.get(url);

      mockHttpClient.setNotModifiedResponse(url);

      final result2 = await aeroCache.get(url);

      expect(result1, testData);
      expect(result2, testData);
      expect(mockHttpClient.requestCount, 2);
    });

    test('should call progress callback', () async {
      await aeroCache.initialize();

      const url = 'https://example.com/test.jpg';
      final testData = Uint8List.fromList(List.generate(1000, (i) => i % 256));

      mockHttpClient.setResponse(url, testData, {});

      final progressCalls = <Map<String, int>>[];

      await aeroCache.get(
        url,
        onProgress: (received, total) {
          progressCalls.add({'received': received, 'total': total});
        },
      );

      expect(progressCalls.isNotEmpty, true);
      expect(progressCalls.last['received'], testData.length);
      expect(progressCalls.last['total'], testData.length);
    });

    test('should handle HTTP errors', () async {
      await aeroCache.initialize();

      const url = 'https://example.com/test.jpg';

      mockHttpClient.setErrorResponse(url, 404);

      expect(
        () => aeroCache.get(url),
        throwsA(isA<AeroCacheException>()),
      );
    });

    test('should handle network errors', () async {
      await aeroCache.initialize();

      const url = 'https://example.com/test.jpg';

      mockHttpClient.setNetworkError(url);

      expect(
        () => aeroCache.get(url),
        throwsA(isA<AeroCacheException>()),
      );
    });

    test('should not cache data with no-store directive', () async {
      await aeroCache.initialize();

      const url = 'https://example.com/no-store-test.jpg';
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

      mockHttpClient.setResponse(url, testData, {
        'cache-control': 'no-store',
      });

      final result1 = await aeroCache.get(url);
      final result2 = await aeroCache.get(url);

      expect(result1, testData);
      expect(result2, testData);
      // Should make two requests since no-store prevents caching
      expect(mockHttpClient.requestCount, 2);
    });

    test('should force revalidation with no-cache directive', () async {
      await aeroCache.initialize();

      const url = 'https://example.com/no-cache-test.jpg';
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

      // First request with no-cache
      mockHttpClient.setResponse(url, testData, {
        'cache-control': 'no-cache, max-age=3600',
      });

      final result1 = await aeroCache.get(url);

      // Second request should revalidate even though cache exists
      mockHttpClient.setNotModifiedResponse(url);
      final result2 = await aeroCache.get(url);

      expect(result1, testData);
      expect(result2, testData);
      // Should make two requests due to no-cache directive
      expect(mockHttpClient.requestCount, 2);
    });

    test(
      'should force revalidation for cached items with requiresRevalidation',
      () async {
        await aeroCache.initialize();

        const url = 'https://example.com/requires-revalidation-test.jpg';
        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

        // First request creates cache with requiresRevalidation=true
        mockHttpClient.setResponse(url, testData, {
          'cache-control': 'no-cache, max-age=3600',
        });

        final result1 = await aeroCache.get(url);

        // Second request should revalidate because requiresRevalidation=true
        mockHttpClient.setNotModifiedResponse(url);
        final result2 = await aeroCache.get(url);

        expect(result1, testData);
        expect(result2, testData);
        // Should make two requests due to requiresRevalidation
        expect(mockHttpClient.requestCount, 2);
      },
    );

    test('should force revalidation with no-cache request directive', () async {
      await aeroCache.initialize();

      const url = 'https://example.com/no-cache-request-test.jpg';
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

      // First request creates cache
      mockHttpClient.setResponse(url, testData, {
        'cache-control': 'max-age=3600',
      });

      final result1 = await aeroCache.get(url);

      // Second request with no-cache directive should force revalidation
      mockHttpClient.setNotModifiedResponse(url);
      final result2 = await aeroCache.get(
        url,
        noCache: true,
      );

      expect(result1, testData);
      expect(result2, testData);
      // Should make two requests due to no-cache request directive
      expect(mockHttpClient.requestCount, 2);
    });

    test(
      'should reject cached response older than max-age request directive',
      () async {
        await aeroCache.initialize();

        const url = 'https://example.com/max-age-request-test.jpg';
        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

        // First request creates cache with long max-age
        mockHttpClient.setResponse(url, testData, {
          'cache-control': 'max-age=7200', // 2 hours
        });

        final result1 = await aeroCache.get(url);

        // Wait a small amount to ensure cache age > 0
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Second request with max-age=0 should reject any cached response
        // and make a new request
        mockHttpClient.setNotModifiedResponse(url);
        final result2 = await aeroCache.get(
          url,
          maxAge: 10, // Force revalidation
        );

        expect(result1, testData);
        expect(result2, testData);
        // Should make two requests since cache is older than request max-age
        expect(mockHttpClient.requestCount, 2);
      },
    );

    test(
      'should return stale data on error when stale-if-error allows',
      () async {
        await aeroCache.initialize();

        const url = 'https://example.com/stale-if-error-test.jpg';
        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

        // First request creates stale cache with stale-if-error
        mockHttpClient.setResponse(url, testData, {
          'cache-control': 'max-age=0, stale-if-error=600',
        });

        final result1 = await aeroCache.get(url);
        expect(result1, testData);

        await Future<void>.delayed(const Duration(milliseconds: 100));

        // 2nd request should fail, but return stale data due to stale-if-error
        mockHttpClient.setErrorResponse(url, 500);
        final result2 = await aeroCache.get(url);

        expect(result1, testData);
        expect(result2, testData);
        expect(mockHttpClient.requestCount, 2);
      },
    );

    test('should throw error when stale-if-error window expired', () async {
      await aeroCache.initialize();

      const url = 'https://example.com/stale-if-error-expired-test.jpg';
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

      // First request creates cache with short stale-if-error window
      mockHttpClient.setResponse(url, testData, {
        'cache-control': 'max-age=0, stale-if-error=0',
      });

      final result1 = await aeroCache.get(url);
      expect(result1, testData);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Second request should throw error since stale-if-error window expired
      mockHttpClient.setErrorResponse(url, 500);

      expect(
        () => aeroCache.get(url),
        throwsA(isA<AeroCacheException>()),
      );
    });

    test('should throw error when no stale data available', () async {
      await aeroCache.initialize();

      const url = 'https://example.com/no-stale-data-test.jpg';

      // No cache exists, should throw error immediately
      mockHttpClient.setErrorResponse(url, 500);

      expect(
        () => aeroCache.get(url),
        throwsA(isA<AeroCacheException>()),
      );
    });

    test('should accept stale response when max-stale allows', () async {
      await aeroCache.initialize();

      const url = 'https://example.com/max-stale-test.jpg';
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

      // First request creates cache with short max-age
      mockHttpClient.setResponse(url, testData, {
        'cache-control': 'max-age=1',
      });

      final result1 = await aeroCache.get(url);
      expect(result1, testData);

      // Wait for cache to become stale
      await Future<void>.delayed(const Duration(seconds: 2));

      // Second request with max-stale should accept stale cache
      final result2 = await aeroCache.get(
        url,
        maxStale: 600, // Allow stale content up to 10 minutes
      );

      expect(result1, testData);
      expect(result2, testData);
      // Should only make one request since stale cache is acceptable
      expect(mockHttpClient.requestCount, 1);
    });

    test('should reject cache when min-fresh requirement not met', () async {
      await aeroCache.initialize();

      const url = 'https://example.com/min-fresh-test.jpg';
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

      // First request creates cache with max-age=5
      mockHttpClient.setResponse(url, testData, {
        'cache-control': 'max-age=5',
      });

      final result1 = await aeroCache.get(url);
      expect(result1, testData);

      // Wait 3 seconds (cache is still fresh but has only 2 seconds left)
      await Future<void>.delayed(const Duration(seconds: 3));

      // Request with min-fresh=3 requires cache to be fresh for 3+ seconds
      // Since cache only has 2 seconds left, should make new request
      mockHttpClient.setResponse(url, testData, {
        'cache-control': 'max-age=10',
      });

      final result2 = await aeroCache.get(
        url,
        minFresh: 3, // Require cache to be fresh for at least 3 more seconds
      );

      expect(result2, testData);
      // Should make two requests since cache doesn't meet min-fresh requirement
      expect(mockHttpClient.requestCount, 2);
    });

    test(
      'should return only cached content with only-if-cached directive',
      () async {
        await aeroCache.initialize();

        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
        const url = 'https://example.com/only-if-cached-test.jpg';

        // First request to populate cache
        mockHttpClient.setResponse(url, testData, {
          'cache-control': 'max-age=10',
        });

        final result1 = await aeroCache.get(url);
        expect(result1, testData);
        expect(mockHttpClient.requestCount, 1);

        // Second request with only-if-cached should return cached content
        final result2 = await aeroCache.get(url, onlyIfCached: true);
        expect(result2, testData);
        expect(mockHttpClient.requestCount, 1); // No new network request

        // Third request with only-if-cached when no cache should fail
        const url2 = 'https://example.com/no-cache-available.jpg';
        expect(
          () => aeroCache.get(url2, onlyIfCached: true),
          throwsA(isA<AeroCacheException>()),
        );
      },
    );

    test(
      'should not store response when no-store request directive is used',
      () async {
        await aeroCache.initialize();

        const url = 'https://example.com/no-store-request-test.jpg';
        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

        // Set up response
        mockHttpClient.setResponse(url, testData, {
          'cache-control': 'max-age=3600',
        });

        // First request with no-store directive should not cache the response
        final result1 = await aeroCache.get(url, noStore: true);
        expect(result1, testData);

        // 2nd request should trigger a network call since no cache was stored
        final result2 = await aeroCache.get(url);
        expect(result2, testData);

        // Should make two requests since no-store prevented caching
        expect(mockHttpClient.requestCount, 2);
      },
    );

    test(
      'should cache different responses for same URL with Vary header',
      () async {
        await aeroCache.initialize();

        const url = 'https://example.com/api/content';
        final jsonData = Uint8List.fromList([1, 2, 3]);
        final xmlData = Uint8List.fromList([4, 5, 6]);

        // First request for JSON content
        mockHttpClient.setResponse(url, jsonData, {
          'vary': 'Accept',
          'cache-control': 'max-age=3600',
          'content-type': 'application/json',
        });

        final jsonResult = await aeroCache.get(
          url,
          headers: {'accept': 'application/json'},
        );
        expect(jsonResult, jsonData);
        expect(mockHttpClient.requestCount, 1);

        // Second request for XML content (should make new request due to Vary)
        mockHttpClient.setResponse(url, xmlData, {
          'vary': 'Accept',
          'cache-control': 'max-age=3600',
          'content-type': 'application/xml',
        });

        final xmlResult = await aeroCache.get(
          url,
          headers: {'accept': 'application/xml'},
        );
        expect(xmlResult, xmlData);
        expect(mockHttpClient.requestCount, 2);

        // Third request for JSON content should use cache
        final cachedJsonResult = await aeroCache.get(
          url,
          headers: {'accept': 'application/json'},
        );
        expect(cachedJsonResult, jsonData);
        expect(mockHttpClient.requestCount, 2); // No new request
      },
    );

    test('should not cache responses with Vary: * header', () async {
      await aeroCache.initialize();

      const url = 'https://example.com/vary-asterisk';
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);

      mockHttpClient.setResponse(url, testData, {
        'vary': '*',
        'cache-control': 'max-age=3600',
      });

      final result1 = await aeroCache.get(url);
      expect(result1, testData);
      expect(mockHttpClient.requestCount, 1);

      // Second request should not use cache due to Vary: *
      final result2 = await aeroCache.get(url);
      expect(result2, testData);
      expect(mockHttpClient.requestCount, 2);
    });
  });
}
