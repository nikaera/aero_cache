### **AeroCache - Revised Design Policy**

To maintain the philosophy of minimalism, dependencies on external packages are minimized, and Dart's standard library `dart:io`'s `HttpClient` is used. This allows the core functionality of the library to be implemented without even requiring the `http` package.

1.  **Minimizing Dependencies**: Eliminate `dio` and use Dart's standard `HttpClient` as the foundation of the network layer. As a result, the only external dependencies are `zstd` and `path_provider`, keeping the library extremely lightweight.
2.  **Stream-based Progress Management**: `HttpClient` receives responses as streams. By listening to this stream and summing the sizes of received data chunks, download progress can be reported in real time via callback.
3.  **Clear Error Handling**: Network errors and file I/O errors are caught with `try-catch` and rethrown as the library's custom exception class `AeroCacheException`. This makes it easier for library users to identify the cause of errors.

-----

### **Main Components and Revised Flow**

Since `dio`'s `Interceptor` is not used, the cache logic is implemented directly in the main `AeroCache` class.

#### **1. `AeroCache` Main Class**

This class serves as the entry point for all functionalities of the library.

```dart
// Example of using the library
final aeroCache = AeroCache();
await aeroCache.initialize(); // Prepare the cache directory

try {
  final Uint8List imageData = await aeroCache.get(
    'https://example.com/image.jpg',
    onProgress: (received, total) {
      final percentage = total > 0 ? (received / total * 100).toStringAsFixed(1) : 0;
      print('Downloading... $received / $total bytes ($percentage%)');
    },
  );
  // Use the retrieved data with Image.memory, etc.
} on AeroCacheException catch (e) {
  // Handle network errors, cache read/write failures, etc.
  print('Failed to load media: $e');
}
```

#### **2. `get(url, {onProgress})` Processing Flow**

1.  **Cache Lookup**:

      * Calculate the hash value from the URL and look for the corresponding `.meta` file.

2.  **Cache Hit (Local Processing)**:

      * **a. If the cache is valid**:
          * Read the `.cache` file and decompress the data with zstd to return it immediately. No network communication is involved.
      * **b. If the cache is expired but revalidatable**:
          * Similar to the "Cache Miss" flow below, but add `If-None-Match` or `If-Modified-Since` to the request headers to query the server.
          * If the server responds with **`304 Not Modified`**, consider the cache valid and return the local data.
          * If the response is **`200 OK`**, the resource has been updated, so proceed with the download process.

3.  **Cache Miss (Network Processing)**:

      * Send a request to the server using `HttpClient`.
      * Obtain the `Content-Length` from the response headers to determine the total download size `total`.
      * **Listen to the response body stream**:
          * Each time a data chunk is received, add its size to the received size `received`.
          * If the `onProgress` callback is specified, call `onProgress(received, total)` to notify the progress.
          * The received chunks are temporarily buffered.
      * Once the download is complete (the stream closes), perform the following processing **asynchronously**:
          * Compress the buffered raw data with zstd and save it to the `.cache` file.
          * Parse the response headers and create/save the `.meta` file.
      * Return the downloaded raw data as `Uint8List`.

4.  **Failure Detection**:

      * All of the above processes are wrapped in `try-catch` blocks.
      * Capture `SocketException` (network connection failed), `HttpException` (server error), `FileSystemException` (disk write failure), etc.
      * Rethrow the captured errors wrapped in `AeroCacheException` with a message indicating the cause.

-----

### **Code Implementation Outline (Revised)**

#### **1. Custom Exception**

A class for clarifying error handling.

```dart
class AeroCacheException implements Exception {
  final String message;
  final dynamic originalException;

  AeroCacheException(this.message, [this.originalException]);

  @override
  String toString() => 'AeroCacheException: $message (Original: $originalException)';
}
```

#### **2. `AeroCache` Class**

Outline of the implementation using `HttpClient`.

```dart
import 'dart:io';
import 'dart:typed_data';
// ... other imports

// Callback type definition for progress notifications
typedef ProgressCallback = void Function(int received, int total);

class AeroCache {
  late final CacheManager _cacheManager;
  final HttpClient _httpClient;

  AeroCache()
      : _httpClient = HttpClient(),
        _cacheManager = CacheManager();

  Future<void> initialize() async {
    await _cacheManager.initialize();
  }

  Future<Uint8List> get(String url, {ProgressCallback? onProgress}) async {
    try {
      // 1. Cache lookup and validation logic (similar to the previous code)
      final meta = await _cacheManager.getMeta(url);

      if (meta != null && !meta.isStale) {
        print('Cache HIT: $url');
        return await _cacheManager.getData(url);
      }
      
      // 2. Cache miss or expired -> Network request
      final request = await _httpClient.getUrl(Uri.parse(url));

      // Add revalidation headers
      if (meta != null && meta.isStale) {
        if (meta.etag != null) request.headers.add('If-None-Match', meta.etag!);
        if (meta.lastModified != null) request.headers.add('If-Modified-Since', meta.lastModified!);
      }

      final response = await request.close();

      // 3. Response handling
      if (response.statusCode == 304) { // Not Modified
        print('Cache REVALIDATED: $url');
        // TODO: Update meta information with new headers
        return await _cacheManager.getData(url);
      }

      if (response.statusCode != 200) {
        throw AeroCacheException('Server error: ${response.statusCode}');
      }
      
      // 4. Download and progress notification
      final total = response.contentLength;
      int received = 0;
      final chunks = <List<int>>[];

      await for (final chunk in response) {
        chunks.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }

      final data = Uint8List.fromList(chunks.expand((x) => x).toList());

      // 5. Cache saving (executed asynchronously)
      _cacheManager.saveData(url, data, response.headers);

      return data;

    } catch (e) {
      // 6. Error handling
      throw AeroCacheException('Failed to get media from $url', e);
    }
  }
}
```
