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
}
