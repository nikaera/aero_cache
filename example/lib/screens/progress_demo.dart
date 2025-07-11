import 'package:flutter/material.dart';
import 'package:aero_cache/aero_cache.dart';

class ProgressDemo extends StatefulWidget {
  final AeroCache aeroCache;

  const ProgressDemo({super.key, required this.aeroCache});

  @override
  State<ProgressDemo> createState() => _ProgressDemoState();
}

class _ProgressDemoState extends State<ProgressDemo> {
  final TextEditingController _urlController = TextEditingController();
  double _progress = 0.0;
  bool _isDownloading = false;
  String _status = 'Ready to download';
  int _totalBytes = 0;

  final List<String> _largeFileUrls = [
    'https://www.sample-videos.com/video321/mp4/720/big_buck_bunny_720p_20mb.mp4',
    'https://www.sample-videos.com/img/Sample-png-image-3mb.png',
  ];

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _downloadWithProgress([String? url]) async {
    final urlToUse = url ?? _urlController.text.trim();
    if (urlToUse.isEmpty) return;

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _status = 'Starting download...';
      _totalBytes = 0;
    });

    try {
      await widget.aeroCache.get(
        urlToUse,
        onProgress: (received, total) {
          setState(() {
            _totalBytes = total;
            _progress = total > 0 ? received / total : 0.0;
            _status =
                'Downloaded ${_formatBytes(received)} / ${_formatBytes(total)}';
          });
        },
      );

      setState(() {
        _status = 'Download completed!';
        _isDownloading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isDownloading = false;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _calculateSpeed() {
    return '---';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Tracking Demo'),
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
                labelText: 'File URL',
                hintText: 'Enter URL or use sample files below',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isDownloading ? null : () => _downloadWithProgress(),
              child: const Text('Download with Progress'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sample Large Files:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _isDownloading
                        ? null
                        : () => _downloadWithProgress(_largeFileUrls[0]),
                    child: const Text('Video File (20MB)'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isDownloading
                        ? null
                        : () => _downloadWithProgress(_largeFileUrls[1]),
                    child: const Text('Large Image (3MB)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Flexible(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Download Progress:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${(_progress * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: Text(
                          _status,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      if (_totalBytes > 0) ...[
                        const SizedBox(height: 8),
                        Text('Speed: ${_calculateSpeed()} KB/s'),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
