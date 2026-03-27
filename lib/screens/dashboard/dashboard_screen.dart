import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/models.dart';
import '../../providers/app_providers.dart';
import 'widgets/resource_card_widgets.dart';
import 'widgets/combined_resource_chart.dart';
import 'widgets/traffic_monitor_widgets.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isLoading = false;
  bool _isInitialLoad = true;
  String? _errorMessage;
  SystemResources? _resources;
  Timer? _refreshTimer;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    // Use schedulerBinding to defer initialization
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    if (!mounted) return;

    // Check if we have cached data before showing loading state
    final cache = ref.read(cacheServiceProvider);
    final hasCachedData = cache.getSystemResources() != null ||
        ref.read(authStateProvider).value?.systemResources != null;

    // Don't show loading if we have cached data (seamless navigation)
    _loadDashboardData(showLoading: !hasCachedData);
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    // Delay periodic refresh to not block initial render
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _fetchAndCacheResources();
        _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          if (mounted) {
            _fetchAndCacheResources();
          } else {
            timer.cancel();
          }
        });
      }
    });
  }

  void _updateResourceHistory() {
    if (_resources != null) {
      ref.read(resourceHistoryProvider).addFromResources(_resources!);
    }
  }

  Future<void> _loadDashboardData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final service = ref.read(routerOSServiceProvider);
      final cache = ref.read(cacheServiceProvider);

      // Check if we have pre-fetched data from login (fastest path)
      final authState = ref.read(authStateProvider);
      if (authState.value?.systemResources != null) {
        if (mounted) {
          setState(() {
            _resources =
                SystemResources.fromJson(authState.value!.systemResources!);
            _isLoading = false;
            _isInitialLoad = false;
          });
          _updateResourceHistory();
        }
        // Clear the pre-fetched data so future refreshes fetch new data
        // Delay to avoid modifying provider during widget lifecycle
        Future.microtask(() =>
            ref.read(authStateProvider.notifier).clearPrefetchedResources());
        // Background refresh to get latest data
        _fetchAndCacheResources();
        return;
      }

      // Check cache for instant data display (second fastest path)
      final cachedResources = cache.getSystemResources();
      if (cachedResources != null) {
        if (mounted) {
          setState(() {
            _resources = SystemResources.fromJson(cachedResources);
            _isLoading = false;
            _isInitialLoad = false;
          });
          _updateResourceHistory();
        }
        // Don't fetch fresh data on navigation - use cached data instantly
        // The periodic timer will keep data updated
        return;
      }

      // Fetch new data if we're connected (slowest path - first time ever)
      if (service.isConnected) {
        await _fetchAndCacheResources();
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Not connected to RouterOS. Please login again.';
          });
        }
      }
    } catch (e) {
      if (mounted && showLoading) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    } finally {
      if (mounted && showLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Fetch resources from RouterOS and cache them
  /// Guarded against concurrent fetches with _isFetching flag
  Future<void> _fetchAndCacheResources() async {
    // Prevent concurrent fetches
    if (_isFetching) {
      return;
    }

    _isFetching = true;

    try {
      final service = ref.read(routerOSServiceProvider);
      final cache = ref.read(cacheServiceProvider);

      if (!service.isConnected) {
        return;
      }

      final client = service.client;
      if (client == null) {
        return;
      }

      final resourcesData = await client.getSystemResources();

      // Validate that we got meaningful data before saving
      // Check if we have at least some expected fields
      if (resourcesData.isEmpty ||
          (!resourcesData.containsKey('platform') &&
              !resourcesData.containsKey('cpu-load') &&
              !resourcesData.containsKey('free-memory'))) {
        return;
      }

      // Save to cache
      await cache.saveSystemResources(resourcesData);

      // Update UI if mounted
      if (mounted) {
        final newResources = SystemResources.fromJson(resourcesData);
        setState(() {
          _resources = newResources;
          _errorMessage = null;
          _isInitialLoad = false; // First successful data load
        });
        _updateResourceHistory();
      }
    } catch (e) {
      // Don't show error on background refresh failures
      // Only show error if there's no cached data
      if (_resources == null && mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      _isFetching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appOnSurface,
        elevation: 0,
        title: Text(
          'Dashboard',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push('/main/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed:
                _isLoading ? null : () => _loadDashboardData(showLoading: true),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Show loading indicator for initial load
    if (_isInitialLoad && _isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(context.appPrimary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading dashboard...',
              style: TextStyle(
                color: context.appOnBackground.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: context.appError,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Connection Error',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: context.appOnBackground,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                context.appOnBackground.withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loadDashboardData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.appPrimary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_resources == null) {
      return Center(
        child: Text(
          'No data available',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.appOnBackground,
              ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadDashboardData(showLoading: false),
      color: context.appPrimary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 400;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSystemInfoCard(),
                SizedBox(height: isSmallScreen ? 12 : 16),
                _buildResourceChart(),
                SizedBox(height: isSmallScreen ? 12 : 16),
                const TrafficMonitorCard(),
                SizedBox(height: isSmallScreen ? 12 : 16),
                _buildIncomeCards(),
                SizedBox(height: isSmallScreen ? 12 : 16),
                _buildQuickActions(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return Card(
      color: context.appSurface,
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.appPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.router_rounded,
                    color: context.appPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _resources!.boardName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: context.appOnSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'RouterOS ${_resources!.version}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  context.appOnSurface.withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.memory_rounded,
              'Platform',
              _resources!.platform,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.speed_rounded,
              'CPU',
              '${_resources!.cpuFrequency} MHz',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.access_time_rounded,
              'Uptime',
              _formatUptime(_resources!.uptimeSeconds),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceChart() {
    return ListenableBuilder(
      listenable: ref.read(resourceHistoryProvider),
      builder: (context, child) {
        return CombinedResourceChart(
          resourceHistory: ref.read(resourceHistoryProvider),
        );
      },
    );
  }

  Widget _buildIncomeCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Income',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: context.appOnBackground,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(
              child: DailyIncomeCard(),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: MonthlyIncomeCard(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.appOnBackground,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          color: context.appSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildActionButton(
                Icons.person_add_rounded,
                'Add Hotspot User',
                Icons.arrow_forward_ios_rounded,
                () {
                  context.push('/main/users/add');
                },
              ),
              Divider(
                height: 1,
                color: context.appOnSurface.withValues(alpha: 0.1),
              ),
              _buildActionButton(
                Icons.wifi_rounded,
                'Manage Hotspot',
                Icons.arrow_forward_ios_rounded,
                () {
                  context.go('/main/users');
                },
              ),
              Divider(
                height: 1,
                color: context.appOnSurface.withValues(alpha: 0.1),
              ),
              _buildActionButton(
                Icons.card_membership_rounded,
                'User Profiles',
                Icons.arrow_forward_ios_rounded,
                () {
                  context.go('/main/profiles');
                },
              ),
              Divider(
                height: 1,
                color: context.appOnSurface.withValues(alpha: 0.1),
              ),
              _buildActionButton(
                Icons.lan_rounded,
                'Hotspot Hosts',
                Icons.arrow_forward_ios_rounded,
                () {
                  context.go('/main/hosts');
                },
              ),
              Divider(
                height: 1,
                color: context.appOnSurface.withValues(alpha: 0.1),
              ),
              _buildActionButton(
                Icons.payments_rounded,
                'Revenue',
                Icons.arrow_forward_ios_rounded,
                () {
                  context.push('/main/revenue');
                },
              ),
              Divider(
                height: 1,
                color: context.appOnSurface.withValues(alpha: 0.1),
              ),
              _buildActionButton(
                Icons.confirmation_number_rounded,
                'Vouchers',
                Icons.arrow_forward_ios_rounded,
                () {
                  context.push('/main/vouchers');
                },
              ),
              Divider(
                height: 1,
                color: context.appOnSurface.withValues(alpha: 0.1),
              ),
              _buildActionButton(
                Icons.history_rounded,
                'Connection Logs',
                Icons.arrow_forward_ios_rounded,
                () {
                  // Navigate to logs screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logs feature coming soon')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    IconData leadingIcon,
    String title,
    IconData trailingIcon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              leadingIcon,
              color: context.appPrimary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.appOnSurface,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            Icon(
              trailingIcon,
              color: context.appOnSurface.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          color: context.appPrimary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.appOnSurface.withValues(alpha: 0.7),
              ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  String _formatUptime(int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (days > 0) {
      return '${days}d ${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
