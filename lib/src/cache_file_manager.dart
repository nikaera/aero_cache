import 'dart:io';
import 'dart:typed_data';

import 'package:aero_cache/src/cache_url_hasher.dart';
import 'package:aero_cache/src/meta_info.dart';
import 'package:aero_cache/src/storage/cache_cleanup_service.dart';
import 'package:aero_cache/src/storage/cache_data_service.dart';
import 'package:aero_cache/src/storage/cache_key_service.dart';
import 'package:aero_cache/src/storage/file_storage_service.dart';
import 'package:aero_cache/src/storage/metadata_service.dart';

/// Handles file operations for cache and metadata files
class CacheFileManager {
  /// Create a new CacheFileManager instance
  CacheFileManager(this.cacheDirectory)
      : _fileStorage = FileStorageService(cacheDirectory),
        _keyService = const CacheKeyService() {
    _metadataService = MetadataService(_fileStorage, _keyService);
    _dataService = CacheDataService(
      _fileStorage,
      _keyService,
      _metadataService,
    );
    _cleanupService = CacheCleanupService(_fileStorage);
  }

  /// Cache directory instance
  final Directory cacheDirectory;

  final FileStorageService _fileStorage;
  final CacheKeyService _keyService;
  late final MetadataService _metadataService;
  late final CacheDataService _dataService;
  late final CacheCleanupService _cleanupService;

  /// Get the cache file for a URL
  File getCacheFile(String url) {
    final hash = CacheUrlHasher.getUrlHash(url);
    return File('${cacheDirectory.path}/$hash.cache');
  }

  /// Get the metadata file for a URL
  File getMetaFile(String url) {
    final hash = CacheUrlHasher.getUrlHash(url);
    return File('${cacheDirectory.path}/$hash.meta');
  }

  /// Read metadata information for a URL
  Future<MetaInfo?> readMeta(String url) async {
    return _metadataService.readMeta(url);
  }

  /// Write metadata information for a URL
  Future<void> writeMeta(String url, MetaInfo metaInfo) async {
    return _metadataService.writeMeta(url, metaInfo);
  }

  /// Read cached data for a URL
  Future<Uint8List> readCacheData(String url) async {
    return _dataService.readCacheData(url);
  }

  /// Write cached data for a URL
  Future<void> writeCacheData(String url, Uint8List data) async {
    return _dataService.writeCacheData(url, data);
  }

  /// Delete all cache and meta files in the cache directory
  Future<void> clearAllFiles() async {
    return _cleanupService.clearAllFiles();
  }

  /// Delete all expired cache (.meta) and data files
  Future<void> clearExpiredFiles() async {
    return _cleanupService.clearExpiredFiles();
  }

  /// Get the cache file for a URL with request headers (Vary-aware)
  File getCacheFileWithRequestHeaders(
    String url,
    Map<String, String> requestHeaders,
    List<String> varyHeaders,
  ) {
    final hash = CacheUrlHasher.getVaryAwareUrlHash(
      url,
      requestHeaders,
      varyHeaders,
    );
    return File('${cacheDirectory.path}/$hash.cache');
  }

  /// Get the metadata file for a URL with request headers (Vary-aware)
  File getMetaFileWithRequestHeaders(
    String url,
    Map<String, String> requestHeaders,
    List<String> varyHeaders,
  ) {
    final hash = CacheUrlHasher.getVaryAwareUrlHash(
      url,
      requestHeaders,
      varyHeaders,
    );
    return File('${cacheDirectory.path}/$hash.meta');
  }

  /// Read metadata information for a URL with request headers
  Future<MetaInfo?> readMetaWithRequestHeaders(
    String url,
    Map<String, String> requestHeaders,
  ) async {
    return _metadataService.readMetaWithRequestHeaders(url, requestHeaders);
  }

  /// Write metadata information for a URL with request headers
  Future<void> writeMetaWithRequestHeaders(
    String url,
    MetaInfo metaInfo,
    Map<String, String> requestHeaders,
    List<String> varyHeaders,
  ) async {
    return _metadataService.writeMetaWithRequestHeaders(
      url,
      metaInfo,
      requestHeaders,
      varyHeaders,
    );
  }

  /// Read cached data for a URL with request headers
  Future<Uint8List> readCacheDataWithRequestHeaders(
    String url,
    Map<String, String> requestHeaders,
  ) async {
    return _dataService.readCacheDataWithRequestHeaders(url, requestHeaders);
  }

  /// Write cached data for a URL with request headers
  Future<void> writeCacheDataWithRequestHeaders(
    String url,
    Uint8List data,
    Map<String, String> requestHeaders,
    List<String> varyHeaders,
  ) async {
    return _dataService.writeCacheDataWithRequestHeaders(
      url,
      data,
      requestHeaders,
      varyHeaders,
    );
  }
}
