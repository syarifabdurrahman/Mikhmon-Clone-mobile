import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/routeros_service.dart';
import '../../services/models.dart';
import 'widgets/resource_card_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _routerOSService = RouterOSService();
  bool _isLoading = false;
  String? _errorMessage;
  SystemResources? _resources;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Check if demo mode is enabled
      if (_routerOSService.isDemoMode) {
        // Simulate loading delay for initial load
        if (showLoading) {
          await Future.delayed(const Duration(milliseconds: 800));
        }

        if (mounted) {
          setState(() {
            _resources = _getDemoResources();
          });
        }
        return;
      }

      if (!_routerOSService.isConnected) {
        await _routerOSService.connect();
      }

      final client = _routerOSService.client;

      if (client != null && mounted) {
        final resourcesData = await client.getSystemResources();

        if (mounted) {
          setState(() {
            _resources = SystemResources.fromJson(resourcesData);
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

  SystemResources _getDemoResources() {
    // Return static base resources - individual widgets handle dynamic updates
    return SystemResources(
      platform: 'Mikrotik Cloud Hosted Router',
      boardName: 'CHR-demo',
      version: '7.12 (long-term)',
      cpuFrequency: 1000,
      cpuLoad: 15,
      freeMemory: 1048576,
      totalMemory: 2097152,
      freeHddSpace: 52428800,
      totalHddSpace: 104857600,
      uptimeSeconds: 86400 * 3 + 3600 * 12 + 1800,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.onSurfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            RouterOSService().setDemoMode(false);
            context.go('/');
          },
        ),
        title: Text(
          'Dashboard',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.onSurfaceColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : () => _loadDashboardData(showLoading: true),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Connection Error',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.onBackgroundColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onBackgroundColor.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadDashboardData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.onPrimaryColor,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_resources == null) {
      return Center(
        child: Text(
          'No data available',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.onBackgroundColor,
              ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadDashboardData(showLoading: false),
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_routerOSService.isDemoMode) _buildDemoBanner(),
            _buildSystemInfoCard(),
            const SizedBox(height: 16),
            _buildResourceCards(),
            const SizedBox(height: 16),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return Card(
      color: AppTheme.surfaceColor,
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
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.router_rounded,
                    color: AppTheme.primaryColor,
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
                              color: AppTheme.onSurfaceColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RouterOS ${_resources!.version}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
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

  Widget _buildResourceCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resources',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.onBackgroundColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CpuLoadCard(initialResources: _resources),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MemoryCard(initialResources: _resources),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DiskCard(initialResources: _resources),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                Icons.people_rounded,
                'All Users',
                subtitle: 'View All',
                onTap: () {
                  context.go('/users');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                Icons.wifi_rounded,
                'Active Users',
                subtitle: 'View Connected',
                onTap: () {
                  context.go('/users/active');
                },
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                Icons.person_add_rounded,
                'Add User',
                subtitle: 'Create New',
                onTap: () {
                  context.push('/users/add');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                Icons.card_membership_rounded,
                'User Profiles',
                subtitle: 'Manage Profiles',
                onTap: () {
                  context.go('/profiles');
                },
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                Icons.settings_rounded,
                'Settings',
                subtitle: 'Configure',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings feature coming soon')),
                  );
                },
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    IconData icon,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
    Color? color,
  }) {
    final cardColor = color ?? AppTheme.primaryColor;

    return Card(
      color: AppTheme.surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: cardColor,
                size: 20,
              ),
              const SizedBox(height: 8),
              Text(
                title,
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
                        color: cardColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.onBackgroundColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          color: AppTheme.surfaceColor,
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
                  context.push('/users/add');
                },
              ),
              Divider(
                height: 1,
                color: AppTheme.onSurfaceColor.withValues(alpha: 0.1),
              ),
              _buildActionButton(
                Icons.wifi_rounded,
                'Manage Hotspot',
                Icons.arrow_forward_ios_rounded,
                () {
                  context.go('/users');
                },
              ),
              Divider(
                height: 1,
                color: AppTheme.onSurfaceColor.withValues(alpha: 0.1),
              ),
              _buildActionButton(
                Icons.card_membership_rounded,
                'User Profiles',
                Icons.arrow_forward_ios_rounded,
                () {
                  context.go('/profiles');
                },
              ),
              Divider(
                height: 1,
                color: AppTheme.onSurfaceColor.withValues(alpha: 0.1),
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
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.onSurfaceColor,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            Icon(
              trailingIcon,
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
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
          color: AppTheme.primaryColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
              ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceColor,
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

  Widget _buildDemoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.2),
            AppTheme.primaryColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.science_rounded,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Demo Mode - Showing simulated data',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
