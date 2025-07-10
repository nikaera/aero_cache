import 'dart:io';

import 'package:aero_cache/src/cache_control_parser.dart';
import 'package:flutter_test/flutter_test.dart';

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
      final headers = _createMockHeaders({'cache-control': 'no-store'});
      expect(CacheControlParser.hasNoStore(headers), true);
    });
    
    test('should return false for no-store when not present', () {
      final headers = _createMockHeaders({'cache-control': 'max-age=3600'});
      expect(CacheControlParser.hasNoStore(headers), false);
    });
    
    test('should return false for no-store when no cache-control header', () {
      final headers = _createMockHeaders({});
      expect(CacheControlParser.hasNoStore(headers), false);
    });
    
    test('should detect no-cache directive', () {
      final headers = _createMockHeaders({'cache-control': 'no-cache'});
      expect(CacheControlParser.hasNoCache(headers), true);
    });
    
    test('should return false for no-cache when not present', () {
      final headers = _createMockHeaders({'cache-control': 'max-age=3600'});
      expect(CacheControlParser.hasNoCache(headers), false);
    });
    
    test('should return false for no-cache when no cache-control header', () {
      final headers = _createMockHeaders({});
      expect(CacheControlParser.hasNoCache(headers), false);
    });
    
    test('should detect must-revalidate directive', () {
      final headers = _createMockHeaders({'cache-control': 'must-revalidate'});
      expect(CacheControlParser.hasMustRevalidate(headers), true);
    });
    
    test('should return false for must-revalidate when not present', () {
      final headers = _createMockHeaders({'cache-control': 'max-age=3600'});
      expect(CacheControlParser.hasMustRevalidate(headers), false);
    });
    
    test('should return false for must-revalidate when no cache-control header',
        () {
      final headers = _createMockHeaders({});
      expect(CacheControlParser.hasMustRevalidate(headers), false);
    });
    
    test('should extract max-age value', () {
      final headers = _createMockHeaders({'cache-control': 'max-age=3600'});
      expect(CacheControlParser.getMaxAge(headers), 3600);
    });
    
    test('should extract max-age value from complex header', () {
      final headers = _createMockHeaders({
        'cache-control': 'no-cache, max-age=7200, must-revalidate'
      });
      expect(CacheControlParser.getMaxAge(headers), 7200);
    });
    
    test('should return null for max-age when not present', () {
      final headers = _createMockHeaders({'cache-control': 'no-cache'});
      expect(CacheControlParser.getMaxAge(headers), null);
    });
    
    test('should return null for max-age when no cache-control header', () {
      final headers = _createMockHeaders({});
      expect(CacheControlParser.getMaxAge(headers), null);
    });
    
    test('should return null for invalid max-age value', () {
      final headers = _createMockHeaders({'cache-control': 'max-age=invalid'});
      expect(CacheControlParser.getMaxAge(headers), null);
    });
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