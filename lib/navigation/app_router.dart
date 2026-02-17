import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/welcome/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/hotspot_users/hotspot_users_screen.dart';
import '../screens/hotspot_users/user_profiles_screen.dart';

class AppRouter {
  static const String initialRoute = '/';
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String usersRoute = '/users';
  static const String profilesRoute = '/profiles';
  static const String settingsRoute = '/settings';

  static final router = GoRouter(
    initialLocation: initialRoute,
    routes: [
      GoRoute(
        path: initialRoute,
        pageBuilder: (context, state) => const MaterialPage(child: WelcomeScreen()),
      ),
      GoRoute(
        path: loginRoute,
        pageBuilder: (context, state) => const MaterialPage(child: LoginScreen()),
      ),
      GoRoute(
        path: dashboardRoute,
        pageBuilder: (context, state) => const MaterialPage(child: DashboardScreen()),
      ),
      GoRoute(
        path: usersRoute,
        pageBuilder: (context, state) => const MaterialPage(child: HotspotUsersScreen()),
      ),
      GoRoute(
        path: profilesRoute,
        pageBuilder: (context, state) => const MaterialPage(child: UserProfilesScreen()),
      ),
    ],
  );
}
