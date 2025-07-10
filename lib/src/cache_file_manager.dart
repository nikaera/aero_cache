import 'dart:io';
import 'dart:typed_data';

import 'package:aero_cache/src/cache_url_hasher.dart';
import 'package:aero_cache/src/exceptions.dart';
import 'package:aero_cache/src/meta_info.dart';

/// Handles file operations for cache and metadata files
class CacheFileManager {
  /// Create a new CacheFileManager instance
  const CacheFileManager(this.cacheDirectory);

  /// Cache directory instance
  final Directory cacheDirectory;

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
    try {
      final metaFile = getMetaFile(url);
      if (!metaFile.existsSync()) {
        return null;
      }

      final metaContent = await metaFile.readAsString();
      return MetaInfo.fromJsonString(metaContent);
    } catch (e) {
      throw AeroCacheException('Failed to read meta information for $url', e);
    }
  }

  /// Write metadata information for a URL
  Future<void> writeMeta(String url, MetaInfo metaInfo) async {
    try {
      final metaFile = getMetaFile(url);
      await metaFile.writeAsString(metaInfo.toJsonString());
    } catch (e) {
      throw AeroCacheException('Failed to write meta information for $url', e);
    }
  }

  /// Read cached data for a URL
  Future<Uint8List> readCacheData(String url) async {
    try {
      final cacheFile = getCacheFile(url);
      if (!cacheFile.existsSync()) {
        throw AeroCacheException('Cache file not found for $url');
      }

      return await cacheFile.readAsBytes();
    } catch (e) {
      throw AeroCacheException('Failed to read cache data for $url', e);
    }
  }

  /// Write cached data for a URL
  Future<void> writeCacheData(String url, Uint8List data) async {
    try {
      final cacheFile = getCacheFile(url);
      await cacheFile.writeAsBytes(data);
    } catch (e) {
      throw AeroCacheException('Failed to write cache data for $url', e);
    }
  }

  /// Delete all cache and meta files in the cache directory
  Future<void> clearAllFiles() async {
    try {
      if (!cacheDirectory.existsSync()) return;
      final files = cacheDirectory.list();
      await for (final file in files) {
        if (file is File) {
          await file.delete();
        }
      }
    } catch (e) {
      throw AeroCacheException('Failed to clear all cache files', e);
    }
  }

  /// Delete all expired cache (.meta) and data files
  Future<void> clearExpiredFiles() async {
    try {
      if (!cacheDirectory.existsSync()) return;
      final files = cacheDirectory.list();
      await for (final file in files) {
        if (file is File && file.path.endsWith('.meta')) {
          try {
            final metaContent = await file.readAsString();
            final meta = MetaInfo.fromJsonString(metaContent);
            if (meta.isStale) {
              // キャッシュデータファイルも削除
              final cacheFile = File(file.path.replaceAll('.meta', '.cache'));
              if (cacheFile.existsSync()) {
                await cacheFile.delete();
              }
              await file.delete();
            }
          } on Exception catch (_) {
            // 読み込み失敗やパース失敗はスキップ
            continue;
          }
        }
      }
    } catch (e) {
      throw AeroCacheException('Failed to clear expired cache files', e);
    }
  }
}
