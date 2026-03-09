import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../../../../services/resource_history.dart';
import '../../../../theme/app_theme.dart';

/// Line chart widget for monitoring CPU, Memory, or Disk usage over time
class ResourceLineChart extends StatefulWidget {
  final List<ResourceDataPoint> dataPoints;
  final String title;
  final Color chartColor;
  final IconData icon;
  final String unit;
  final bool isDemoMode;

  const ResourceLineChart({
    super.key,
    required this.dataPoints,
    required this.title,
    required this.chartColor,
    required this.icon,
    this.unit = '%',
    this.isDemoMode = false,
  });

  @override
  State<ResourceLineChart> createState() => _ResourceLineChartState();
}

class _ResourceLineChartState extends State<ResourceLineChart> {
  Timer? _refreshTimer;
  late List<FlSpot> _spots;

  @override
  void initState() {
    super.initState();
    _spots = _generateSpots();
    if (widget.isDemoMode && widget.dataPoints.isEmpty) {
      _startDemoMode();
    }
  }

  @override
  void didUpdateWidget(ResourceLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataPoints != widget.dataPoints) {
      setState(() {
        _spots = _generateSpots();
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startDemoMode() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _spots = _generateDemoSpots();
        });
      }
    });
  }

  List<FlSpot> _generateSpots() {
    if (widget.dataPoints.isEmpty) return [];

    final points = widget.dataPoints.take(60).toList();
    return points.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final point = entry.value;

      double value;
      switch (widget.title.toLowerCase()) {
        case 'cpu load':
          value = point.cpuLoad;
          break;
        case 'memory':
          value = point.memoryUsage;
          break;
        case 'disk':
          value = point.diskUsage;
          break;
        default:
          value = point.cpuLoad;
      }

      return FlSpot(index, value);
    }).toList();
  }

  List<FlSpot> _generateDemoSpots() {
    final now = DateTime.now();
    final spots = <FlSpot>[];

    for (int i = 0; i < 30; i++) {
      final baseValue = widget.title.toLowerCase() == 'cpu load'
          ? 20.0
          : widget.title.toLowerCase() == 'memory'
              ? 45.0
              : 35.0;

      final variance = (i % 10) * 3.0;
      final noise = (now.millisecond % 20) - 10;

      spots.add(FlSpot(
        i.toDouble(),
        (baseValue + variance + noise).clamp(0.0, 100.0),
      ));
    }

    return spots;
  }

  String _formatTime(int index) {
    if (widget.dataPoints.isEmpty) return '';
    final reversedIndex = widget.dataPoints.length - 1 - index;
    if (reversedIndex < 0 || reversedIndex >= widget.dataPoints.length) {
      return '';
    }
    final timestamp = widget.dataPoints[reversedIndex].timestamp;
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else {
      return '${difference.inHours}h';
    }
  }

  Widget _buildChart() {
    if (_spots.isEmpty && !widget.isDemoMode) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppTheme.onSurfaceColor.withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _spots.length > 10 ? _spots.length / 5 : 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index % 6 != 0 || index >= _spots.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    _formatTime(index),
                    style: TextStyle(
                      color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                interval: 25,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value > 100) return const SizedBox.shrink();
                  return Text(
                    '${value.toInt()}',
                    style: TextStyle(
                      color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          minX: 0,
          maxX: (_spots.length - 1).toDouble().clamp(1, double.infinity),
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: _spots,
              isCurved: true,
              curveSmoothness: 0.3,
              gradient: LinearGradient(
                colors: [
                  widget.chartColor.withValues(alpha: 0.8),
                  widget.chartColor,
                ],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.chartColor.withValues(alpha: 0.3),
                    widget.chartColor.withValues(alpha: 0.05),
                    widget.chartColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) =>
                  widget.chartColor.withValues(alpha: 0.9),
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)}$widget.unit',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 150,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart_rounded,
            size: 48,
            color: AppTheme.onSurfaceColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 8),
          Text(
            'Collecting data...',
            style: TextStyle(
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentValue = _spots.isNotEmpty ? _spots.last.y : 0.0;
    final historyPoints = widget.dataPoints.length;

    return Card(
      color: AppTheme.surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.chartColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.chartColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${currentValue.toStringAsFixed(1)}${widget.unit}',
                            style: const TextStyle(
                              color: AppTheme.onSurfaceColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          if (historyPoints > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$historyPoints pts',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.more_vert_rounded,
                  color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: _buildChart(),
          ),
        ],
      ),
    );
  }
}

/// CPU Load Chart Widget
class CpuLoadChart extends StatelessWidget {
  final List<ResourceDataPoint> dataPoints;
  final bool isDemoMode;

  const CpuLoadChart({
    super.key,
    required this.dataPoints,
    this.isDemoMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResourceLineChart(
      dataPoints: dataPoints,
      title: 'CPU Load',
      chartColor: const Color(0xFF6366F1),
      icon: Icons.memory_rounded,
      unit: '%',
      isDemoMode: isDemoMode,
    );
  }
}

/// Memory Usage Chart Widget
class MemoryUsageChart extends StatelessWidget {
  final List<ResourceDataPoint> dataPoints;
  final bool isDemoMode;

  const MemoryUsageChart({
    super.key,
    required this.dataPoints,
    this.isDemoMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResourceLineChart(
      dataPoints: dataPoints,
      title: 'Memory',
      chartColor: const Color(0xFF10B981),
      icon: Icons.storage_rounded,
      unit: '%',
      isDemoMode: isDemoMode,
    );
  }
}

/// Disk Usage Chart Widget
class DiskUsageChart extends StatelessWidget {
  final List<ResourceDataPoint> dataPoints;
  final bool isDemoMode;

  const DiskUsageChart({
    super.key,
    required this.dataPoints,
    this.isDemoMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResourceLineChart(
      dataPoints: dataPoints,
      title: 'Disk',
      chartColor: const Color(0xFFF59E0B),
      icon: Icons.sd_storage_rounded,
      unit: '%',
      isDemoMode: isDemoMode,
    );
  }
}
