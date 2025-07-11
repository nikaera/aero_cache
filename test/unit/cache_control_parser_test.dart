import 'package:aero_cache/src/cache_control_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_utils.dart';

void main() {
  group('CacheControlParser', () {
    test('should parse cache-control header with multiple directives', () {
      const cacheControlValue = 'no-cache, max-age=3600, must-revalidate';
      final directives = CacheControlParser.parse(cacheControlValue);

      expect(directives['no-cache'], null);
      expect(directives['max-age'], '3600');
      expect(directives['must-revalidate'], null);
    });

    test('should parse cache-control header with whitespace', () {
      const cacheControlValue = ' no-store , max-age = 7200 , public ';
      final directives = CacheControlParser.parse(cacheControlValue);

      expect(directives['no-store'], null);
      expect(directives['max-age'], '7200');
      expect(directives['public'], null);
    });

    test('should return empty map for null cache-control', () {
      final directives = CacheControlParser.parse(null);
      expect(directives, isEmpty);
    });

    test('should return empty map for empty cache-control', () {
      final directives = CacheControlParser.parse('');
      expect(directives, isEmpty);
    });

    test('should detect no-store directive', () {
      final headers = createMockHeaders({'cache-control': 'no-store'});
      expect(CacheControlParser.hasNoStore(headers), true);
    });

    test('should return false for no-store when not present', () {
      final headers = createMockHeaders({'cache-control': 'max-age=3600'});
      expect(CacheControlParser.hasNoStore(headers), false);
    });

    test('should return false for no-store when no cache-control header', () {
      final headers = createMockHeaders({});
      expect(CacheControlParser.hasNoStore(headers), false);
    });

    test('should detect no-cache directive', () {
      final headers = createMockHeaders({'cache-control': 'no-cache'});
      expect(CacheControlParser.hasNoCache(headers), true);
    });

    test('should return false for no-cache when not present', () {
      final headers = createMockHeaders({'cache-control': 'max-age=3600'});
      expect(CacheControlParser.hasNoCache(headers), false);
    });

    test('should return false for no-cache when no cache-control header', () {
      final headers = createMockHeaders({});
      expect(CacheControlParser.hasNoCache(headers), false);
    });

    test('should detect must-revalidate directive', () {
      final headers = createMockHeaders({'cache-control': 'must-revalidate'});
      expect(CacheControlParser.hasMustRevalidate(headers), true);
    });

    test('should return false for must-revalidate when not present', () {
      final headers = createMockHeaders({'cache-control': 'max-age=3600'});
      expect(CacheControlParser.hasMustRevalidate(headers), false);
    });

    test(
      'should return false for must-revalidate when no cache-control header',
      () {
        final headers = createMockHeaders({});
        expect(CacheControlParser.hasMustRevalidate(headers), false);
      },
    );

    test('should extract max-age value', () {
      final headers = createMockHeaders({'cache-control': 'max-age=3600'});
      expect(CacheControlParser.getMaxAge(headers), 3600);
    });

    test('should extract max-age value from complex header', () {
      final headers = createMockHeaders({
        'cache-control': 'no-cache, max-age=7200, must-revalidate',
      });
      expect(CacheControlParser.getMaxAge(headers), 7200);
    });

    test('should return null for max-age when not present', () {
      final headers = createMockHeaders({'cache-control': 'no-cache'});
      expect(CacheControlParser.getMaxAge(headers), null);
    });

    test('should return null for max-age when no cache-control header', () {
      final headers = createMockHeaders({});
      expect(CacheControlParser.getMaxAge(headers), null);
    });

    test('should return null for invalid max-age value', () {
      final headers = createMockHeaders({'cache-control': 'max-age=invalid'});
      expect(CacheControlParser.getMaxAge(headers), null);
    });

    test('should detect stale-if-error directive', () {
      final headers = createMockHeaders({'cache-control': 'stale-if-error'});
      expect(CacheControlParser.hasStaleIfError(headers), true);
    });

    test('should return false for stale-if-error when not present', () {
      final headers = createMockHeaders({'cache-control': 'max-age=3600'});
      expect(CacheControlParser.hasStaleIfError(headers), false);
    });

    test(
      'should return false for stale-if-error when no cache-control header',
      () {
        final headers = createMockHeaders({});
        expect(CacheControlParser.hasStaleIfError(headers), false);
      },
    );

    test('should extract stale-if-error value', () {
      final headers = createMockHeaders({
        'cache-control': 'stale-if-error=600',
      });
      expect(CacheControlParser.getStaleIfError(headers), 600);
    });

    test('should return null for stale-if-error when not present', () {
      final headers = createMockHeaders({'cache-control': 'no-cache'});
      expect(CacheControlParser.getStaleIfError(headers), null);
    });

    test(
      'should return null for stale-if-error when no cache-control header',
      () {
        final headers = createMockHeaders({});
        expect(CacheControlParser.getStaleIfError(headers), null);
      },
    );

    test('should return null for invalid stale-if-error value', () {
      final headers = createMockHeaders({
        'cache-control': 'stale-if-error=invalid',
      });
      expect(CacheControlParser.getStaleIfError(headers), null);
    });

    test('should extract vary header values', () {
      final headers = createMockHeaders({
        'vary': 'Accept-Encoding, User-Agent',
      });
      expect(
        CacheControlParser.getVaryHeaders(headers),
        ['Accept-Encoding', 'User-Agent'],
      );
    });

    test('should return empty list when no vary header', () {
      final headers = createMockHeaders({});
      expect(CacheControlParser.getVaryHeaders(headers), isEmpty);
    });

    test('should handle single vary header value', () {
      final headers = createMockHeaders({
        'vary': 'Accept-Encoding',
      });
      expect(
        CacheControlParser.getVaryHeaders(headers),
        ['Accept-Encoding'],
      );
    });

    test('should handle vary header with asterisk', () {
      final headers = createMockHeaders({
        'vary': '*',
      });
      expect(CacheControlParser.getVaryHeaders(headers), ['*']);
    });

    test('should detect Vary: * header as uncacheable', () {
      final headers = createMockHeaders({
        'vary': '*',
      });
      expect(CacheControlParser.hasVaryAsterisk(headers), true);
    });

    test('should not detect regular Vary headers as asterisk', () {
      final headers = createMockHeaders({
        'vary': 'Accept, User-Agent',
      });
      expect(CacheControlParser.hasVaryAsterisk(headers), false);
    });

    test('should return false when no Vary header present', () {
      final headers = createMockHeaders({});
      expect(CacheControlParser.hasVaryAsterisk(headers), false);
    });

    test('should handle directive priorities - no-store overrides max-age', () {
      final headers = createMockHeaders({
        'cache-control': 'no-store, max-age=3600',
      });
      expect(CacheControlParser.hasNoStore(headers), true);
      expect(CacheControlParser.getMaxAge(headers), null);
    });

    test('should handle invalid directive values gracefully', () {
      const cacheControlValue = 'max-age=invalid, no-cache, stale-if-error=-1';
      final directives = CacheControlParser.parse(cacheControlValue);

      expect(directives['max-age'], 'invalid');
      expect(directives['no-cache'], null);
      expect(directives['stale-if-error'], '-1');

      // Methods should return null for invalid values
      final headers = createMockHeaders({
        'cache-control': cacheControlValue,
      });
      expect(CacheControlParser.getMaxAge(headers), null);
      expect(CacheControlParser.getStaleIfError(headers), null);
    });

    test('should handle malformed directive syntax gracefully', () {
      const cacheControlValue = 'max-age=, =3600, , malformed=value=extra';
      final directives = CacheControlParser.parse(cacheControlValue);

      expect(directives['max-age'], '');
      expect(directives.containsKey(''), false); // Empty key filtered out
      expect(directives['malformed'], 'value=extra');

      // Should not crash and should handle gracefully
      final headers = createMockHeaders({
        'cache-control': cacheControlValue,
      });
      expect(CacheControlParser.getMaxAge(headers), null);
      expect(CacheControlParser.hasNoStore(headers), false);
    });

    test('should ignore empty directive names and values', () {
      const cacheControlValue = 'max-age=, =3600, , ';
      final directives = CacheControlParser.parse(cacheControlValue);

      // Empty directive names should be filtered out
      expect(directives.containsKey(''), false);
      // max-age with empty value should still be included
      expect(directives.containsKey('max-age'), true);
      expect(directives['max-age'], '');
      expect(directives.length, 1);
    });

    test('should identify request headers that may affect cache key', () {
      final requestHeaders = {
        'accept': 'application/json',
        'accept-encoding': 'gzip, deflate',
        'accept-language': 'en-US,en;q=0.9',
        'user-agent': 'TestAgent/1.0',
        'authorization': 'Bearer token123',
        'cookie': 'session=abc123',
        'referer': 'https://example.com',
        'host': 'api.example.com',
        'x-custom-header': 'custom-value',
      };

      final varyHeaders = ['Accept', 'Accept-Encoding', 'User-Agent'];

      // Identify relevant request headers for cache key calculation
      final relevantHeaders = CacheControlParser.getRelevantRequestHeaders(
        requestHeaders,
        varyHeaders,
      );

      expect(relevantHeaders, {
        'accept': 'application/json',
        'accept-encoding': 'gzip, deflate',
        'user-agent': 'TestAgent/1.0',
      });
    });
  });
}
