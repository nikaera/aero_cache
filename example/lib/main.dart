import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:aero_cache/aero_cache.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AeroCache Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
      ),
      home: MyHomePage(title: 'AeroCache Demo Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({super.key, required this.title});

  final String title;
  final AeroCache aeroCache = AeroCache();

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String fileUrl = '';
  Uint8List? fileData;
  MetaInfo? fileMetaInfo;

  @override
  void initState() {
    super.initState();
    widget.aeroCache
        .initialize()
        .then((_) {
          // Initialization complete, you can now use the AeroCache instance.
          debugPrint('AeroCache initialized');
        })
        .catchError((error) {
          debugPrint('Error initializing AeroCache: $error');
        });
  }

  @override
  void dispose() {
    widget.aeroCache.dispose();
    super.dispose();
  }

  Future<void> _handleDownload() async {
    final rawData = await widget.aeroCache.get(
      fileUrl,
      onProgress: (received, total) => debugPrint("$received/$total"),
    );
    final metaInfo = await widget.aeroCache.metaInfo(fileUrl);
    debugPrint('File downloaded: $fileUrl, ${metaInfo?.toJsonString()}');
    final contentType = metaInfo?.contentType ?? 'unknown';

    // 動画の場合はVideoPlayerControllerを初期化
    if (contentType.startsWith('image/')) {
      setState(() {
        fileData = rawData as Uint8List?;
        fileMetaInfo = metaInfo;
      });
    } else {
      setState(() {
        fileData = null;
        fileMetaInfo = metaInfo;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentType = fileMetaInfo?.contentType ?? 'unknown';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: widget.aeroCache.clearAllCache,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter a file URL',
              ),
              onChanged: (value) {
                setState(() {
                  fileUrl = value;
                });
              },
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _handleDownload,
              child: Text('Download File'),
            ),
            Divider(),
            if (contentType.startsWith('image/') && fileData != null)
              Image(image: MemoryImage(fileData!)),
            SizedBox(height: 8),
            fileMetaInfo == null
                ? SizedBox.shrink()
                : Text(
                    "Etag: ${fileMetaInfo!.etag}\n"
                    "Last Modified: ${fileMetaInfo!.lastModified}\n"
                    "Created At: ${fileMetaInfo!.createdAt}\n"
                    "Expires At: ${fileMetaInfo!.expiresAt}\n"
                    "Content Length: ${fileMetaInfo!.contentLength}\n"
                    "Content Type: ${fileMetaInfo!.contentType ?? 'unknown'}",
                  ),
          ],
        ),
      ),
    );
  }
}
