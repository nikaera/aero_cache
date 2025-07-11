import 'dart:io';

import 'package:aero_cache/src/cache_control_parser.dart';
import 'package:aero_cache/src/cache_expiration_calculator.dart';
import 'package:aero_cache/src/exceptions.dart';
import 'package:aero_cache/src/meta_info.dart';
import 'package:aero_cache/src/storage/cache_key_service.dart';
import 'package:aero_cache/src/storage/file_storage_service.dart';

/// Service for handling metadata operations
class MetadataService {
  /// Create a new MetadataService instance
  const MetadataService(
    this._fileStorage,
    this._keyService,
  );

  final FileStorageService _fileStorage;
  final CacheKeyService _keyService;

  /// Read metadata information for a URL
  Future<MetaInfo?> readMeta(String url) async {
    try {
      final filename = _keyService.getMetaFilename(url);
      if (!_fileStorage.fileExists(filename)) {
        return null;
      }

      final metaContent = await _fileStorage.readTextFile(filename);
      return MetaInfo.fromJsonString(metaContent);
    } catch (e) {
      throw AeroCacheException('Failed to read meta information for $url', e);
    }
  }

  /// Write metadata information for a URL
  Future<void> writeMeta(String url, MetaInfo metaInfo) async {
    try {
      final filename = _keyService.getMetaFilename(url);
      await _fileStorage.writeTextFile(filename, metaInfo.toJsonString());
    } catch (e) {
      throw AeroCacheException('Failed to write meta information for $url', e);
    }
  }

  /// Read metadata information for a URL with request headers (Vary-aware)
  Future<MetaInfo?> readMetaWithRequestHeaders(
    String url,
    Map<String, String> requestHeaders,
  ) async {
    // First try to read the regular meta file to get Vary headers
    final regularMeta = await readMeta(url);
    if (regularMeta != null && regularMeta.varyHeaders != null) {
      // Try to read the vary-aware meta file
      try {
        final filename = _keyService.getVaryAwareMetaFilename(
          url,
          requestHeaders,
          regularMeta.varyHeaders!,
        );
        if (_fileStorage.fileExists(filename)) {
          final metaContent = await _fileStorage.readTextFile(filename);
          return MetaInfo.fromJsonString(metaContent);
        } else {
          // Vary-aware file doesn't exist, return null for cache miss
          return null;
        }
      } on Exception catch (_) {
        // Vary-aware read failed, return null for cache miss
        return null;
      }
    }

    // Return regular meta if no vary headers
    return regularMeta;
  }

  /// Write metadata information for a URL with request headers (Vary-aware)
  Future<void> writeMetaWithRequestHeaders(
    String url,
    MetaInfo metaInfo,
    Map<String, String> requestHeaders,
    List<String> varyHeaders,
  ) async {
    try {
      final filename = _keyService.getVaryAwareMetaFilename(
        url,
        requestHeaders,
        varyHeaders,
      );
      await _fileStorage.writeTextFile(filename, metaInfo.toJsonString());
    } catch (e) {
      throw AeroCacheException('Failed to write meta information for $url', e);
    }
  }

  /// Create MetaInfo from response headers
  MetaInfo createMetaInfo(
    String url,
    HttpHeaders headers,
    int contentLength,
    Duration defaultCacheDuration,
  ) {
    final varyHeaders = CacheControlParser.getVaryHeaders(headers);
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

  /// Update existing metadata with new response headers
  MetaInfo updateMetaInfo(
    MetaInfo oldMeta,
    HttpHeaders headers,
    Duration defaultCacheDuration,
  ) {
    return MetaInfo(
      url: oldMeta.url,
      etag: headers.value('etag') ?? oldMeta.etag,
      lastModified: headers.value('last-modified') ?? oldMeta.lastModified,
      createdAt: oldMeta.createdAt,
      expiresAt: CacheExpirationCalculator.calculateExpiresAt(
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
      varyHeaders: oldMeta.varyHeaders,
    );
  }
}
