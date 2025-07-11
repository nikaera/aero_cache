import 'dart:io';
import 'dart:typed_data';

import 'package:aero_cache/src/exceptions.dart';

/// Basic file storage operations service
class FileStorageService {
  /// Create a new FileStorageService instance
  const FileStorageService(this.cacheDirectory);

  /// Cache directory instance
  final Directory cacheDirectory;

  /// Check if a file exists
  bool fileExists(String filename) {
    final file = File('${cacheDirectory.path}/$filename');
    return file.existsSync();
  }

  /// Read binary data from a file
  Future<Uint8List> readBinaryFile(String filename) async {
    try {
      final file = File('${cacheDirectory.path}/$filename');
      if (!file.existsSync()) {
        throw AeroCacheException('File not found: $filename');
      }
      return await file.readAsBytes();
    } catch (e) {
      throw AeroCacheException('Failed to read file: $filename', e);
    }
  }

  /// Write binary data to a file
  Future<void> writeBinaryFile(String filename, Uint8List data) async {
    try {
      final file = File('${cacheDirectory.path}/$filename');
      await file.writeAsBytes(data);
    } catch (e) {
      throw AeroCacheException('Failed to write file: $filename', e);
    }
  }

  /// Read text data from a file
  Future<String> readTextFile(String filename) async {
    try {
      final file = File('${cacheDirectory.path}/$filename');
      if (!file.existsSync()) {
        throw AeroCacheException('File not found: $filename');
      }
      return await file.readAsString();
    } catch (e) {
      throw AeroCacheException('Failed to read file: $filename', e);
    }
  }

  /// Write text data to a file
  Future<void> writeTextFile(String filename, String content) async {
    try {
      final file = File('${cacheDirectory.path}/$filename');
      await file.writeAsString(content);
    } catch (e) {
      throw AeroCacheException('Failed to write file: $filename', e);
    }
  }

  /// Delete a file
  Future<void> deleteFile(String filename) async {
    try {
      final file = File('${cacheDirectory.path}/$filename');
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (e) {
      throw AeroCacheException('Failed to delete file: $filename', e);
    }
  }

  /// List all files in the cache directory
  Stream<FileSystemEntity> listFiles() {
    if (!cacheDirectory.existsSync()) {
      return const Stream.empty();
    }
    return cacheDirectory.list();
  }

  /// Delete all files in the cache directory
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
      throw AeroCacheException('Failed to clear all files', e);
    }
  }
}
