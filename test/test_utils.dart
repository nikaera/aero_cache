import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aero_cache/aero_cache.dart';
import 'package:aero_cache/src/cache_manager.dart';
import 'package:flutter/services.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class FakePathProviderPlatform extends PathProviderPlatform {
  Directory? _tempDir;

  @override
  Future<String?> getApplicationSupportPath() async {
    _tempDir ??= await Directory.systemTemp.createTemp('aero_cache_test');
    return _tempDir!.path;
  }
}

class MockHttpClient implements HttpClient {
  final Map<String, MockHttpClientResponse> _responses = {};
  int requestCount = 0;

  void setResponse(String url, Uint8List data, Map<String, String> headers) {
    _responses[url] = MockHttpClientResponse(data, 200, headers);
  }

  void setResponseWithDelay(
      String url, Uint8List data, Map<String, String> headers, int delayMs) {
    _responses[url] = MockHttpClientResponse(data, 200, headers, delayMs);
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

  void reset() {
    _responses.clear();
    requestCount = 0;
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
    )? f,
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
  MockHttpClientResponse(this.data, this._statusCode, this._headers,
      [this._delayMs = 0]);
  final Uint8List? data;
  final int _statusCode;
  final Map<String, String> _headers;
  final int _delayMs;

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

    var stream = Stream.value(data!.toList());
    if (_delayMs > 0) {
      stream = stream.asyncMap((chunk) async {
        await Future<void>.delayed(Duration(milliseconds: _delayMs));
        return chunk;
      });
    }

    return stream.listen(
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
  void noFolding(String name) {}
}

class TestSetupHelper {
  static Future<Directory> createTempDirectory([String? name]) async {
    return Directory.systemTemp.createTemp(name ?? 'aero_cache_test');
  }

  static Future<CacheManager> createCacheManager([String? path]) async {
    final tempDir =
        path != null ? Directory(path) : await createTempDirectory();
    return CacheManager(
      cacheDirPath: tempDir.path,
      disableCompression: true,
    );
  }

  static Future<AeroCache> createAeroCache({
    MockHttpClient? httpClient,
    String? cacheDirPath,
  }) async {
    final tempDir = cacheDirPath != null
        ? Directory(cacheDirPath)
        : await createTempDirectory();
    return AeroCache(
      httpClient: httpClient ?? MockHttpClient(),
      disableCompression: true,
      cacheDirPath: tempDir.path,
    );
  }

  static void setupPathProvider() {
    PathProviderPlatform.instance = FakePathProviderPlatform();
  }
}

HttpHeaders createMockHeaders(Map<String, String> headers) {
  final request = MockHttpClientRequest(
    MockHttpClientResponse(Uint8List(0), 200, {}),
  );
  headers.forEach(request.headers.add);
  return request.headers;
}
