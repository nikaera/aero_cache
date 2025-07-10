import 'dart:convert';

/// Metadata information for cached content
class MetaInfo {
  /// Create a new MetaInfo instance
  MetaInfo({
    required this.url,
    required this.createdAt,
    required this.contentLength,
    this.etag,
    this.lastModified,
    this.expiresAt,
    this.contentType,
    this.requiresRevalidation = false,
    this.staleWhileRevalidate,
  });

  /// Create MetaInfo from JSON data
  factory MetaInfo.fromJson(Map<String, dynamic> json) {
    return MetaInfo(
      url: json['url'] as String,
      etag: json['etag'] as String?,
      lastModified: json['lastModified'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      expiresAt: json['expiresAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int)
          : null,
      contentLength: json['contentLength'] as int,
      contentType: json['contentType'] as String?,
      requiresRevalidation: json['requiresRevalidation'] as bool? ?? false,
      staleWhileRevalidate: json['staleWhileRevalidate'] as int?,
    );
  }

  /// Create MetaInfo from JSON string
  factory MetaInfo.fromJsonString(String jsonString) =>
      MetaInfo.fromJson(json.decode(jsonString) as Map<String, dynamic>);

  /// Original URL
  final String url;

  /// ETag value from server
  final String? etag;

  /// Last-Modified value from server
  final String? lastModified;

  /// When the cache was created
  final DateTime createdAt;

  /// When the cache expires
  final DateTime? expiresAt;

  /// Content length in bytes
  final int contentLength;

  /// Content-Type value from server
  final String? contentType;

  /// Whether the cache requires revalidation (no-cache directive)
  final bool requiresRevalidation;

  /// Stale-while-revalidate value in seconds
  final int? staleWhileRevalidate;

  /// Check if the cache is stale (expired)
  bool get isStale => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Check if stale content can be served during revalidation
  bool get canServeStale {
    if (!isStale || staleWhileRevalidate == null || expiresAt == null) {
      return false;
    }
    final staleWindow = Duration(seconds: staleWhileRevalidate!);
    final staleExpiry = expiresAt!.add(staleWindow);
    return DateTime.now().isBefore(staleExpiry);
  }

  /// Convert to JSON Map
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'etag': etag,
      'lastModified': lastModified,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
      'contentLength': contentLength,
      'contentType': contentType,
      'requiresRevalidation': requiresRevalidation,
      'staleWhileRevalidate': staleWhileRevalidate,
    };
  }

  /// Convert to JSON string
  String toJsonString() => json.encode(toJson());
}
