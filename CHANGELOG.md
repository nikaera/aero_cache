## 1.0.1

### Features

- **Download Queue with Concurrency Limits**: Implemented queue-based download management with configurable concurrency limits to improve performance and prevent overwhelming network resources
- **Enhanced Exception Handling**: Added Flutter & Dart development best practices documentation and improved cache management exception handling

### Improvements

- **Better Error Logging**: Replaced print statements with proper log calls for download error handling in AeroCache
- **Documentation Updates**: Fixed documentation URL in pubspec.yaml and updated example README license statement
- **Code Quality**: Improved code formatting and readability across the codebase
- **CI/CD Enhancements**: Added automated API documentation deployment and optimized workflow configurations
- **Package Metadata**: Cleaned up pubspec.yaml by removing irrelevant topics for better package discoverability

### Technical Changes

- Enhanced test utilities with better mock setup and configuration
- Improved cache management with better error handling
- Updated CI workflows to remove unnecessary Java installation steps
- Added comprehensive development best practices documentation

## 1.0.0+1

- Improved documentation and clarified package description in pubspec.yaml
- Updated dependency versions for better compatibility
- Added dependabot configuration for automated dependency updates
- Minor CI and documentation improvements

## 1.0.0

### Initial Release 🎉

- **Core Features**
  - High-performance caching for Dart/Flutter with zstd compression
  - ETag and Last-Modified based cache revalidation
  - Progress callback for downloads
  - Unified error handling with AeroCacheException
  - Automatic expired cache cleanup
  - Customizable cache directory and compression settings
  - API for retrieving cache metadata

### Advanced Caching Features

- **Vary Header Support**
  - Intelligent cache key generation based on Vary header specifications
  - Support for request header-aware caching (Accept-Language, User-Agent, etc.)
  - Proper handling of Vary: * header to prevent caching when appropriate
  - Cache hit/miss scenarios based on varying request headers

- **Cache Control Directives**
  - Support for no-cache, no-store, must-revalidate directives
  - Implementation of max-age, max-stale, min-fresh request directives
  - only-if-cached directive support
  - stale-while-revalidate and stale-if-error background cache strategies

- **Advanced Cache Management**
  - Background cache revalidation for stale-while-revalidate scenarios
  - Stale data serving on network errors (stale-if-error)
  - Comprehensive cache expiration calculation with Cache-Control headers
  - Priority-based Cache-Control directive handling

### Technical Improvements

- **Architecture**
  - Modular storage system with dedicated services
  - Separate cache key generation service for Vary-aware caching
  - Enhanced file management with metadata and data separation
  - Improved error handling and exception management

- **Testing & Quality**
  - Comprehensive test suite with mock headers and cache manager setup
  - Test coverage for all Vary header scenarios
  - Cache-Control directive validation tests
  - Edge case handling for malformed headers

### Development Tools

- **Code Quality**
  - Test setup helper for consistent mock initialization
  - Clean separation of concerns in cache management
  - Improved code readability and documentation
  - Following TDD principles throughout development

### Examples & Documentation

- Flutter integration example included
- Comprehensive API documentation
- Usage examples for advanced caching scenarios
- Vary header handling examples
