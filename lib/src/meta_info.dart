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

  /// Check if the cache is stale (expired)
  bool get isStale => expiresAt != null && DateTime.now().isAfter(expiresAt!);

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
    };
  }

  /// Convert to JSON string
  String toJsonString() => json.encode(toJson());
}
