/// Cache configuration container
class CacheConfig {
  /// Create a new CacheConfig instance
  const CacheConfig({
    this.disableCompression = false,
    this.compressionLevel = 3,
    this.cacheDirPath,
    this.defaultCacheDuration = const Duration(days: 5),
  }) : assert(
         compressionLevel >= 1 && compressionLevel <= 22,
         'Compression level must be between 1 and 22',
       );

  /// Whether compression is disabled
  final bool disableCompression;

  /// Zstandard compression level (1-22)
  final int compressionLevel;

  /// Optional custom cache directory path
  final String? cacheDirPath;

  /// Default cache duration when no cache headers are present
  final Duration defaultCacheDuration;
}
