# AeroCache ☁️

<img src="https://github.com/user-attachments/assets/63710118-2c6e-4402-92ad-d7eb0ea27208" width="80%"/>

[![CI](https://github.com/nikaera/aero_cache/actions/workflows/project-ci.yaml/badge.svg)](https://github.com/nikaera/aero_cache/actions/workflows/project-ci.yaml)
[![pub package](https://img.shields.io/pub/v/aero_cache.svg)](https://pub.dev/packages/aero_cache)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)

A high-performance HTTP caching library for Dart/Flutter with zstd compression, ETag/Last-Modified revalidation, and full Cache-Control directive support.

## Features

- **High Performance**: Efficient caching with zstd compression for optimal storage
- **ETag Support**: Automatic cache revalidation using ETag headers
- **Last-Modified Support**: Fallback cache validation using Last-Modified headers
- **Vary Header Support**: Intelligent cache key generation based on Vary header specifications
- **Cache Control Directives**: Support for no-cache, no-store, must-revalidate, max-age, max-stale, min-fresh, only-if-cached, stale-while-revalidate, and stale-if-error
- **Background Revalidation**: Stale-while-revalidate support for serving stale content while updating cache
- **Error Resilience**: Stale-if-error support for serving cached content during network failures
- **Progress Tracking**: Real-time download progress callbacks
- **Automatic Cleanup**: Built-in expired cache cleanup
- **Flexible Configuration**: Customizable cache directory and compression settings
- **Exception Handling**: Comprehensive error handling with custom exceptions

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  aero_cache: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic Usage

```dart
import 'package:aero_cache/aero_cache.dart';

void main() async {
  // Create AeroCache instance
  final cache = AeroCache();
  
  // Initialize the cache
  await cache.initialize();
  
  // Get data (downloads if not cached or stale)
  final data = await cache.get('https://example.com/image.jpg');
  
  // Use the data
  print('Downloaded ${data.length} bytes');
  
  // Clean up
  cache.dispose();
}
```

### Advanced Usage

```dart
import 'package:aero_cache/aero_cache.dart';

void main() async {
  // Create AeroCache with custom configuration
  final cache = AeroCache(
    disableCompression: false,  // Enable zstd compression
    compressionLevel: 6,        // Custom compression level (1-22)
    cacheDirPath: '/custom/cache/path',  // Custom cache directory
    defaultCacheDuration: const Duration(hours: 24),  // Custom cache duration
  );
  
  await cache.initialize();
  
  // Get data with progress tracking
  final data = await cache.get(
    'https://example.com/large-file.zip',
    onProgress: (received, total) {
      final progress = (received / total * 100).toStringAsFixed(1);
      print('Download progress: $progress%');
    },
  );
  
  // Get metadata information
  final metaInfo = await cache.metaInfo('https://example.com/large-file.zip');
  if (metaInfo != null) {
    print('ETag: ${metaInfo.etag}');
    print('Last Modified: ${metaInfo.lastModified}');
    print('Is Stale: ${metaInfo.isStale}');
    print('Expires At: ${metaInfo.expiresAt}');
    print('Content Type: ${metaInfo.contentType}');
  }
  
  // Clear expired cache
  await cache.clearExpiredCache();
  
  // Clear all cache
  await cache.clearAllCache();
  
  cache.dispose();
}
```

### Vary Header Handling

```dart
import 'package:aero_cache/aero_cache.dart';

void main() async {
  final cache = AeroCache();
  await cache.initialize();
  
  // First request with English accept-language
  final data1 = await cache.get(
    'https://api.example.com/content',
    headers: {
      'Accept-Language': 'en-US',
      'User-Agent': 'MyApp/1.0',
      'Accept-Encoding': 'gzip',
    },
  );
  
  // Second request with different accept-language
  // This will create a separate cache entry if the server's response
  // includes "Vary: Accept-Language"
  final data2 = await cache.get(
    'https://api.example.com/content',
    headers: {
      'Accept-Language': 'ja-JP',
      'User-Agent': 'MyApp/1.0',
      'Accept-Encoding': 'gzip',
    },
  );
  
  cache.dispose();
}
```

### Cache Control Directives

```dart
import 'package:aero_cache/aero_cache.dart';

void main() async {
  final cache = AeroCache();
  await cache.initialize();
  
  // Force bypass cache and download fresh data
  final freshData = await cache.get(
    'https://api.example.com/data',
    noCache: true,
  );
  
  // Only use cached data, fail if not available
  try {
    final cachedData = await cache.get(
      'https://api.example.com/data',
      onlyIfCached: true,
    );
  } catch (e) {
    print('No cached data available');
  }
  
  // Accept stale data up to 3600 seconds old
  final staleData = await cache.get(
    'https://api.example.com/data',
    maxStale: 3600,
  );
  
  // Require data to be fresh for at least 300 seconds
  final freshRequiredData = await cache.get(
    'https://api.example.com/data',
    minFresh: 300,
  );
  
  // Download without caching (no-store equivalent)
  final temporaryData = await cache.get(
    'https://api.example.com/data',
    noStore: true,
  );
  
  cache.dispose();
}
```

### Flutter Integration

```dart
import 'package:flutter/material.dart';
import 'package:aero_cache/aero_cache.dart';

class ImageWidget extends StatefulWidget {
  final String imageUrl;
  
  const ImageWidget({Key? key, required this.imageUrl}) : super(key: key);
  
  @override
  _ImageWidgetState createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> {
  final AeroCache _cache = AeroCache();
  Uint8List? _imageData;
  bool _isLoading = true;
  double _progress = 0.0;
  
  @override
  void initState() {
    super.initState();
    _loadImage();
  }
  
  Future<void> _loadImage() async {
    try {
      await _cache.initialize();
      final data = await _cache.get(
        widget.imageUrl,
        onProgress: (received, total) {
          setState(() {
            _progress = received / total;
          });
        },
      );
      setState(() {
        _imageData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 8),
          Text('${(_progress * 100).toInt()}%'),
        ],
      );
    }
    
    if (_imageData != null) {
      return Image.memory(_imageData!);
    }
    
    return const Icon(Icons.error);
  }
  
  @override
  void dispose() {
    _cache.dispose();
    super.dispose();
  }
}
```

## API Reference

### AeroCache

#### Constructor

```dart
AeroCache({
  HttpClient? httpClient,
  bool disableCompression = false,
  int compressionLevel = 3,
  Duration defaultCacheDuration = const Duration(days: 5),
  String? cacheDirPath,
})
```

- `httpClient`: Optional custom HTTP client
- `disableCompression`: Disable zstd compression (default: false)
- `compressionLevel`: Zstd compression level 1-22 (default: 3)
- `defaultCacheDuration`: Default cache duration (default: 5 days)
- `cacheDirPath`: Custom cache directory path

#### Methods

- `Future<void> initialize()`: Initialize the cache manager
- `Future<Uint8List> get(String url, {ProgressCallback? onProgress, bool noCache, int? maxAge, int? maxStale, int? minFresh, bool onlyIfCached, bool noStore, Map<String, String>? headers})`: Get data from cache or download with advanced cache control
- `Future<void> clearAllCache()`: Clear all cached data
- `Future<void> clearExpiredCache()`: Clear expired cache entries
- `Future<MetaInfo?> metaInfo(String url)`: Get metadata for a URL
- `void dispose()`: Dispose of resources

### MetaInfo

Contains metadata information about cached entries:

- `String? etag`: ETag header value
- `String? lastModified`: Last-Modified header value
- `String? contentType`: Content-Type header value
- `DateTime createdAt`: Cache creation time
- `DateTime expiresAt`: Cache expiration time
- `int contentLength`: Content length in bytes
- `bool isStale`: Whether the cache entry is stale
- `bool requiresRevalidation`: Whether cache requires revalidation
- `bool mustRevalidate`: Whether cache must be revalidated
- `Duration? staleWhileRevalidate`: Stale-while-revalidate duration
- `Duration? staleIfError`: Stale-if-error duration
- `List<String>? varyHeaders`: Vary header specifications

### Exceptions

- `AeroCacheException`: Base exception class for cache-related errors

## Performance

AeroCache uses zstd compression by default, which provides:
- Fast compression/decompression speeds
- Excellent compression ratios
- Low memory usage

Benchmarks show significant storage savings compared to uncompressed caching, especially for text-based content like JSON and HTML.

## Vary Header Support

AeroCache intelligently handles the `Vary` header to ensure correct cache behavior when responses depend on request headers. When a server includes a `Vary` header in its response, AeroCache automatically:

- Parses the `Vary` header to identify which request headers affect the response
- Incorporates relevant request header values into the cache key calculation
- Ensures cache hits only occur when the specified request headers match exactly
- Supports common headers like `Accept-Encoding`, `User-Agent`, `Accept-Language`, etc.

This ensures that cached responses are served only when appropriate, preventing issues like serving compressed content to clients that don't support compression.

## Contributing

We welcome contributions to AeroCache! Please follow the GitHub Flow process:

### How to Contribute

1. **Fork the repository** on GitHub
2. **Create a feature branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes** and add tests if applicable
4. **Ensure all tests pass**:
   ```bash
   flutter test
   ```
5. **Follow the code style** using `very_good_analysis`:
   ```bash
   dart analyze
   ```
6. **Commit your changes** with a clear message:
   ```bash
   git commit -m "Add: your feature description"
   ```
7. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```
8. **Create a Pull Request** on GitHub with:
   - Clear description of changes
   - Reference any related issues
   - Screenshots if applicable

### Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/aero_cache.git
   cd aero_cache
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run tests:
   ```bash
   flutter test
   ```

4. Run the example:
   ```bash
   cd example
   flutter run
   ```

### Code Style

- Follow the official [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `very_good_analysis` linting rules
- Write comprehensive tests for new features
- Add documentation for public APIs

### Reporting Issues

When reporting issues, please include:
- Flutter/Dart version
- Operating system
- Steps to reproduce
- Expected vs actual behavior
- Code samples if applicable

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and changes.

## Support

For questions and support:
- Check the [example](example/) directory for usage examples
- Open an issue on GitHub for bugs or feature requests
- Review the API documentation
