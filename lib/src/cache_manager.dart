import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aero_cache/src/exceptions.dart';
import 'package:aero_cache/src/meta_info.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zstandard/zstandard.dart';

/// Zstandard compression level
const int kZstdCompressionLevel = 3;

/// Manages cache files and metadata
class CacheManager {
  /// Create a new CacheManager instance
  CacheManager({this.disableCompression = false, this.cacheDirPath});

  /// Cache directory instance
  late final Directory _cacheDirectory;

  /// Zstandard compression instance
  late final Zstandard _zstandard;

  /// Whether compression is disabled
  final bool disableCompression;

  /// Optional custom cache directory path
  final String? cacheDirPath;

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
      if (!disableCompression) {
        _zstandard = Zstandard();
      }
      if (!_cacheDirectory.existsSync()) {
        await _cacheDirectory.create(recursive: true);
      }
    } catch (e) {
      throw AeroCacheException('Failed to initialize cache directory', e);
    }
  }

  /// Get metadata information for a URL
  Future<MetaInfo?> getMeta(String url) async {
    try {
      final metaFile = _getMetaFile(url);
      if (!metaFile.existsSync()) {
        return null;
      }

      final metaContent = await metaFile.readAsString();
      return MetaInfo.fromJsonString(metaContent);
    } catch (e) {
      throw AeroCacheException('Failed to read meta information for $url', e);
    }
  }

  /// Get cached data for a URL
  Future<Uint8List> getData(String url) async {
    try {
      final cacheFile = _getCacheFile(url);
      if (!cacheFile.existsSync()) {
        throw AeroCacheException('Cache file not found for $url');
      }

      final compressedData = await cacheFile.readAsBytes();
      if (disableCompression) {
        return Uint8List.fromList(compressedData);
      }
      final rawData =
          await _zstandard.decompress(compressedData) ?? compressedData;
      return Uint8List.fromList(rawData);
    } catch (e) {
      throw AeroCacheException('Failed to read cache data for $url', e);
    }
  }

  /// Save data to cache with compression
  Future<void> saveData(
    String url,
    Uint8List rawData,
    HttpHeaders headers,
  ) async {
    try {
      final cacheFile = _getCacheFile(url);
      final metaFile = _getMetaFile(url);
      Uint8List dataToWrite;
      if (disableCompression) {
        dataToWrite = rawData;
      } else {
        dataToWrite =
            await _zstandard.compress(rawData, kZstdCompressionLevel) ??
            rawData;
      }
      debugPrint(
        'Saving cache for $url, '
        'compressionRatio: ${dataToWrite.length/rawData.length}',
      );
      final metaInfo = MetaInfo(
        url: url,
        etag: headers.value('etag'),
        lastModified: headers.value('last-modified'),
        createdAt: DateTime.now(),
        expiresAt: _calculateExpiresAt(headers),
        contentLength: rawData.length,
        contentType: headers.value('content-type'),
      );
      await Future.wait([
        cacheFile.writeAsBytes(dataToWrite),
        metaFile.writeAsString(metaInfo.toJsonString()),
      ]);
    } catch (e) {
      throw AeroCacheException('Failed to save cache data for $url', e);
    }
  }

  /// Update metadata for a URL
  Future<void> updateMeta(String url, HttpHeaders headers) async {
    try {
      final metaFile = _getMetaFile(url);
      if (!metaFile.existsSync()) return;
      final metaContent = await metaFile.readAsString();
      final oldMeta = MetaInfo.fromJsonString(metaContent);
      final newMeta = MetaInfo(
        url: oldMeta.url,
        etag: headers.value('etag') ?? oldMeta.etag,
        lastModified: headers.value('last-modified') ?? oldMeta.lastModified,
        createdAt: oldMeta.createdAt,
        expiresAt: _calculateExpiresAt(headers) ?? oldMeta.expiresAt,
        contentLength: oldMeta.contentLength,
        contentType: headers.value('content-type') ?? oldMeta.contentType,
      );
      await metaFile.writeAsString(newMeta.toJsonString());
    } catch (e) {
      throw AeroCacheException('Failed to update meta for $url', e);
    }
  }

  DateTime? _calculateExpiresAt(HttpHeaders headers) {
    final cacheControl = headers.value('cache-control');
    if (cacheControl != null) {
      final maxAgeMatch = RegExp(r'max-age=(\d+)').firstMatch(cacheControl);
      if (maxAgeMatch != null) {
        final maxAge = int.parse(maxAgeMatch.group(1)!);
        return DateTime.now().add(Duration(seconds: maxAge));
      }
    }

    final expires = headers.value('expires');
    if (expires != null) {
      return HttpDate.parse(expires);
    }

    // デフォルトで1時間のキャッシュ
    return DateTime.now().add(const Duration(hours: 1));
  }

  String _getUrlHash(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  File _getCacheFile(String url) {
    final hash = _getUrlHash(url);
    return File('${_cacheDirectory.path}/$hash.cache');
  }

  File _getMetaFile(String url) {
    final hash = _getUrlHash(url);
    return File('${_cacheDirectory.path}/$hash.meta');
  }

  /// Delete all cache and meta files in the cache directory
  Future<void> clearAllCache() async {
    try {
      if (!_cacheDirectory.existsSync()) return;
      final files = _cacheDirectory.list();
      await for (final file in files) {
        if (file is File) {
          await file.delete();
        }
      }
    } catch (e) {
      throw AeroCacheException('Failed to clear all cache', e);
    }
  }

  /// Delete all expired cache (.meta) and data files
  Future<void> clearExpiredCache() async {
    try {
      if (!_cacheDirectory.existsSync()) return;
      final files = _cacheDirectory.list();
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
      throw AeroCacheException('Failed to clear expired cache', e);
    }
  }
}
