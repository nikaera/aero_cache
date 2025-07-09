import 'dart:io' as io;
import 'dart:typed_data';

import 'package:aero_cache/aero_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AeroCache Integration Tests', () {
    late AeroCache aeroCache;
    late io.Directory tempDir;

    setUp(() async {
      tempDir = await io.Directory.systemTemp.createTemp(
        'aero_cache_integration_test',
      );
      aeroCache = AeroCache(
        cacheDirPath: tempDir.path,
        disableCompression: true,
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

      const url = 'https://httpbin.org/bytes/16';
      final result = await aeroCache.get(url);
      expect(result, isA<Uint8List>());
      expect(result.length, 16);
    });

    test('should return cached data on subsequent requests', () async {
      await aeroCache.initialize();

      const url = 'https://httpbin.org/bytes/32';
      final result1 = await aeroCache.get(url);
      final result2 = await aeroCache.get(url);

      expect(result1, isA<Uint8List>());
      expect(result2, isA<Uint8List>());
      expect(result2, result1);
    });

    test('should handle cache revalidation', () async {
      await aeroCache.initialize();

      const url = 'https://httpbin.org/cache/0';
      final data1 = await aeroCache.get(url);
      final data2 = await aeroCache.get(url);

      expect(data1, isA<Uint8List>());
      expect(data2, isA<Uint8List>());
    });

    test('should call progress callback', () async {
      await aeroCache.initialize();

      const url = 'https://httpbin.org/bytes/1000';
      final progressCalls = <Map<String, int>>[];

      await aeroCache.get(
        url,
        onProgress: (received, total) {
          progressCalls.add({'received': received, 'total': total});
        },
      );

      expect(progressCalls.isNotEmpty, true);
      expect(progressCalls.last['received'], 1000);
      expect(progressCalls.last['total'], 1000);
    });

    test('should handle HTTP errors', () async {
      await aeroCache.initialize();

      const url = 'https://httpbin.org/status/404';

      expect(
        () => aeroCache.get(url),
        throwsA(isA<AeroCacheException>()),
      );
    });

    test('should handle different content types', () async {
      await aeroCache.initialize();

      const urls = [
        'https://httpbin.org/json',
        'https://httpbin.org/html',
        'https://httpbin.org/xml',
      ];

      for (final url in urls) {
        final data = await aeroCache.get(url);
        expect(data, isA<Uint8List>());
        expect(data.isNotEmpty, true);
      }
    });
  });
}
