import 'dart:typed_data';

import 'package:aero_cache/src/exceptions.dart';
import 'package:zstandard/zstandard.dart';

/// Handles data compression and decompression
class CacheCompression {
  /// Create a new CacheCompression instance
  CacheCompression({
    this.disableCompression = false,
    this.compressionLevel = 3,
  }) : assert(
          compressionLevel >= 1 && compressionLevel <= 22,
          'Compression level must be between 1 and 22',
        );

  /// Zstandard compression instance
  late final Zstandard _zstandard;

  /// Whether compression is disabled
  final bool disableCompression;

  /// Zstandard compression level
  final int compressionLevel;

  /// Initialize compression if not disabled
  void initialize() {
    if (!disableCompression) {
      _zstandard = Zstandard();
    }
  }

  /// Compress data for storage
  Future<Uint8List> compress(Uint8List rawData) async {
    try {
      if (disableCompression) {
        return rawData;
      }
      return await _zstandard.compress(rawData, compressionLevel) ?? rawData;
    } catch (e) {
      throw CompressionException('Failed to compress data', e);
    }
  }

  /// Decompress data from storage
  Future<Uint8List> decompress(Uint8List compressedData) async {
    try {
      if (disableCompression) {
        return Uint8List.fromList(compressedData);
      }
      final rawData =
          await _zstandard.decompress(compressedData) ?? compressedData;
      return Uint8List.fromList(rawData);
    } catch (e) {
      throw CompressionException('Failed to decompress data', e);
    }
  }
}
