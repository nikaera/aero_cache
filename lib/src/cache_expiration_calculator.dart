import 'dart:io';

import 'package:aero_cache/src/cache_control_parser.dart';

/// Handles cache expiration time calculation
class CacheExpirationCalculator {
  /// Calculate the expiration time based on HTTP headers
  ///
  /// Falls back to [defaultCacheDuration] if no cache headers are present
  static DateTime? calculateExpiresAt(
    HttpHeaders headers,
    Duration defaultCacheDuration,
  ) {
    final maxAge = CacheControlParser.getMaxAge(headers);
    if (maxAge != null) {
      return DateTime.now().add(Duration(seconds: maxAge));
    }

    final expires = headers.value('expires');
    if (expires != null) {
      return HttpDate.parse(expires);
    }

    // If no cache-control or expires header, use default cache duration
    return DateTime.now().add(defaultCacheDuration);
  }
}
