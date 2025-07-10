import 'dart:io';
import 'dart:typed_data';

import 'package:aero_cache/src/cache_control_parser.dart';
import 'package:aero_cache/src/cache_manager.dart';
import 'package:aero_cache/src/exceptions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CacheManager', () {
    late CacheManager cacheManager;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('aero_cache_test');
      cacheManager = CacheManager(
        cacheDirPath: tempDir.path,
        disableCompression: true,
      );
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should initialize cache directory', () async {
      await cacheManager.initialize();
      expect(cacheManager, isNotNull);
    });

    test('should return null for non-existent meta', () async {
      await cacheManager.initialize();
      final meta = await cacheManager.getMeta('https://example.com/test.jpg');
      expect(meta, null);
    });

    test('should save and retrieve meta information', () async {
      await cacheManager.initialize();
      const url = 'https://example.com/test.jpg';
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final headers = _createMockHeaders({
        'etag': '"abc123"',
        'last-modified': 'Wed, 09 Jul 2025 12:00:00 GMT',
        'cache-control': 'max-age=3600',
      });
      await cacheManager.saveData(url, testData, headers);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final meta = await cacheManager.getMeta(url);
      expect(meta, isNotNull);
      expect(meta!.url, url);
      expect(meta.etag, '"abc123"');
      expect(meta.lastModified, 'Wed, 09 Jul 2025 12:00:00 GMT');
      expect(meta.contentLength, testData.length);
    });

    test('should save and retrieve cache data', () async {
      await cacheManager.initialize();
      const url = 'https://example.com/test.jpg';
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final headers = _createMockHeaders({});
      await cacheManager.saveData(url, testData, headers);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final retrievedData = await cacheManager.getData(url);
      expect(retrievedData, testData);
    });

    test('should throw exception for non-existent cache data', () async {
      await cacheManager.initialize();
      const url = 'https://example.com/nonexistent.jpg';
      expect(
        () => cacheManager.getData(url),
        throwsA(isA<AeroCacheException>()),
      );
    });

    test('should handle cache-control max-age', () async {
      await cacheManager.initialize();
      const url = 'https://example.com/test.jpg';
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final headers = _createMockHeaders({
        'cache-control': 'max-age=3600',
      });
      await cacheManager.saveData(url, testData, headers);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final meta = await cacheManager.getMeta(url);
      expect(meta, isNotNull);
      expect(meta!.expiresAt, isNotNull);
      expect(meta.expiresAt!.isAfter(DateTime.now()), true);
    });

    test('should handle expires header', () async {
      await cacheManager.initialize();
      const url = 'https://example.com/test.jpg';
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final futureDate = DateTime.now().add(const Duration(hours: 2));
      final headers = _createMockHeaders({
        'expires': HttpDate.format(futureDate),
      });
      await cacheManager.saveData(url, testData, headers);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final meta = await cacheManager.getMeta(url);
      expect(meta, isNotNull);
      expect(meta!.expiresAt, isNotNull);
      expect(meta.expiresAt!.day, futureDate.day);
      expect(meta.expiresAt!.hour, futureDate.hour);
    });

    test('should use default expiration when no cache headers', () async {
      await cacheManager.initialize();
      const url = 'https://example.com/test.jpg';
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final headers = _createMockHeaders({});
      await cacheManager.saveData(url, testData, headers);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final meta = await cacheManager.getMeta(url);
      expect(meta, isNotNull);
      expect(meta!.expiresAt, isNotNull);
      expect(meta.expiresAt!.isAfter(DateTime.now()), true);
    });

    test('should clear all cache files and meta files', () async {
      await cacheManager.initialize();
      const url1 = 'https://example.com/test1.jpg';
      const url2 = 'https://example.com/test2.jpg';
      final testData = Uint8List.fromList([1, 2, 3]);
      final headers = _createMockHeaders({});
      await cacheManager.saveData(url1, testData, headers);
      await cacheManager.saveData(url2, testData, headers);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final cacheDir = Directory('${tempDir.path}/aero_cache');
      expect(cacheDir.existsSync(), true);
      expect((await cacheDir.list().toList()).isNotEmpty, true);
      await cacheManager.clearAllCache();
      expect((await cacheDir.list().toList()).isEmpty, true);
    });

    test('should clear only expired cache and meta files', () async {
      await cacheManager.initialize();
      const url1 = 'https://example.com/expired.jpg';
      const url2 = 'https://example.com/valid.jpg';
      final testData = Uint8List.fromList([1, 2, 3]);
      // 期限切れ（過去日時）
      final expiredHeaders = _createMockHeaders({
        'cache-control': 'max-age=0',
      });
      // 有効期限（未来日時）
      final validHeaders = _createMockHeaders({
        'cache-control': 'max-age=3600',
      });
      await cacheManager.saveData(url1, testData, expiredHeaders);
      await cacheManager.saveData(url2, testData, validHeaders);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final cacheDir = Directory('${tempDir.path}/aero_cache');
      final beforeFiles = await cacheDir.list().toList();
      // 2url x 2ファイル
      expect(beforeFiles.whereType<File>().length >= 4, true);
      await cacheManager.clearExpiredCache();
      final afterFiles = await cacheDir.list().toList();
      // url2(有効)のファイルは残る
      final validMeta = afterFiles
          .where((f) => f.path.endsWith('.meta'))
          .toList();
      final validCache = afterFiles
          .where((f) => f.path.endsWith('.cache'))
          .toList();
      expect(validMeta.length, 1);
      expect(validCache.length, 1);
      // 厳密なファイル名チェックは省略（残数で判定）
    });

    test('should handle no-cache directive requiring revalidation', () async {
      await cacheManager.initialize();
      const url = 'https://example.com/no-cache-test.jpg';
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final headers = _createMockHeaders({
        'cache-control': 'no-cache',
      });
      await cacheManager.saveData(url, testData, headers);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final meta = await cacheManager.getMeta(url);
      expect(meta, isNotNull);
      expect(meta!.requiresRevalidation, true);
    });

    test('should not cache data with no-store directive', () async {
      await cacheManager.initialize();
      final headers = _createMockHeaders({
        'cache-control': 'no-store',
      });
      final noStore = CacheControlParser.hasNoStore(headers);
      expect(noStore, true);
    });

    test(
      'should allow caching when no-store directive is not present',
      () async {
        await cacheManager.initialize();
        final headers = _createMockHeaders({
          'cache-control': 'max-age=3600',
        });
        final noStore = CacheControlParser.hasNoStore(headers);
        expect(noStore, false);
      },
    );

    test(
      'should allow caching when no cache-control header is present',
      () async {
        await cacheManager.initialize();
        final headers = _createMockHeaders({});
        final noStore = CacheControlParser.hasNoStore(headers);
        expect(noStore, false);
      },
    );

    test('should identify must-revalidate directive', () async {
      await cacheManager.initialize();
      final headers = _createMockHeaders({
        'cache-control': 'must-revalidate',
      });
      final mustRevalidate = CacheControlParser.hasMustRevalidate(headers);
      expect(mustRevalidate, true);
    });

    test('should return false for non-must-revalidate responses', () async {
      await cacheManager.initialize();
      final headers = _createMockHeaders({
        'cache-control': 'max-age=3600',
      });
      final mustRevalidate = CacheControlParser.hasMustRevalidate(headers);
      expect(mustRevalidate, false);
    });

    test(
      'should return false when no cache-control for must-revalidate check',
      () async {
        await cacheManager.initialize();
        final headers = _createMockHeaders({});
        final mustRevalidate = CacheControlParser.hasMustRevalidate(headers);
        expect(mustRevalidate, false);
      },
    );

    test('should identify stale-while-revalidate directive', () async {
      await cacheManager.initialize();
      final headers = _createMockHeaders({
        'cache-control': 'stale-while-revalidate=300',
      });
      final hasStaleWhileRevalidate =
          CacheControlParser.hasStaleWhileRevalidate(headers);
      expect(hasStaleWhileRevalidate, true);
    });

    test(
      'should return false for non-stale-while-revalidate responses',
      () async {
        await cacheManager.initialize();
        final headers = _createMockHeaders({
          'cache-control': 'max-age=3600',
        });
        final hasStaleWhileRevalidate =
            CacheControlParser.hasStaleWhileRevalidate(headers);
        expect(hasStaleWhileRevalidate, false);
      },
    );

    test('should extract stale-while-revalidate value', () async {
      await cacheManager.initialize();
      final headers = _createMockHeaders({
        'cache-control': 'max-age=3600, stale-while-revalidate=300',
      });
      final staleWhileRevalidateValue =
          CacheControlParser.getStaleWhileRevalidate(headers);
      expect(staleWhileRevalidateValue, 300);
    });

    test(
      'should return null when stale-while-revalidate is not present',
      () async {
        await cacheManager.initialize();
        final headers = _createMockHeaders({
          'cache-control': 'max-age=3600',
        });
        final staleWhileRevalidateValue =
            CacheControlParser.getStaleWhileRevalidate(headers);
        expect(staleWhileRevalidateValue, null);
      },
    );

    test('should store stale-while-revalidate value in MetaInfo', () async {
      await cacheManager.initialize();
      const url = 'https://example.com/test.jpg';
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final headers = _createMockHeaders({
        'cache-control': 'max-age=3600, stale-while-revalidate=300',
      });
      await cacheManager.saveData(url, testData, headers);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final meta = await cacheManager.getMeta(url);
      expect(meta, isNotNull);
      expect(meta!.staleWhileRevalidate, 300);
    });

    test(
      'should allow serving stale content within stale-while-revalidate window',
      () async {
        await cacheManager.initialize();
        const url = 'https://example.com/test.jpg';
        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
        // Create an entry that will be stale but within
        // stale-while-revalidate window
        final headers = _createMockHeaders({
          'cache-control': 'max-age=0, stale-while-revalidate=300',
        });
        await cacheManager.saveData(url, testData, headers);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        final meta = await cacheManager.getMeta(url);
        expect(meta, isNotNull);
        expect(meta!.isStale, true);
        expect(meta.canServeStale, true);
      },
    );

    test(
      'should provide method to get stale data when revalidation needed',
      () async {
        await cacheManager.initialize();
        const url = 'https://example.com/test.jpg';
        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final headers = _createMockHeaders({
          'cache-control': 'max-age=0, stale-while-revalidate=300',
        });
        await cacheManager.saveData(url, testData, headers);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final staleData = await cacheManager.getStaleData(url);
        expect(staleData, isNotNull);
        expect(staleData, testData);
      },
    );

    test(
      'should identify cache entries needing background revalidation',
      () async {
        await cacheManager.initialize();
        const url = 'https://example.com/test.jpg';
        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final headers = _createMockHeaders({
          'cache-control': 'max-age=0, stale-while-revalidate=300',
        });
        await cacheManager.saveData(url, testData, headers);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final needsRevalidation = await cacheManager
            .needsBackgroundRevalidation(url);
        expect(needsRevalidation, true);
      },
    );

    test('should store stale-if-error value in MetaInfo', () async {
      await cacheManager.initialize();
      const url = 'https://example.com/test.jpg';
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final headers = _createMockHeaders({
        'cache-control': 'max-age=3600, stale-if-error=600',
      });
      await cacheManager.saveData(url, testData, headers);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final meta = await cacheManager.getMeta(url);
      expect(meta, isNotNull);
      expect(meta!.staleIfError, 600);
    });

    test(
      'should serve stale content on error within stale-if-error window',
      () async {
        await cacheManager.initialize();
        const url = 'https://example.com/test.jpg';
        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
        // Create an entry that will be stale but within stale-if-error window
        final headers = _createMockHeaders({
          'cache-control': 'max-age=0, stale-if-error=600',
        });
        await cacheManager.saveData(url, testData, headers);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        final meta = await cacheManager.getMeta(url);
        expect(meta, isNotNull);
        expect(meta!.isStale, true);
        expect(meta.canServeStaleOnError, true);
      },
    );

    test(
      'should get stale data on error if revalidation fails',
      () async {
        await cacheManager.initialize();
        const url = 'https://example.com/test.jpg';
        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final headers = _createMockHeaders({
          'cache-control': 'max-age=0, stale-if-error=600',
        });
        await cacheManager.saveData(url, testData, headers);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final staleData = await cacheManager.getStaleDataOnError(url);
        expect(staleData, isNotNull);
        expect(staleData, testData);
      },
    );

    test(
      'should identify cache entries that can serve stale on error',
      () async {
        await cacheManager.initialize();
        const url = 'https://example.com/test.jpg';
        final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final headers = _createMockHeaders({
          'cache-control': 'max-age=0, stale-if-error=600',
        });
        await cacheManager.saveData(url, testData, headers);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final canServeStaleOnError = await cacheManager.canServeStaleOnError(
          url,
        );
        expect(canServeStaleOnError, true);
      },
    );
  });
}

HttpHeaders _createMockHeaders(Map<String, String> headers) {
  final request = MockHttpClientRequest();
  headers.forEach(request.headers.add);
  return request.headers;
}

class MockHttpClientRequest {
  final HttpHeaders headers = _MockHttpHeaders();
}

class _MockHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = {};
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers.putIfAbsent(name.toLowerCase(), () => []).add(value.toString());
  }

  @override
  String? value(String name) {
    final values = _headers[name.toLowerCase()];
    return values?.isNotEmpty ?? false ? values!.first : null;
  }

  @override
  List<String>? operator [](String name) {
    return _headers[name.toLowerCase()];
  }

  @override
  void clear() => _headers.clear();
  @override
  bool get chunkedTransferEncoding => false;
  @override
  set chunkedTransferEncoding(bool value) {}
  @override
  int get contentLength => -1;
  @override
  set contentLength(int value) {}
  @override
  ContentType? get contentType => null;
  @override
  set contentType(ContentType? value) {}
  @override
  DateTime? get date => null;
  @override
  set date(DateTime? value) {}
  @override
  DateTime? get expires => null;
  @override
  set expires(DateTime? value) {}
  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach(action);
  }

  @override
  String? get host => null;
  @override
  set host(String? value) {}
  @override
  DateTime? get ifModifiedSince => null;
  @override
  set ifModifiedSince(DateTime? value) {}
  @override
  bool get persistentConnection => false;
  @override
  set persistentConnection(bool value) {}
  @override
  int? get port => null;
  @override
  set port(int? value) {}
  @override
  void remove(String name, Object value) {
    _headers[name.toLowerCase()]?.remove(value.toString());
  }

  @override
  void removeAll(String name) {
    _headers.remove(name.toLowerCase());
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers[name.toLowerCase()] = [value.toString()];
  }

  @override
  void noFolding(String name) {
    // no-op for test mock
  }
}
