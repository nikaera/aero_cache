import 'package:aero_cache/src/cache_url_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CacheUrlHasher', () {
    test('should generate consistent hash for same URL', () {
      const url = 'https://example.com/api/data';
      final hash1 = CacheUrlHasher.getUrlHash(url);
      final hash2 = CacheUrlHasher.getUrlHash(url);
      
      expect(hash1, hash2);
      expect(hash1, isNotEmpty);
    });

    test('should generate different hash for different URLs', () {
      const url1 = 'https://example.com/api/data';
      const url2 = 'https://example.com/api/other';
      final hash1 = CacheUrlHasher.getUrlHash(url1);
      final hash2 = CacheUrlHasher.getUrlHash(url2);
      
      expect(hash1, isNot(hash2));
    });

    test('should generate vary-aware cache key with request headers', () {
      const url = 'https://example.com/api/data';
      final requestHeaders = {
        'accept': 'application/json',
        'accept-encoding': 'gzip',
        'user-agent': 'TestAgent/1.0',
      };
      final varyHeaders = ['Accept', 'Accept-Encoding'];
      
      final hash = CacheUrlHasher.getVaryAwareUrlHash(
        url,
        requestHeaders,
        varyHeaders,
      );
      
      expect(hash, isNotEmpty);
      expect(hash, isNot(CacheUrlHasher.getUrlHash(url)));
    });

    test('should generate same hash for same URL and headers', () {
      const url = 'https://example.com/api/data';
      final requestHeaders = {
        'accept': 'application/json',
        'accept-encoding': 'gzip',
      };
      final varyHeaders = ['Accept', 'Accept-Encoding'];
      
      final hash1 = CacheUrlHasher.getVaryAwareUrlHash(
        url,
        requestHeaders,
        varyHeaders,
      );
      final hash2 = CacheUrlHasher.getVaryAwareUrlHash(
        url,
        requestHeaders,
        varyHeaders,
      );
      
      expect(hash1, hash2);
    });

    test('should generate different hash for different header values', () {
      const url = 'https://example.com/api/data';
      final requestHeaders1 = {
        'accept': 'application/json',
        'accept-encoding': 'gzip',
      };
      final requestHeaders2 = {
        'accept': 'text/html',
        'accept-encoding': 'gzip',
      };
      final varyHeaders = ['Accept', 'Accept-Encoding'];
      
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
      
      expect(hash1, isNot(hash2));
    });

    test('should ignore headers not specified in Vary', () {
      const url = 'https://example.com/api/data';
      final requestHeaders1 = {
        'accept': 'application/json',
        'user-agent': 'TestAgent/1.0',
        'cookie': 'session=abc123',
      };
      final requestHeaders2 = {
        'accept': 'application/json',
        'user-agent': 'TestAgent/1.0',
        'cookie': 'session=xyz789',
      };
      final varyHeaders = ['Accept', 'User-Agent'];
      
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
      
      expect(hash1, hash2);
    });
  });
}