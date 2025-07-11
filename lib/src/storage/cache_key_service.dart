import 'package:aero_cache/src/cache_url_hasher.dart';

/// Service for generating cache keys and filenames
class CacheKeyService {
  /// Create a new CacheKeyService instance
  const CacheKeyService();

  /// Generate cache filename for a URL
  String getCacheFilename(String url) {
    final hash = CacheUrlHasher.getUrlHash(url);
    return '$hash.cache';
  }

  /// Generate metadata filename for a URL
  String getMetaFilename(String url) {
    final hash = CacheUrlHasher.getUrlHash(url);
    return '$hash.meta';
  }

  /// Generate Vary-aware cache filename for a URL with request headers
  String getVaryAwareCacheFilename(
    String url,
    Map<String, String> requestHeaders,
    List<String> varyHeaders,
  ) {
    final hash = CacheUrlHasher.getVaryAwareUrlHash(
      url,
      requestHeaders,
      varyHeaders,
    );
    return '$hash.cache';
  }

  /// Generate Vary-aware metadata filename for a URL with request headers
  String getVaryAwareMetaFilename(
    String url,
    Map<String, String> requestHeaders,
    List<String> varyHeaders,
  ) {
    final hash = CacheUrlHasher.getVaryAwareUrlHash(
      url,
      requestHeaders,
      varyHeaders,
    );
    return '$hash.meta';
  }
}
