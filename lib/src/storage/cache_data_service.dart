import 'dart:typed_data';

import 'package:aero_cache/src/exceptions.dart';
import 'package:aero_cache/src/storage/cache_key_service.dart';
import 'package:aero_cache/src/storage/file_storage_service.dart';
import 'package:aero_cache/src/storage/metadata_service.dart';

/// Service for handling cache data operations
class CacheDataService {
  /// Create a new CacheDataService instance
  const CacheDataService(
    this._fileStorage,
    this._keyService,
    this._metadataService,
  );

  final FileStorageService _fileStorage;
  final CacheKeyService _keyService;
  final MetadataService _metadataService;

  /// Read cached data for a URL
  Future<Uint8List> readCacheData(String url) async {
    try {
      final filename = _keyService.getCacheFilename(url);
      if (!_fileStorage.fileExists(filename)) {
        throw AeroCacheException('Cache file not found for $url');
      }

      return await _fileStorage.readBinaryFile(filename);
    } catch (e) {
      throw AeroCacheException('Failed to read cache data for $url', e);
    }
  }

  /// Write cached data for a URL
  Future<void> writeCacheData(String url, Uint8List data) async {
    try {
      final filename = _keyService.getCacheFilename(url);
      await _fileStorage.writeBinaryFile(filename, data);
    } catch (e) {
      throw AeroCacheException('Failed to write cache data for $url', e);
    }
  }

  /// Read cached data for a URL with request headers (Vary-aware)
  Future<Uint8List> readCacheDataWithRequestHeaders(
    String url,
    Map<String, String> requestHeaders,
  ) async {
    // First try to read the regular meta file to get Vary headers
    final regularMeta = await _metadataService.readMeta(url);
    if (regularMeta == null || regularMeta.varyHeaders == null) {
      throw AeroCacheException('Cache file not found for $url');
    }

    try {
      final filename = _keyService.getVaryAwareCacheFilename(
        url,
        requestHeaders,
        regularMeta.varyHeaders!,
      );
      if (!_fileStorage.fileExists(filename)) {
        throw AeroCacheException('Cache file not found for $url');
      }

      return await _fileStorage.readBinaryFile(filename);
    } catch (e) {
      throw AeroCacheException('Failed to read cache data for $url', e);
    }
  }

  /// Write cached data for a URL with request headers (Vary-aware)
  Future<void> writeCacheDataWithRequestHeaders(
    String url,
    Uint8List data,
    Map<String, String> requestHeaders,
    List<String> varyHeaders,
  ) async {
    try {
      final filename = _keyService.getVaryAwareCacheFilename(
        url,
        requestHeaders,
        varyHeaders,
      );
      await _fileStorage.writeBinaryFile(filename, data);
    } catch (e) {
      throw AeroCacheException('Failed to write cache data for $url', e);
    }
  }
}
