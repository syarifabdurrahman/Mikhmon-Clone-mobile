import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../services/models.dart';
import 'hotspot_user_details_screen.dart';
import 'add_hotspot_user_screen.dart';
import 'edit_hotspot_user_screen.dart';

class HotspotUsersScreen extends ConsumerStatefulWidget {
  const HotspotUsersScreen({super.key});

  @override
  ConsumerState<HotspotUsersScreen> createState() => _HotspotUsersScreenState();
}

class _HotspotUsersScreenState extends ConsumerState<HotspotUsersScreen> {
  String _searchQuery = '';
  UserStatusFilter _statusFilter = UserStatusFilter.all;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreUsers();
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoadingMore) return;

    final paginatedUsers = ref.read(hotspotUsersProvider).value;
    if (paginatedUsers == null || !paginatedUsers.hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await ref.read(hotspotUsersProvider.notifier).loadMore();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(hotspotUsersProvider);
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
          'Hotspot Users',
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
              ref.read(hotspotUsersProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: usersAsync.when(
              data: (paginatedUsers) {
                // Convert Map data to HotspotUser objects
                final users = paginatedUsers.users.map((data) => HotspotUser.fromJson(data)).toList();
                final filteredUsers = _filterUsers(users);

                if (filteredUsers.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(hotspotUsersProvider.notifier).refresh(),
                  color: AppTheme.primaryColor,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredUsers.length + (paginatedUsers.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filteredUsers.length) {
                        return _buildLoadingIndicator();
                      }
                      return _buildUserCard(filteredUsers[index]);
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
                      'Error loading users',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddHotspotUserScreen(),
            ),
          );
          // If user was added successfully, the provider will automatically update
          // No need to manually refresh - Riverpod handles this
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onPrimaryColor,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add User'),
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
              hintText: 'Search by username or profile...',
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
              Expanded(
                child: SegmentedButton<UserStatusFilter>(
                  segments: const [
                    ButtonSegment(
                      value: UserStatusFilter.all,
                      label: Text('All'),
                      icon: Icon(Icons.people_rounded, size: 18),
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

  List<HotspotUser> _filterUsers(List<HotspotUser> users) {
    var filtered = users;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        return user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.profile.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply status filter
    switch (_statusFilter) {
      case UserStatusFilter.active:
        filtered = filtered.where((user) => user.active).toList();
        break;
      case UserStatusFilter.inactive:
        filtered = filtered.where((user) => !user.active).toList();
        break;
      case UserStatusFilter.all:
        break;
    }

    return filtered;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_rounded,
            size: 64,
            color: AppTheme.onSurfaceColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No hotspot users found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.onSurfaceColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _statusFilter != UserStatusFilter.all
                ? 'Try adjusting your search or filter'
                : 'Add your first user to get started',
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

  Widget _buildUserCard(HotspotUser user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: user.active
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : AppTheme.onSurfaceColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HotspotUserDetailsScreen(user: user),
            ),
          );
        },
        onLongPress: () => _showUserContextMenu(user),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: user.active
                        ? [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withValues(alpha: 0.7),
                          ]
                        : [
                            AppTheme.onSurfaceColor.withValues(alpha: 0.3),
                            AppTheme.onSurfaceColor.withValues(alpha: 0.2),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: user.active ? Colors.white : AppTheme.onSurfaceColor.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: user.active
                                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                                : AppTheme.onSurfaceColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: user.active
                                  ? AppTheme.primaryColor.withValues(alpha: 0.3)
                                  : AppTheme.onSurfaceColor.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            user.profile.toUpperCase(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: user.active
                                      ? AppTheme.primaryColor
                                      : AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          user.active ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                          size: 16,
                          color: user.active
                              ? Colors.green
                              : AppTheme.onSurfaceColor.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.active ? 'Connected' : 'Disconnected',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: user.active
                                    ? Colors.green
                                    : AppTheme.onSurfaceColor.withValues(alpha: 0.5),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppTheme.onSurfaceColor.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserContextMenu(HotspotUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            ListTile(
              leading: const Icon(Icons.visibility_rounded),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,  // Use outer context
                  MaterialPageRoute(
                    builder: (context) => HotspotUserDetailsScreen(user: user),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit User'),
              onTap: () async {
                Navigator.pop(sheetContext);
                // Convert HotspotUser to Map and navigate to edit screen
                final userData = {
                  '.id': user.id,
                  'name': user.name,
                  'profile': user.profile,
                  'active': user.active.toString(),
                  'uptime': user.uptime ?? '0',
                  'bytes-in': (user.bytesIn ?? 0).toString(),
                  'bytes-out': (user.bytesOut ?? 0).toString(),
                  'limit-uptime': '0',
                  'disabled': (!user.active).toString(),
                  'comment': '',
                };
                await Navigator.push(
                  context,  // Use outer context
                  MaterialPageRoute(
                    builder: (context) => EditHotspotUserScreen(user: userData),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                user.active ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                color: user.active ? AppTheme.errorColor : AppTheme.primaryColor,
              ),
              title: Text(user.active ? 'Disable User' : 'Enable User'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await ref.read(hotspotUsersProvider.notifier).toggleUserStatus(user.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('User "${user.name}" ${user.active ? 'disabled' : 'enabled'}'),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: AppTheme.errorColor),
              title: const Text('Delete User'),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDeleteUser(user);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteUser(HotspotUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete user "${user.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (!mounted) return;
              final messenger = ScaffoldMessenger.of(context);
              await ref.read(hotspotUsersProvider.notifier).deleteUser(user.id);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('User "${user.name}" deleted successfully'),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
              }
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
}

enum UserStatusFilter { all, active, inactive }
