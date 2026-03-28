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
  static const _routes = [
    '/main/dashboard',
    '/main/users',
    '/main/profiles',
    '/main/hosts',
    '/main/settings',
  ];

  int _getTabFromPath(String path) {
    if (path.contains('/main/dashboard')) return 0;
    if (path.contains('/main/users')) return 1;
    if (path.contains('/main/profiles')) return 2;
    if (path.contains('/main/hosts')) return 3;
    if (path.contains('/main/settings')) return 4;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).uri.path;
    final tab = _getTabFromPath(location);
    Future.microtask(() {
      final currentTab = ref.read(currentTabProvider);
      if (tab != currentTab) {
        ref.read(currentTabProvider.notifier).state = tab;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (currentTab != 0) {
          _navigateToTab(0);
        }
      },
      child: Scaffold(
        backgroundColor: context.appBackground,
        body: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            // Detect swipe down to open search
            if (notification is ScrollUpdateNotification) {
              if (notification.scrollDelta != null &&
                  notification.scrollDelta! > 0 &&
                  notification.metrics.pixels == 0) {
                // User swiped down from top
                showGlobalSearch(context);
                return true;
              }
            }
            return false;
          },
          child: widget.child,
        ),
        bottomNavigationBar: ConvexAppBar(
          style: TabStyle.reactCircle,
          backgroundColor: context.appSurface,
          activeColor: context.appPrimary,
          color: context.appOnSurface.withValues(alpha: 0.5),
          initialActiveIndex: currentTab,
          height: 65,
          top: -30,
          curveSize: 90,
          onTap: (index) {
            ref.read(currentTabProvider.notifier).state = index;
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
