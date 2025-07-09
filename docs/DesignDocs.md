# AeroCache Detailed Design Document (DesignDocs)

## 1. Introduction
This document summarizes the detailed design of each component based on the "AeroCache Revised Design Policy" described in PRD.md.  
The main purpose is to concretize the following for easy understanding and implementation by library users/implementers:
- Cache file/meta file format
- Class/method interfaces
- Processing flow (cache hit/miss, revalidation, download)
- Error handling strategy
- Test scenarios

---

## 2. System Structure and Dependencies

### 2.1 Dependency Packages
- dart:io (`HttpClient`, `File`, `Directory`, `SocketException`, etc.)
- dart:typed_data (`Uint8List`)
- zstd (using [landamessenger/zstandard](https://github.com/landamessenger/zstandard) for data compression/decompression)
- path_provider (for obtaining cache directory)

### 2.2 Component Structure Diagram
- **AeroCache**  
  Entry point. Handles cache validation → network fetch → progress notification → save
- **CacheManager**  
  Manages cache directory, reads/writes meta info, saves/gets data
- **MetaInfo**  
  Data class representing meta file
- **AeroCacheException**  
  For exception wrapping

---

## 3. Directory and File Format

### 3.1 Cache Structure
```
<cache_root>/
  ├─ <urlHash>.cache      # zstd compressed binary
  └─ <urlHash>.meta       # JSON meta information
```

### 3.2 `.meta` File Format
```json
{
  "url": "https://example.com/image.jpg",
  "etag": "\"abc123\"",
  "lastModified": "Wed, 09 Jul 2025 12:00:00 GMT",
  "createdAt": 1625836800000,    // milliseconds
  "expiresAt": 1625923200000,    // milliseconds
  "contentLength": 102400        // original size
}
```

---

## 4. API Interface

### 4.1 class AeroCache

```dart
class AeroCache {
  /// Default initialization of HttpClient + CacheManager
  AeroCache();

  /// Create cache directory
  Future<void> initialize();

  /// Get data from URL
  /// onProgress: (received bytes, total bytes) → progress notification
  /// Exception: AeroCacheException
  Future<Uint8List> get(String url,
      {ProgressCallback? onProgress});
}
```

### 4.2 class CacheManager

```dart
class CacheManager {
  /// Prepare cache root
  Future<void> initialize();

  /// Read meta info / return null if not found
  Future<MetaInfo?> getMeta(String url);

  /// Read cached data (including decompression)
  Future<Uint8List> getData(String url);

  /// Save data + update meta asynchronously
  void saveData(
    String url,
    Uint8List rawData,
    HttpHeaders headers
  );
}
```

### 4.3 class MetaInfo

```dart
class MetaInfo {
  final String url;
  final String? etag;
  final String? lastModified;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int contentLength;
  final String? contentType;

  bool get isStale =>
    expiresAt != null && DateTime.now().isAfter(expiresAt!);
}
```

### 4.4 class AeroCacheException

```dart
class AeroCacheException implements Exception {
  final String message;
  final dynamic originalException;
  AeroCacheException(this.message, [this.originalException]);
  @override String toString() =>
    'AeroCacheException: $message (Original: $originalException)';
}
```

---

## 5. Detailed Processing Flow

### 5.1 Sequence Overview

```text
Client                  AeroCache              CacheManager            Server
   |-- initialize() -->|                        |                      |
   |                   |-- initialize() -----> |-- create dirs ------>|
   |                   |<-- done ------------- |                      |
   |-- get(url) ------>|                        |                      |
   |                   |-- getMeta(url) ------>|-- read .meta ------->|
   |                   |<-- meta or null ------|                      |
[Cache Hit?]
   ├→ Yes:
   |    |-- getData(url) --------------------->|-- read .cache ------>|
   |    |<---------------- Uint8List ----------|                      |
   |<-- return data --------------------------|                      |
   └→ No:
        |-- HttpClient.getUrl →               |                      |
        |-- request.close() →                 |                      |
        |<-- response -------------------------|                      |
        |-- foreach chunk → onProgress()      |                      |
        |-- collect chunks                    |                      |
        |-- Uint8List data                   |                      |
        |-- saveData(url, data, headers) ---->|-- write .cache/.meta>|
        |<-- return data ------------------------------------------->|
```

### 5.2 Cache Revalidation
- If `meta.isStale == true`, add `If-None-Match`/`If-Modified-Since`
- Status `304` → return local cache
- Status `200` → new download

---

## 6. Error Handling

| Exception Type         | Occurrence Location      | Wrapped Exception      |
|-----------------------|-------------------------|-----------------------|
| SocketException       | Network                 | AeroCacheException    |
| HttpException         | Response error          | AeroCacheException    |
| FileSystemException   | IO read/write           | AeroCacheException    |
| ZstdException         | Compression/decompression| AeroCacheException    |
| Others                | Unknown exceptions      | AeroCacheException    |

Wrap all processing in `try-catch` and always throw `AeroCacheException` to the user.

---

## 7. Test Plan

### 7.1 Unit Test Cases
- Verify directory creation with CacheManager.initialize
- getMeta: Check for existence and content of meta file
- getData: Verify decompression of cached data
- saveData: Check file creation and content integrity
- AeroCache.get:
  - Cache hit (within validity) → No re-networking
  - Expired + 304 → No re-download
  - Expired + 200 → New download
  - Network error → AeroCacheException
  - Verify call count/parameters of progress callback

### 7.2 Integration Tests
- Use a mock HTTP server to control各ステータスコード・ヘッダー
- Verify progress notification for large/small file downloads

---

## 8. Extensibility and Considerations
- **Parallel Downloads**: Locking mechanism to prevent duplicate requests to the same URL
- **TTL Policy**: Pluggable logic for calculating `expiresAt`
- **Cache Cleaning**: Option to automatically delete old files
- **Platform Support**: Replacement of `HttpClient` for web and mobile environments

---
