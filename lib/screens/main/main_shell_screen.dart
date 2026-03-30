import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import '../../theme/app_theme.dart';
import '../../widgets/global_search.dart';
import '../../l10n/translations.dart';
import '../../services/onboarding_service.dart';

final isDemoModeProvider = FutureProvider<bool>((ref) async {
  return await OnboardingService.isDemoMode();
});

class MainShellScreen extends ConsumerStatefulWidget {
  final Widget child;

  const MainShellScreen({super.key, required this.child});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  static const _routes = [
    '/main/dashboard',
    '/main/users',
    '/main/profiles',
    '/main/hosts',
    '/main/settings',
  ];

  int _getTabFromPath(String path) {
    if (path == '/main/dashboard' || path.startsWith('/main/dashboard')) {
      return 0;
    }
    if (path == '/main/users' ||
        path.startsWith('/main/users') ||
        path.startsWith('/main/vouchers')) {
      return 1;
    }
    if (path == '/main/profiles' || path.startsWith('/main/profiles')) {
      return 2;
    }
    if (path == '/main/hosts' || path.startsWith('/main/hosts')) {
      return 3;
    }
    if (path == '/main/settings' || path.startsWith('/main/settings')) {
      return 4;
    }
    return 0;
  }

  void _navigateToTab(int index) {
    final currentPath = GoRouterState.of(context).uri.path;
    final targetPath = _routes[index];
    if (!currentPath.contains(targetPath)) {
      context.go(targetPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always get current tab from route
    final location = GoRouterState.of(context).uri.path;
    final computedTab = _getTabFromPath(location);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (computedTab != 0) {
          _navigateToTab(0);
        }
      },
      child: Scaffold(
        backgroundColor: context.appBackground,
        body: Column(
          children: [
            // Demo mode banner
            Consumer(
              builder: (context, ref, _) {
                final isDemoAsync = ref.watch(isDemoModeProvider);
                return isDemoAsync.when(
                  data: (isDemo) {
                    if (!isDemo) return const SizedBox.shrink();
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: Colors.orange.withValues(alpha: 0.9),
                      child: Row(
                        children: [
                          Icon(Icons.science_rounded,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Demo Mode - Data is simulated',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showLogoutDialog(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('Exit',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification) {
                    if (notification.scrollDelta != null &&
                        notification.scrollDelta! > 0 &&
                        notification.metrics.pixels == 0) {
                      showGlobalSearch(context);
                      return true;
                    }
                  }
                  return false;
                },
                child: widget.child,
              ),
            ),
          ],
        ),
        bottomNavigationBar: ConvexAppBar(
          key: ValueKey('nav_$computedTab'),
          style: TabStyle.reactCircle,
          backgroundColor: context.appSurface,
          activeColor: context.appPrimary,
          color: context.appOnSurface.withValues(alpha: 0.5),
          initialActiveIndex: computedTab,
          height: 65,
          top: -30,
          curveSize: 90,
          onTap: (index) {
            _navigateToTab(index);
          },
          items: [
            TabItem(
                icon: Icons.dashboard_rounded,
                title: AppStrings.of(context).dashboardNav),
            TabItem(
                icon: Icons.people_rounded,
                title: AppStrings.of(context).usersNav),
            TabItem(icon: Icons.add_rounded, title: ''),
            TabItem(
                icon: Icons.router_rounded,
                title: AppStrings.of(context).hostsNav),
            TabItem(
                icon: Icons.settings_rounded,
                title: AppStrings.of(context).settingsNav),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit Demo Mode?'),
        content: Text('You will be redirected to the login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await OnboardingService.setDemoMode(false);
              await OnboardingService.clearAll();
              if (context.mounted) {
                context.go('/');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('Exit Demo'),
          ),
        ],
      ),
    );
  }
}
