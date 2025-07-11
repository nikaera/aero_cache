import 'package:flutter/material.dart';
import 'package:aero_cache/aero_cache.dart';

class CacheStatsDemo extends StatefulWidget {
  final AeroCache aeroCache;

  const CacheStatsDemo({super.key, required this.aeroCache});

  @override
  State<CacheStatsDemo> createState() => _CacheStatsDemoState();
}

class _CacheStatsDemoState extends State<CacheStatsDemo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cache Statistics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AeroCache Features:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        '✅ Zstd Compression',
                        'Efficient storage with fast compression',
                      ),
                      _buildFeatureItem(
                        '✅ ETag Validation',
                        'Automatic cache revalidation',
                      ),
                      _buildFeatureItem(
                        '✅ Vary Header Support',
                        'Intelligent cache key generation',
                      ),
                      _buildFeatureItem(
                        '✅ Progress Tracking',
                        'Real-time download monitoring',
                      ),
                      _buildFeatureItem(
                        '✅ Stale-While-Revalidate',
                        'Background cache updates',
                      ),
                      _buildFeatureItem(
                        '✅ Error Recovery',
                        'Stale-if-error support',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Performance Benefits:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildBenefitItem(
                        '🚀 Fast Access',
                        'Compressed cache for quick retrieval',
                      ),
                      _buildBenefitItem(
                        '💾 Space Efficient',
                        'Zstd compression saves storage',
                      ),
                      _buildBenefitItem(
                        '🔄 Smart Updates',
                        'Only downloads when necessary',
                      ),
                      _buildBenefitItem(
                        '📱 Mobile Optimized',
                        'Designed for Flutter apps',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await widget.aeroCache.clearExpiredCache();
                        if (mounted) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Expired cache cleared!'),
                            ),
                          );
                        }
                      },
                      child: const Text('Clear Expired'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await widget.aeroCache.clearAllCache();
                        if (mounted) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All cache cleared!')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade400,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Clear All'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              description,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              description,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}
