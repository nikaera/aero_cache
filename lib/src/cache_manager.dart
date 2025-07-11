import 'dart:io';

import 'package:aero_cache/src/cache_compression.dart';
import 'package:aero_cache/src/cache_control_parser.dart';
import 'package:aero_cache/src/cache_expiration_calculator.dart';
import 'package:aero_cache/src/cache_file_manager.dart';
import 'package:aero_cache/src/exceptions.dart';
import 'package:aero_cache/src/meta_info.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Manages cache files and metadata
class CacheManager {
  /// Create a new CacheManager instance
  CacheManager({
    this.disableCompression = false,
    this.compressionLevel = 3,
    this.cacheDirPath,
    this.defaultCacheDuration = const Duration(days: 5),
  }) : assert(
         compressionLevel >= 1 && compressionLevel <= 22,
         'Compression level must be between 1 and 22',
       );

  /// Cache directory instance
  late final Directory _cacheDirectory;

  /// Cache file manager instance
  late final CacheFileManager _fileManager;

  /// Cache compression instance
  late final CacheCompression _compression;

  /// Whether compression is disabled
  final bool disableCompression;

  /// Zstandard compression level
  final int compressionLevel;

  /// Optional custom cache directory path
  final String? cacheDirPath;

  /// Default cache duration
  final Duration defaultCacheDuration;

  /// Initialize the cache directory and compression
  Future<void> initialize() async {
    try {
      Directory appDir;
      if (cacheDirPath != null) {
        appDir = Directory(cacheDirPath!);
      } else {
        appDir = await getTemporaryDirectory();
      }
      _cacheDirectory = Directory('${appDir.path}/aero_cache');
      _fileManager = CacheFileManager(_cacheDirectory);
      _compression = CacheCompression(
        disableCompression: disableCompression,
        compressionLevel: compressionLevel,
      );
      _compression.initialize();

      if (!_cacheDirectory.existsSync()) {
        await _cacheDirectory.create(recursive: true);
      }
    } catch (e) {
      throw AeroCacheException('Failed to initialize cache directory', e);
    }
  }

  /// Get metadata information for a URL
  Future<MetaInfo?> getMeta(String url) async {
    return _fileManager.readMeta(url);
  }

  /// Get cached data for a URL
  Future<Uint8List> getData(String url) async {
    try {
      final compressedData = await _fileManager.readCacheData(url);
      return await _compression.decompress(compressedData);
    } on Exception catch (e) {
      return _handleError('read cache data', url, e);
    }
  }

  /// Create MetaInfo from headers
  MetaInfo _createMetaInfo(
    String url,
    int contentLength,
    HttpHeaders headers,
    List<String> varyHeaders,
  ) {
    return MetaInfo(
      url: url,
      etag: headers.value('etag'),
      lastModified: headers.value('last-modified'),
      createdAt: DateTime.now(),
      expiresAt: CacheExpirationCalculator.calculateExpiresAt(
        headers,
        defaultCacheDuration,
      ),
      contentLength: contentLength,
      contentType: headers.value('content-type'),
      requiresRevalidation: CacheControlParser.hasNoCache(headers),
      staleWhileRevalidate: CacheControlParser.getStaleWhileRevalidate(
        headers,
      ),
      staleIfError: CacheControlParser.getStaleIfError(headers),
      mustRevalidate: CacheControlParser.hasMustRevalidate(headers),
      varyHeaders: varyHeaders.isNotEmpty ? varyHeaders : null,
    );
  }

  /// Save data to cache with compression
  Future<void> saveData(
    String url,
    Uint8List rawData,
    HttpHeaders headers,
  ) async {
    try {
      final dataToWrite = await _compression.compress(rawData);
      _logCompressionRatio(url, dataToWrite.length, rawData.length);

      final varyHeaders = CacheControlParser.getVaryHeaders(headers);
      final metaInfo = _createMetaInfo(
        url,
        rawData.length,
        headers,
        varyHeaders,
      );

      await Future.wait([
        _fileManager.writeCacheData(url, dataToWrite),
        _fileManager.writeMeta(url, metaInfo),
      ]);
    } on Exception catch (e) {
      return _handleError('save cache data', url, e);
    }
  }

  /// Log compression ratio for debugging
  void _logCompressionRatio(String url, int compressedSize, int originalSize) {
    debugPrint(
      'Saving cache for $url, '
      'compressionRatio: ${compressedSize / originalSize}',
    );
  }

  /// Handle errors consistently with proper exception wrapping
  T _handleError<T>(String operation, String url, Exception error) {
    throw AeroCacheException('Failed to $operation for $url', error);
  }

  /// Update metadata for a URL
  Future<void> updateMeta(String url, HttpHeaders headers) async {
    try {
      final oldMeta = await _fileManager.readMeta(url);
      if (oldMeta == null) return;

      final newMeta = MetaInfo(
        url: oldMeta.url,
        etag: headers.value('etag') ?? oldMeta.etag,
        lastModified: headers.value('last-modified') ?? oldMeta.lastModified,
        createdAt: oldMeta.createdAt,
        expiresAt:
            CacheExpirationCalculator.calculateExpiresAt(
              headers,
              defaultCacheDuration,
            ) ??
            oldMeta.expiresAt,
        contentLength: oldMeta.contentLength,
        contentType: headers.value('content-type') ?? oldMeta.contentType,
        requiresRevalidation: CacheControlParser.hasNoCache(headers),
        staleWhileRevalidate:
            CacheControlParser.getStaleWhileRevalidate(headers) ??
            oldMeta.staleWhileRevalidate,
        staleIfError:
            CacheControlParser.getStaleIfError(headers) ?? oldMeta.staleIfError,
        mustRevalidate: CacheControlParser.hasMustRevalidate(headers),
      );

      await _fileManager.writeMeta(url, newMeta);
    } on Exception catch (e) {
      return _handleError('update meta', url, e);
    }
  }

  /// Delete all cache and meta files in the cache directory
  Future<void> clearAllCache() async {
    return _fileManager.clearAllFiles();
  }

  /// Delete all expired cache (.meta) and data files
  Future<void> clearExpiredCache() async {
    return _fileManager.clearExpiredFiles();
  }

  /// Get stale data for stale-while-revalidate scenarios
  Future<Uint8List?> getStaleData(String url) async {
    try {
      final meta = await getMeta(url);
      if (meta == null || !meta.canServeStale) {
        return null;
      }
      return await getData(url);
    } on Exception catch (_) {
      return null;
    }
  }

  /// Check if cache entry needs background revalidation
  Future<bool> needsBackgroundRevalidation(String url) async {
    try {
      final meta = await getMeta(url);
      if (meta == null) return false;

      return meta.isStale && meta.canServeStale;
    } on Exception catch (_) {
      return false;
    }
  }

  /// Get stale data for stale-if-error scenarios
  Future<Uint8List?> getStaleDataOnError(String url) async {
    try {
      final meta = await getMeta(url);
      if (meta == null || !meta.canServeStaleOnError) {
        return null;
      }
      return await getData(url);
    } on Exception catch (_) {
      return null;
    }
  }

  /// Check if cache entry can serve stale data on error
  Future<bool> canServeStaleOnError(String url) async {
    try {
      final meta = await getMeta(url);
      if (meta == null) return false;

      return meta.canServeStaleOnError;
    } on Exception catch (_) {
      return false;
    }
  }

  /// Save data to cache with Vary-aware key generation
  Future<void> saveDataWithRequestHeaders(
    String url,
    Uint8List rawData,
    HttpHeaders headers,
    Map<String, String> requestHeaders,
  ) async {
    try {
      final dataToWrite = await _compression.compress(rawData);
      final varyHeaders = CacheControlParser.getVaryHeaders(headers);

      debugPrint('Saving Vary-aware cache for $url');
      _logCompressionRatio(url, dataToWrite.length, rawData.length);

      final metaInfo = _createMetaInfo(
        url,
        rawData.length,
        headers,
        varyHeaders,
      );

      await Future.wait([
        _fileManager.writeCacheData(url, dataToWrite),
        _fileManager.writeMeta(url, metaInfo),
        _fileManager.writeCacheDataWithRequestHeaders(
          url,
          dataToWrite,
          requestHeaders,
          varyHeaders,
        ),
        _fileManager.writeMetaWithRequestHeaders(
          url,
          metaInfo,
          requestHeaders,
          varyHeaders,
        ),
      ]);
    } on Exception catch (e) {
      return _handleError('save cache data', url, e);
    }
  }

  /// Get metadata with Vary-aware lookup
  Future<MetaInfo?> getMetaWithRequestHeaders(
    String url,
    Map<String, String> requestHeaders,
  ) async {
    return _fileManager.readMetaWithRequestHeaders(url, requestHeaders);
  }

  /// Get cached data with Vary-aware lookup
  Future<Uint8List> getDataWithRequestHeaders(
    String url,
    Map<String, String> requestHeaders,
  ) async {
    try {
      final compressedData = await _fileManager.readCacheDataWithRequestHeaders(
        url,
        requestHeaders,
      );
      return await _compression.decompress(compressedData);
    } on Exception catch (e) {
      return _handleError('read cache data', url, e);
    }
  }
}
