import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../services/models.dart';

class HotspotActiveUsersScreen extends ConsumerStatefulWidget {
  const HotspotActiveUsersScreen({super.key});

  @override
  ConsumerState<HotspotActiveUsersScreen> createState() => _HotspotActiveUsersScreenState();
}

class _HotspotActiveUsersScreenState extends ConsumerState<HotspotActiveUsersScreen> {
  String _searchQuery = '';
  String _selectedServer = 'All';
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreUsers();
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoadingMore) return;

    final paginatedUsers = ref.read(hotspotActiveUsersProvider).value;
    if (paginatedUsers == null || !paginatedUsers.hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await ref.read(hotspotActiveUsersProvider.notifier).loadMore();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _startAutoRefresh() {
    final service = ref.read(routerOSServiceProvider);

    // Only refresh periodically in real mode (not demo)
    // In demo mode, individual cards update themselves
    if (service.isDemoMode) {
      debugPrint('[ActiveUsers] Demo mode - skipping periodic refresh');
      return;
    }

    // Refresh every 5 seconds to get actual data from router
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        debugPrint('[ActiveUsers] Periodic refresh triggered');
        ref.read(hotspotActiveUsersProvider.notifier).refresh();
      }
    });

    debugPrint('[ActiveUsers] Started periodic refresh (every 5 seconds)');
  }

  @override
  Widget build(BuildContext context) {
    final activeUsersAsync = ref.watch(hotspotActiveUsersProvider);
    final service = ref.watch(routerOSServiceProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.onSurfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text(
          'Active Users',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.onSurfaceColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          if (service.isDemoMode)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.2),
                    AppTheme.primaryColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
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
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'DEMO',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(hotspotActiveUsersProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: activeUsersAsync.when(
              data: (paginatedUsers) {
                final users = paginatedUsers.users.map((data) => HotspotActiveUser.fromJson(data)).toList();
                final filteredUsers = _filterUsers(users);

                if (filteredUsers.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(hotspotActiveUsersProvider.notifier).refresh(),
                  color: AppTheme.primaryColor,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredUsers.length + (paginatedUsers.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filteredUsers.length) {
                        return _buildLoadingIndicator();
                      }
                      final user = filteredUsers[index];
                      // Use the new widget card that handles its own dynamic updates
                      return RepaintBoundary(
                        key: ValueKey(user.id),
                        child: _UserCardWidget(
                          user: user,
                          onTap: () => _showUserDetails(user),
                          onDetails: () => _showUserDetails(user),
                          onLogout: () => _confirmLogout(user),
                          isDemoMode: service.isDemoMode,
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading active users',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.onSurfaceColor,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
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
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by username or IP...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.filter_list_rounded,
                size: 18,
                color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                'Filter by server:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceColor.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'All',
                      label: Text('All'),
                    ),
                    ButtonSegment(
                      value: 'hotspot1',
                      label: Text('HS1'),
                    ),
                  ],
                  selected: {_selectedServer},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedServer = newSelection.first;
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppTheme.primaryColor;
                      }
                      return AppTheme.backgroundColor;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppTheme.onPrimaryColor;
                      }
                      return AppTheme.onSurfaceColor;
                    }),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<HotspotActiveUser> _filterUsers(List<HotspotActiveUser> users) {
    var filtered = users;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        return user.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.address.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply server filter
    if (_selectedServer != 'All') {
      filtered = filtered.where((user) => user.server == _selectedServer).toList();
    }

    return filtered;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 64,
            color: AppTheme.onSurfaceColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No active users',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.onSurfaceColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Currently no users are logged into the hotspot',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      ),
    );
  }

  void _showUserDetails(HotspotActiveUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.onSurfaceColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: AppTheme.onSurfaceColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 6,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Connected',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                controller: scrollController,
                children: [
                  _buildDetailTile(Icons.badge_rounded, 'Username', user.username),
                  _buildDetailTile(Icons.computer_rounded, 'IP Address', user.address),
                  _buildDetailTile(Icons.router_rounded, 'MAC Address', user.macAddress),
                  _buildDetailTile(Icons.access_time_rounded, 'Login Time', _formatLoginTime(user.loginTime)),
                  _buildDetailTile(Icons.timer_rounded, 'Uptime', user.uptime),
                  _buildDetailTile(Icons.swap_vert_rounded, 'Data Used', user.dataUsed),
                  _buildDetailTile(Icons.cloud_rounded, 'Server', user.server ?? 'N/A'),
                  _buildDetailTile(Icons.card_membership_rounded, 'Profile', user.profile),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _confirmLogout(user);
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: AppTheme.primaryColor,
      ),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
            ),
      ),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.onSurfaceColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  String _formatLoginTime(String timestamp) {
    try {
      final seconds = int.parse(timestamp);
      final dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  void _confirmLogout(HotspotActiveUser user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Logout User'),
        content: Text('Are you sure you want to logout "${user.username}" from ${user.address}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref.read(hotspotActiveUsersProvider.notifier).logoutUser(user.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('User "${user.username}" logged out successfully'),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to logout user: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

/// Individual user card widget that handles its own dynamic updates
/// Only the dynamic values (uptime, data used) update, not the entire card
class _UserCardWidget extends StatefulWidget {
  final HotspotActiveUser user;
  final VoidCallback onTap;
  final VoidCallback onDetails;
  final VoidCallback onLogout;
  final bool isDemoMode;

  const _UserCardWidget({
    required this.user,
    required this.onTap,
    required this.onDetails,
    required this.onLogout,
    this.isDemoMode = false,
  });

  @override
  State<_UserCardWidget> createState() => _UserCardWidgetState();
}

class _UserCardWidgetState extends State<_UserCardWidget> {
  late String _displayUptime;
  late String _displayDataUsed;
  Timer? _updateTimer;
  final Random _random = Random();

  // Track initial bytes for demo mode simulation
  late int _initialBytesIn;
  late int _initialBytesOut;

  @override
  void initState() {
    super.initState();
    _displayUptime = widget.user.uptime;
    _displayDataUsed = widget.user.dataUsed;
    _initialBytesIn = widget.user.bytesIn;
    _initialBytesOut = widget.user.bytesOut;

    // Start local timer for dynamic updates (every 1 second)
    _startDynamicUpdates();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startDynamicUpdates() {
    // Update dynamic values every second independently
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (widget.isDemoMode) {
            // Demo mode: simulate data changes
            _simulateDynamicUpdates();
          } else {
            // Real mode: use actual values from user object
            // (these update when provider refreshes)
            _displayUptime = widget.user.uptime;
            _displayDataUsed = widget.user.dataUsed;
          }
        });
      }
    });
  }

  void _simulateDynamicUpdates() {
    // Simulate uptime increment
    final uptimeParts = widget.user.uptime.split(' ');
    if (uptimeParts.isNotEmpty) {
      final lastPart = uptimeParts.last;
      final value = int.tryParse(lastPart.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
      final unit = lastPart.replaceAll(RegExp(r'[\d]'), '');

      if (unit.contains('m') || unit.isEmpty) {
        final newValue = value + 1;
        final prefix = uptimeParts.sublist(0, uptimeParts.length - 1).join(' ');
        _displayUptime = '$prefix${uptimeParts.length > 1 ? ' ' : ''}${newValue}m';
      }
    }

    // Simulate data usage increase
    final additionalBytes = _random.nextInt(1024 * 100); // 0-100KB
    final currentBytesIn = _initialBytesIn + additionalBytes;
    final currentBytesOut = _initialBytesOut + (additionalBytes ~/ 2);
    final totalBytes = currentBytesIn + currentBytesOut;

    if (totalBytes < 1024 * 1024) {
      _displayDataUsed = '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else if (totalBytes < 1024 * 1024 * 1024) {
      _displayDataUsed = '${(totalBytes / 1024 / 1024).toStringAsFixed(1)} MB';
    } else {
      _displayDataUsed = '${(totalBytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.username,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.onSurfaceColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.computer_rounded,
                              size: 14,
                              color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.user.address,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                                    fontFamily: 'monospace',
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Online',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: AppTheme.onSurfaceColor.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      Icons.access_time_rounded,
                      'Uptime',
                      _displayUptime,
                      AppTheme.primaryColor,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppTheme.onSurfaceColor.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      Icons.download_rounded,
                      'Download',
                      _displayDataUsed,
                      Colors.blue,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppTheme.onSurfaceColor.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      Icons.router_rounded,
                      'Server',
                      widget.user.server ?? 'N/A',
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: widget.onDetails,
                    icon: const Icon(Icons.info_outline_rounded, size: 18),
                    label: const Text('Details'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: widget.onLogout,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor.withValues(alpha: 0.1),
                      foregroundColor: AppTheme.errorColor,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
