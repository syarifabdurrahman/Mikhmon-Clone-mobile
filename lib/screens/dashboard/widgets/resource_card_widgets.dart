import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../../services/models.dart';
import '../../../providers/app_providers.dart';

// Optimized resource card widget with RepaintBoundary
class ResourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final double usagePercent;
  final String? subtitle;

  const ResourceCard({
    super.key,
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

// Real-time CPU Load card that listens to resources updates
class CpuLoadCard extends StatelessWidget {
  final ValueNotifier<SystemResources?> resourcesNotifier;
  final bool isDemoMode;

  const CpuLoadCard({
    super.key,
    required this.resourcesNotifier,
    this.isDemoMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isDemoMode) {
      // Demo mode: show random values with local timer
      return _DemoCpuLoadCard();
    }

    // Real mode: show actual data from router
    return ValueListenableBuilder<SystemResources?>(
      valueListenable: resourcesNotifier,
      builder: (context, resources, _) {
        final cpuLoad = resources?.cpuLoad ?? 0;
        return ResourceCard(
          icon: Icons.memory_rounded,
          title: 'CPU Load',
          value: '$cpuLoad%',
          usagePercent: cpuLoad / 100,
        );
      },
    );
  }
}

// Demo mode CPU card with random values
class _DemoCpuLoadCard extends StatefulWidget {
  @override
  State<_DemoCpuLoadCard> createState() => _DemoCpuLoadCardState();
}

class _DemoCpuLoadCardState extends State<_DemoCpuLoadCard> {
  late int _cpuLoad;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _cpuLoad = 5 + Random().nextInt(36);
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

// Real-time Memory card that listens to resources updates
class MemoryCard extends StatelessWidget {
  final ValueNotifier<SystemResources?> resourcesNotifier;
  final bool isDemoMode;

  const MemoryCard({
    super.key,
    required this.resourcesNotifier,
    this.isDemoMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isDemoMode) {
      // Demo mode: show random values with local timer
      return _DemoMemoryCard();
    }

    // Real mode: show actual data from router
    return ValueListenableBuilder<SystemResources?>(
      valueListenable: resourcesNotifier,
      builder: (context, resources, _) {
        final freeMemory = resources?.freeMemory ?? 0;
        final totalMemory = resources?.totalMemory ?? 0;
        final usedMemory = totalMemory - freeMemory;
        final memoryUsagePercent = totalMemory > 0
            ? ((totalMemory - freeMemory) / totalMemory).toDouble()
            : 0.0;

        return ResourceCard(
          icon: Icons.storage_rounded,
          title: 'Memory',
          value: '${(usedMemory / 1024 / 1024).toStringAsFixed(1)} MB',
          usagePercent: memoryUsagePercent,
          subtitle: '${(totalMemory / 1024 / 1024).toStringAsFixed(0)} MB Total',
        );
      },
    );
  }
}

// Demo mode Memory card with random values
class _DemoMemoryCard extends StatefulWidget {
  @override
  State<_DemoMemoryCard> createState() => _DemoMemoryCardState();
}

class _DemoMemoryCardState extends State<_DemoMemoryCard> {
  late int _freeMemory;
  late int _totalMemory;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _totalMemory = 2097152;
    _freeMemory = 1048576;
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

  double get memoryUsagePercent => _totalMemory > 0
      ? ((_totalMemory - _freeMemory) / _totalMemory)
      : 0;

  @override
  Widget build(BuildContext context) {
    final usedMemory = _totalMemory - _freeMemory;
    return ResourceCard(
      icon: Icons.storage_rounded,
      title: 'Memory',
      value: '${(usedMemory / 1024 / 1024).toStringAsFixed(1)} MB',
      usagePercent: memoryUsagePercent,
      subtitle: '${(_totalMemory / 1024 / 1024).toStringAsFixed(0)} MB Total',
    );
  }
}

// Real-time Disk card that listens to resources updates
class DiskCard extends StatelessWidget {
  final ValueNotifier<SystemResources?> resourcesNotifier;
  final bool isDemoMode;

  const DiskCard({
    super.key,
    required this.resourcesNotifier,
    this.isDemoMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isDemoMode) {
      // Demo mode: show random values with local timer
      return _DemoDiskCard();
    }

    // Real mode: show actual data from router
    return ValueListenableBuilder<SystemResources?>(
      valueListenable: resourcesNotifier,
      builder: (context, resources, _) {
        final freeHddSpace = resources?.freeHddSpace ?? 0;
        final totalHddSpace = resources?.totalHddSpace ?? 0;
        final usedHdd = totalHddSpace - freeHddSpace;
        final hddUsagePercent = totalHddSpace > 0
            ? ((totalHddSpace - freeHddSpace) / totalHddSpace).toDouble()
            : 0.0;

        return ResourceCard(
          icon: Icons.sd_storage_rounded,
          title: 'Disk',
          value: '${(usedHdd / 1024 / 1024).toStringAsFixed(1)} MB',
          usagePercent: hddUsagePercent,
          subtitle: '${(totalHddSpace / 1024 / 1024).toStringAsFixed(0)} MB Total',
        );
      },
    );
  }
}

// Demo mode Disk card with random values
class _DemoDiskCard extends StatefulWidget {
  @override
  State<_DemoDiskCard> createState() => _DemoDiskCardState();
}

class _DemoDiskCardState extends State<_DemoDiskCard> {
  late int _freeHddSpace;
  late int _totalHddSpace;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _totalHddSpace = 104857600;
    _freeHddSpace = 52428800;
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

  double get hddUsagePercent => _totalHddSpace > 0
      ? ((_totalHddSpace - _freeHddSpace) / _totalHddSpace)
      : 0;

  @override
  Widget build(BuildContext context) {
    final usedHdd = _totalHddSpace - _freeHddSpace;
    return ResourceCard(
      icon: Icons.sd_storage_rounded,
      title: 'Disk',
      value: '${(usedHdd / 1024 / 1024).toStringAsFixed(1)} MB',
      usagePercent: hddUsagePercent,
      subtitle: '${(_totalHddSpace / 1024 / 1024).toStringAsFixed(0)} MB Total',
    );
  }
}

// Daily Income card - shows today's revenue
class DailyIncomeCard extends ConsumerWidget {
  const DailyIncomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(routerOSServiceProvider);

    if (service.isDemoMode) {
      // In demo mode, use the income provider which has demo data
      return ref.watch(incomeProvider).when(
        data: (incomeState) {
          return _IncomeCard(
            icon: Icons.attach_money_rounded,
            title: 'Today\'s Income',
            value: '\$${incomeState.summary.todayIncome.toStringAsFixed(2)}',
            subtitle: '${incomeState.summary.transactionsToday} transaction${incomeState.summary.transactionsToday != 1 ? 's' : ''}',
            color: Colors.green,
          );
        },
        loading: () => const _IncomeCard(
          icon: Icons.attach_money_rounded,
          title: 'Today\'s Income',
          value: '\$0.00',
          subtitle: 'Loading...',
          color: Colors.green,
        ),
        error: (_, __) => const _IncomeCard(
          icon: Icons.attach_money_rounded,
          title: 'Today\'s Income',
          value: '\$0.00',
          subtitle: 'Error loading',
          color: Colors.green,
        ),
      );
    }

    return ref.watch(incomeProvider).when(
      data: (incomeState) {
        return _IncomeCard(
          icon: Icons.attach_money_rounded,
          title: 'Today\'s Income',
          value: '\$${incomeState.summary.todayIncome.toStringAsFixed(2)}',
          subtitle: '${incomeState.summary.transactionsToday} transaction${incomeState.summary.transactionsToday != 1 ? 's' : ''}',
          color: Colors.green,
        );
      },
      loading: () => const _IncomeCard(
        icon: Icons.attach_money_rounded,
        title: 'Today\'s Income',
        value: '\$0.00',
        subtitle: 'Loading...',
        color: Colors.green,
      ),
      error: (_, __) => const _IncomeCard(
        icon: Icons.attach_money_rounded,
        title: 'Today\'s Income',
        value: '\$0.00',
        subtitle: 'Error loading',
        color: Colors.green,
      ),
    );
  }
}

// Monthly Income card - shows this month's revenue
class MonthlyIncomeCard extends ConsumerWidget {
  const MonthlyIncomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(routerOSServiceProvider);

    if (service.isDemoMode) {
      // In demo mode, use the income provider which has demo data
      return ref.watch(incomeProvider).when(
        data: (incomeState) {
          return _IncomeCard(
            icon: Icons.account_balance_wallet_rounded,
            title: 'This Month',
            value: '\$${incomeState.summary.thisMonthIncome.toStringAsFixed(2)}',
            subtitle: '${incomeState.summary.transactionsThisMonth} transaction${incomeState.summary.transactionsThisMonth != 1 ? 's' : ''}',
            color: Colors.blue,
          );
        },
        loading: () => const _IncomeCard(
          icon: Icons.account_balance_wallet_rounded,
          title: 'This Month',
          value: '\$0.00',
          subtitle: 'Loading...',
          color: Colors.blue,
        ),
        error: (_, __) => const _IncomeCard(
          icon: Icons.account_balance_wallet_rounded,
          title: 'This Month',
          value: '\$0.00',
          subtitle: 'Error loading',
          color: Colors.blue,
        ),
      );
    }

    return ref.watch(incomeProvider).when(
      data: (incomeState) {
        return _IncomeCard(
          icon: Icons.account_balance_wallet_rounded,
          title: 'This Month',
          value: '\$${incomeState.summary.thisMonthIncome.toStringAsFixed(2)}',
          subtitle: '${incomeState.summary.transactionsThisMonth} transaction${incomeState.summary.transactionsThisMonth != 1 ? 's' : ''}',
          color: Colors.blue,
        );
      },
      loading: () => _IncomeCard(
        icon: Icons.account_balance_wallet_rounded,
        title: 'This Month',
        value: '\$0.00',
        subtitle: 'Loading...',
        color: Colors.blue,
      ),
      error: (_, __) => _IncomeCard(
        icon: Icons.account_balance_wallet_rounded,
        title: 'This Month',
        value: '\$0.00',
        subtitle: 'Error loading',
        color: Colors.blue,
      ),
    );
  }
}

// Custom Income Card widget without progress bar
class _IncomeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final Color color;

  const _IncomeCard({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.onSurfaceColor,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
