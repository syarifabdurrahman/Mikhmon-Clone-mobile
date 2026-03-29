import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../widgets/global_search.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  final Widget child;

  const MainShellScreen({super.key, required this.child});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _currentTab = 0;

  static const _routes = [
    '/main/dashboard',
    '/main/users',
    '/main/profiles',
    '/main/hosts',
    '/main/settings',
  ];

  int _getTabFromPath(String path) {
    if (path == '/main/dashboard' || path.startsWith('/main/dashboard'))
      return 0;
    if (path == '/main/users' ||
        path.startsWith('/main/users') ||
        path.startsWith('/main/vouchers')) return 1;
    if (path == '/main/profiles' || path.startsWith('/main/profiles')) return 2;
    if (path == '/main/hosts' || path.startsWith('/main/hosts')) return 3;
    if (path == '/main/settings' || path.startsWith('/main/settings')) return 4;
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
        body: NotificationListener<ScrollNotification>(
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
            TabItem(icon: Icons.dashboard_rounded, title: 'Dash'),
            TabItem(icon: Icons.people_rounded, title: 'Users'),
            TabItem(icon: Icons.add_rounded, title: ''),
            TabItem(icon: Icons.router_rounded, title: 'Hosts'),
            TabItem(icon: Icons.settings_rounded, title: 'Settings'),
          ],
        ),
      ),
    );
  }
}
