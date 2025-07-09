import 'dart:io';
import 'dart:typed_data';

import 'package:aero_cache/src/cache_manager.dart';
import 'package:aero_cache/src/exceptions.dart';
import 'package:aero_cache/src/meta_info.dart';

export 'src/exceptions.dart';
export 'src/meta_info.dart';

/// Callback function for progress updates during download
typedef ProgressCallback = void Function(int received, int total);

/// High-performance cache library for Dart/Flutter with zstd compression
class AeroCache {
  /// Create a new AeroCache instance
  ///
  /// [httpClient] - Optional HTTP client to use for requests
  /// [disableCompression] - Whether to disable zstd compression
  /// [cacheDirPath] - Optional custom cache directory path
  AeroCache({
    HttpClient? httpClient,
    bool disableCompression = false,
    String? cacheDirPath,
  }) : _cacheManager = CacheManager(
         disableCompression: disableCompression,
         cacheDirPath: cacheDirPath,
       ),
       _httpClient = httpClient ?? HttpClient();

  /// Internal cache manager instance
  final CacheManager _cacheManager;

  /// HTTP client for network requests
  final HttpClient _httpClient;

  /// Initialize the cache manager and clear expired cache
  Future<void> initialize() async {
    await _cacheManager.initialize();
    await _cacheManager.clearExpiredCache();
  }

  /// Get data from cache or download if not available/stale
  Future<Uint8List> get(String url, {ProgressCallback? onProgress}) async {
    try {
      final meta = await _cacheManager.getMeta(url);

      if (meta != null && !meta.isStale) {
        return await _cacheManager.getData(url);
      }

      return await _downloadAndCache(url, meta, onProgress);
    } catch (e) {
      if (e is AeroCacheException) {
        rethrow;
      }
      throw AeroCacheException('Failed to get data for $url', e);
    }
  }

  Future<Uint8List> _downloadAndCache(
    String url,
    MetaInfo? meta,
    ProgressCallback? onProgress,
  ) async {
    try {
      final uri = Uri.parse(url);
      final request = await _httpClient.getUrl(uri);

      if (meta != null && meta.isStale) {
        if (meta.etag != null) {
          request.headers.add('If-None-Match', meta.etag!);
        }
        if (meta.lastModified != null) {
          request.headers.add('If-Modified-Since', meta.lastModified!);
        }
      }

      final response = await request.close();

      if (response.statusCode == 304) {
        await _cacheManager.updateMeta(url, response.headers);
        return await _cacheManager.getData(url);
      }

      if (response.statusCode != 200) {
        throw AeroCacheException('HTTP ${response.statusCode} for $url');
      }

      final contentLength = response.contentLength;
      final chunks = <List<int>>[];
      var received = 0;

      await for (final chunk in response) {
        chunks.add(chunk);
        received += chunk.length;

        if (onProgress != null && contentLength > 0) {
          onProgress(received, contentLength);
        }
      }

      final data = Uint8List.fromList(chunks.expand((x) => x).toList());
      await _cacheManager.saveData(url, data, response.headers);

      return data;
    } catch (e) {
      if (e is AeroCacheException) {
        rethrow;
      }
      throw AeroCacheException('Failed to download $url', e);
    }
  }

  /// Clear all cached data
  Future<void> clearAllCache() => _cacheManager.clearAllCache();

  /// Clear expired cache entries
  Future<void> clearExpiredCache() => _cacheManager.clearExpiredCache();

  /// Get metadata information for a URL
  Future<MetaInfo?> metaInfo(String url) => _cacheManager.getMeta(url);

  /// Dispose of resources
  void dispose() {
    _httpClient.close();
  }
}
