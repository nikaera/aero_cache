import 'package:flutter/material.dart';
import 'package:aero_cache/aero_cache.dart';

class AdvancedFeaturesDemo extends StatefulWidget {
  final AeroCache aeroCache;

  const AdvancedFeaturesDemo({super.key, required this.aeroCache});

  @override
  State<AdvancedFeaturesDemo> createState() => _AdvancedFeaturesDemoState();
}

class _AdvancedFeaturesDemoState extends State<AdvancedFeaturesDemo> {
  final TextEditingController _urlController = TextEditingController();
  final Map<String, String> _requestHeaders = {};
  String _result = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testAdvancedFeatures() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isLoading = true;
      _result = 'Testing advanced features...';
    });

    try {
      final data = await widget.aeroCache.get(
        url,
        headers: _requestHeaders.isNotEmpty ? _requestHeaders : null,
        maxAge: 300,
      );

      final metaInfo = await widget.aeroCache.metaInfo(url);

      setState(() {
        _result =
            '''
Advanced Features Test Result:

Data Size: ${data.length} bytes
ETag: ${metaInfo?.etag ?? 'None'}
Last Modified: ${metaInfo?.lastModified ?? 'None'}
Content Type: ${metaInfo?.contentType ?? 'Unknown'}
Requires Revalidation: ${metaInfo?.requiresRevalidation ?? false}
Stale While Revalidate: ${metaInfo?.staleWhileRevalidate ?? 'None'}
Stale If Error: ${metaInfo?.staleIfError ?? 'None'}
Must Revalidate: ${metaInfo?.mustRevalidate ?? false}
Vary Headers: ${metaInfo?.varyHeaders?.join(', ') ?? 'None'}

Request Headers Used:
${_requestHeaders.entries.map((e) => '${e.key}: ${e.value}').join('\n')}
''';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _addHeader() {
    showDialog(
      context: context,
      builder: (context) {
        String key = '';
        String value = '';
        return AlertDialog(
          title: const Text('Add Request Header'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Header Name'),
                onChanged: (v) => key = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Header Value'),
                onChanged: (v) => value = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (key.isNotEmpty && value.isNotEmpty) {
                  setState(() {
                    _requestHeaders[key] = value;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Features'),
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
                labelText: 'API URL',
                hintText: 'Enter URL to test advanced features',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Request Headers:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: _addHeader,
                          child: const Text('Add Header'),
                        ),
                      ],
                    ),
                    if (_requestHeaders.isEmpty)
                      const Text('No headers added')
                    else
                      Column(
                        children: _requestHeaders.entries.map((entry) {
                          return Row(
                            children: [
                              Expanded(
                                child: Text('${entry.key}: ${entry.value}'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _requestHeaders.remove(entry.key);
                                  });
                                },
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testAdvancedFeatures,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Test Advanced Features'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    child: Text(
                      _result.isEmpty
                          ? 'Test results will appear here...'
                          : _result,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
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
