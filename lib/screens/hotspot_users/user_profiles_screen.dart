import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../services/models.dart';
import 'add_edit_profile_screen.dart';

class UserProfilesScreen extends ConsumerStatefulWidget {
  const UserProfilesScreen({super.key});

  @override
  ConsumerState<UserProfilesScreen> createState() => _UserProfilesScreenState();
}

class _UserProfilesScreenState extends ConsumerState<UserProfilesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final profilesAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: profilesAsync.when(
        data: (profiles) {
          if (profiles.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(userProfileProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: profiles.length,
              // Performance optimization: estimated item height for better scrolling
              itemExtent: 190,
              // Performance optimization: explicit repaint boundaries
              addRepaintBoundaries: true,
              // Performance optimization: keep widgets alive for better performance
              addAutomaticKeepAlives: true,
              // Performance optimization: cache extent determines how many widgets to render off-screen
              cacheExtent: 500,
              itemBuilder: (context, index) {
                return RepaintBoundary(
                  key: ValueKey(profiles[index].id),
                  child: _ProfileCard(
                    profile: profiles[index],
                    onTap: () => _showProfileDetails(profiles[index]),
                    onMoreTap: () => _showProfileOptions(profiles[index]),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddProfile,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onPrimaryColor,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Profile'),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.surfaceColor,
      foregroundColor: AppTheme.onSurfaceColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.go('/dashboard'),
        tooltip: 'Back to Dashboard',
      ),
      title: const Text(
        'User Profiles',
        style: TextStyle(
          color: AppTheme.onSurfaceColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () {
            ref.read(userProfileProvider.notifier).refresh();
          },
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_membership_rounded,
            size: 80,
            color: AppTheme.onSurfaceColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Profiles Found',
            style: TextStyle(
              color: AppTheme.onSurfaceColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first user profile to get started',
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
            'Failed to load profiles',
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

  void _showProfileDetails(UserProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => _ProfileDetailsSheet(
        profile: profile,
        onEdit: () => _navigateToEditProfile(profile),
        onDelete: () => _confirmDeleteProfile(profile),
      ),
    );
  }

  void _showProfileOptions(UserProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_rounded),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showProfileDetails(profile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                _navigateToEditProfile(profile);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_rounded, color: AppTheme.errorColor),
              title: const Text(
                'Delete Profile',
                style: TextStyle(color: AppTheme.errorColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteProfile(profile);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditProfileScreen(),
      ),
    );
  }

  void _navigateToEditProfile(UserProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditProfileScreen(profile: profile),
      ),
    );
  }

  void _confirmDeleteProfile(UserProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Delete Profile',
          style: TextStyle(color: AppTheme.onSurfaceColor),
        ),
        content: Text(
          'Are you sure you want to delete "${profile.name}" profile? This action cannot be undone.',
          style:
              TextStyle(color: AppTheme.onSurfaceColor.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(userProfileProvider.notifier)
                  .deleteProfile(profile.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Profile "${profile.name}" deleted'),
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

// Extracted as separate widget for better performance with RepaintBoundary
class _ProfileCard extends ConsumerWidget {
  final UserProfile profile;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const _ProfileCard({
    required this.profile,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppTheme.onSurfaceColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIconContainer(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildProfileInfo(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded),
                    color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                    onPressed: onMoreTap,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ProfileInfoGrid(profile: profile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.card_membership_rounded,
        color: AppTheme.onPrimaryColor,
        size: 24,
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.name.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.onSurfaceColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          profile.priceDisplay,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Extracted as separate widget for better performance
class _ProfileInfoGrid extends StatelessWidget {
  final UserProfile profile;

  const _ProfileInfoGrid({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoRow(
          icon: Icons.speed_rounded,
          label: 'Rate Limit',
          value: profile.rateLimitDisplay,
        ),
        const SizedBox(height: 5),
        _InfoRow(
          icon: Icons.access_time_rounded,
          label: 'Validity',
          value: profile.validityDisplay,
        ),
        const SizedBox(height: 5),
        _InfoRow(
          icon: Icons.people_rounded,
          label: 'Shared Users',
          value: profile.sharedUsersDisplay,
        ),
      ],
    );
  }
}

// Optimized info row widget
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.onSurfaceColor,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ],
    );
  }
}

// Extracted as separate widget for better performance
class _ProfileDetailsSheet extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProfileDetailsSheet({
    required this.profile,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDragHandle(),
            _buildHeader(),
            const SizedBox(height: 24),
            _ProfileDetailItem(
              icon: Icons.speed_rounded,
              label: 'Rate Limit',
              value: profile.rateLimitDisplay,
            ),
            const SizedBox(height: 16),
            _ProfileDetailItem(
              icon: Icons.access_time_rounded,
              label: 'Validity',
              value: profile.validityDisplay,
            ),
            const SizedBox(height: 16),
            _ProfileDetailItem(
              icon: Icons.people_rounded,
              label: 'Shared Users',
              value: profile.sharedUsersDisplay,
            ),
            const SizedBox(height: 16),
            _ProfileDetailItem(
              icon: Icons.logout_rounded,
              label: 'Auto Logout',
              value: profile.autologout == true ? 'Enabled' : 'Disabled',
            ),
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.onSurfaceColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
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
            Icons.card_membership_rounded,
            color: AppTheme.onPrimaryColor,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.onSurfaceColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile.priceDisplay,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onEdit();
            },
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            icon: const Icon(Icons.delete_rounded),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

// Extracted detail item widget for better performance
class _ProfileDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileDetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.onSurfaceColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}
