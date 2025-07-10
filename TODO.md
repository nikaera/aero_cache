# AeroCache - Cache-Control Implementation TODO

## Implemented Cache-Control Directives
- [x] `max-age` - Response directive (currently implemented)
- [x] `expires` - Expires header support (currently implemented)

## Unimplemented Response Directives

### Basic Caching Controls
- [ ] `s-maxage` - max-age for shared caches (proxies, CDNs)
- [ ] `no-cache` - Requires revalidation (can be cached but must be validated before use)
- [ ] `no-store` - Caching prohibited (both private and shared caches)
- [ ] `private` - Private cache only (browser local cache only)
- [ ] `public` - Can be cached by shared caches (even responses with Authorization)

### Revalidation Controls
- [ ] `must-revalidate` - Must revalidate when stale
- [ ] `proxy-revalidate` - Must revalidate for shared caches
- [ ] `must-understand` - Cache only if status code is understood

### Content Transformation/Optimization
- [ ] `no-transform` - Prohibits content transformation by intermediaries
- [ ] `immutable` - Absolutely unchanged while fresh

### Advanced Caching Strategies
- [ ] `stale-while-revalidate` - Serve stale data while revalidating in the background
- [ ] `stale-if-error` - Use stale response in case of error

## Unimplemented Request Directives

### Basic Request Controls
- [ ] `no-cache` - Revalidation request (used for forced reload)
- [ ] `no-store` - Prohibit cache storage request
- [ ] `max-age` - Accept only responses generated within specified seconds

### Detailed Cache Controls
- [ ] `max-stale` - Accept stale responses up to specified seconds
- [ ] `min-fresh` - Accept only responses that are fresh for at least specified seconds
- [ ] `only-if-cached` - Only cached responses (prohibit network access)

### Others
- [ ] `no-transform` - Prohibit content transformation request
- [ ] `stale-if-error` - Allow stale response in case of error

## Implementation Priority

### High Priority (Basic HTTP Caching Behavior)
1. [x] `no-cache` (Response) - Must revalidate caching
2. [x] `no-store` (Response) - Completely prohibit caching
3. [x] `private` (Response) - Private cache only
4. [x] `public` (Response) - Allow shared cache
5. [x] `must-revalidate` (Response) - Force revalidation when stale

### Medium Priority (Advanced Caching Strategies)
6. [ ] `s-maxage` (Response) - max-age for shared caches
7. [ ] `stale-while-revalidate` (Response) - Background revalidation
8. [ ] `immutable` (Response) - Immutable content
9. [ ] `no-cache` (Request) - Force revalidation request
10. [ ] `max-age` (Request) - Maximum allowed age

### Low Priority (Special Use Cases)
11. [ ] `proxy-revalidate` (Response) - Revalidation for proxies
12. [ ] `must-understand` (Response) - Conditional caching
13. [ ] `no-transform` (Request/Response) - Prohibit content transformation
14. [ ] `stale-if-error` (Request/Response) - Fallback on error
15. [ ] `max-stale` (Request) - Allow stale response
16. [ ] `min-fresh` (Request) - Minimum freshness requirement
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

### Add Tests
- [ ] Unit tests for each directive
- [ ] Combination tests for multiple directives
- [ ] Edge case tests (invalid values, conflicts, etc.)

## Reference Links
- [MDN Cache-Control](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control)
- [RFC 9111 - HTTP Caching](https://httpwg.org/specs/rfc9111.html)
- [RFC 5861 - HTTP Cache-Control Extensions for Stale Content](https://httpwg.org/specs/rfc5861.html)