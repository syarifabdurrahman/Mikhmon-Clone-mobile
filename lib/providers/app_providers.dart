import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/routeros_service.dart';
import '../screens/welcome/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/hotspot_users/hotspot_users_screen.dart';

// Secure Storage Provider
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
});

// RouterOS Service Provider
final routerOSServiceProvider = Provider<RouterOSService>((ref) {
  return RouterOSService();
});

// Authentication State Provider
final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    // Check if user has saved credentials
    final storage = ref.read(secureStorageProvider);
    final host = await storage.read(key: 'router_ip');
    final username = await storage.read(key: 'username');
    final password = await storage.read(key: 'password');

    return host != null && username != null && password != null;
  }

  Future<void> login({
    required String host,
    required String port,
    required String username,
    required String password,
    required bool rememberMe,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // Store credentials if remember me is checked
      if (rememberMe) {
        final storage = ref.read(secureStorageProvider);
        await storage.write(key: 'router_ip', value: host);
        await storage.write(key: 'port', value: port);
        await storage.write(key: 'username', value: username);
        await storage.write(key: 'password', value: password);
      }

      // Connect to RouterOS
      final service = ref.read(routerOSServiceProvider);
      await service.connect();

      return true;
    });
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(routerOSServiceProvider);
      await service.disconnect();

      // Clear credentials
      await service.clearCredentials();

      return false;
    });
  }

  Future<void> setDemoMode(bool enabled) async {
    final service = ref.read(routerOSServiceProvider);
    service.setDemoMode(enabled);
    state = AsyncValue.data(enabled);
  }
}

// GoRouter Provider with refresh support
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _RouterRefreshNotifier(ref),
    routes: [
      GoRoute(
        path: '/',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/users',
        name: 'users',
        builder: (context, state) => const HotspotUsersScreen(),
      ),
      GoRoute(
        path: '/users/:id',
        name: 'user_details',
        builder: (context, state) => const HotspotUsersScreen(),
      ),
      GoRoute(
        path: '/users/add',
        name: 'add_user',
        builder: (context, state) => const HotspotUsersScreen(),
      ),
    ],
  );
});

// Custom ChangeNotifier for router refresh
class _RouterRefreshNotifier extends ChangeNotifier {
  final Ref ref;

  _RouterRefreshNotifier(this.ref) {
    // Listen to auth state changes
    ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }
}

// Hotspot Users Provider
final hotspotUsersProvider = AsyncNotifierProvider<HotspotUsersNotifier, List<Map<String, dynamic>>>(() {
  return HotspotUsersNotifier();
});

class HotspotUsersNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final service = ref.read(routerOSServiceProvider);

    if (service.isDemoMode) {
      // Return demo data
      return _getDemoUsers();
    }

    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    return await client.getHotspotUsersList();
  }

  Future<void> refresh() async {
    ref.invalidate(hotspotUsersProvider);
  }

  Future<void> addUser({
    required String username,
    required String password,
    required String profile,
    String? comment,
  }) async {
    final service = ref.read(routerOSServiceProvider);

    if (service.isDemoMode) {
      // Add to demo data
      final currentUsers = state.value ?? [];
      final newUser = {
        '.id': '*${currentUsers.length + 1}',
        'name': username,
        'profile': profile,
        'comment': comment ?? '',
        'bytes-in': '0',
        'bytes-out': '0',
        'limit-uptime': '0',
        'uptime': '0',
        'disabled': 'false',
      };
      state = AsyncValue.data([...currentUsers, newUser]);
      return;
    }

    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    await client.addHotspotUser(
      username: username,
      password: password,
      profile: profile,
      comment: comment,
    );

    // Refresh the list
    ref.invalidate(hotspotUsersProvider);
  }

  Future<void> deleteUser(String id) async {
    final service = ref.read(routerOSServiceProvider);

    if (service.isDemoMode) {
      // Remove from demo data
      final currentUsers = state.value ?? [];
      state = AsyncValue.data(
        currentUsers.where((user) => user['.id'] != id).toList(),
      );
      return;
    }

    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    await client.removeHotspotUser(id);

    // Refresh the list
    ref.invalidate(hotspotUsersProvider);
  }

  List<Map<String, dynamic>> _getDemoUsers() {
    return [
      {
        '.id': '*1',
        'name': 'demo_user1',
        'profile': 'default',
        'bytes-in': '1048576',
        'bytes-out': '2097152',
        'limit-uptime': '1h',
        'uptime': '30m',
        'disabled': 'false',
        'comment': 'Demo user 1',
      },
      {
        '.id': '*2',
        'name': 'demo_user2',
        'profile': 'premium',
        'bytes-in': '5242880',
        'bytes-out': '10485760',
        'limit-uptime': '24h',
        'uptime': '2h',
        'disabled': 'false',
        'comment': 'Demo user 2',
      },
      {
        '.id': '*3',
        'name': 'expired_user',
        'profile': 'default',
        'bytes-in': '0',
        'bytes-out': '0',
        'limit-uptime': '0',
        'uptime': '0',
        'disabled': 'true',
        'comment': 'Expired demo user',
      },
    ];
  }
}

// System Resources Provider
final systemResourcesProvider = AsyncNotifierProvider<SystemResourcesNotifier, Map<String, dynamic>>(() {
  return SystemResourcesNotifier();
});

class SystemResourcesNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    final service = ref.read(routerOSServiceProvider);

    if (service.isDemoMode) {
      return _getDemoResources();
    }

    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    return await client.getSystemResources();
  }

  Future<void> refresh() async {
    ref.invalidate(systemResourcesProvider);
  }

  Map<String, dynamic> _getDemoResources() {
    return {
      'cpu-load': '25',
      'free-memory': '104857600',
      'total-memory': '524288000',
      'free-hdd-space': '524288000',
      'total-hdd-space': '2097152000',
      'uptime': '2d 3h 45m',
      'platform': 'MikroTik',
      'board-name': 'RB750Gr3',
      'version': '7.10',
    };
  }
}
