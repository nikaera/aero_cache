import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aero_cache/aero_cache.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class FakePathProviderPlatform extends PathProviderPlatform {
  Directory? _tempDir;

  @override
  Future<String?> getApplicationSupportPath() async {
    _tempDir ??= await Directory.systemTemp.createTemp('aero_cache_test');
    return _tempDir!.path;
  }

  // 必要に応じて他のメソッドもオーバーライド
}

void main() {
  setUpAll(() {
    PathProviderPlatform.instance = FakePathProviderPlatform();
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('AeroCache', () {
    late AeroCache aeroCache;
    late MockHttpClient mockHttpClient;
    late Directory tempDir;

    setUp(() async {
      mockHttpClient = MockHttpClient();
      tempDir = await Directory.systemTemp.createTemp('aero_cache_test');
      aeroCache = AeroCache(
        httpClient: mockHttpClient,
        disableCompression: true,
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

      // Request with min-fresh=3 should require fresh cache for at least 3 more seconds
      // Since cache only has 2 seconds left, should make new request
      mockHttpClient.setResponse(url, testData, {
        'cache-control': 'max-age=10',
      });

      final result2 = await aeroCache.get(
        url,
        minFresh: 3, // Require cache to be fresh for at least 3 more seconds
      );

      expect(result2, testData);
      // Should make two requests since cached content doesn't meet min-fresh requirement
      expect(mockHttpClient.requestCount, 2);
    });
  });
}

class MockHttpClient implements HttpClient {
  final Map<String, MockHttpClientResponse> _responses = {};
  int requestCount = 0;

  void setResponse(String url, Uint8List data, Map<String, String> headers) {
    _responses[url] = MockHttpClientResponse(data, 200, headers);
  }

  void setNotModifiedResponse(String url) {
    _responses[url] = MockHttpClientResponse(Uint8List(0), 304, {});
  }

  void setErrorResponse(String url, int statusCode) {
    _responses[url] = MockHttpClientResponse(Uint8List(0), statusCode, {});
  }

  void setNetworkError(String url) {
    _responses[url] = MockHttpClientResponse(null, 0, {});
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    requestCount++;
    final response = _responses[url.toString()];
    if (response == null) {
      throw const SocketException('Connection failed');
    }
    return MockHttpClientRequest(response);
  }

  @override
  void close({bool force = false}) {}

  @override
  Duration? get connectionTimeout => null;

  @override
  set connectionTimeout(Duration? value) {}

  @override
  Duration get idleTimeout => const Duration(seconds: 15);

  @override
  set idleTimeout(Duration value) {}

  @override
  int? get maxConnectionsPerHost => null;

  @override
  set maxConnectionsPerHost(int? value) {}

  @override
  bool get autoUncompress => true;

  @override
  set autoUncompress(bool value) {}

  @override
  String? get userAgent => null;

  @override
  set userAgent(String? value) {}

  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    throw UnimplementedError();
  }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) {
    throw UnimplementedError();
  }

  @override
  Future<HttpClientRequest> post(String host, int port, String path) {
    throw UnimplementedError();
  }

  @override
  Future<HttpClientRequest> put(String host, int port, String path) {
    throw UnimplementedError();
  }

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) {
    throw UnimplementedError();
  }

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) {
    throw UnimplementedError();
  }

  @override
  Future<HttpClientRequest> head(String host, int port, String path) {
    throw UnimplementedError();
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) {
    throw UnimplementedError();
  }

  @override
  Future<HttpClientRequest> putUrl(Uri url) {
    throw UnimplementedError();
  }

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) {
    throw UnimplementedError();
  }

  @override
  Future<HttpClientRequest> patchUrl(Uri url) {
    throw UnimplementedError();
  }

  @override
  Future<HttpClientRequest> headUrl(Uri url) {
    throw UnimplementedError();
  }

  @override
  set authenticate(
    Future<bool> Function(Uri url, String scheme, String? realm)? f,
  ) {}

  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) {}

  @override
  set authenticateProxy(
    Future<bool> Function(String host, int port, String scheme, String? realm)?
    f,
  ) {}

  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) {}

  @override
  set findProxy(String Function(Uri url)? f) {}

  @override
  set badCertificateCallback(
    bool Function(X509Certificate cert, String host, int port)? callback,
  ) {}

  @override
  set connectionFactory(
    Future<ConnectionTask<Socket>> Function(
      Uri url,
      String? proxyHost,
      int? proxyPort,
    )?
    f,
  ) {}

  @override
  set keyLog(void Function(String line)? callback) {}
}

class MockHttpClientRequest implements HttpClientRequest {
  MockHttpClientRequest(this._response);
  final MockHttpClientResponse _response;
  final HttpHeaders _headers = MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    if (_response.data == null) {
      throw const SocketException('Connection failed');
    }
    return _response;
  }

  @override
  HttpHeaders get headers => _headers;

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {}

  @override
  Future<HttpClientResponse> get done => close();

  @override
  Future<void> flush() async {}

  @override
  void write(Object? object) {}

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? object = '']) {}

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  List<Cookie> get cookies => [];

  Future<HttpClientResponse> get response => close();

  @override
  String get method => 'GET';

  @override
  Uri get uri => Uri.parse('https://example.com');

  @override
  int get contentLength => -1;

  @override
  set contentLength(int value) {}

  @override
  Encoding get encoding => utf8;

  @override
  set encoding(Encoding value) {}

  @override
  bool get persistentConnection => false;

  @override
  set persistentConnection(bool value) {}

  @override
  bool get followRedirects => false;

  @override
  set followRedirects(bool value) {}

  @override
  int get maxRedirects => 0;

  @override
  set maxRedirects(int value) {}

  @override
  bool get bufferOutput => false;

  @override
  set bufferOutput(bool value) {}

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}
}

class MockHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  MockHttpClientResponse(this.data, this._statusCode, this._headers);
  final Uint8List? data;
  final int _statusCode;
  final Map<String, String> _headers;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    if (data == null) {
      return Stream<List<int>>.error(
        const SocketException('Connection failed'),
      ).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
    }

    return Stream.value(data!.toList()).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  int get statusCode => _statusCode;

  @override
  int get contentLength => data?.length ?? 0;

  @override
  HttpHeaders get headers => MockHttpHeaders(_headers);

  @override
  String get reasonPhrase => '';

  @override
  bool get persistentConnection => false;

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => [];

  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) {
    throw UnimplementedError();
  }

  @override
  List<Cookie> get cookies => [];

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  Future<Socket> detachSocket() {
    throw UnimplementedError();
  }

  @override
  HttpClientResponseCompressionState get compressionState =>
      throw UnimplementedError();
}

class MockHttpHeaders implements HttpHeaders {
  MockHttpHeaders([Map<String, String>? headers]) {
    headers?.forEach((key, value) {
      _headers[key.toLowerCase()] = [value];
    });
  }
  final Map<String, List<String>> _headers = {};

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers.putIfAbsent(name.toLowerCase(), () => []).add(value.toString());
  }

  @override
  String? value(String name) {
    final values = _headers[name.toLowerCase()];
    final isExistValues = values?.isNotEmpty ?? false;
    return isExistValues ? values!.first : null;
  }

  @override
  List<String>? operator [](String name) => _headers[name.toLowerCase()];

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
