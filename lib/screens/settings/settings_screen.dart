import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../services/models.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appOnSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, 'Appearance'),
          const SizedBox(height: 8),
          _buildThemeCard(context, ref),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Connections'),
          const SizedBox(height: 8),
          _buildSavedRoutersCard(context, ref),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Account'),
          const SizedBox(height: 8),
          _buildLogoutCard(context, ref),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'About'),
          const SizedBox(height: 8),
          _buildAboutCard(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: context.appOnBackground.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeModeProvider);

    return Card(
      color: context.appSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildThemeOption(
            context,
            ref,
            icon: Icons.auto_awesome_rounded,
            title: 'Purple Theme',
            subtitle: 'Default vibrant purple',
            color: const Color(0xFF7C3AED),
            mode: AppThemeMode.purple,
            currentMode: currentTheme,
          ),
          Divider(
            height: 1,
            color: context.appOnSurface.withValues(alpha: 0.1),
          ),
          _buildThemeOption(
            context,
            ref,
            icon: Icons.wb_sunny_rounded,
            title: 'Light Theme',
            subtitle: 'Clean and modern look',
            color: const Color(0xFFF8FAFC),
            mode: AppThemeMode.light,
            currentMode: currentTheme,
            iconColor: const Color(0xFF7C3AED),
          ),
          Divider(
            height: 1,
            color: context.appOnSurface.withValues(alpha: 0.1),
          ),
          _buildThemeOption(
            context,
            ref,
            icon: Icons.waves_rounded,
            title: 'Blue Theme',
            subtitle: 'Ocean blue vibes',
            color: const Color(0xFF2563EB),
            mode: AppThemeMode.blue,
            currentMode: currentTheme,
          ),
          Divider(
            height: 1,
            color: context.appOnSurface.withValues(alpha: 0.1),
          ),
          _buildThemeOption(
            context,
            ref,
            icon: Icons.eco_rounded,
            title: 'Green Theme',
            subtitle: 'Nature inspired green',
            color: const Color(0xFF10B981),
            mode: AppThemeMode.green,
            currentMode: currentTheme,
          ),
          Divider(
            height: 1,
            color: context.appOnSurface.withValues(alpha: 0.1),
          ),
          _buildThemeOption(
            context,
            ref,
            icon: Icons.favorite_rounded,
            title: 'Pink Theme',
            subtitle: 'Romantic pink vibes',
            color: const Color(0xFFEC4899),
            mode: AppThemeMode.pink,
            currentMode: currentTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required AppThemeMode mode,
    required AppThemeMode currentMode,
    Color? iconColor,
  }) {
    final isSelected = mode == currentMode;

    return InkWell(
      onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(mode),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? color).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: iconColor ?? color,
                        width: 2,
                      )
                    : null,
              ),
              child: Icon(
                icon,
                color: iconColor ?? color,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: context.appOnSurface,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appOnSurface.withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: iconColor ?? color,
                size: 24,
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: context.appOnSurface.withValues(alpha: 0.4),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedRoutersCard(BuildContext context, WidgetRef ref) {
    final connectionsAsync = ref.watch(savedConnectionsProvider);

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
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saved Routers',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: context.appOnSurface,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      connectionsAsync.when(
                        data: (connections) {
                          return Text(
                            '${connections.length} saved',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: context.appOnSurface
                                          .withValues(alpha: 0.6),
                                    ),
                          );
                        },
                        loading: () => Text(
                          'Loading...',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    context.appOnSurface.withValues(alpha: 0.6),
                              ),
                        ),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  color: context.appPrimary,
                  onPressed: () => _showAddRouterDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 12),
            connectionsAsync.when(
              data: (connections) {
                if (connections.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text(
                        'No saved routers yet.\nLogin to save a connection.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  context.appOnSurface.withValues(alpha: 0.5),
                            ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: connections.map((conn) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildConnectionTile(context, ref, conn),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (_, __) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionTile(
      BuildContext context, WidgetRef ref, RouterConnection connection) {
    return InkWell(
      onTap: () => _showEditRouterDialog(context, ref, connection),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.appBackground.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.router_rounded,
              color: context.appPrimary.withValues(alpha: 0.7),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connection.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.appOnSurface,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    connection.address,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.appOnSurface.withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: context.appOnSurface.withValues(alpha: 0.6),
              iconSize: 20,
              onPressed: () => _showEditRouterDialog(context, ref, connection),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: context.appError,
              iconSize: 20,
              onPressed: () => _showDeleteDialog(context, ref, connection),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, RouterConnection connection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(
          'Delete Connection?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: context.appOnSurface,
              ),
        ),
        content: Text(
          'Remove "${connection.name}" from saved connections?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.appOnSurface.withValues(alpha: 0.8),
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style:
                  TextStyle(color: context.appOnSurface.withValues(alpha: 0.6)),
            ),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(savedConnectionsProvider.notifier)
                  .deleteConnection(connection.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted "${connection.name}"')),
              );
            },
            child: Text(
              'Delete',
              style: TextStyle(color: context.appError),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutCard(BuildContext context, WidgetRef ref) {
    return Card(
      color: context.appSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showLogoutDialog(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: AppTheme.errorColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logout',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: context.appOnSurface,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Disconnect from router',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.appOnSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.appOnSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.appSurface,
        title: Text(
          'Logout',
          style: TextStyle(color: context.appOnSurface),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: context.appOnSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style:
                  TextStyle(color: context.appOnSurface.withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go('/');
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Card(
      color: context.appSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showAboutDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.blue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: context.appOnSurface,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Version 1.0.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.appOnSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.appOnSurface.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: context.appSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.appPrimary,
                      context.appSecondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.router_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),

              // App Name
              Text(
                'ΩMMON',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: context.appOnSurface,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),

              // Tagline
              Text(
                'Open Mikrotik Monitor',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: context.appSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),

              // Version
              Text(
                'Version 1.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.appOnSurface.withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 24),

              // Description
              Text(
                'A professional RouterOS management solution for monitoring and managing Mikrotik devices.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.appOnSurface.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 24),

              // Divider
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      context.appOnSurface.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Developers Section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.code_rounded,
                    color: context.appPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Developed by',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: context.appOnSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Developer Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildDeveloperCard(
                      context,
                      name: 'Favian Hugo',
                      icon: Icons.person_rounded,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDeveloperCard(
                      context,
                      name: 'Syarif Abdurrahman',
                      icon: Icons.person_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Close Button
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: context.appPrimary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeveloperCard(
    BuildContext context, {
    required String name,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: context.appBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.appPrimary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: context.appPrimary,
            size: 28,
          ),
          const SizedBox(height: 8),
          // Use FittedBox to prevent text overflow
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appOnSurface,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Show dialog to add a new router connection
  void _showAddRouterDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final hostController = TextEditingController();
    final portController = TextEditingController(text: '8728');
    final usernameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => _RouterConnectionDialog(
        title: 'Add Router',
        nameController: nameController,
        hostController: hostController,
        portController: portController,
        usernameController: usernameController,
        onSave: () {
          if (nameController.text.trim().isEmpty ||
              hostController.text.trim().isEmpty ||
              usernameController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Please fill in all required fields')),
            );
            return;
          }

          ref.read(savedConnectionsProvider.notifier).addConnection(
                name: nameController.text.trim(),
                host: hostController.text.trim(),
                port: portController.text.trim(),
                username: usernameController.text.trim(),
              );

          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added "${nameController.text.trim()}"')),
          );
        },
      ),
    );
  }

  /// Show dialog to edit an existing router connection
  void _showEditRouterDialog(
      BuildContext context, WidgetRef ref, RouterConnection connection) {
    final nameController = TextEditingController(text: connection.name);
    final hostController = TextEditingController(text: connection.host);
    final portController = TextEditingController(text: connection.port);
    final usernameController = TextEditingController(text: connection.username);

    showDialog(
      context: context,
      builder: (context) => _RouterConnectionDialog(
        title: 'Edit Router',
        nameController: nameController,
        hostController: hostController,
        portController: portController,
        usernameController: usernameController,
        onSave: () {
          if (nameController.text.trim().isEmpty ||
              hostController.text.trim().isEmpty ||
              usernameController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Please fill in all required fields')),
            );
            return;
          }

          final updatedConnection = RouterConnection(
            id: connection.id,
            name: nameController.text.trim(),
            host: hostController.text.trim(),
            port: portController.text.trim(),
            username: usernameController.text.trim(),
            createdAt: connection.createdAt,
          );

          ref
              .read(savedConnectionsProvider.notifier)
              .updateConnection(updatedConnection);

          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Updated "${nameController.text.trim()}"')),
          );
        },
      ),
    );
  }
}

/// Dialog widget for adding/editing router connections
class _RouterConnectionDialog extends StatefulWidget {
  final String title;
  final TextEditingController nameController;
  final TextEditingController hostController;
  final TextEditingController portController;
  final TextEditingController usernameController;
  final VoidCallback onSave;

  const _RouterConnectionDialog({
    required this.title,
    required this.nameController,
    required this.hostController,
    required this.portController,
    required this.usernameController,
    required this.onSave,
  });

  @override
  State<_RouterConnectionDialog> createState() =>
      _RouterConnectionDialogState();
}

class _RouterConnectionDialogState extends State<_RouterConnectionDialog> {
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    widget.nameController.dispose();
    widget.hostController.dispose();
    widget.portController.dispose();
    widget.usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.appSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            context.appPrimary.withValues(alpha: 0.2),
                            context.appSecondary.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.router_rounded,
                        color: context.appPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: context.appOnSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enter router connection details',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: context.appOnSurface
                                          .withValues(alpha: 0.6),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Name Field
                TextFormField(
                  controller: widget.nameController,
                  decoration: InputDecoration(
                    labelText: 'Connection Name *',
                    labelStyle: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.7)),
                    hintText: 'e.g., Office Router',
                    hintStyle: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.4)),
                    prefixIcon:
                        Icon(Icons.bookmark_rounded, color: context.appPrimary),
                    filled: true,
                    fillColor: context.appBackground.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: context.appOnSurface.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: context.appPrimary, width: 2),
                    ),
                  ),
                  style: TextStyle(color: context.appOnSurface),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a connection name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Host Field
                TextFormField(
                  controller: widget.hostController,
                  decoration: InputDecoration(
                    labelText: 'Host/IP Address *',
                    labelStyle: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.7)),
                    hintText: 'e.g., 192.168.88.1',
                    hintStyle: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.4)),
                    prefixIcon:
                        Icon(Icons.computer_rounded, color: context.appPrimary),
                    filled: true,
                    fillColor: context.appBackground.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: context.appOnSurface.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: context.appPrimary, width: 2),
                    ),
                  ),
                  style: TextStyle(color: context.appOnSurface),
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a host or IP address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Port Field
                TextFormField(
                  controller: widget.portController,
                  decoration: InputDecoration(
                    labelText: 'Port *',
                    labelStyle: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.7)),
                    hintText: 'e.g., 8728',
                    hintStyle: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.4)),
                    prefixIcon: Icon(Icons.settings_ethernet_rounded,
                        color: context.appPrimary),
                    filled: true,
                    fillColor: context.appBackground.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: context.appOnSurface.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: context.appPrimary, width: 2),
                    ),
                  ),
                  style: TextStyle(color: context.appOnSurface),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a port number';
                    }
                    final port = int.tryParse(value.trim());
                    if (port == null || port < 1 || port > 65535) {
                      return 'Please enter a valid port (1-65535)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Username Field
                TextFormField(
                  controller: widget.usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username *',
                    labelStyle: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.7)),
                    hintText: 'e.g., admin',
                    hintStyle: TextStyle(
                        color: context.appOnSurface.withValues(alpha: 0.4)),
                    prefixIcon:
                        Icon(Icons.person_rounded, color: context.appPrimary),
                    filled: true,
                    fillColor: context.appBackground.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: context.appOnSurface.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: context.appPrimary, width: 2),
                    ),
                  ),
                  style: TextStyle(color: context.appOnSurface),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Note about password
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.appPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: context.appPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Password will be required when connecting',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: context.appOnSurface,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              context.appOnSurface.withValues(alpha: 0.7),
                          side: BorderSide(
                            color: context.appOnSurface.withValues(alpha: 0.2),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: widget.onSave,
                        style: FilledButton.styleFrom(
                          backgroundColor: context.appPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
