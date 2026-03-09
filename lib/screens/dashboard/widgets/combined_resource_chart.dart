import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';
import '../../../services/resource_history.dart';

/// Combined real-time line chart showing CPU, Memory, and Disk usage
/// Animates and scrolls right-to-left like a system monitor (Linux Mint style)
class CombinedResourceChart extends StatefulWidget {
  final ResourceHistoryNotifier resourceHistory;
  final bool isDemoMode;

  const CombinedResourceChart({
    super.key,
    required this.resourceHistory,
    this.isDemoMode = false,
  });

  @override
  State<CombinedResourceChart> createState() => _CombinedResourceChartState();
}

class _CombinedResourceChartState extends State<CombinedResourceChart>
    with SingleTickerProviderStateMixin {
  Timer? _refreshTimer;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Data points for each metric
  List<FlSpot> _cpuSpots = [];
  List<FlSpot> _memorySpots = [];
  List<FlSpot> _diskSpots = [];

  @override
  void initState() {
    super.initState();
    _generateSpots();

    // Setup animation for smooth transitions
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Skip initial animation if we already have data (prevents hiccup on navigation)
    if (widget.resourceHistory.cpuData.isNotEmpty) {
      _animationController.value = 1.0;
    }

    if (widget.isDemoMode) {
      _startDemoMode();
    }

    // Listen to resource history changes for real-time updates
    widget.resourceHistory.addListener(_onDataChanged);
  }

  @override
  void didUpdateWidget(CombinedResourceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resourceHistory != widget.resourceHistory) {
      oldWidget.resourceHistory.removeListener(_onDataChanged);
      widget.resourceHistory.addListener(_onDataChanged);
      setState(() {
        _generateSpots();
      });
    }
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {
        _generateSpots();
      });
      // Trigger smooth animation when new data arrives
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animationController.dispose();
    widget.resourceHistory.removeListener(_onDataChanged);
    super.dispose();
  }

  void _startDemoMode() {
    // Update demo data every 2 seconds to simulate real-time monitoring
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        widget.resourceHistory.addDataPoint(ResourceDataPoint(
          timestamp: DateTime.now(),
          cpuLoad: 15 + (timer.tick % 20) * 2.0,
          memoryUsage: 35 + (timer.tick % 15) * 2.0,
          diskUsage: 25 + (timer.tick % 10) * 2.5,
        ));
      }
    });
  }

  void _generateSpots() {
    final dataPoints = widget.resourceHistory.cpuData;
    final maxPoints = 60; // Keep last 60 data points (scrolling window)

    // Only keep the last maxPoints for the scrolling effect
    final startIndex = dataPoints.length > maxPoints
        ? dataPoints.length - maxPoints
        : 0;

    _cpuSpots = [];
    _memorySpots = [];
    _diskSpots = [];

    // Get the timestamp of the first visible point as reference
    DateTime? referenceTime;
    if (dataPoints.isNotEmpty && startIndex < dataPoints.length) {
      referenceTime = dataPoints[startIndex].timestamp;
    }

    for (int i = startIndex; i < dataPoints.length; i++) {
      final point = dataPoints[i];
      // Use actual elapsed time in seconds from the reference point
      final x = referenceTime != null
          ? point.timestamp.difference(referenceTime).inSeconds.toDouble()
          : 0.0;
      _cpuSpots.add(FlSpot(x, point.cpuLoad));
      _memorySpots.add(FlSpot(x, point.memoryUsage));
      _diskSpots.add(FlSpot(x, point.diskUsage));
    }
  }

  /// Format time based on x-coordinate (elapsed seconds)
  String _formatElapsedTime(double elapsedSeconds) {
    if (elapsedSeconds < 60) {
      return '${elapsedSeconds.toInt()}s';
    } else if (elapsedSeconds < 3600) {
      final minutes = (elapsedSeconds / 60).floor();
      final seconds = (elapsedSeconds % 60).toInt();
      return seconds > 0 ? '${minutes}m${seconds}s' : '${minutes}m';
    } else {
      final hours = (elapsedSeconds / 3600).floor();
      final minutes = ((elapsedSeconds % 3600) / 60).floor();
      return minutes > 0 ? '${hours}h${minutes}m' : '${hours}h';
    }
  }

  Widget _buildChart() {
    final hasData = _cpuSpots.isNotEmpty || widget.isDemoMode;

    if (!hasData) {
      return _buildEmptyState();
    }

    // Right-to-left scrolling: show last 30-40 points in the visible window
    // As new data arrives, old data scrolls off to the left
    final visiblePoints = (_cpuSpots.length.clamp(10, 50)).toDouble();
    final startX = (_cpuSpots.length - visiblePoints).clamp(0.0, double.infinity);
    final maxX = (_cpuSpots.length - 1).toDouble().clamp(1.0, double.infinity); // Remove the 60.0 clamp to allow continuous scrolling

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppTheme.onSurfaceColor.withValues(alpha: 0.08),
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
                    reservedSize: 18,
                    interval: (maxX - startX) / 6,
                    getTitlesWidget: (value, meta) {
                      // value is the x-coordinate in seconds
                      if (value < 0) return const SizedBox.shrink();

                      return Text(
                        _formatElapsedTime(value),
                        style: TextStyle(
                          color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
                          fontSize: 8,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    interval: 25,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value > 100) return const SizedBox.shrink();
                      return Text(
                        '${value.toInt()}',
                        style: TextStyle(
                          color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
                          fontSize: 8,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              // Right-to-left scroll: newest data on right, window shifts left
              minX: startX,
              maxX: maxX.clamp(1.0, 60.0),
              minY: 0,
              maxY: 100,
              clipData: FlClipData.all(),
              lineBarsData: [
                // CPU Line - Purple
                LineChartBarData(
                  spots: _cpuSpots,
                  isCurved: true,
                  curveSmoothness: 0.4,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1),
                      const Color(0xFF8B5CF6),
                    ],
                  ),
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF6366F1).withValues(alpha: 0.15),
                        const Color(0xFF6366F1).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                // Memory Line - Green
                LineChartBarData(
                  spots: _memorySpots,
                  isCurved: true,
                  curveSmoothness: 0.4,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981),
                      const Color(0xFF34D399),
                    ],
                  ),
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF10B981).withValues(alpha: 0.15),
                        const Color(0xFF10B981).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                // Disk Line - Orange
                LineChartBarData(
                  spots: _diskSpots,
                  isCurved: true,
                  curveSmoothness: 0.4,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF59E0B),
                      const Color(0xFFFBBF24),
                    ],
                  ),
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        const Color(0xFFF59E0B).withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) => AppTheme.surfaceColor.withValues(alpha: 0.95),
                  tooltipRoundedRadius: 8,
                  tooltipPadding: const EdgeInsets.all(6),
                  tooltipMargin: 6,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      String label;
                      Color color;

                      // Find which line this spot belongs to
                      final cpuMatch = _cpuSpots.indexWhere((s) => (s.x - spot.x).abs() < 0.5);
                      final memMatch = _memorySpots.indexWhere((s) => (s.x - spot.x).abs() < 0.5);

                      if (cpuMatch >= 0 && (_cpuSpots[cpuMatch].y - spot.y).abs() < 5) {
                        label = 'CPU';
                        color = const Color(0xFF6366F1);
                      } else if (memMatch >= 0 && (_memorySpots[memMatch].y - spot.y).abs() < 5) {
                        label = 'RAM';
                        color = const Color(0xFF10B981);
                      } else {
                        label = 'Disk';
                        color = const Color(0xFFF59E0B);
                      }

                      return LineTooltipItem(
                        '$label: ${spot.y.toStringAsFixed(1)}%',
                        TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 220,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Collecting data...',
            style: TextStyle(
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Waiting for first data point',
            style: TextStyle(
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.3),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latest = widget.resourceHistory.latest;
    final historyPoints = widget.resourceHistory.cpuData.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;
        final chartHeight = isSmallScreen ? 180.0 : 240.0;

        return Card(
          color: AppTheme.surfaceColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 12 : 16,
                  isSmallScreen ? 12 : 16,
                  isSmallScreen ? 12 : 16,
                  isSmallScreen ? 8 : 16,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor.withValues(alpha: 0.15),
                            AppTheme.primaryColor.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.analytics_rounded,
                        color: AppTheme.primaryColor,
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'System Resources',
                            style: TextStyle(
                              color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: isSmallScreen ? 6 : 12,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (latest != null) ...[
                                _buildLegendItem('CPU', latest.cpuLoad, const Color(0xFF6366F1), isSmallScreen),
                                _buildLegendItem('RAM', latest.memoryUsage, const Color(0xFF10B981), isSmallScreen),
                                _buildLegendItem('Disk', latest.diskUsage, const Color(0xFFF59E0B), isSmallScreen),
                              ] else if (widget.isDemoMode && _cpuSpots.isNotEmpty) ...[
                                _buildLegendItem('CPU', _cpuSpots.last.y, const Color(0xFF6366F1), isSmallScreen),
                                _buildLegendItem('RAM', _memorySpots.last.y, const Color(0xFF10B981), isSmallScreen),
                                _buildLegendItem('Disk', _diskSpots.last.y, const Color(0xFFF59E0B), isSmallScreen),
                              ] else ...[
                                Text(
                                  'Loading...',
                                  style: TextStyle(
                                    color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
                                    fontSize: isSmallScreen ? 10 : 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (historyPoints > 0)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 6 : 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sync_rounded,
                              size: isSmallScreen ? 10 : 12,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: isSmallScreen ? 9 : 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Chart
              SizedBox(
                height: chartHeight,
                child: _buildChart(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, double value, Color color, bool isSmallScreen) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isSmallScreen ? 6 : 8,
          height: isSmallScreen ? 6 : 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ${value.toStringAsFixed(0)}%',
          style: TextStyle(
            color: AppTheme.onSurfaceColor,
            fontWeight: FontWeight.w600,
            fontSize: isSmallScreen ? 11 : 13,
          ),
        ),
      ],
    );
  }
}
