import 'package:aero_cache/src/meta_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MetaInfo', () {
    late DateTime createdAt;
    late DateTime expiresAt;
    late MetaInfo metaInfo;

    setUp(() {
      createdAt = DateTime.now();
      expiresAt = createdAt.add(const Duration(hours: 1));
      metaInfo = MetaInfo(
        url: 'https://example.com/test.jpg',
        etag: '"abc123"',
        lastModified: 'Wed, 09 Jul 2025 12:00:00 GMT',
        createdAt: createdAt,
        expiresAt: expiresAt,
        contentLength: 1024,
      );
    });

    test('should create instance with all fields', () {
      expect(metaInfo.url, 'https://example.com/test.jpg');
      expect(metaInfo.etag, '"abc123"');
      expect(metaInfo.lastModified, 'Wed, 09 Jul 2025 12:00:00 GMT');
      expect(metaInfo.createdAt, createdAt);
      expect(metaInfo.expiresAt, expiresAt);
      expect(metaInfo.contentLength, 1024);
    });

    test('should detect stale cache', () {
      final pastTime = DateTime.now().subtract(const Duration(hours: 1));
      final staleMetaInfo = MetaInfo(
        url: 'https://example.com/test.jpg',
        createdAt: DateTime.now(),
        expiresAt: pastTime,
        contentLength: 1024,
      );
      expect(staleMetaInfo.isStale, true);
    });

    test('should detect fresh cache', () {
      final futureTime = DateTime.now().add(const Duration(hours: 1));
      final freshMetaInfo = MetaInfo(
        url: 'https://example.com/test.jpg',
        createdAt: DateTime.now(),
        expiresAt: futureTime,
        contentLength: 1024,
      );
      expect(freshMetaInfo.isStale, false);
    });

    test('should handle null expiresAt', () {
      final metaInfoNull = MetaInfo(
        url: 'https://example.com/test.jpg',
        createdAt: DateTime.now(),
        contentLength: 1024,
      );
      expect(metaInfoNull.isStale, false);
    });

    test('should store and retrieve stale-if-error value', () {
      final metaInfoWithStaleIfError = MetaInfo(
        url: 'https://example.com/test.jpg',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        contentLength: 1024,
        staleIfError: 600,
      );
      expect(metaInfoWithStaleIfError.staleIfError, 600);
    });

    test(
      'should serve stale on error within window',
      () {
        final pastTime = DateTime.now().subtract(const Duration(minutes: 5));
        final metaInfoStaleIfError = MetaInfo(
          url: 'https://example.com/test.jpg',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          expiresAt: pastTime,
          contentLength: 1024,
          staleIfError: 600, // 10 minutes window
        );
        expect(metaInfoStaleIfError.isStale, true);
        expect(metaInfoStaleIfError.canServeStaleOnError, true);
      },
    );

    test(
      'should not allow serving stale content on error when window expired',
      () {
        final pastTime = DateTime.now().subtract(const Duration(hours: 1));
        final metaInfoStaleIfError = MetaInfo(
          url: 'https://example.com/test.jpg',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          expiresAt: pastTime,
          contentLength: 1024,
          staleIfError: 600, // 10 minutes window (expired)
        );
        expect(metaInfoStaleIfError.isStale, true);
        expect(metaInfoStaleIfError.canServeStaleOnError, false);
      },
    );

    test('should serialize to JSON', () {
      final json = metaInfo.toJson();
      expect(json['url'], 'https://example.com/test.jpg');
      expect(json['etag'], '"abc123"');
      expect(json['lastModified'], 'Wed, 09 Jul 2025 12:00:00 GMT');
      expect(json['createdAt'], createdAt.millisecondsSinceEpoch);
      expect(json['expiresAt'], expiresAt.millisecondsSinceEpoch);
      expect(json['contentLength'], 1024);
    });

    test('should deserialize from JSON', () {
      final json = {
        'url': 'https://example.com/test.jpg',
        'etag': '"abc123"',
        'lastModified': 'Wed, 09 Jul 2025 12:00:00 GMT',
        'createdAt': createdAt.millisecondsSinceEpoch,
        'expiresAt': expiresAt.millisecondsSinceEpoch,
        'contentLength': 1024,
      };
      final meta = MetaInfo.fromJson(json);
      expect(meta.url, 'https://example.com/test.jpg');
      expect(meta.etag, '"abc123"');
      expect(meta.lastModified, 'Wed, 09 Jul 2025 12:00:00 GMT');
      expect(
        meta.createdAt.millisecondsSinceEpoch,
        createdAt.millisecondsSinceEpoch,
      );
      expect(
        meta.expiresAt?.millisecondsSinceEpoch,
        expiresAt.millisecondsSinceEpoch,
      );
      expect(meta.contentLength, 1024);
    });

    test('should handle null values in JSON', () {
      final now = DateTime.now();
      final json = {
        'url': 'https://example.com/test.jpg',
        'etag': null,
        'lastModified': null,
        'createdAt': now.millisecondsSinceEpoch,
        'expiresAt': null,
        'contentLength': 1024,
      };
      final meta = MetaInfo.fromJson(json);
      expect(meta.url, 'https://example.com/test.jpg');
      expect(meta.etag, null);
      expect(meta.lastModified, null);
      expect(meta.expiresAt, null);
    });

    test('should convert to and from JSON string', () {
      final jsonString = metaInfo.toJsonString();
      final restored = MetaInfo.fromJsonString(jsonString);
      expect(restored.url, metaInfo.url);
      expect(restored.etag, metaInfo.etag);
      expect(restored.lastModified, metaInfo.lastModified);
      expect(
        restored.createdAt.millisecondsSinceEpoch,
        metaInfo.createdAt.millisecondsSinceEpoch,
      );
      expect(
        restored.expiresAt?.millisecondsSinceEpoch,
        metaInfo.expiresAt?.millisecondsSinceEpoch,
      );
      expect(restored.contentLength, metaInfo.contentLength);
    });

    test('should handle requiresRevalidation field', () {
      final metaWithRevalidation = MetaInfo(
        url: 'https://example.com/test.jpg',
        createdAt: DateTime.now(),
        contentLength: 1024,
        requiresRevalidation: true,
      );
      expect(metaWithRevalidation.requiresRevalidation, true);

      final json = metaWithRevalidation.toJson();
      expect(json['requiresRevalidation'], true);

      final restored = MetaInfo.fromJson(json);
      expect(restored.requiresRevalidation, true);
    });

    test('should default requiresRevalidation to false', () {
      final metaWithoutRevalidation = MetaInfo(
        url: 'https://example.com/test.jpg',
        createdAt: DateTime.now(),
        contentLength: 1024,
      );
      expect(metaWithoutRevalidation.requiresRevalidation, false);

      final json = metaWithoutRevalidation.toJson();
      expect(json['requiresRevalidation'], false);
    });

    test('should handle missing requiresRevalidation in JSON', () {
      final json = {
        'url': 'https://example.com/test.jpg',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'contentLength': 1024,
      };
      final meta = MetaInfo.fromJson(json);
      expect(meta.requiresRevalidation, false);
    });

    test('isWithinStalePeriod returns true when within maxStale seconds after expiresAt', () {
      final now = DateTime.now();
      final expiresAt = now.subtract(const Duration(seconds: 30));
      final meta = MetaInfo(
        url: 'https://example.com/test.jpg',
        createdAt: now.subtract(const Duration(hours: 1)),
        expiresAt: expiresAt,
        contentLength: 1024,
      );
      // 30秒経過、maxStale=60ならtrue
      expect(meta.isWithinStalePeriod(60), isTrue);
    });
  });
}
