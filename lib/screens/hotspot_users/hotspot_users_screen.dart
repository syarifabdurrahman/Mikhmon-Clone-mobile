import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/routeros_service.dart';
import '../../services/models.dart';
import 'hotspot_user_details_screen.dart';
import 'add_hotspot_user_screen.dart';

class HotspotUsersScreen extends StatefulWidget {
  const HotspotUsersScreen({super.key});

  @override
  State<HotspotUsersScreen> createState() => _HotspotUsersScreenState();
}

class _HotspotUsersScreenState extends State<HotspotUsersScreen> {
  final _routerOSService = RouterOSService();
  bool _isLoading = false;
  String? _errorMessage;
  List<HotspotUser> _users = [];
  String _searchQuery = '';
  UserStatusFilter _statusFilter = UserStatusFilter.all;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if demo mode is enabled
      if (_routerOSService.isDemoMode) {
        // Simulate loading delay
        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          setState(() {
            _users = _getDemoUsers();
            _isLoading = false;
          });
        }
        return;
      }

      final client = _routerOSService.client;
      if (client != null) {
        final usersData = await client.getHotspotUsersList();

        if (mounted) {
          setState(() {
            _users = usersData.map((data) => HotspotUser.fromJson(data)).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Not connected to RouterOS';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<HotspotUser> _getDemoUsers() {
    return [
      HotspotUser(
        id: '*1',
        name: 'john_doe',
        profile: 'premium',
        active: true,
        uptime: '2h 15m',
        bytesIn: 524288000,
        bytesOut: 1048576000,
        limitBytesIn: null,
        limitBytesOut: null,
      ),
      HotspotUser(
        id: '*2',
        name: 'jane_smith',
        profile: 'default',
        active: true,
        uptime: '45m',
        bytesIn: 104857600,
        bytesOut: 209715200,
        limitBytesIn: 524288000,
        limitBytesOut: 1048576000,
      ),
      HotspotUser(
        id: '*3',
        name: 'guest_user',
        profile: 'trial',
        active: false,
        uptime: null,
        bytesIn: 0,
        bytesOut: 0,
        limitBytesIn: 104857600,
        limitBytesOut: 209715200,
      ),
      HotspotUser(
        id: '*4',
        name: 'admin_test',
        profile: 'unlimited',
        active: true,
        uptime: '1d 3h',
        bytesIn: 1073741824,
        bytesOut: 2147483648,
        limitBytesIn: null,
        limitBytesOut: null,
      ),
      HotspotUser(
        id: '*5',
        name: 'expired_user',
        profile: 'default',
        active: false,
        uptime: null,
        bytesIn: 52428800,
        bytesOut: 104857600,
        limitBytesIn: 104857600,
        limitBytesOut: 209715200,
      ),
    ];
  }

  List<HotspotUser> get _filteredUsers {
    var filtered = _users;

    // Apply status filter
    if (_statusFilter == UserStatusFilter.active) {
      filtered = filtered.where((u) => u.active).toList();
    } else if (_statusFilter == UserStatusFilter.inactive) {
      filtered = filtered.where((u) => !u.active).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((u) =>
              u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              u.profile.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
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
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text(
          'Hotspot Users',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.onSurfaceColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _loadUsers,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddUser(),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onPrimaryColor,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add User'),
      ),
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
                'Error loading users',
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
                onPressed: _loadUsers,
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

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: AppTheme.onSurfaceColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No hotspot users found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.onBackgroundColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first hotspot user to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onBackgroundColor.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_routerOSService.isDemoMode) _buildDemoBanner(),
        _buildSearchBar(),
        _buildStatusChips(),
        Expanded(
          child: _filteredUsers.isEmpty
              ? Center(
                  child: Text(
                    'No users match your filters',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.onBackgroundColor.withValues(alpha: 0.7),
                        ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  color: AppTheme.primaryColor,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredUsers.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return _buildUserCard(user);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search by name or profile...',
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
        ),
      ),
    );
  }

  Widget _buildStatusChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatusChip('All', UserStatusFilter.all),
          const SizedBox(width: 8),
          _buildStatusChip('Active', UserStatusFilter.active),
          const SizedBox(width: 8),
          _buildStatusChip('Inactive', UserStatusFilter.inactive),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, UserStatusFilter filter) {
    final isSelected = _statusFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _statusFilter = filter;
        });
      },
      backgroundColor: AppTheme.surfaceColor,
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isSelected ? AppTheme.primaryColor : AppTheme.onSurfaceColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
    );
  }

  Widget _buildUserCard(HotspotUser user) {
    return Card(
      color: AppTheme.surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: user.active
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : AppTheme.onSurfaceColor.withValues(alpha: 0.1),
          width: user.active ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToUserDetails(user),
        onLongPress: () => _showUserOptions(user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: user.active
                          ? AppTheme.primaryColor.withValues(alpha: 0.1)
                          : AppTheme.onSurfaceColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: user.active ? AppTheme.primaryColor : AppTheme.onSurfaceColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.onSurfaceColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.profile,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(user.active),
                ],
              ),
              if (user.active && user.uptime != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Uptime: ${user.uptime}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.data_usage_rounded,
                      size: 14,
                      color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      user.dataUsed,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? AppTheme.primaryColor.withValues(alpha: 0.15)
            : AppTheme.onSurfaceColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active
              ? AppTheme.primaryColor.withValues(alpha: 0.5)
              : AppTheme.onSurfaceColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: active ? AppTheme.primaryColor : AppTheme.onSurfaceColor.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Users'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<UserStatusFilter>(
              segments: const [
                ButtonSegment(
                  value: UserStatusFilter.all,
                  label: Text('All'),
                  icon: Icon(Icons.list_rounded, size: 18),
                ),
                ButtonSegment(
                  value: UserStatusFilter.active,
                  label: Text('Active'),
                  icon: Icon(Icons.check_circle_rounded, size: 18),
                ),
                ButtonSegment(
                  value: UserStatusFilter.inactive,
                  label: Text('Inactive'),
                  icon: Icon(Icons.cancel_rounded, size: 18),
                ),
              ],
              selected: {_statusFilter},
              onSelectionChanged: (Set<UserStatusFilter> newSelection) {
                setState(() {
                  _statusFilter = newSelection.first;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUserOptions(HotspotUser user) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_rounded),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _navigateToUserDetails(user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit User'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to edit user screen
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_rounded, color: AppTheme.errorColor),
              title: Text('Delete User', style: TextStyle(color: AppTheme.errorColor)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteUser(user);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToUserDetails(HotspotUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HotspotUserDetailsScreen(user: user),
      ),
    ).then((_) => _loadUsers()); // Refresh list when returning from details
  }

  void _navigateToAddUser() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddHotspotUserScreen(),
      ),
    ).then((_) => _loadUsers());
  }

  void _confirmDeleteUser(HotspotUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete user "${user.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(user);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(HotspotUser user) async {
    try {
      // Skip actual deletion in demo mode
      if (_routerOSService.isDemoMode) {
        if (mounted) {
          setState(() {
            _users.removeWhere((u) => u.id == user.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User "${user.name}" removed (demo mode)'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
        return;
      }

      final client = _routerOSService.client;
      if (client != null) {
        await client.removeHotspotUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User "${user.name}" deleted successfully'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
          _loadUsers();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete user: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildDemoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 12),
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
              'Demo Mode - Showing simulated users',
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

enum UserStatusFilter { all, active, inactive }
