# AeroCache - Cache-Control Implementation TODO
## Checklist for Supporting the `Vary` Header in AeroCache

- [x] Analyze HTTP specification for `Vary` header semantics
- [x] Identify all relevant request headers that may affect cache key calculation
- [x] Design cache key structure to incorporate `Vary` header values
- [x] Implement logic to parse and store `Vary` header from origin responses
- [x] Update cache lookup to consider `Vary`-specified headers from requests
- [x] Add tests for cache hits/misses with different `Vary` header scenarios
- [x] Document `Vary` header support and usage in AeroCache
- [x] Review and refactor code for clarity and maintainability
- [x] Validate implementation against real-world HTTP responses
- [ ] Finalize and merge changes after code review
