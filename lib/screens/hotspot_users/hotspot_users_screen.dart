import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../services/routeros_service.dart';
import '../../services/models.dart';
import 'hotspot_user_details_screen.dart';
import 'add_hotspot_user_screen.dart';
import 'edit_hotspot_user_screen.dart';

class HotspotUsersScreen extends ConsumerStatefulWidget {
  const HotspotUsersScreen({super.key});

  @override
  ConsumerState<HotspotUsersScreen> createState() => _HotspotUsersScreenState();
}

class _HotspotUsersScreenState extends ConsumerState<HotspotUsersScreen>
    with AutomaticKeepAliveClientMixin {
  String _searchQuery = '';
  UserStatusFilter _statusFilter = UserStatusFilter.all;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  bool get wantKeepAlive => true;

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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final usersAsync = ref.watch(hotspotUsersProvider);
    final service = ref.watch(routerOSServiceProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(service),
      body: Column(
        children: [
          _SearchAndFilterBar(
            searchQuery: _searchQuery,
            statusFilter: _statusFilter,
            onSearchChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            onClearSearch: () {
              setState(() {
                _searchQuery = '';
              });
            },
            onFilterChanged: (filter) {
              setState(() {
                _statusFilter = filter;
              });
            },
          ),
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
                    // Performance optimization: estimated item height
                    itemExtent: 100,
                    // Performance optimization: repaint boundaries
                    addRepaintBoundaries: true,
                    // Performance optimization: cache extent
                    cacheExtent: 500,
                    itemBuilder: (context, index) {
                      if (index == filteredUsers.length) {
                        return const _LoadingIndicator();
                      }
                      return RepaintBoundary(
                        key: ValueKey(filteredUsers[index].id),
                        child: _UserCard(
                          user: filteredUsers[index],
                          onTap: () => _navigateToUserDetails(filteredUsers[index]),
                          onLongPress: () => _showUserContextMenu(filteredUsers[index]),
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
              error: (error, stack) => _buildErrorState(error.toString()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddUser(),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onPrimaryColor,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add User'),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(RouterOSService service) {
    return AppBar(
      backgroundColor: AppTheme.surfaceColor,
      foregroundColor: AppTheme.onSurfaceColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.go('/dashboard'),
      ),
      title: const Text(
        'Hotspot Users',
        style: TextStyle(
          color: AppTheme.onSurfaceColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (service.isDemoMode) _buildDemoBadge(),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            ref.read(hotspotUsersProvider.notifier).refresh();
          },
        ),
      ],
    );
  }

  Widget _buildDemoBadge() {
    return Container(
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
      child: const Row(
        children: [
          Icon(
            Icons.science_rounded,
            color: AppTheme.primaryColor,
            size: 16,
          ),
          SizedBox(width: 6),
          Text(
            'DEMO',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  List<HotspotUser> _filterUsers(List<HotspotUser> users) {
    var filtered = users;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((user) {
        return user.name.toLowerCase().contains(query) ||
            user.profile.toLowerCase().contains(query);
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
    final hasFilters = _searchQuery.isNotEmpty || _statusFilter != UserStatusFilter.all;

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
          const Text(
            'No hotspot users found',
            style: TextStyle(
              color: AppTheme.onSurfaceColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters ? 'Try adjusting your search or filter' : 'Add your first user to get started',
            style: TextStyle(
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          const Text(
            'Error loading users',
            style: TextStyle(
              color: AppTheme.onSurfaceColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAddUser() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddHotspotUserScreen(),
      ),
    );
  }

  void _navigateToUserDetails(HotspotUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HotspotUserDetailsScreen(user: user),
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
      builder: (sheetContext) => _UserContextMenu(
        user: user,
        onViewDetails: () {
          Navigator.pop(sheetContext);
          _navigateToUserDetails(user);
        },
        onEdit: () async {
          Navigator.pop(sheetContext);
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
            context,
            MaterialPageRoute(
              builder: (context) => EditHotspotUserScreen(user: userData),
            ),
          );
        },
        onToggleStatus: () async {
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
        onDelete: () {
          Navigator.pop(sheetContext);
          _confirmDeleteUser(user);
        },
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

// Extracted search and filter bar widget for better performance
class _SearchAndFilterBar extends StatelessWidget {
  final String searchQuery;
  final UserStatusFilter statusFilter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<UserStatusFilter> onFilterChanged;

  const _SearchAndFilterBar({
    required this.searchQuery,
    required this.statusFilter,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
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
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: onClearSearch,
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 12),
          SegmentedButton<UserStatusFilter>(
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
            selected: {statusFilter},
            onSelectionChanged: (newSelection) => onFilterChanged(newSelection.first),
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
        ],
      ),
    );
  }
}

// Extracted user card widget for better performance with RepaintBoundary
class _UserCard extends StatelessWidget {
  final HotspotUser user;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _UserCard({
    required this.user,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
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
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _UserAvatar(active: user.active),
              const SizedBox(width: 16),
              Expanded(
                child: _UserInfo(user: user),
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
}

// Extracted user avatar widget
class _UserAvatar extends StatelessWidget {
  final bool active;

  const _UserAvatar({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: active ? _activeAvatarColors : _inactiveAvatarColors,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.person_rounded,
        color: active ? Colors.white : AppTheme.onSurfaceColor.withValues(alpha: 0.5),
      ),
    );
  }
}

// Extracted user info widget
class _UserInfo extends StatelessWidget {
  final HotspotUser user;

  const _UserInfo({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.name,
          style: const TextStyle(
            color: AppTheme.onSurfaceColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        _UserStatusBadge(user: user),
      ],
    );
  }
}

// Extracted user status badge widget
class _UserStatusBadge extends StatelessWidget {
  final HotspotUser user;

  const _UserStatusBadge({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
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
            style: TextStyle(
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
          color: user.active ? Colors.green : AppTheme.onSurfaceColor.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 4),
        Text(
          user.active ? 'Connected' : 'Disconnected',
          style: TextStyle(
            color: user.active ? Colors.green : AppTheme.onSurfaceColor.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// Extracted loading indicator widget
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      ),
    );
  }
}

// Extracted user context menu widget
class _UserContextMenu extends StatelessWidget {
  final HotspotUser user;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _UserContextMenu({
    required this.user,
    required this.onViewDetails,
    required this.onEdit,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          ListTile(
            leading: const Icon(Icons.visibility_rounded),
            title: const Text('View Details'),
            onTap: onViewDetails,
          ),
          ListTile(
            leading: const Icon(Icons.edit_rounded),
            title: const Text('Edit User'),
            onTap: onEdit,
          ),
          ListTile(
            leading: Icon(
              user.active ? Icons.wifi_off_rounded : Icons.wifi_rounded,
              color: user.active ? AppTheme.errorColor : AppTheme.primaryColor,
            ),
            title: Text(user.active ? 'Disable User' : 'Enable User'),
            onTap: onToggleStatus,
          ),
          ListTile(
            leading: const Icon(Icons.delete_rounded, color: AppTheme.errorColor),
            title: const Text('Delete User'),
            onTap: onDelete,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.onSurfaceColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

enum UserStatusFilter { all, active, inactive }

// Constants for avatar gradients
const List<Color> _activeAvatarColors = [
  AppTheme.primaryColor,
  Color(0xFF1976D2),
];

const List<Color> _inactiveAvatarColors = [
  Color(0x4DFFFFFF),
  Color(0x33FFFFFF),
];
