import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_providers.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  final Widget child;

  const MainShellScreen({super.key, required this.child});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update current tab based on current route (delayed to avoid modifying during build)
    final location = GoRouterState.of(context).uri.path;
    final tab = _getTabFromPath(location);
    if (tab != null) {
      Future.microtask(() => ref.read(currentTabProvider.notifier).state = tab);
    }
  }

  int? _getTabFromPath(String path) {
    if (path.contains('/main/dashboard')) return 0;
    if (path.contains('/main/users')) return 1;
    if (path.contains('/main/profiles')) return 2;
    if (path.contains('/main/hosts')) return 3;
    if (path.contains('/main/settings')) return 4;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      body: widget.child,
      bottomNavigationBar: _ConvexBottomBar(
        currentTab: currentTab,
        onTabChanged: (index) {
          ref.read(currentTabProvider.notifier).state = index;
          _navigateToTab(context, index);
        },
      ),
    );
  }

  void _navigateToTab(BuildContext context, int index) {
    final routes = [
      '/main/dashboard',
      '/main/users',
      '/main/profiles',
      '/main/hosts',
      '/main/settings',
    ];

    // Only navigate if not already on this tab's route
    final currentPath = GoRouterState.of(context).uri.path;
    final targetPath = routes[index];

    // Check if we're already on this tab or a sub-route
    if (!currentPath.contains(targetPath)) {
      context.go(targetPath);
    }
  }
}

class _ConvexBottomBar extends StatefulWidget {
  final int currentTab;
  final ValueChanged<int> onTabChanged;

  const _ConvexBottomBar({
    required this.currentTab,
    required this.onTabChanged,
  });

  @override
  State<_ConvexBottomBar> createState() => _ConvexBottomBarState();
}

class _ConvexBottomBarState extends State<_ConvexBottomBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    // Start idle pulse animation for center circle
    _startPulseAnimation();
  }

  void _startPulseAnimation() {
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && widget.currentTab == 2) {
        _animationController.forward().then((_) {
          if (mounted) {
            _animationController.reverse();
          }
        });
      }
    });
  }

  void _handleTap(int index) {
    // Trigger bounce animation on tap
    if (index == 2) {
      _animationController.forward().then((_) {
        if (mounted) {
          _animationController.reverse();
        }
      });
    }
    widget.onTabChanged(index);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return StyleProvider(
          style: _AnimatedConvexStyle(scaleAnimation: _scaleAnimation),
          child: ConvexAppBar(
        initialActiveIndex: widget.currentTab,
        height: 60,
        curveSize: 85,
        backgroundColor: context.appSurface,
        activeColor: context.appPrimary,
        color: context.appOnSurface.withValues(alpha: 0.5),
        style: TabStyle.fixedCircle,
        items: [
          TabItem(
            icon: Icons.dashboard_rounded,
            title: 'Dashboard',
          ),
          TabItem(
            icon: Icons.people_rounded,
            title: 'Users',
          ),
          TabItem(
            icon: Icons.card_membership_rounded,
            title: 'Profiles',
            isIconBlend: true,
          ),
          TabItem(
            icon: Icons.router_rounded,
            title: 'Hosts',
          ),
          TabItem(
            icon: Icons.settings_rounded,
            title: 'Settings',
          ),
        ],
        onTap: _handleTap,
      ),
    );
      },
    );
  }
}

class _AnimatedConvexStyle extends StyleHook {
  final Animation<double> scaleAnimation;

  _AnimatedConvexStyle({required this.scaleAnimation});

  @override
  double get activeIconSize => 35 * scaleAnimation.value;

  @override
  double get activeIconMargin => 8;

  @override
  double get iconSize => 22;

  @override
  TextStyle textStyle(Color color, String? text) {
    return TextStyle(
      fontSize: 11,
      color: color,
      fontWeight: FontWeight.w600,
    );
  }

  double get itemSpacing => 8;
}
