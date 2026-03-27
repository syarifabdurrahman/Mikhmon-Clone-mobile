import 'dart:async';
import 'package:flutter/material.dart';
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
  bool _isInitialLoad = true; // Track if this is the first data load
  String? _errorMessage;
  SystemResources? _resources;
  Timer? _refreshTimer;
  late final ValueNotifier<SystemResources?> _resourcesNotifier;
  bool _isFetching = false; // Guard against concurrent fetches

  @override
  void initState() {
    super.initState();
    _resourcesNotifier = ValueNotifier<SystemResources?>(null);

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
    _resourcesNotifier.dispose();
    super.dispose();
  }

  /// Start periodic refresh every 3 seconds
  /// Uses Future.delayed to skip first tick for seamless navigation
  void _startPeriodicRefresh() {
    debugPrint('[Dashboard] Starting periodic refresh timer (first tick in 3s)');

    // Use Future.delayed to skip first tick, then start periodic timer
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        debugPrint('[Dashboard] First periodic refresh after delay');
        _fetchAndCacheResources();
        // Then start periodic timer
        _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
          if (mounted) {
            debugPrint('[Dashboard] Periodic refresh triggered (tick ${timer.tick})');
            _fetchAndCacheResources();
          } else {
            debugPrint('[Dashboard] Timer fired but widget not mounted, cancelling');
            timer.cancel();
          }
        });
        debugPrint('[Dashboard] Started periodic refresh (every 3 seconds)');
      } else {
        debugPrint('[Dashboard] Widget not mounted, cancelling timer start');
      }
    });
  }

  /// Update the resources notifier when resources change
  void _updateResourcesNotifier() {
    _resourcesNotifier.value = _resources;
    // Also add to history for charts
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
      debugPrint('=== DASHBOARD LOADING ===');
      final service = ref.read(routerOSServiceProvider);
      final cache = ref.read(cacheServiceProvider);
      debugPrint('Is Connected: ${service.isConnected}');
      debugPrint('Initial Load: $_isInitialLoad');

      // Check if we have pre-fetched data from login (fastest path)
      final authState = ref.read(authStateProvider);
      if (authState.value?.systemResources != null) {
        debugPrint('Using pre-fetched resources from login');
        if (mounted) {
          setState(() {
            _resources = SystemResources.fromJson(authState.value!.systemResources!);
            _isLoading = false;
            _isInitialLoad = false;
          });
          _updateResourcesNotifier();
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
        debugPrint('Using cached resources');
        if (mounted) {
          setState(() {
            _resources = SystemResources.fromJson(cachedResources);
            _isLoading = false;
            _isInitialLoad = false;
          });
          _updateResourcesNotifier();
        }
        // Don't fetch fresh data on navigation - use cached data instantly
        // The periodic timer will keep data updated
        return;
      }

      // Fetch new data if we're connected (slowest path - first time ever)
      if (service.isConnected) {
        await _fetchAndCacheResources();
      } else {
        debugPrint('Not connected - waiting for login');
        if (mounted) {
          setState(() {
            _errorMessage = 'Not connected to RouterOS. Please login again.';
          });
        }
      }
    } catch (e) {
      debugPrint('=== DASHBOARD ERROR ===');
      debugPrint('Error: $e');
      debugPrint('Error Type: ${e.runtimeType}');
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
      debugPrint('[Refresh] Already fetching, skipping duplicate request');
      return;
    }

    _isFetching = true;

    try {
      final service = ref.read(routerOSServiceProvider);
      final cache = ref.read(cacheServiceProvider);

      if (!service.isConnected) {
        debugPrint('[Refresh] Not connected, skipping fetch');
        return;
      }

      final client = service.client;
      if (client == null) {
        debugPrint('[Refresh] Client is null, skipping fetch');
        return;
      }

      debugPrint('[Refresh] Fetching fresh system resources...');
      final resourcesData = await client.getSystemResources();
      debugPrint('[Refresh] Resources data received: ${resourcesData.length} fields');

      // Validate that we got meaningful data before saving
      // Check if we have at least some expected fields
      if (resourcesData.isEmpty ||
          (!resourcesData.containsKey('platform') &&
           !resourcesData.containsKey('cpu-load') &&
           !resourcesData.containsKey('free-memory'))) {
        debugPrint('[Refresh] Warning: Received invalid/empty resources data');
        debugPrint('[Refresh] Data keys: ${resourcesData.keys.toList()}');
        return;
      }

      // Save to cache
      await cache.saveSystemResources(resourcesData);
      debugPrint('[Refresh] Resources cached successfully');

      // Update UI if mounted
      if (mounted) {
        final newResources = SystemResources.fromJson(resourcesData);
        setState(() {
          _resources = newResources;
          _errorMessage = null;
          _isInitialLoad = false; // First successful data load
        });
        _updateResourcesNotifier();
        debugPrint('[Refresh] Dashboard updated successfully! CPU: ${newResources.cpuLoad}%, RAM: ${(newResources.freeMemory / newResources.totalMemory * 100).toStringAsFixed(1)}%');
      }
    } catch (e) {
      debugPrint('[Refresh] Error fetching resources: $e');
      debugPrint('[Refresh] Error type: ${e.runtimeType}');
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
            onPressed: _isLoading ? null : () => _loadDashboardData(showLoading: true),
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
                            color: context.appOnBackground.withValues(alpha: 0.7),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSystemInfoCard(),
            const SizedBox(height: 16),
            _buildResourceChart(),
            const SizedBox(height: 16),
            const TrafficMonitorCard(),
            const SizedBox(height: 16),
            _buildIncomeCards(),
            const SizedBox(height: 16),
            _buildQuickActions(),
          ],
        ),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.appPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.router_rounded,
                    color: context.appPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _resources!.boardName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: context.appOnSurface,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RouterOS ${_resources!.version}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.appOnSurface.withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.memory_rounded,
              'Platform',
              _resources!.platform,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.speed_rounded,
              'CPU',
              '${_resources!.cpuFrequency} MHz',
            ),
            const SizedBox(height: 12),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.appOnBackground,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: DailyIncomeCard(),
            ),
            SizedBox(width: 12),
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
