import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Handles URL hashing for cache file naming
class CacheUrlHasher {
  /// Generate a hash for the given URL to use as cache file name
  static String getUrlHash(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate a Vary-aware hash for the given URL and request headers
  static String getVaryAwareUrlHash(
    String url,
    Map<String, String> requestHeaders,
    List<String> varyHeaders,
  ) {
    // Create a string combining URL and relevant headers
    final buffer = StringBuffer(url);
    
    // Sort vary headers for consistent ordering
    final sortedVaryHeaders = List<String>.from(varyHeaders)..sort();
    
    for (final varyHeader in sortedVaryHeaders) {
      final lowerVaryHeader = varyHeader.toLowerCase();
      
      // Find matching request header (case-insensitive)
      for (final requestHeader in requestHeaders.keys) {
        if (requestHeader.toLowerCase() == lowerVaryHeader) {
          buffer.write('|$requestHeader:${requestHeaders[requestHeader]}');
          break;
        }
      }
    }
    
    final bytes = utf8.encode(buffer.toString());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
