import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:aero_cache/src/cache_control_parser.dart';
import 'package:aero_cache/src/cache_manager.dart';
import 'package:aero_cache/src/exceptions.dart';
import 'package:aero_cache/src/meta_info.dart';

export 'src/exceptions.dart';
export 'src/meta_info.dart';

/// Callback function for progress updates during download
typedef ProgressCallback = void Function(int received, int total);

/// Download queue item for managing background downloads
class _DownloadQueueItem {
  _DownloadQueueItem(this.url, this.meta, this.onProgress, this.headers);
  final String url;
  final MetaInfo? meta;
  final ProgressCallback? onProgress;
  final Map<String, String>? headers;
}

/// High-performance cache library for Dart/Flutter with zstd compression
class AeroCache {
  /// Create a new AeroCache instance
  ///
  /// [httpClient] - Optional HTTP client to use for requests
  /// [disableCompression] - Whether to disable zstd compression
  /// [cacheDirPath] - Optional custom cache directory path
  /// [compressionLevel] - Compression level for zstd (1-22)
  /// [defaultCacheDuration] - Default duration for cached items
  ///   (default is 5 days)
  /// Throws [AeroCacheException] if initialization fails.
  AeroCache({
    HttpClient? httpClient,
    bool disableCompression = false,
    int compressionLevel = 3,
    Duration defaultCacheDuration = const Duration(days: 5),
    String? cacheDirPath,
  })  : _cacheManager = CacheManager(
          disableCompression: disableCompression,
          compressionLevel: compressionLevel,
          defaultCacheDuration: defaultCacheDuration,
          cacheDirPath: cacheDirPath,
        ),
        _httpClient = httpClient ?? HttpClient();

  /// Internal cache manager instance
  final CacheManager _cacheManager;

  /// HTTP client for network requests
  final HttpClient _httpClient;

  /// Download queue for managing background downloads
  final Queue<_DownloadQueueItem> _downloadQueue = Queue<_DownloadQueueItem>();

  /// Currently active download futures
  final Set<Future<void>> _activeDownloads = <Future<void>>{};

  /// Maximum number of concurrent downloads
  static const int _maxConcurrentDownloads = 5;

  /// Initialize the cache manager and clear expired cache
  Future<void> initialize() async {
    await _cacheManager.initialize();
    await _cacheManager.clearExpiredCache();
  }

  /// Retrieves data from cache or downloads if not available/stale.
  ///
  /// This method implements HTTP caching semantics including:
  /// - Cache-Control directive handling
  /// - ETag/Last-Modified revalidation
  /// - Stale-while-revalidate support
  /// - Background cache updates
  ///
  /// ## Parameters
  /// - [url]: The URL to fetch data from
  /// - [onProgress]: Optional callback for download progress updates
  /// - [noCache]: If true, bypasses cache and always fetches fresh data
  /// - [maxAge]: Maximum age in seconds for cached content
  /// - [maxStale]: Maximum staleness in seconds that's acceptable
  /// - [minFresh]: Minimum freshness in seconds required
  /// - [onlyIfCached]: If true, only returns cached data (throws if not cached)
  /// - [noStore]: If true, downloads without caching the response
  /// - [headers]: Additional request headers to include
  ///
  /// ## Examples
  /// ```dart
  /// // Basic usage
  /// final data = await cache.get('https://api.example.com/data');
  ///
  /// // With cache control
  /// final data = await cache.get(
  ///   'https://api.example.com/data',
  ///   maxAge: 3600, // Cache for 1 hour max
  ///   onProgress: (received, total) => print('$received/$total'),
  /// );
  ///
  /// // Only use cache, don't fetch if not available
  /// try {
  ///   final data = await cache.get(
  ///     'https://api.example.com/data',
  ///     onlyIfCached: true,
  ///   );
  /// } catch (e) {
  ///   print('No cached data available');
  /// }
  ///
  /// // Download without caching
  /// final data = await cache.get(
  ///   'https://api.example.com/data',
  ///   noStore: true,
  /// );
  /// ```
  ///
  /// ## Throws
  /// - [NetworkException] when network requests fail
  /// - [AeroCacheException] when cache operations fail
  /// - [ValidationException] when parameters are invalid
  Future<Uint8List> get(
    String url, {
    ProgressCallback? onProgress,
    bool noCache = false,
    int? maxAge,
    int? maxStale,
    int? minFresh,
    bool onlyIfCached = false,
    bool noStore = false,
    Map<String, String>? headers,
  }) async {
    try {
      final meta = headers != null
          ? await _cacheManager.getMetaWithRequestHeaders(url, headers)
          : await _cacheManager.getMeta(url);

      // Handle only-if-cached directive
      if (onlyIfCached) {
        if (meta == null) {
          throw AeroCacheException('No cached response available for $url');
        }
        return headers != null
            ? await _cacheManager.getDataWithRequestHeaders(url, headers)
            : await _cacheManager.getData(url);
      }

      if (meta != null && !noCache) {
        // Check for max-age request directive
        if (maxAge != null && !meta.isOlderThan(maxAge)) {
          // Cache is older than maxAge, revalidate with server
          return await _downloadAndCache(url, meta, onProgress, headers);
        }

        // min-fresh requirement check
        if (minFresh != null && !meta.hasMinimumFreshness(minFresh)) {
          // Not fresh enough, must fetch new data
          return await _downloadAndCache(url, meta, onProgress, headers);
        }

        // Check if stale data is acceptable within max-stale tolerance
        if (maxStale != null && meta.isWithinStalePeriod(maxStale)) {
          return headers != null
              ? await _cacheManager.getDataWithRequestHeaders(url, headers)
              : await _cacheManager.getData(url);
        }

        // Return stale data and update cache in the background (SWR)
        if (await _cacheManager.needsBackgroundRevalidation(url)) {
          final staleData = await _cacheManager.getStaleData(url);
          if (staleData != null) {
            // Update cache in the background using download queue
            _queueDownload(url, meta, onProgress, headers);
            return staleData;
          }
        }

        // Check if we can use cached data
        if (!meta.isStale && !meta.requiresRevalidation) {
          return headers != null
              ? await _cacheManager.getDataWithRequestHeaders(url, headers)
              : await _cacheManager.getData(url);
        }
      }

      // Handle no-store directive - download only without caching
      if (noStore) {
        return await _downloadOnly(url, onProgress, headers);
      }

      return await _downloadAndCache(url, meta, onProgress, headers);
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
    Map<String, String>? requestHeaders,
  ) async {
    try {
      final uri = Uri.parse(url);
      final request = await _httpClient.getUrl(uri);

      // Add request headers if provided
      if (requestHeaders != null) {
        requestHeaders.forEach((key, value) {
          request.headers.add(key, value);
        });
      }

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
        // Try to serve stale data on error if stale-if-error allows
        final staleData = await _cacheManager.getStaleDataOnError(url);
        if (staleData != null) {
          return staleData;
        }
        throw NetworkException.withDetails(
          'HTTP error',
          url,
          response.statusCode,
        );
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

      // Check if no-store directive or Vary: * prevents caching
      if (!CacheControlParser.hasNoStore(response.headers) &&
          !CacheControlParser.hasVaryAsterisk(response.headers)) {
        if (requestHeaders != null) {
          await _cacheManager.saveDataWithRequestHeaders(
            url,
            data,
            response.headers,
            requestHeaders,
          );
        } else {
          await _cacheManager.saveData(url, data, response.headers);
        }
      }

      return data;
    } catch (e) {
      // Try to serve stale data on error if stale-if-error allows
      if (e is! AeroCacheException) {
        final staleData = await _cacheManager.getStaleDataOnError(url);
        if (staleData != null) {
          return staleData;
        }
      }

      if (e is AeroCacheException) {
        rethrow;
      }
      throw AeroCacheException('Failed to download $url', e);
    }
  }

  Future<Uint8List> _downloadOnly(
    String url,
    ProgressCallback? onProgress,
    Map<String, String>? requestHeaders,
  ) async {
    try {
      final uri = Uri.parse(url);
      final request = await _httpClient.getUrl(uri);

      // Add request headers if provided
      if (requestHeaders != null) {
        requestHeaders.forEach((key, value) {
          request.headers.add(key, value);
        });
      }

      final response = await request.close();

      if (response.statusCode != 200) {
        throw NetworkException.withDetails(
          'HTTP error',
          url,
          response.statusCode,
        );
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

      return Uint8List.fromList(chunks.expand((x) => x).toList());
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

  /// Queue a download for background processing
  void _queueDownload(
    String url,
    MetaInfo? meta,
    ProgressCallback? onProgress,
    Map<String, String>? headers,
  ) {
    _downloadQueue.add(_DownloadQueueItem(url, meta, onProgress, headers));
    _processDownloadQueue();
  }

  /// Process the download queue with concurrency limits
  void _processDownloadQueue() {
    while (_downloadQueue.isNotEmpty &&
        _activeDownloads.length < _maxConcurrentDownloads) {
      final item = _downloadQueue.removeFirst();
      late Future<void> downloadFuture;

      downloadFuture = _downloadAndCache(
        item.url,
        item.meta,
        item.onProgress,
        item.headers,
      ).then((_) {}).catchError((error) {
        print('Download failed for URL ${item.url}: $error');
      }).whenComplete(() {
        _activeDownloads.remove(downloadFuture);
        // Process next item in queue if available
        if (_downloadQueue.isNotEmpty) {
          _processDownloadQueue();
        }
      });

      _activeDownloads.add(downloadFuture);
    }
  }

  /// Dispose of resources
  void dispose() {
    _httpClient.close();
  }
}
