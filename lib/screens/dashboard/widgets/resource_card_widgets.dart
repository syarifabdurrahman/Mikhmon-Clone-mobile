import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../services/models.dart';

// Optimized resource card widget with RepaintBoundary
class ResourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final double usagePercent;
  final String? subtitle;

  const ResourceCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.usagePercent,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
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
              _buildHeader(context),
              const SizedBox(height: 8),
              _buildValue(context),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                _buildSubtitle(context),
              ],
              const SizedBox(height: 12),
              _buildProgressBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
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
            style: TextStyle(
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildValue(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        color: AppTheme.onSurfaceColor,
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Text(
      subtitle!,
      style: TextStyle(
        color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
        fontSize: 12,
      ),
    );
  }

  Widget _buildProgressBar() {
    final isError = usagePercent > 0.8;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: usagePercent.clamp(0.0, 1.0),
        backgroundColor: AppTheme.onSurfaceColor.withValues(alpha: 0.1),
        valueColor: AlwaysStoppedAnimation<Color>(
          isError ? AppTheme.errorColor : AppTheme.primaryColor,
        ),
        minHeight: 6,
      ),
    );
  }
}

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
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _cpuLoad = 5 + Random().nextInt(36);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResourceCard(
      icon: Icons.memory_rounded,
      title: 'CPU Load',
      value: '$_cpuLoad%',
      usagePercent: _cpuLoad / 100,
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
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          final random = Random();
          final fluctuation = random.nextInt(524288) - 262144;
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
    return ResourceCard(
      icon: Icons.storage_rounded,
      title: 'Memory',
      value: '${(usedMemory / 1024 / 1024).toStringAsFixed(2)} MB',
      usagePercent: memoryUsagePercent / 100,
      subtitle: '${(_totalMemory / 1024 / 1024).toStringAsFixed(2)} MB Total',
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
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          final random = Random();
          final fluctuation = random.nextInt(1048576) - 524288;
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
    return ResourceCard(
      icon: Icons.sd_storage_rounded,
      title: 'Disk',
      value: '${(usedHdd / 1024 / 1024).toStringAsFixed(2)} MB',
      usagePercent: hddUsagePercent / 100,
      subtitle: '${(_totalHddSpace / 1024 / 1024).toStringAsFixed(2)} MB Total',
    );
  }
}
