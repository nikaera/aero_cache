import 'dart:io';

import 'package:aero_cache/src/exceptions.dart';
import 'package:aero_cache/src/meta_info.dart';
import 'package:aero_cache/src/storage/file_storage_service.dart';

/// Service for cache cleanup operations
class CacheCleanupService {
  /// Create a new CacheCleanupService instance
  const CacheCleanupService(this._fileStorage);

  final FileStorageService _fileStorage;

  /// Delete all cache and meta files in the cache directory
  Future<void> clearAllFiles() async {
    return _fileStorage.clearAllFiles();
  }

  /// Delete all expired cache (.meta) and data files
  Future<void> clearExpiredFiles() async {
    try {
      final files = _fileStorage.listFiles();
      await for (final file in files) {
        if (file is File && file.path.endsWith('.meta')) {
          try {
            final metaContent = await file.readAsString();
            final meta = MetaInfo.fromJsonString(metaContent);
            if (meta.isStale) {
              // Delete cache data file
              final cacheFile = File(file.path.replaceAll('.meta', '.cache'));
              if (cacheFile.existsSync()) {
                await cacheFile.delete();
              }
              // Delete meta file
              await file.delete();
            }
          } on Exception catch (_) {
            // Skip files that can't be read or parsed
            continue;
          }
        }
      }
    } catch (e) {
      throw AeroCacheException('Failed to clear expired cache files', e);
    }
  }
}
