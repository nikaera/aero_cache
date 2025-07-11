import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:aero_cache/aero_cache.dart';

class ImageCacheDemo extends StatefulWidget {
  final AeroCache aeroCache;

  const ImageCacheDemo({super.key, required this.aeroCache});

  @override
  State<ImageCacheDemo> createState() => _ImageCacheDemoState();
}

class _ImageCacheDemoState extends State<ImageCacheDemo> {
  final TextEditingController _urlController = TextEditingController();
  Uint8List? _imageData;
  MetaInfo? _metaInfo;
  bool _isLoading = false;
  String? _error;

  final List<String> _sampleUrls = [
    'https://picsum.photos/300/200?random=1',
    'https://picsum.photos/300/200?random=2',
    'https://picsum.photos/300/200?random=3',
  ];

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _downloadImage([String? url]) async {
    final urlToUse = url ?? _urlController.text.trim();
    if (urlToUse.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await widget.aeroCache.get(urlToUse);
      final metaInfo = await widget.aeroCache.metaInfo(urlToUse);

      setState(() {
        _imageData = data;
        _metaInfo = metaInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Caching Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                hintText: 'Enter image URL or use sample images below',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _downloadImage(),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Download Image'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Sample Images:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _sampleUrls.map((url) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton(
                      onPressed: () => _downloadImage(url),
                      child: Text('Sample ${_sampleUrls.indexOf(url) + 1}'),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (_error != null)
                      Card(
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Error: $_error',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ),
                    if (_imageData != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.memory(_imageData!),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_metaInfo != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cache Metadata:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text('ETag: ${_metaInfo!.etag ?? 'None'}'),
                              Text(
                                'Last Modified: ${_metaInfo!.lastModified ?? 'None'}',
                              ),
                              Text(
                                'Content Type: ${_metaInfo!.contentType ?? 'Unknown'}',
                              ),
                              Text(
                                'Content Length: ${_metaInfo!.contentLength} bytes',
                              ),
                              Text('Created At: ${_metaInfo!.createdAt}'),
                              Text('Expires At: ${_metaInfo!.expiresAt}'),
                              Text('Is Stale: ${_metaInfo!.isStale}'),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
