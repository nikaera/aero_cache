# AeroCache - Claude Development Guide

## Project Overview
AeroCache is a high-performance cache library for Dart/Flutter. It stores HTTP request results compressed with zstd and performs cache revalidation using ETag and Last-Modified headers.

## Main Features
- Cache size reduction with zstd compression
- Cache revalidation based on ETag/Last-Modified
- Download with progress notification
- Unified error handling

## Development Environment
- Dart SDK 3.0 or higher
- Flutter SDK (optional)

## Dependencies
```yaml
dependencies:
  zstd: ^1.0.0
  path_provider: ^2.0.0

dev_dependencies:
  test: ^1.24.0
  http: ^1.0.0  # Mock server for testing
```

## Project Structure
```
lib/
├── aero_cache.dart          # Main entry point
├── src/
│   ├── cache_manager.dart   # Cache file management
│   ├── meta_info.dart       # Meta information data class
│   └── exceptions.dart      # Exception definitions
test/
├── unit/
│   ├── cache_manager_test.dart
│   ├── meta_info_test.dart
│   └── aero_cache_test.dart
├── integration/
│   └── aero_cache_integration_test.dart
└── mock/
    └── mock_http_server.dart
example/
└── main.dart
```

## Development & Test Commands
```bash
# Install dependencies
dart pub get

# Run unit tests
dart test test/unit/

# Run integration tests
dart test test/integration/

# Run all tests
dart test

# Run example sample
dart run example/main.dart

# Static analysis
dart analyze

# Formatting
dart format lib/ test/ example/
```

## Key Implementation Points

### Cache File Structure
- `<urlHash>.cache`: zstd-compressed binary data
- `<urlHash>.meta`: Meta information in JSON format

### Error Handling
- All exceptions are wrapped in `AeroCacheException`
- Unified handling for network, file I/O, and compression errors

### Progress Notification
- Progress is notified with the `ProgressCallback` type
- Format: `(int received, int total)`

### Cache Revalidation
- Uses `If-None-Match` (ETag) and `If-Modified-Since` headers
- Returns local cache on 304 Not Modified response

## Test Strategy
1. **Unit Tests**: Test each class individually
2. **Integration Tests**: Test actual communication using a mock HTTP server
3. **Error Tests**: Test various exception cases

## Development Notes
- Use `sha256` from the `crypto` package for URL hashing
- Implement file I/O asynchronously
- Obtain cache directory using `path_provider`
- Use the `zstd` package for compression