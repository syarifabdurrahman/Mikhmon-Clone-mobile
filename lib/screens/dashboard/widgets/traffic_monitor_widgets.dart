import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_providers.dart';
import '../../../services/models.dart';

/// Traffic Monitor Card - Displays network interface traffic statistics
class TrafficMonitorCard extends ConsumerStatefulWidget {
  const TrafficMonitorCard({super.key});

  @override
  ConsumerState<TrafficMonitorCard> createState() => _TrafficMonitorCardState();
}

class _TrafficMonitorCardState extends ConsumerState<TrafficMonitorCard> {
  Timer? _refreshTimer;
  bool _timerStarted = false; // Track if timer has been started
  List<InterfaceTraffic>? _currentData;
  // Individual notifiers for each interface's values - allows text-only updates
  final Map<String, _InterfaceTrafficNotifiers> _trafficNotifiers = {};

  @override
  void initState() {
    super.initState();
    debugPrint('[Traffic] TrafficMonitorCard initState called');
    // Load initial data
    _loadInitialData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _timerStarted = false; // Reset flag
    // Dispose all traffic notifiers
    for (final notifier in _trafficNotifiers.values) {
      notifier.dispose();
    }
    _trafficNotifiers.clear();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    debugPrint('[Traffic] _loadInitialData called');
    final trafficAsync = ref.read(interfaceTrafficProvider);
    debugPrint('[Traffic] Provider state: ${trafficAsync}');
    trafficAsync.when(
      data: (interfaces) {
        debugPrint('[Traffic] Initial data loaded: ${interfaces.length} interfaces');
        if (mounted) {
          setState(() {
            _currentData = interfaces;
          });
          // Initialize notifiers for all interfaces
          _updateTrafficValues(interfaces);
        }
        // Timer will be started from build() method when data is available
      },
      loading: () {
        debugPrint('[Traffic] Initial data is loading, waiting...');
      },
      error: (error, _) {
        debugPrint('[Traffic] Initial data error: $error');
      },
    );
  }

  void _startAutoRefresh() {
    if (_timerStarted) {
      debugPrint('[Traffic] Timer already started, skipping');
      return;
    }
    _timerStarted = true;
    debugPrint('[Traffic] Auto-refresh timer started');
    // Auto-refresh every 3 seconds for both demo and real mode
    // Use Future.delayed to skip first tick, then start periodic timer
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        debugPrint('[Traffic] First refresh after delay');
        _silentRefresh();
        // Then start periodic timer
        _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
          if (mounted) {
            debugPrint('[Traffic] Timer fired, calling _silentRefresh()');
            _silentRefresh();
          } else {
            debugPrint('[Traffic] Timer fired but widget not mounted, cancelling');
            timer.cancel();
          }
        });
      } else {
        debugPrint('[Traffic] Widget not mounted after delay, not starting timer');
      }
    });
  }

  Future<void> _silentRefresh() async {
    debugPrint('[Traffic] _silentRefresh() starting');

    // Trigger a silent refresh without showing loading
    final notifier = ref.read(interfaceTrafficProvider.notifier);
    debugPrint('[Traffic] Calling notifier.silentRefresh()');
    await notifier.silentRefresh();
    debugPrint('[Traffic] notifier.silentRefresh() completed');

    // Get the updated data
    final trafficAsync = ref.read(interfaceTrafficProvider);
    debugPrint('[Traffic] Reading provider state after refresh');
    trafficAsync.when(
      data: (interfaces) {
        if (mounted) {
          debugPrint('[Traffic] Provider has data: ${interfaces.length} interfaces');
          for (final interface in interfaces) {
            debugPrint('[Traffic] ${interface.name}: txBytesPerSecond=${interface.txBytesPerSecond}, rxBytesPerSecond=${interface.rxBytesPerSecond}');
            debugPrint('[Traffic] ${interface.name}: Display values - TX=${interface.txRateDisplay}, RX=${interface.rxRateDisplay}');
          }
          // Only update the values, not the whole structure
          debugPrint('[Traffic] Calling _updateTrafficValues with ${interfaces.length} interfaces');
          _updateTrafficValues(interfaces);
          debugPrint('[Traffic] _updateTrafficValues completed');
          // Update current data reference if needed
          _currentData = interfaces;
        }
      },
      loading: () {
        debugPrint('[Traffic] Still loading...');
      },
      error: (error, _) {
        debugPrint('[Traffic] Error: $error');
      },
    );
  }

  void _updateTrafficValues(List<InterfaceTraffic> interfaces) {
    debugPrint('[Traffic] _updateTrafficValues called with ${interfaces.length} interfaces');
    for (final interface in interfaces) {
      final name = interface.name;
      final notifiers = _trafficNotifiers[name];

      debugPrint('[Traffic] Processing $name: txRate=${interface.txBytesPerSecond}, rxRate=${interface.rxBytesPerSecond}');
      debugPrint('[Traffic] Processing $name: txRateDisplay="${interface.txRateDisplay}", rxRateDisplay="${interface.rxRateDisplay}"');

      if (notifiers != null) {
        // Update existing notifiers - this triggers text updates without rebuild
        debugPrint('[Traffic] Updating existing notifiers for $name');
        notifiers.update(
          tx: interface.txDisplay,
          rx: interface.rxDisplay,
          txRate: interface.txRateDisplay,
          rxRate: interface.rxRateDisplay,
        );
        debugPrint('[Traffic] Notifiers updated for $name');
      } else {
        // Create new notifiers for this interface
        debugPrint('[Traffic] Creating new notifiers for $name');
        _trafficNotifiers[name] = _InterfaceTrafficNotifiers(
          tx: interface.txDisplay,
          rx: interface.rxDisplay,
          txRate: interface.txRateDisplay,
          rxRate: interface.rxRateDisplay,
        );
        debugPrint('[Traffic] Notifiers created for $name');
      }
    }
    debugPrint('[Traffic] _updateTrafficValues completed');
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider but don't let it trigger rebuilds unnecessarily
    // We'll update local state instead
    final trafficAsync = ref.watch(interfaceTrafficProvider);
    debugPrint('[Traffic] build() called, provider state: ${trafficAsync.value?.length ?? 0} interfaces');

    // Update local state whenever provider data changes (but don't setState here)
    trafficAsync.when(
      data: (interfaces) {
        // Always update current data reference
        _currentData = interfaces;
        // Update notifiers with new values - this triggers text updates
        _updateTrafficValues(interfaces);
        // Start auto-refresh timer when data becomes available
        _startAutoRefresh();
      },
      loading: () {},
      error: (_, __) => {},
    );

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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.appSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.network_check_rounded,
                    color: context.appSecondary,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Interface Traffic',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: context.appOnSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_currentData == null)
              _buildLoadingState(context)
            else if (_currentData!.isEmpty)
              _buildEmptyState(context)
            else
              _buildInterfaceList(context, _currentData!),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(context.appSecondary),
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lan_rounded,
              color: context.appOnSurface.withValues(alpha: 0.3),
              size: 48,
            ),
            SizedBox(height: 8),
            Text(
              'No interfaces found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.appOnSurface.withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterfaceList(BuildContext context, List<InterfaceTraffic> interfaces) {
    // Filter only running interfaces and sort by type (ether first, then wlan, then others)
    final runningInterfaces = interfaces
        .where((i) => i.running)
        .toList()
      ..sort((a, b) {
        // Priority: ether > wlan > bridge > other
        const priority = {'ether': 0, 'wlan': 1, 'bridge': 2};
        final aPriority = priority[a.type] ?? 3;
        final bPriority = priority[b.type] ?? 3;
        return aPriority.compareTo(bPriority);
      });

    if (runningInterfaces.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: runningInterfaces.map((interface) {
        return _buildInterfaceCard(context, interface);
      }).toList(),
    );
  }

  Widget _buildInterfaceCard(BuildContext context, InterfaceTraffic interface) {
    final iconColor = _getInterfaceTypeColor(interface.type);
    final interfaceIcon = _getInterfaceTypeIcon(interface.type);

    // Get or create notifiers for this interface
    var notifiers = _trafficNotifiers[interface.name];
    if (notifiers == null) {
      notifiers = _InterfaceTrafficNotifiers(
        tx: interface.txDisplay,
        rx: interface.rxDisplay,
        txRate: interface.txRateDisplay,
        rxRate: interface.rxRateDisplay,
      );
      _trafficNotifiers[interface.name] = notifiers;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.appOnSurface.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  interfaceIcon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      interface.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: context.appOnSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      _getInterfaceTypeLabel(interface.type),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.appOnSurface.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(context, interface),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTrafficStat(
                  context,
                  icon: Icons.upload_rounded,
                  label: 'TX',
                  txNotifier: notifiers.txDisplay,
                  rateNotifier: notifiers.txRateDisplay,
                  color: context.appSecondary,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildTrafficStat(
                  context,
                  icon: Icons.download_rounded,
                  label: 'RX',
                  txNotifier: notifiers.rxDisplay,
                  rateNotifier: notifiers.rxRateDisplay,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, InterfaceTraffic interface) {
    final isEnabled = interface.enabled ?? true;
    final isRunning = interface.running;

    if (!isEnabled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: context.appOnSurface.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'Disabled',
          style: TextStyle(
            color: context.appOnSurface.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (isRunning) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.successColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.successColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 4),
            Text(
              'Active',
              style: TextStyle(
                color: AppTheme.successColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Inactive',
        style: TextStyle(
          color: AppTheme.warningColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTrafficStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required ValueNotifier<String> txNotifier,
    required ValueNotifier<String> rateNotifier,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          // ValueListenableBuilder rebuilds ONLY this text when value changes
          ValueListenableBuilder<String>(
            valueListenable: txNotifier,
            builder: (context, value, _) {
              return Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: context.appOnSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
              );
            },
          ),
          SizedBox(height: 2),
          // ValueListenableBuilder rebuilds ONLY this text when rate changes
          ValueListenableBuilder<String>(
            valueListenable: rateNotifier,
            builder: (context, rate, _) {
              return Text(
                rate,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.appOnSurface.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getInterfaceTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'ether':
        return const Color(0xFF06B6D4); // Cyan
      case 'wlan':
      case 'wifi':
        return const Color(0xFF8B5CF6); // Violet
      case 'bridge':
        return const Color(0xFF10B981); // Emerald
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  IconData _getInterfaceTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'ether':
        return Icons.settings_ethernet_rounded;
      case 'wlan':
      case 'wifi':
        return Icons.wifi_rounded;
      case 'bridge':
        return Icons.hub_rounded;
      default:
        return Icons.lan_rounded;
    }
  }

  String _getInterfaceTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'ether':
        return 'Ethernet';
      case 'wlan':
        return 'Wireless';
      case 'bridge':
        return 'Bridge';
      default:
        return type;
    }
  }
}

// Helper class to hold individual notifiers for each interface's traffic values
class _InterfaceTrafficNotifiers {
  final ValueNotifier<String> txDisplay;
  final ValueNotifier<String> rxDisplay;
  final ValueNotifier<String> txRateDisplay;
  final ValueNotifier<String> rxRateDisplay;

  _InterfaceTrafficNotifiers({
    required String tx,
    required String rx,
    required String txRate,
    required String rxRate,
  })  : txDisplay = ValueNotifier(tx),
        rxDisplay = ValueNotifier(rx),
        txRateDisplay = ValueNotifier(txRate),
        rxRateDisplay = ValueNotifier(rxRate);

  void update({
    required String tx,
    required String rx,
    required String txRate,
    required String rxRate,
  }) {
    txDisplay.value = tx;
    rxDisplay.value = rx;
    txRateDisplay.value = txRate;
    rxRateDisplay.value = rxRate;
  }

  void dispose() {
    txDisplay.dispose();
    rxDisplay.dispose();
    txRateDisplay.dispose();
    rxRateDisplay.dispose();
  }
}
