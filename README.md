# AeroCache ☁️

<img src="https://github.com/user-attachments/assets/63710118-2c6e-4402-92ad-d7eb0ea27208" width="80%"/>

[![pub package](https://img.shields.io/pub/v/aero_cache.svg)](https://pub.dev/packages/aero_cache)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)

A high-performance caching library for Dart/Flutter with zstd compression and ETag-based cache revalidation.

## Features

- **High Performance**: Efficient caching with zstd compression for optimal storage
- **ETag Support**: Automatic cache revalidation using ETag headers
- **Last-Modified Support**: Fallback cache validation using Last-Modified headers
- **Vary Header Support**: Intelligent cache key generation based on Vary header specifications
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
    cacheDirPath: '/custom/cache/path',  // Custom cache directory
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
import 'dart:io';

void main() async {
  final cache = AeroCache();
  await cache.initialize();
  
  // Create custom HTTP client with specific headers
  final client = HttpClient();
  final customCache = AeroCache(httpClient: client);
  await customCache.initialize();
  
  // First request with English accept-language
  client.userAgent = 'MyApp/1.0';
  final request1 = await client.getUrl(Uri.parse('https://api.example.com/content'));
  request1.headers.set('Accept-Language', 'en-US');
  request1.headers.set('Accept-Encoding', 'gzip');
  
  // AeroCache will automatically handle Vary header from response
  // and create cache key based on specified headers
  final data1 = await customCache.get('https://api.example.com/content');
  
  // Second request with different accept-language
  final request2 = await client.getUrl(Uri.parse('https://api.example.com/content'));
  request2.headers.set('Accept-Language', 'ja-JP');
  request2.headers.set('Accept-Encoding', 'gzip');
  
  // This will create a separate cache entry due to different Accept-Language
  // if the server's response includes "Vary: Accept-Language"
  final data2 = await customCache.get('https://api.example.com/content');
  
  client.close();
  customCache.dispose();
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
  
  @override
  void initState() {
    super.initState();
    _loadImage();
  }
  
  Future<void> _loadImage() async {
    try {
      await _cache.initialize();
      final data = await _cache.get(widget.imageUrl);
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
      return const CircularProgressIndicator();
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
  String? cacheDirPath,
})
```

- `httpClient`: Optional custom HTTP client
- `disableCompression`: Disable zstd compression (default: false)
- `cacheDirPath`: Custom cache directory path

#### Methods

- `Future<void> initialize()`: Initialize the cache manager
- `Future<Uint8List> get(String url, {ProgressCallback? onProgress})`: Get data from cache or download
- `Future<void> clearAllCache()`: Clear all cached data
- `Future<void> clearExpiredCache()`: Clear expired cache entries
- `Future<MetaInfo?> metaInfo(String url)`: Get metadata for a URL
- `void dispose()`: Dispose of resources

### MetaInfo

Contains metadata information about cached entries:

- `String? etag`: ETag header value
- `String? lastModified`: Last-Modified header value
- `DateTime expiresAt`: Cache expiration time
- `bool isStale`: Whether the cache entry is stale

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
