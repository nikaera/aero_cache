import 'package:flutter/material.dart';
import 'package:aero_cache/aero_cache.dart';
import '../widgets/feature_card.dart';
import 'image_cache_demo.dart';
import 'progress_demo.dart';
import 'cache_stats_demo.dart';
import 'advanced_features_demo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AeroCache _aeroCache = AeroCache();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCache();
  }

  Future<void> _initializeCache() async {
    try {
      await _aeroCache.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Error initializing AeroCache: $e');
    }
  }

  @override
  void dispose() {
    _aeroCache.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AeroCache Feature Showcase'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () async {
              await _aeroCache.clearAllCache();
              if (mounted) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All cache cleared!')),
                );
              }
            },
            tooltip: 'Clear All Cache',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final crossAxisCount = isWide ? 3 : 2;

            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isWide ? 1.2 : 1.0,
              children: [
                FeatureCard(
                  title: 'Image Caching',
                  subtitle: 'Download & cache images with ETag validation',
                  icon: Icons.image,
                  color: Colors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImageCacheDemo(aeroCache: _aeroCache),
                    ),
                  ),
                ),
                FeatureCard(
                  title: 'Progress Tracking',
                  subtitle: 'Real-time download progress monitoring',
                  icon: Icons.download,
                  color: Colors.green,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProgressDemo(aeroCache: _aeroCache),
                    ),
                  ),
                ),
                FeatureCard(
                  title: 'Cache Statistics',
                  subtitle: 'View cache performance metrics',
                  icon: Icons.analytics,
                  color: Colors.orange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CacheStatsDemo(aeroCache: _aeroCache),
                    ),
                  ),
                ),
                FeatureCard(
                  title: 'Advanced Features',
                  subtitle: 'Vary headers, stale-while-revalidate',
                  icon: Icons.settings,
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AdvancedFeaturesDemo(aeroCache: _aeroCache),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
