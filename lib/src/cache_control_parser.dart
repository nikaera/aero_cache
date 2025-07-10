import 'dart:io';

/// Parser for Cache-Control header directives
class CacheControlParser {
  /// Parse Cache-Control header value and return individual directives
  static Map<String, String?> parse(String? cacheControlValue) {
    final directives = <String, String?>{};

    if (cacheControlValue == null) {
      return directives;
    }

    // Split by comma and process each directive
    final parts = cacheControlValue.split(',');
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;

      // Check if directive has a value (e.g., max-age=3600)
      if (trimmed.contains('=')) {
        final equalIndex = trimmed.indexOf('=');
        final directive = trimmed.substring(0, equalIndex).trim();
        final value = trimmed.substring(equalIndex + 1).trim();
        
        // Skip empty directive names
        if (directive.isNotEmpty) {
          directives[directive] = value;
        }
      } else {
        // Boolean directive (e.g., no-cache, no-store)
        directives[trimmed] = null;
      }
    }

    return directives;
  }

  /// Check if the response should not be cached
  static bool hasNoStore(HttpHeaders headers) {
    final cacheControl = headers.value('cache-control');
    return cacheControl != null && cacheControl.contains('no-store');
  }

  /// Check if the response requires revalidation
  static bool hasNoCache(HttpHeaders headers) {
    final cacheControl = headers.value('cache-control');
    return cacheControl != null && cacheControl.contains('no-cache');
  }

  /// Check if the response must be revalidated when stale
  static bool hasMustRevalidate(HttpHeaders headers) {
    final cacheControl = headers.value('cache-control');
    return cacheControl != null && cacheControl.contains('must-revalidate');
  }

  /// Extract max-age value from Cache-Control header
  static int? getMaxAge(HttpHeaders headers) {
    final cacheControl = headers.value('cache-control');
    if (cacheControl == null) return null;

    // Parse directives to handle priorities
    final directives = parse(cacheControl);
    
    // no-store takes precedence over max-age
    if (directives.containsKey('no-store')) {
      return null;
    }

    final maxAgeValue = directives['max-age'];
    if (maxAgeValue != null) {
      return int.tryParse(maxAgeValue);
    }

    return null;
  }

  /// Check if the response has stale-while-revalidate directive
  static bool hasStaleWhileRevalidate(HttpHeaders headers) {
    final cacheControl = headers.value('cache-control');
    return cacheControl != null &&
        cacheControl.contains('stale-while-revalidate');
  }

  /// Extract stale-while-revalidate value from Cache-Control header
  static int? getStaleWhileRevalidate(HttpHeaders headers) {
    final cacheControl = headers.value('cache-control');
    if (cacheControl == null) return null;

    final staleWhileRevalidateMatch = RegExp(
      r'stale-while-revalidate=(\d+)',
    ).firstMatch(cacheControl);
    if (staleWhileRevalidateMatch != null) {
      return int.tryParse(staleWhileRevalidateMatch.group(1)!);
    }

    return null;
  }

  /// Check if the response has stale-if-error directive
  static bool hasStaleIfError(HttpHeaders headers) {
    final cacheControl = headers.value('cache-control');
    return cacheControl != null && cacheControl.contains('stale-if-error');
  }

  /// Extract stale-if-error value from Cache-Control header
  static int? getStaleIfError(HttpHeaders headers) {
    final cacheControl = headers.value('cache-control');
    if (cacheControl == null) return null;

    final staleIfErrorMatch = RegExp(
      r'stale-if-error=(\d+)',
    ).firstMatch(cacheControl);
    if (staleIfErrorMatch != null) {
      return int.tryParse(staleIfErrorMatch.group(1)!);
    }

    return null;
  }

  /// Extract Vary header values
  static List<String> getVaryHeaders(HttpHeaders headers) {
    final varyHeader = headers.value('vary');
    if (varyHeader == null) return [];
    
    return varyHeader
        .split(',')
        .map((header) => header.trim())
        .where((header) => header.isNotEmpty)
        .toList();
  }

  /// Get relevant request headers for cache key calculation based on Vary 
  /// headers
  static Map<String, String> getRelevantRequestHeaders(
    Map<String, String> requestHeaders,
    List<String> varyHeaders,
  ) {
    final relevantHeaders = <String, String>{};
    
    for (final varyHeader in varyHeaders) {
      final lowerVaryHeader = varyHeader.toLowerCase();
      for (final requestHeader in requestHeaders.keys) {
        if (requestHeader.toLowerCase() == lowerVaryHeader) {
          relevantHeaders[requestHeader] = requestHeaders[requestHeader]!;
          break;
        }
      }
    }
    
    return relevantHeaders;
  }
}
