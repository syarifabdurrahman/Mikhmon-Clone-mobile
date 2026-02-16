import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../services/models.dart';

// Individual refreshable widget for CPU Load
class CpuLoadCard extends StatefulWidget {
  final SystemResources? initialResources;

  const CpuLoadCard({super.key, required this.initialResources});

  @override
  State<CpuLoadCard> createState() => _CpuLoadCardState();
}

class _CpuLoadCardState extends State<CpuLoadCard> {
  late int _cpuLoad;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _cpuLoad = widget.initialResources?.cpuLoad ?? 0;
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh every 2 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          // Generate random CPU load between 5-40%
          _cpuLoad = 5 + Random().nextInt(36);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildResourceCard(
      Icons.memory_rounded,
      'CPU Load',
      '$_cpuLoad%',
      _cpuLoad / 100,
    );
  }

  Widget _buildResourceCard(
    IconData icon,
    String title,
    String value,
    double usagePercent,
  ) {
    return Card(
      color: AppTheme.surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.onSurfaceColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: usagePercent.clamp(0.0, 1.0),
                backgroundColor: AppTheme.onSurfaceColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  usagePercent > 0.8
                      ? AppTheme.errorColor
                      : AppTheme.primaryColor,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Individual refreshable widget for Memory
class MemoryCard extends StatefulWidget {
  final SystemResources? initialResources;

  const MemoryCard({super.key, required this.initialResources});

  @override
  State<MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<MemoryCard> {
  late int _freeMemory;
  late int _totalMemory;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _freeMemory = widget.initialResources?.freeMemory ?? 0;
    _totalMemory = widget.initialResources?.totalMemory ?? 0;
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh every 3 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          // Fluctuate memory usage
          final random = Random();
          final fluctuation = random.nextInt(524288) - 262144; // -256KB to +256KB
          _freeMemory = (_freeMemory + fluctuation).clamp(
            (_totalMemory * 0.2).toInt(),
            (_totalMemory * 0.8).toInt(),
          );
        });
      }
    });
  }

  double get memoryUsagePercent =>
      _totalMemory > 0 ? ((_totalMemory - _freeMemory) / _totalMemory * 100) : 0;

  @override
  Widget build(BuildContext context) {
    final usedMemory = _totalMemory - _freeMemory;
    return _buildResourceCard(
      Icons.storage_rounded,
      'Memory',
      '${(usedMemory / 1024 / 1024).toStringAsFixed(2)} MB',
      memoryUsagePercent / 100,
      subtitle: '${(_totalMemory / 1024 / 1024).toStringAsFixed(2)} MB Total',
    );
  }

  Widget _buildResourceCard(
    IconData icon,
    String title,
    String value,
    double usagePercent, {
    String? subtitle,
  }) {
    return Card(
      color: AppTheme.surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.onSurfaceColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
                    ),
              ),
            ],
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: usagePercent.clamp(0.0, 1.0),
                backgroundColor: AppTheme.onSurfaceColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  usagePercent > 0.8
                      ? AppTheme.errorColor
                      : AppTheme.primaryColor,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Individual refreshable widget for Disk
class DiskCard extends StatefulWidget {
  final SystemResources? initialResources;

  const DiskCard({super.key, required this.initialResources});

  @override
  State<DiskCard> createState() => _DiskCardState();
}

class _DiskCardState extends State<DiskCard> {
  late int _freeHddSpace;
  late int _totalHddSpace;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _freeHddSpace = widget.initialResources?.freeHddSpace ?? 0;
    _totalHddSpace = widget.initialResources?.totalHddSpace ?? 0;
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh every 5 seconds (slower, disk changes less frequently)
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          // Fluctuate disk usage slightly
          final random = Random();
          final fluctuation = random.nextInt(1048576) - 524288; // -512KB to +512KB
          _freeHddSpace = (_freeHddSpace + fluctuation).clamp(
            (_totalHddSpace * 0.1).toInt(),
            (_totalHddSpace * 0.9).toInt(),
          );
        });
      }
    });
  }

  double get hddUsagePercent =>
      _totalHddSpace > 0 ? ((_totalHddSpace - _freeHddSpace) / _totalHddSpace * 100) : 0;

  @override
  Widget build(BuildContext context) {
    final usedHdd = _totalHddSpace - _freeHddSpace;
    return _buildResourceCard(
      Icons.sd_storage_rounded,
      'Disk',
      '${(usedHdd / 1024 / 1024).toStringAsFixed(2)} MB',
      hddUsagePercent / 100,
      subtitle: '${(_totalHddSpace / 1024 / 1024).toStringAsFixed(2)} MB Total',
    );
  }

  Widget _buildResourceCard(
    IconData icon,
    String title,
    String value,
    double usagePercent, {
    String? subtitle,
  }) {
    return Card(
      color: AppTheme.surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.onSurfaceColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
                    ),
              ),
            ],
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: usagePercent.clamp(0.0, 1.0),
                backgroundColor: AppTheme.onSurfaceColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  usagePercent > 0.8
                      ? AppTheme.errorColor
                      : AppTheme.primaryColor,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
