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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.onSurfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.onSurfaceColor,
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
              color: AppTheme.onBackgroundColor.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, WidgetRef ref) {
    return Card(
      color: AppTheme.surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildThemeOption(
            context,
            icon: Icons.looks_one_rounded,
            title: 'Light Theme',
            subtitle: 'Clean and modern look',
            color: AppTheme.primaryColor,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme selection coming soon')),
              );
            },
          ),
          Divider(
            height: 1,
            color: AppTheme.onSurfaceColor.withValues(alpha: 0.1),
          ),
          _buildThemeOption(
            context,
            icon: Icons.nights_stay_rounded,
            title: 'Dark Theme',
            subtitle: 'Easy on the eyes',
            color: Colors.grey[800]!,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dark theme coming soon')),
              );
            },
          ),
          Divider(
            height: 1,
            color: AppTheme.onSurfaceColor.withValues(alpha: 0.1),
          ),
          _buildThemeOption(
            context,
            icon: Icons.palette_rounded,
            title: 'More Themes',
            subtitle: 'Green, Pink, and more',
            color: Colors.purple,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('More themes coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
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
                          color: AppTheme.onSurfaceColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.4),
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
      color: AppTheme.surfaceColor,
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
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.router_rounded,
                    color: AppTheme.primaryColor,
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
                              color: AppTheme.onSurfaceColor,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      connectionsAsync.when(
                        data: (connections) {
                          return Text(
                            '${connections.length} saved',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                                ),
                          );
                        },
                        loading: () => Text(
                          'Loading...',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                              ),
                        ),
                        error: (_, __) => const SizedBox(),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded),
                  color: AppTheme.primaryColor,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add router coming soon - use login screen')),
                    );
                  },
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
                              color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
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

  Widget _buildConnectionTile(BuildContext context, WidgetRef ref, RouterConnection connection) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.router_rounded,
            color: AppTheme.primaryColor.withValues(alpha: 0.7),
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
                        color: AppTheme.onSurfaceColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  connection.address,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppTheme.errorColor,
            iconSize: 20,
            onPressed: () => _showDeleteDialog(context, ref, connection),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, RouterConnection connection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(
          'Delete Connection?',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.onSurfaceColor,
              ),
        ),
        content: Text(
          'Remove "${connection.name}" from saved connections?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceColor.withValues(alpha: 0.8),
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.onSurfaceColor.withValues(alpha: 0.6)),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(savedConnectionsProvider.notifier).deleteConnection(connection.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted "${connection.name}"')),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Card(
      color: AppTheme.surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          showAboutDialog(
            context: context,
            applicationName: 'Mikhmon Clone',
            applicationVersion: '1.0.0',
            applicationIcon: const Icon(Icons.router_rounded, size: 48),
            children: [
              const Text('A mobile clone of Mikhmon for managing MikroTik Hotspot.'),
            ],
          );
        },
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
                            color: AppTheme.onSurfaceColor,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Version 1.0.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.onSurfaceColor.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
