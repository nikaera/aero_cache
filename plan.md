# AeroCache - Cache-Control Implementation TODO

## Implemented Cache-Control Directives
- [x] `max-age` - Response directive (currently implemented)
- [x] `expires` - Expires header support (currently implemented)

## Unimplemented Response Directives

### Basic Caching Controls
- [ ] `no-cache` - Requires revalidation (can be cached but must be validated before use)
- [ ] `no-store` - Caching prohibited (both private and shared caches)

### Revalidation Controls
- [ ] `must-revalidate` - Must revalidate when stale

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
- [ ] `Vary` header support - Handle cache key variation based on request headers

## Unimplemented Request Directives

### Basic Request Controls
- [ ] `no-cache` - Revalidation request (used for forced reload)
- [ ] `no-store` - Prohibit cache storage request
- [ ] `max-age` - Accept only responses generated within specified seconds

### Detailed Cache Controls
- [x] `max-stale` - Accept stale responses up to specified seconds
- [ ] `min-fresh` - Accept only responses that are fresh for at least specified seconds
- [ ] `only-if-cached` - Only cached responses (prohibit network access)

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
17. [ ] `only-if-cached` (Request) - Cache-only mode
18. [ ] `no-store` (Request) - Prohibit cache storage request

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
- [ ] Support for `Vary` header - Cache key calculation and lookup must respect Vary header values

### Add Tests
- [ ] Unit tests for each directive
- [ ] Combination tests for multiple directives
- [ ] Edge case tests (invalid values, conflicts, etc.)

## Reference Links
- [MDN Cache-Control](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control)
- [RFC 9111 - HTTP Caching](https://httpwg.org/specs/rfc9111.html)
- [RFC 5861 - HTTP Cache-Control Extensions for Stale Content](https://httpwg.org/specs/rfc5861.html)
