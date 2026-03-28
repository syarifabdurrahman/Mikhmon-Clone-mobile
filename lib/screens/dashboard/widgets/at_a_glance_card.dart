import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/app_providers.dart';
import '../../../services/models.dart';

/// A compact "At a Glance" summary card showing key metrics
class AtAGlanceCard extends ConsumerWidget {
  const AtAGlanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(hotspotUsersProvider);
    final incomeAsync = ref.watch(incomeProvider);

    return Card(
      color: context.appSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => context.go('/main/users'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.dashboard_rounded,
                    color: context.appPrimary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'At a Glance',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: context.appOnSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: context.appOnSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricChip(
                      context,
                      usersAsync,
                      incomeAsync,
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

  Widget _buildMetricChip(
    BuildContext context,
    AsyncValue usersAsync,
    AsyncValue incomeAsync,
  ) {
    return Row(
      children: [
        // Online users
        _buildMetric(
          context,
          icon: Icons.wifi_rounded,
          color: Colors.green,
          label: 'Online',
          value: usersAsync.when(
            data: (paginatedUsers) {
              final online = paginatedUsers.users.where((u) {
                final user = HotspotUser.fromJson(u);
                return user.uptime != null &&
                    user.uptime != '0s' &&
                    user.uptime != '00:00:00';
              }).length;
              return '$online';
            },
            loading: () => '-',
            error: (_, __) => '-',
          ),
        ),
        Container(
          width: 1,
          height: 24,
          color: context.appOnSurface.withValues(alpha: 0.1),
          margin: const EdgeInsets.symmetric(horizontal: 12),
        ),
        // Total users
        _buildMetric(
          context,
          icon: Icons.people_rounded,
          color: context.appPrimary,
          label: 'Total',
          value: usersAsync.when(
            data: (paginatedUsers) => '${paginatedUsers.users.length}',
            loading: () => '-',
            error: (_, __) => '-',
          ),
        ),
        Container(
          width: 1,
          height: 24,
          color: context.appOnSurface.withValues(alpha: 0.1),
          margin: const EdgeInsets.symmetric(horizontal: 12),
        ),
        // Today's revenue
        _buildMetric(
          context,
          icon: Icons.payments_rounded,
          color: Colors.amber,
          label: 'Today',
          value: incomeAsync.when(
            data: (income) => _formatCurrency(income.summary.dailyTotal),
            loading: () => '-',
            error: (_, __) => '-',
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.appOnSurface.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.appOnSurface,
                  fontWeight: FontWeight.bold,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}K';
    }
    return 'Rp ${amount.toStringAsFixed(0)}';
  }
}
