import 'dart:math';
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
import '../screens/hotspot_users/hotspot_active_users_screen.dart';
import '../screens/hotspot_users/add_hotspot_user_screen.dart';

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
        path: '/users/active',
        name: 'active_users',
        builder: (context, state) => const HotspotActiveUsersScreen(),
      ),
      GoRoute(
        path: '/users/add',
        name: 'add_user',
        builder: (context, state) => const AddHotspotUserScreen(),
      ),
      GoRoute(
        path: '/users/:id',
        name: 'user_details',
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
final hotspotUsersProvider = AsyncNotifierProvider<HotspotUsersNotifier, PaginatedUsers>(() {
  return HotspotUsersNotifier();
});

// In-memory storage for demo mode users (persists across provider rebuilds)
List<Map<String, dynamic>> _demoUsersCache = [];
bool _demoUsersInitialized = false;

// Cache for demo active sessions - maps user ID to their session data
final Map<String, Map<String, dynamic>> _demoActiveSessions = {};

// Pagination state class
class PaginatedUsers {
  final List<Map<String, dynamic>> users;
  final bool hasMore;
  final int currentPage;
  final int pageSize;

  PaginatedUsers({
    required this.users,
    this.hasMore = true,
    this.currentPage = 1,
    this.pageSize = 20,
  });

  PaginatedUsers copyWith({
    List<Map<String, dynamic>>? users,
    bool? hasMore,
    int? currentPage,
  }) {
    return PaginatedUsers(
      users: users ?? this.users,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize,
    );
  }
}

class HotspotUsersNotifier extends AsyncNotifier<PaginatedUsers> {
  int _currentPage = 1;
  final int _pageSize = 20;

  @override
  Future<PaginatedUsers> build() async {
    _currentPage = 1;
    return await _loadUsers(page: 1);
  }

  Future<PaginatedUsers> _loadUsers({required int page}) async {
    final service = ref.read(routerOSServiceProvider);

    if (service.isDemoMode) {
      // Initialize demo users only once
      if (!_demoUsersInitialized) {
        _demoUsersCache = _getDemoUsers();
        _demoUsersInitialized = true;
      }

      // Simulate pagination
      final startIndex = (page - 1) * _pageSize;
      final endIndex = startIndex + _pageSize;
      final hasMore = endIndex < _demoUsersCache.length;
      final users = _demoUsersCache.skip(startIndex).take(_pageSize).toList();

      return PaginatedUsers(
        users: users,
        hasMore: hasMore,
        currentPage: page,
        pageSize: _pageSize,
      );
    }

    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    final allUsers = await client.getHotspotUsersList();
    final startIndex = (page - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;
    final hasMore = endIndex < allUsers.length;
    final users = allUsers.skip(startIndex).take(_pageSize).toList();

    return PaginatedUsers(
      users: users,
      hasMore: hasMore,
      currentPage: page,
      pageSize: _pageSize,
    );
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore) return;

    _currentPage++;
    final nextPageData = await _loadUsers(page: _currentPage);

    state = AsyncValue.data(PaginatedUsers(
      users: [...currentState.users, ...nextPageData.users],
      hasMore: nextPageData.hasMore,
      currentPage: nextPageData.currentPage,
      pageSize: _pageSize,
    ));
  }

  Future<void> refresh() async {
    _currentPage = 1;
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _loadUsers(page: 1));
  }

  Future<void> addUser({
    required String username,
    required String password,
    required String profile,
    String? comment,
  }) async {
    final service = ref.read(routerOSServiceProvider);

    if (service.isDemoMode) {
      // Create new user with unique ID
      final newId = '*${DateTime.now().millisecondsSinceEpoch}';
      final newUser = {
        '.id': newId,
        'name': username,
        'profile': profile,
        'comment': comment ?? '',
        'bytes-in': '0',
        'bytes-out': '0',
        'limit-uptime': '0',
        'uptime': '0',
        'disabled': 'false',
      };

      // Add to cache and update state
      _demoUsersCache.add(newUser);
      final currentUsers = state.value?.users ?? [];
      state = AsyncValue.data(PaginatedUsers(
        users: [...currentUsers, newUser],
        hasMore: false,
        currentPage: _currentPage,
        pageSize: _pageSize,
      ));

      // Also refresh active users list to include the new user
      ref.invalidate(hotspotActiveUsersProvider);
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
      // Remove from cache
      _demoUsersCache.removeWhere((user) => user['.id'] == id);
      final currentUsers = (state.value?.users ?? []).where((u) => u['.id'] != id).toList();
      state = AsyncValue.data(PaginatedUsers(
        users: currentUsers,
        hasMore: false,
        currentPage: _currentPage,
        pageSize: _pageSize,
      ));

      // Also remove from active sessions
      _demoActiveSessions.remove(id);
      ref.invalidate(hotspotActiveUsersProvider);
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

  Future<void> updateUser({
    required String id,
    required String username,
    required String profile,
    String? comment,
  }) async {
    final service = ref.read(routerOSServiceProvider);

    if (service.isDemoMode) {
      // Find and update user in cache
      final index = _demoUsersCache.indexWhere((user) => user['.id'] == id);
      if (index != -1) {
        _demoUsersCache[index] = {
          ..._demoUsersCache[index],
          'name': username,
          'profile': profile,
          'comment': comment ?? _demoUsersCache[index]['comment'] ?? '',
        };
        final currentUsers = state.value?.users ?? [];
        final updatedUsers = currentUsers.map((u) {
          if (u['.id'] == id) {
            return _demoUsersCache[index];
          }
          return u;
        }).toList();
        state = AsyncValue.data(PaginatedUsers(
          users: updatedUsers,
          hasMore: state.value?.hasMore ?? false,
          currentPage: _currentPage,
          pageSize: _pageSize,
        ));
      }
      return;
    }

    // For real RouterOS, you would implement the update logic here
    // This typically involves removing and re-adding the user with updated properties
    throw UnimplementedError('Update user not implemented for real RouterOS connection');
  }

  Future<void> toggleUserStatus(String id) async {
    final service = ref.read(routerOSServiceProvider);

    if (service.isDemoMode) {
      // Find user and toggle disabled status
      final index = _demoUsersCache.indexWhere((user) => user['.id'] == id);
      if (index != -1) {
        final currentStatus = _demoUsersCache[index]['disabled'] == 'true';
        _demoUsersCache[index] = {
          ..._demoUsersCache[index],
          'disabled': (!currentStatus).toString(),
        };
        final currentUsers = state.value?.users ?? [];
        final updatedUsers = currentUsers.map((u) {
          if (u['.id'] == id) {
            return _demoUsersCache[index];
          }
          return u;
        }).toList();
        state = AsyncValue.data(PaginatedUsers(
          users: updatedUsers,
          hasMore: state.value?.hasMore ?? false,
          currentPage: _currentPage,
          pageSize: _pageSize,
        ));

        // Also refresh active users list to sync the change
        ref.invalidate(hotspotActiveUsersProvider);
      }
      return;
    }

    throw UnimplementedError('Toggle user status not implemented for real RouterOS connection');
  }

  void resetDemoUsers() {
    _demoUsersInitialized = false;
    _demoUsersCache = [];
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

// Hotspot Active Users Provider
final hotspotActiveUsersProvider = AsyncNotifierProvider<HotspotActiveUsersNotifier, PaginatedUsers>(() {
  return HotspotActiveUsersNotifier();
});

class HotspotActiveUsersNotifier extends AsyncNotifier<PaginatedUsers> {
  int _currentPage = 1;
  final int _pageSize = 15;

  @override
  Future<PaginatedUsers> build() async {
    _currentPage = 1;
    return await _loadActiveUsers(page: 1);
  }

  Future<PaginatedUsers> _loadActiveUsers({required int page}) async {
    final service = ref.read(routerOSServiceProvider);

    if (service.isDemoMode) {
      // Return demo active users synced with enabled users
      final allActiveUsers = _getDemoActiveUsers();
      final startIndex = (page - 1) * _pageSize;
      final endIndex = startIndex + _pageSize;
      final hasMore = endIndex < allActiveUsers.length;
      final users = allActiveUsers.skip(startIndex).take(_pageSize).toList();

      return PaginatedUsers(
        users: users,
        hasMore: hasMore,
        currentPage: page,
        pageSize: _pageSize,
      );
    }

    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    final allActiveUsers = await client.getHotspotActiveUsers();
    final startIndex = (page - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;
    final hasMore = endIndex < allActiveUsers.length;
    final users = allActiveUsers.skip(startIndex).take(_pageSize).toList();

    return PaginatedUsers(
      users: users,
      hasMore: hasMore,
      currentPage: page,
      pageSize: _pageSize,
    );
  }

  Future<void> refresh() async {
    _currentPage = 1;
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _loadActiveUsers(page: 1));
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore) return;

    _currentPage++;
    final nextPageData = await _loadActiveUsers(page: _currentPage);

    state = AsyncValue.data(PaginatedUsers(
      users: [...currentState.users, ...nextPageData.users],
      hasMore: nextPageData.hasMore,
      currentPage: nextPageData.currentPage,
      pageSize: _pageSize,
    ));
  }

  Future<void> logoutUser(String id) async {
    final service = ref.read(routerOSServiceProvider);

    if (service.isDemoMode) {
      // Remove from demo active sessions
      _demoActiveSessions.remove(id);
      final currentUsers = (state.value?.users ?? []).where((u) => u['.id'] != id).toList();
      state = AsyncValue.data(PaginatedUsers(
        users: currentUsers,
        hasMore: false,
        currentPage: _currentPage,
        pageSize: _pageSize,
      ));
      return;
    }

    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    await client.logoutHotspotUser(id);
    ref.invalidate(hotspotActiveUsersProvider);
  }

  List<Map<String, dynamic>> _getDemoActiveUsers() {
    // Get the current users from the users provider
    final usersAsync = ref.read(hotspotUsersProvider);
    final paginatedUsers = usersAsync.value;
    if (paginatedUsers == null) return [];

    final allUsers = paginatedUsers.users;

    // Filter for enabled users (disabled != 'true' or disabled == 'false')
    final enabledUsers = allUsers.where((user) => user['disabled'] != 'true');

    // Build active users list from enabled users
    final now = DateTime.now();
    final activeUsers = <Map<String, dynamic>>[];
    final random = Random(now.millisecondsSinceEpoch);

    for (final user in enabledUsers) {
      final userId = user['.id'] as String;
      final userName = user['name'] as String;
      final profile = user['profile'] as String? ?? 'default';

      // Check if this user already has an active session
      if (!_demoActiveSessions.containsKey(userId)) {
        // Create a new session for this user with initial random values
        _demoActiveSessions[userId] = {
          'login-time': now.subtract(Duration(minutes: random.nextInt(120))).millisecondsSinceEpoch ~/ 1000,
          'bytes-in': random.nextInt(10485760).toString(), // Start with 0-10 MB
          'bytes-out': random.nextInt(10485760).toString(),
        };
      }

      // Update the session data
      final session = _demoActiveSessions[userId]!;
      final loginTime = session['login-time'] as int;
      final uptimeSeconds = now.millisecondsSinceEpoch ~/ 1000 - loginTime;
      final uptime = _formatUptime(uptimeSeconds);

      // Increment bytes significantly to make changes visible (every 2 seconds)
      final currentBytesIn = int.parse(session['bytes-in'] as String);
      final currentBytesOut = int.parse(session['bytes-out'] as String);
      // Add 100KB-2MB random data per refresh cycle to simulate active usage
      final bytesInIncrement = 102400 + random.nextInt(2048000);
      final bytesOutIncrement = 51200 + random.nextInt(1024000);
      final newBytesIn = currentBytesIn + bytesInIncrement;
      final newBytesOut = currentBytesOut + bytesOutIncrement;
      session['bytes-in'] = newBytesIn.toString();
      session['bytes-out'] = newBytesOut.toString();

      // Generate IP address based on user ID
      final ipSuffix = userId.replaceAll('*', '').padLeft(3, '0');
      final address = '192.168.88.$ipSuffix';

      // Generate MAC address
      final macSuffix = int.parse(ipSuffix).toRadixString(16).padLeft(2, '0').toUpperCase();
      final macAddress = 'AA:BB:CC:DD:EE:$macSuffix';

      activeUsers.add({
        '.id': userId,
        'user': userName,
        'address': address,
        'mac-address': macAddress,
        'login-time': loginTime.toString(),
        'uptime': uptime,
        'bytes-in': newBytesIn.toString(),
        'bytes-out': newBytesOut.toString(),
        'server': 'hotspot1',
        'profile': profile,
      });
    }

    return activeUsers;
  }

  String _formatUptime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }
}
