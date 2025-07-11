import 'dart:typed_data';

import 'package:aero_cache/src/cache_control_parser.dart';
import 'package:aero_cache/src/cache_url_hasher.dart';
import 'package:aero_cache/src/meta_info.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

/// Unit test to validate Vary header implementation logic
void main() {
  group('Vary header validation', () {
    test('validates Vary header parsing from HTTP headers', () {
      final headers = createMockHeaders({
        'vary': 'Accept-Encoding, User-Agent, Accept-Language',
      });

      final varyHeaders = CacheControlParser.getVaryHeaders(headers);

      expect(varyHeaders, hasLength(3));
      expect(varyHeaders, contains('Accept-Encoding'));
      expect(varyHeaders, contains('User-Agent'));
      expect(varyHeaders, contains('Accept-Language'));
    });

    test('validates Vary header parsing with whitespace', () {
      final headers = createMockHeaders({
        'vary': ' Accept-Encoding ,  User-Agent  , Accept-Language ',
      });

      final varyHeaders = CacheControlParser.getVaryHeaders(headers);

      expect(varyHeaders, hasLength(3));
      expect(varyHeaders, contains('Accept-Encoding'));
      expect(varyHeaders, contains('User-Agent'));
      expect(varyHeaders, contains('Accept-Language'));
    });

    test('validates Vary: * detection', () {
      final headers = createMockHeaders({'vary': '*'});

      final hasVaryAsterisk = CacheControlParser.hasVaryAsterisk(headers);

      expect(hasVaryAsterisk, true);
    });

    test('validates relevant request headers extraction', () {
      final requestHeaders = {
        'Accept-Encoding': 'gzip, deflate',
        'User-Agent': 'TestClient/1.0',
        'Accept-Language': 'en-US',
        'Authorization': 'Bearer token123',
        'Content-Type': 'application/json',
      };

      final varyHeaders = ['Accept-Encoding', 'User-Agent'];

      final relevantHeaders = CacheControlParser.getRelevantRequestHeaders(
        requestHeaders,
        varyHeaders,
      );

      expect(relevantHeaders, hasLength(2));
      expect(relevantHeaders['Accept-Encoding'], 'gzip, deflate');
      expect(relevantHeaders['User-Agent'], 'TestClient/1.0');
      expect(relevantHeaders, isNot(contains('Authorization')));
      expect(relevantHeaders, isNot(contains('Content-Type')));
    });

    test('validates case-insensitive header matching', () {
      final requestHeaders = {
        'accept-encoding': 'gzip',
        'USER-AGENT': 'TestClient/1.0',
        'Accept-Language': 'en-US',
      };

      final varyHeaders = ['Accept-Encoding', 'User-Agent'];

      final relevantHeaders = CacheControlParser.getRelevantRequestHeaders(
        requestHeaders,
        varyHeaders,
      );

      expect(relevantHeaders, hasLength(2));
      expect(relevantHeaders['accept-encoding'], 'gzip');
      expect(relevantHeaders['USER-AGENT'], 'TestClient/1.0');
    });

    test('validates Vary-aware URL hash generation', () {
      const url = 'https://example.com/api/data';
      final requestHeaders = {
        'Accept-Encoding': 'gzip',
        'User-Agent': 'TestClient/1.0',
      };
      final varyHeaders = ['Accept-Encoding', 'User-Agent'];

      final hash1 = CacheUrlHasher.getVaryAwareUrlHash(
        url,
        requestHeaders,
        varyHeaders,
      );

      // Same headers should produce same hash
      final hash2 = CacheUrlHasher.getVaryAwareUrlHash(
        url,
        requestHeaders,
        varyHeaders,
      );

      expect(hash1, equals(hash2));
      expect(hash1, isNotEmpty);
      expect(hash1.length, 64); // SHA256 hex string length
    });

    test('validates different headers produce different hashes', () {
      const url = 'https://example.com/api/data';
      final requestHeaders1 = {
        'Accept-Encoding': 'gzip',
        'User-Agent': 'TestClient/1.0',
      };
      final requestHeaders2 = {
        'Accept-Encoding': 'deflate',
        'User-Agent': 'TestClient/1.0',
      };
      final varyHeaders = ['Accept-Encoding', 'User-Agent'];

      final hash1 = CacheUrlHasher.getVaryAwareUrlHash(
        url,
        requestHeaders1,
        varyHeaders,
      );
      final hash2 = CacheUrlHasher.getVaryAwareUrlHash(
        url,
        requestHeaders2,
        varyHeaders,
      );

      expect(hash1, isNot(equals(hash2)));
    });

    test('validates header order independence', () {
      const url = 'https://example.com/api/data';
      final requestHeaders = {
        'Accept-Encoding': 'gzip',
        'User-Agent': 'TestClient/1.0',
      };

      // Different order of vary headers
      final varyHeaders1 = ['Accept-Encoding', 'User-Agent'];
      final varyHeaders2 = ['User-Agent', 'Accept-Encoding'];

      final hash1 = CacheUrlHasher.getVaryAwareUrlHash(
        url,
        requestHeaders,
        varyHeaders1,
      );
      final hash2 = CacheUrlHasher.getVaryAwareUrlHash(
        url,
        requestHeaders,
        varyHeaders2,
      );

      expect(hash1, equals(hash2));
    });

    test('validates MetaInfo stores Vary headers correctly', () {
      final varyHeaders = ['Accept-Encoding', 'User-Agent'];

      final metaInfo = MetaInfo(
        url: 'https://example.com/test',
        etag: 'test-etag',
        lastModified: 'Wed, 21 Oct 2015 07:28:00 GMT',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        contentLength: 1024,
        contentType: 'application/json',
        varyHeaders: varyHeaders,
      );

      expect(metaInfo.varyHeaders, isNotNull);
      expect(metaInfo.varyHeaders, hasLength(2));
      expect(metaInfo.varyHeaders, contains('Accept-Encoding'));
      expect(metaInfo.varyHeaders, contains('User-Agent'));
    });

    test('validates empty Vary headers handling', () {
      final headers = createMockHeaders({});
      // No Vary header set

      final varyHeaders = CacheControlParser.getVaryHeaders(headers);

      expect(varyHeaders, isEmpty);
    });

    test('validates missing request headers handling', () {
      final requestHeaders = <String, String>{
        'User-Agent': 'TestClient/1.0',
      };

      final varyHeaders = ['Accept-Encoding', 'User-Agent'];

      final relevantHeaders = CacheControlParser.getRelevantRequestHeaders(
        requestHeaders,
        varyHeaders,
      );

      // Should only include headers that exist in request
      expect(relevantHeaders, hasLength(1));
      expect(relevantHeaders['User-Agent'], 'TestClient/1.0');
      expect(relevantHeaders, isNot(contains('Accept-Encoding')));
    });

    test('validates CacheManager with custom cache directory', () async {
      final tempDir = await TestSetupHelper.createTempDirectory();

      try {
        final cacheManager = await TestSetupHelper.createCacheManager(
          tempDir.path,
        );

        await cacheManager.initialize();

        // Test saving with Vary headers
        const url = 'https://example.com/test';
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        final headers = createMockHeaders({
          'vary': 'Accept-Encoding',
          'cache-control': 'max-age=3600',
        });

        await cacheManager.saveData(url, data, headers);

        // Verify metadata contains Vary headers
        final meta = await cacheManager.getMeta(url);
        expect(meta, isNotNull);
        expect(meta!.varyHeaders, isNotNull);
        expect(meta.varyHeaders, contains('Accept-Encoding'));

        // Test data retrieval
        final retrievedData = await cacheManager.getData(url);
        expect(retrievedData, equals(data));
      } finally {
        // Clean up
        await tempDir.delete(recursive: true);
      }
    });
  });
}
