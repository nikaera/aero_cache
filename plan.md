# AeroCache - Cache-Control Implementation TODO

## Implemented Cache-Control Directives
- [x] `max-age` - Response directive (currently implemented)
- [x] `expires` - Expires header support (currently implemented)

## Unimplemented Response Directives

### Basic Caching Controls
- [x] `no-cache` - Requires revalidation (can be cached but must be validated before use)
- [x] `no-store` - Caching prohibited (both private and shared caches)

### Revalidation Controls
- [x] `must-revalidate` - Must revalidate when stale

### Advanced Caching Strategies
- [x] `stale-while-revalidate` - Serve stale data while revalidating in the background
  - [x] Basic parsing and storage of stale-while-revalidate directive
  - [x] `canServeStale` getter in MetaInfo for determining if stale content can be served
  - [x] `getStaleData()` method in CacheManager for retrieving stale content
  - [x] `needsBackgroundRevalidation()` method for identifying entries requiring revalidation
- [x] `stale-if-error` - Use stale response in case of error
  - [x] Basic parsing and storage of stale-if-error directive
  - [x] `canServeStaleOnError` getter in MetaInfo for determining if stale content can be served on error
  - [x] `getStaleDataOnError()` method in CacheManager for retrieving stale content on error
  - [x] `canServeStaleOnError()` method for identifying entries that can serve stale on error
  - [x] Error handling in AeroCache to serve stale data when stale-if-error allows

### Header Handling
- [x] `Vary` header support - Handle cache key variation based on request headers

## Unimplemented Request Directives

### Basic Request Controls
- [x] `no-cache` - Revalidation request (used for forced reload)
- [x] `no-store` - Prohibit cache storage request
- [x] `max-age` - Accept only responses generated within specified seconds

### Detailed Cache Controls
- [x] `max-stale` - Accept stale responses up to specified seconds
- [x] `min-fresh` - Accept only responses that are fresh for at least specified seconds
- [x] `only-if-cached` - Only cached responses (prohibit network access)

### Others
- [x] `stale-if-error` - Allow stale response in case of error

## Implementation Priority

### High Priority (Basic HTTP Caching Behavior)
1. [x] `no-cache` (Response) - Must revalidate caching
2. [x] `no-store` (Response) - Completely prohibit caching
3. [x] `must-revalidate` (Response) - Force revalidation when stale

### Medium Priority (Advanced Caching Strategies)
7. [x] `stale-while-revalidate` (Response) - Background revalidation
9. [x] `no-cache` (Request) - Force revalidation request
10. [x] `max-age` (Request) - Maximum allowed age

### Low Priority (Special Use Cases)
14. [x] `stale-if-error` (Request/Response) - Fallback on error
15. [x] `max-stale` (Request) - Allow stale response
16. [x] `min-fresh` (Request) - Minimum freshness requirement
17. [x] `only-if-cached` (Request) - Cache-only mode
18. [x] `no-store` (Request) - Prohibit cache storage request

## Implementation Considerations

### Enhanced Parsing Functionality
- [ ] Parse multiple directives in Cache-Control header
- [ ] Process directive priorities
- [ ] Properly handle invalid directives

### MetaInfo Extension
- [ ] Store information for each directive
- [ ] Validity determination based on directives
- [ ] Cache policy determination logic

### AeroCache API Extension
- [ ] Specify Cache-Control in request options
- [ ] API to retrieve response directive information
- [ ] Customizable cache policy feature

### Header Handling
- [x] Support for `Vary` header - Cache key calculation and lookup must respect Vary header values

## Vary Header Full Implementation Checklist

### Core Infrastructure Changes
- [ ] **CacheUrlHasher Redesign**
  - [ ] Extend `getUrlHash()` to accept request headers parameter
  - [ ] Create `getVaryAwareUrlHash(String url, Map<String, String> requestHeaders, List<String> varyHeaders)` method
  - [ ] Add header normalization logic (case-insensitive, whitespace handling)
  - [ ] Implement deterministic header ordering for consistent hash generation
  - [ ] Add support for wildcard Vary header (`Vary: *`) - should create unique cache per request

### Cache Key Management
- [ ] **MetaInfo Enhancement**
  - [ ] Add `List<String>? varyHeaders` field to store Vary header values
  - [ ] Add `Map<String, String>? requestHeaders` field to store relevant request headers
  - [ ] Update `fromJson()` and `toJson()` methods to handle new fields
  - [ ] Add validation for Vary header consistency

- [ ] **Cache Storage Strategy**
  - [ ] Implement cache key variations based on Vary headers
  - [ ] Design cache directory structure for varied responses
  - [ ] Handle cache key conflicts when Vary headers change
  - [ ] Implement cache cleanup for orphaned varied entries

### CacheManager Updates
- [ ] **Storage Methods**
  - [ ] Update `saveData()` to extract and store Vary headers from response
  - [ ] Update `saveData()` to store relevant request headers based on Vary
  - [ ] Implement cache key generation using both URL and request headers
  - [ ] Add validation to prevent caching when `Vary: *` is present

- [ ] **Retrieval Methods**
  - [ ] Update `getMeta()` to accept request headers parameter
  - [ ] Update `getData()` to use Vary-aware cache key lookup
  - [ ] Implement fallback logic when varied cache entry not found
  - [ ] Add `getVariedMeta(String url, Map<String, String> requestHeaders)` method

- [ ] **Cache Invalidation**
  - [ ] Update `clearExpiredCache()` to handle varied cache entries
  - [ ] Add `clearVariedCache(String url)` method to clear all variations
  - [ ] Implement selective cleanup for specific header combinations

### AeroCache API Updates
- [ ] **Request Options**
  - [ ] Add `Map<String, String>? requestHeaders` parameter to fetch methods
  - [ ] Update internal HTTP client to use provided request headers
  - [ ] Add validation for required request headers when Vary is present

- [ ] **Response Handling**
  - [ ] Extract Vary headers from HTTP response
  - [ ] Match request headers with Vary requirements
  - [ ] Implement cache miss handling for new header combinations

### Advanced Features
- [ ] **Header Matching Logic**
  - [ ] Implement case-insensitive header matching
  - [ ] Handle header value normalization (e.g., Accept-Encoding compression formats)
  - [ ] Support for partial header matching patterns
  - [ ] Add support for comma-separated header values

- [ ] **Performance Optimizations**
  - [ ] Implement cache key pre-computation for common header combinations
  - [ ] Add in-memory cache for frequently accessed varied entries
  - [ ] Optimize disk storage layout for varied cache entries
  - [ ] Add metrics for varied cache hit/miss ratios

### Error Handling & Edge Cases
- [ ] **Invalid Vary Headers**
  - [ ] Handle malformed Vary header values gracefully
  - [ ] Implement fallback when required request headers are missing
  - [ ] Add logging for Vary header processing errors

- [ ] **Backward Compatibility**
  - [ ] Ensure existing cache entries without Vary support still work
  - [ ] Implement migration strategy for existing cache files
  - [ ] Add feature flags for Vary header support

### Testing Strategy
- [ ] **Unit Tests**
  - [ ] Test Vary header parsing with complex header combinations
  - [ ] Test cache key generation with different request headers
  - [ ] Test cache storage and retrieval with varied entries
  - [ ] Test edge cases (empty headers, invalid values, conflicts)

- [ ] **Integration Tests**
  - [ ] Test full HTTP request/response cycle with Vary headers
  - [ ] Test cache behavior with multiple varied responses
  - [ ] Test performance with large numbers of varied cache entries
  - [ ] Test cache cleanup and invalidation scenarios

- [ ] **Performance Tests**
  - [ ] Benchmark cache key generation performance
  - [ ] Test memory usage with varied cache entries
  - [ ] Measure disk I/O impact of varied cache storage

### Documentation & Examples
- [ ] **API Documentation**
  - [ ] Document new request headers parameter in public methods
  - [ ] Add examples of common Vary header usage patterns
  - [ ] Document performance implications of varied caching

- [ ] **Implementation Guide**
  - [ ] Create migration guide for existing users
  - [ ] Add troubleshooting guide for Vary header issues
  - [ ] Document best practices for Vary header usage

### Add Tests
- [ ] Unit tests for each directive
- [ ] Combination tests for multiple directives
- [ ] Edge case tests (invalid values, conflicts, etc.)

## Reference Links
- [MDN Cache-Control](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control)
- [RFC 9111 - HTTP Caching](https://httpwg.org/specs/rfc9111.html)
- [RFC 5861 - HTTP Cache-Control Extensions for Stale Content](https://httpwg.org/specs/rfc5861.html)
