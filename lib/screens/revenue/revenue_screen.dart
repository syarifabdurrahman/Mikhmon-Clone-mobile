import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../services/models.dart';
import '../../utils/filter_utils.dart';

class RevenueScreen extends ConsumerStatefulWidget {
  const RevenueScreen({super.key});

  @override
  ConsumerState<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends ConsumerState<RevenueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TimePeriod _timePeriod = TimePeriod.week;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportToCSV(WidgetRef ref) async {
    final incomeAsync = ref.read(incomeProvider);
    final income = incomeAsync.valueOrNull;

    if (income == null || income.transactions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No transactions to export')),
        );
      }
      return;
    }

    try {
      // Generate CSV content
      final buffer = StringBuffer();
      buffer.writeln('Username,Profile,Price,Date,Time,Comment');

      for (final transaction in income.transactions) {
        final date = DateFormat('yyyy-MM-dd').format(transaction.timestamp);
        final time = DateFormat('HH:mm:ss').format(transaction.timestamp);
        final comment = transaction.comment?.replaceAll(',', ';') ?? '';
        buffer.writeln(
            '${transaction.username},${transaction.profile.toUpperCase()},${transaction.price},$date,$time,$comment');
      }

      // Save to file
      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/sales_report_$timestamp.csv');
      await file.writeAsString(buffer.toString());

      // Share the file
      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text:
              'Sales Report - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        context.go('/main');
      },
      child: Scaffold(
        backgroundColor: context.appBackground,
        appBar: AppBar(
          backgroundColor: context.appSurface,
          foregroundColor: context.appOnSurface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/main'),
            tooltip: 'Back',
          ),
          title: Text(
            'Revenue',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: context.appOnSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
          actions: [
            PopupMenuButton<TimePeriod>(
              icon: const Icon(Icons.calendar_today_rounded),
              initialValue: _timePeriod,
              onSelected: (period) {
                setState(() {
                  _timePeriod = period;
                });
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: TimePeriod.week, child: Text('This Week')),
                PopupMenuItem(
                    value: TimePeriod.month, child: Text('This Month')),
                PopupMenuItem(
                    value: TimePeriod.quarter, child: Text('This Quarter')),
                PopupMenuItem(value: TimePeriod.year, child: Text('This Year')),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.file_download_rounded),
              onPressed: () => _exportToCSV(ref),
              tooltip: 'Export CSV',
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.read(incomeProvider.notifier).refresh(),
            ),
          ],
        ),
        body: Column(
          children: [
            _SummaryCards(timePeriod: _timePeriod),
            Container(
              color: context.appSurface,
              child: TabBar(
                controller: _tabController,
                labelColor: context.appPrimary,
                unselectedLabelColor:
                    context.appOnSurface.withValues(alpha: 0.6),
                indicatorColor: context.appPrimary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Charts'),
                  Tab(icon: Icon(Icons.pie_chart_rounded), text: 'By Profile'),
                  Tab(
                      icon: Icon(Icons.receipt_long_rounded),
                      text: 'Transactions'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  _ChartsTab(),
                  _ByProfileTab(),
                  _TransactionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum TimePeriod { week, month, quarter, year }

class _SummaryCards extends ConsumerWidget {
  final TimePeriod timePeriod;

  const _SummaryCards({required this.timePeriod});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(incomeProvider);

    return incomeAsync.when(
      data: (income) {
        final summary = income.summary;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: _getPeriodLabel(timePeriod),
                  value:
                      _formatCurrency(_getValueForPeriod(summary, timePeriod)),
                  icon: Icons.payments_rounded,
                  color: context.appPrimary,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  title: 'Transactions',
                  value: _getTransactionCountForPeriod(summary, timePeriod)
                      .toString(),
                  icon: Icons.receipt_long_rounded,
                  color: context.appSecondary,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => _buildLoadingCards(context),
      error: (_, __) => _buildErrorCards(context),
    );
  }

  Widget _buildLoadingCards(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 100,
      child: Row(
        children: [
          Expanded(child: _CardPlaceholder()),
          SizedBox(width: 12),
          Expanded(child: _CardPlaceholder()),
        ],
      ),
    );
  }

  Widget _buildErrorCards(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 100,
      child: Row(
        children: [
          Expanded(child: _CardPlaceholder()),
          SizedBox(width: 12),
          Expanded(child: _CardPlaceholder()),
        ],
      ),
    );
  }

  String _getPeriodLabel(TimePeriod period) {
    switch (period) {
      case TimePeriod.week:
        return 'This Week';
      case TimePeriod.month:
        return 'This Month';
      case TimePeriod.quarter:
        return 'This Quarter';
      case TimePeriod.year:
        return 'This Year';
    }
  }

  double _getValueForPeriod(IncomeSummary summary, TimePeriod period) {
    switch (period) {
      case TimePeriod.week:
      case TimePeriod.month:
        return summary.thisMonthIncome;
      case TimePeriod.quarter:
      case TimePeriod.year:
        return summary.thisMonthIncome * 3; // Approximate
    }
  }

  int _getTransactionCountForPeriod(IncomeSummary summary, TimePeriod period) {
    switch (period) {
      case TimePeriod.week:
      case TimePeriod.month:
        return summary.transactionsThisMonth;
      case TimePeriod.quarter:
      case TimePeriod.year:
        return summary.transactionsThisMonth * 3; // Approximate
    }
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0).format(value);
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appOnSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
    );
  }
}

class _ChartsTab extends ConsumerWidget {
  const _ChartsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(incomeProvider);

    return incomeAsync.when(
      data: (income) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Revenue Trend',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: context.appOnSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 16),
              _RevenueChart(transactions: income.transactions),
              SizedBox(height: 24),
              Text(
                'Daily Breakdown',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: context.appOnSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 16),
              _DailyBarChart(transactions: income.transactions),
            ],
          ),
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, __) => _buildErrorState(context, error.toString()),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: context.appError,
          ),
          SizedBox(height: 16),
          Text(
            'Failed to load revenue data',
            style: TextStyle(
              color: context.appOnSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: context.appOnSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<SalesTransaction> transactions;

  const _RevenueChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return _buildEmptyChart(context);
    }

    // Group transactions by date
    final groupedData = _groupByDate(transactions);
    final sortedDates = groupedData.keys.toList()..sort();

    if (sortedDates.isEmpty) {
      return _buildEmptyChart(context);
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appOnSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _calculateHorizontalInterval(groupedData),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: context.appOnSurface.withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= sortedDates.length ||
                      value.toInt() < 0) {
                    return Text('');
                  }
                  final date = sortedDates[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _formatDateShort(date),
                      style: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatCurrency(value.toDouble()),
                    style: TextStyle(
                      color: context.appOnSurface.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: context.appOnSurface.withValues(alpha: 0.1),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: _generateSpots(sortedDates, groupedData),
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  context.appPrimary,
                  context.appPrimary.withValues(alpha: 0.3),
                ],
              ),
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: context.appPrimary,
                    strokeWidth: 2,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.appPrimary.withValues(alpha: 0.2),
                    context.appPrimary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
          minY: 0,
        ),
      ),
    );
  }

  Widget _buildEmptyChart(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appOnSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 48,
              color: context.appOnSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: 12),
            Text(
              'No revenue data yet',
              style: TextStyle(
                color: context.appOnSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<DateTime, double> _groupByDate(List<SalesTransaction> transactions) {
    final grouped = <DateTime, double>{};
    for (final transaction in transactions) {
      final date = DateTime(
        transaction.timestamp.year,
        transaction.timestamp.month,
        transaction.timestamp.day,
      );
      grouped[date] = (grouped[date] ?? 0) + transaction.price;
    }
    return grouped;
  }

  List<FlSpot> _generateSpots(
      List<DateTime> dates, Map<DateTime, double> groupedData) {
    final spots = <FlSpot>[];
    for (var i = 0; i < dates.length; i++) {
      spots.add(FlSpot(i.toDouble(), groupedData[dates[i]] ?? 0));
    }
    return spots;
  }

  double _calculateHorizontalInterval(Map<DateTime, double> data) {
    if (data.isEmpty) return 10000;
    final values = data.values.toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    return (max / 4).ceilToDouble() * 1000;
  }

  String _formatDateShort(DateTime date) {
    return '${date.day}/${date.month}';
  }

  String _formatCurrency(double value) {
    return FilterUtils.formatCurrency(value, symbol: '');
  }
}

class _DailyBarChart extends StatelessWidget {
  final List<SalesTransaction> transactions;

  const _DailyBarChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return _buildEmptyChart(context);
    }

    final groupedData = _groupByDate(transactions);
    final sortedDates = groupedData.keys.toList()..sort();
    final recentDates = sortedDates.take(7).toList();

    if (recentDates.isEmpty) {
      return _buildEmptyChart(context);
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appOnSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxYValue(groupedData, recentDates),
          minY: 0,
          barGroups: [
            for (var i = 0; i < recentDates.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: groupedData[recentDates[i]] ?? 0,
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        context.appSecondary,
                        context.appSecondary.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    width: 16,
                  ),
                ],
              ),
          ],
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval:
                _calculateHorizontalInterval(groupedData, recentDates),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: context.appOnSurface.withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= recentDates.length ||
                      value.toInt() < 0) {
                    return Text('');
                  }
                  final date = recentDates[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _formatDateShort(date),
                      style: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatCurrency(value.toDouble()),
                    style: TextStyle(
                      color: context.appOnSurface.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: context.appOnSurface.withValues(alpha: 0.1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChart(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appOnSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          'No data available',
          style: TextStyle(
            color: context.appOnSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Map<DateTime, double> _groupByDate(List<SalesTransaction> transactions) {
    final grouped = <DateTime, double>{};
    for (final transaction in transactions) {
      final date = DateTime(
        transaction.timestamp.year,
        transaction.timestamp.month,
        transaction.timestamp.day,
      );
      grouped[date] = (grouped[date] ?? 0) + transaction.price;
    }
    return grouped;
  }

  double _getMaxYValue(
      Map<DateTime, double> groupedData, List<DateTime> dates) {
    double max = 0;
    for (final date in dates) {
      if ((groupedData[date] ?? 0) > max) {
        max = groupedData[date]!;
      }
    }
    if (max == 0) return 10000;
    return max * 1.2;
  }

  double _calculateHorizontalInterval(
      Map<DateTime, double> groupedData, List<DateTime> dates) {
    double max = 0;
    for (final date in dates) {
      if ((groupedData[date] ?? 0) > max) {
        max = groupedData[date]!;
      }
    }
    return (max / 4).ceilToDouble() * 1000;
  }

  String _formatDateShort(DateTime date) {
    return '${date.day}/${date.month}';
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}

class _ByProfileTab extends ConsumerWidget {
  const _ByProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeAsync = ref.watch(incomeProvider);

    return incomeAsync.when(
      data: (income) {
        if (income.transactions.isEmpty) {
          return _buildEmptyState(context);
        }

        final groupedByProfile = _groupByProfile(income.transactions);
        final sortedProfiles = groupedByProfile.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Revenue by Profile',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: context.appOnSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 16),
              ...sortedProfiles.map((entry) {
                return _ProfileRevenueCard(
                  profileName: entry.key,
                  revenue: entry.value,
                  transactionCount: income.transactions
                      .where((t) => t.profile == entry.key)
                      .length,
                  rank:
                      sortedProfiles.indexWhere((e) => e.key == entry.key) + 1,
                );
              }),
            ],
          ),
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text('Error loading data')),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_rounded,
            size: 64,
            color: context.appOnSurface.withValues(alpha: 0.3),
          ),
          SizedBox(height: 16),
          Text(
            'No revenue data yet',
            style: TextStyle(
              color: context.appOnSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _groupByProfile(List<SalesTransaction> transactions) {
    final grouped = <String, double>{};
    for (final transaction in transactions) {
      grouped[transaction.profile] =
          (grouped[transaction.profile] ?? 0) + transaction.price;
    }
    return grouped;
  }
}

class _ProfileRevenueCard extends StatelessWidget {
  final String profileName;
  final double revenue;
  final int transactionCount;
  final int rank;

  const _ProfileRevenueCard({
    required this.profileName,
    required this.revenue,
    required this.transactionCount,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor(rank);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.appCard,
            context.appCard.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appOnSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profileName.toUpperCase(),
                  style: TextStyle(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$transactionCount transactions',
                  style: TextStyle(
                    color: context.appOnSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(revenue),
            style: TextStyle(
              color: context.appPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0).format(value);
  }
}

class _TransactionsTab extends ConsumerStatefulWidget {
  const _TransactionsTab();

  @override
  ConsumerState<_TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends ConsumerState<_TransactionsTab> {
  String _searchQuery = '';
  String? _selectedProfile;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final incomeAsync = ref.watch(incomeProvider);

    return incomeAsync.when(
      data: (income) {
        // Apply filters using FilterUtils
        final allTransactions = income.transactions;
        var transactions = FilterUtils.filterBySearch<SalesTransaction>(
          allTransactions,
          _searchQuery,
          [(t) => t.username, (t) => t.profile],
        );

        transactions = FilterUtils.filterByField<SalesTransaction>(
          transactions,
          _selectedProfile,
          (t) => t.profile,
        );

        transactions = FilterUtils.filterByDateRange<SalesTransaction>(
          transactions,
          _startDate,
          _endDate,
          (t) => t.timestamp,
        );

        // Sort by date (newest first)
        transactions = FilterUtils.sortByDate<SalesTransaction>(
            transactions, (t) => t.timestamp);

        final profiles = FilterUtils.getUniqueValues<SalesTransaction>(
          allTransactions,
          (t) => t.profile,
        );

        return Column(
          children: [
            _FilterBar(
              searchQuery: _searchQuery,
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              selectedProfile: _selectedProfile,
              profiles: profiles,
              onProfileChanged: (profile) {
                setState(() {
                  _selectedProfile = profile;
                });
              },
              startDate: _startDate,
              endDate: _endDate,
              onDateRangeChanged: (start, end) {
                setState(() {
                  _startDate = start;
                  _endDate = end;
                });
              },
            ),
            Expanded(
              child: transactions.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        return _TransactionCard(
                          transaction: transactions[index],
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text('Error loading data')),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 64,
            color: context.appOnSurface.withValues(alpha: 0.3),
          ),
          SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
              color: context.appOnSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String? selectedProfile;
  final List<String> profiles;
  final ValueChanged<String?> onProfileChanged;
  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(DateTime?, DateTime?) onDateRangeChanged;

  const _FilterBar({
    required this.searchQuery,
    required this.onSearchChanged,
    required this.selectedProfile,
    required this.profiles,
    required this.onProfileChanged,
    required this.startDate,
    required this.endDate,
    required this.onDateRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by username...',
                    prefixIcon: Icon(Icons.search_rounded),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded),
                            onPressed: () => onSearchChanged(''),
                          )
                        : null,
                    filled: true,
                    fillColor: context.appBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: onSearchChanged,
                ),
              ),
              SizedBox(width: 12),
              InkWell(
                onTap: () => _showDateRangePicker(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: context.appOnSurface.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: context.appOnSurface,
                      ),
                      SizedBox(width: 8),
                      Text(
                        _formatDateRange(),
                        style: TextStyle(
                          color: context.appOnSurface,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (profiles.isNotEmpty) ...[
            SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: Text('All Profiles'),
                    selected: selectedProfile == null,
                    onSelected: (selected) {
                      onProfileChanged(selected ? null : '');
                    },
                  ),
                  ...profiles.map((profile) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(profile.toUpperCase()),
                        selected: selectedProfile == profile,
                        onSelected: (selected) {
                          onProfileChanged(selected ? profile : null);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateRange() {
    if (startDate != null && endDate != null) {
      return '${_formatDate(startDate!)} - ${_formatDate(endDate!)}';
    } else if (startDate != null) {
      return '${_formatDate(startDate!)} - Now';
    } else if (endDate != null) {
      return 'Until ${_formatDate(endDate!)}';
    }
    return 'All Time';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      currentDate: DateTime.now(),
      saveText: 'Apply',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF7C3AED),
              onPrimary: Colors.white,
              surface: const Color(0xFF1E293B),
              onSurface: const Color(0xFFE2E8F0),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateRangeChanged(picked.start, picked.end);
    }
  }
}

class _TransactionCard extends StatelessWidget {
  final SalesTransaction transaction;

  const _TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appOnSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.username,
                      style: TextStyle(
                        color: context.appOnSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      transaction.profile.toUpperCase(),
                      style: TextStyle(
                        color: context.appPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0)
                    .format(transaction.price),
                style: TextStyle(
                  color: context.appSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 16,
                color: context.appOnSurface.withValues(alpha: 0.5),
              ),
              SizedBox(width: 6),
              Text(
                _formatTimestamp(transaction.timestamp),
                style: TextStyle(
                  color: context.appOnSurface.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              SizedBox(width: 16),
              if (transaction.comment != null) ...[
                Icon(
                  Icons.comment_rounded,
                  size: 16,
                  color: context.appOnSurface.withValues(alpha: 0.5),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    transaction.comment!,
                    style: TextStyle(
                      color: context.appOnSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return FilterUtils.formatRelativeTime(timestamp);
  }
}
