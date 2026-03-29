import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/routeros_service.dart';
import '../services/models.dart';
import '../services/models/voucher.dart';
import '../services/cache_service.dart';
import '../services/traffic_rate_service.dart';
import '../services/resource_history.dart';
import '../services/theme_service.dart';
import '../services/template_service.dart';
import '../services/log_service.dart';
import '../services/onboarding_service.dart';
import '../theme/app_theme.dart';
import '../screens/welcome/welcome_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/setup_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/hotspot_users/hotspot_users_screen.dart';
import '../screens/hotspot_users/hotspot_active_users_screen.dart';
import '../screens/hotspot_users/hotspot_hosts_screen.dart';
import '../screens/hotspot_users/hotspot_host_details_screen.dart';
import '../screens/hotspot_users/add_hotspot_user_screen.dart';
import '../screens/hotspot_users/user_profiles_screen.dart';
import '../screens/hotspot_users/voucher_generation_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/revenue/revenue_screen.dart';
import '../screens/vouchers/vouchers_list_screen.dart';
import '../screens/activity_logs/activity_logs_screen.dart';
import '../screens/main/main_shell_screen.dart';

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

// Cache Service Provider
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

// Theme Provider
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier() : super(AppThemeMode.light) {
    _loadThemeMode();
  }

  ThemeModeNotifier.preloaded(super.mode);

  Future<void> _loadThemeMode() async {
    final mode = await ThemeService.loadThemeMode();
    state = mode;
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    await ThemeService.saveThemeMode(mode);
  }

  /// Clear saved theme (reset to default)
  Future<void> clearTheme() async {
    await ThemeService.clearThemeMode();
    state = AppThemeMode.light;
  }

  /// Get theme data for current mode
  ThemeData getThemeData() {
    return ThemeService.getThemeData(state);
  }
}

// Voucher Template Provider
final voucherTemplateProvider =
    StateNotifierProvider<TemplateNotifier, VoucherTemplate>((ref) {
  return TemplateNotifier();
});

class TemplateNotifier extends StateNotifier<VoucherTemplate> {
  TemplateNotifier() : super(VoucherTemplate.full) {
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    final template = await TemplateService.loadTemplate();
    state = template;
  }

  Future<void> setTemplate(VoucherTemplate template) async {
    state = template;
    await TemplateService.saveTemplate(template);
  }
}

// RouterOS Service Provider
final routerOSServiceProvider = Provider<RouterOSService>((ref) {
  return RouterOSService();
});

// Authentication State Provider
final authStateProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthState {
  final bool isAuthenticated;
  final Map<String, dynamic>? systemResources;
  final String? error;

  const AuthState({
    required this.isAuthenticated,
    this.systemResources,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    Map<String, dynamic>? systemResources,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      systemResources: systemResources ?? this.systemResources,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    return const AuthState(isAuthenticated: false);
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
      final service = ref.read(routerOSServiceProvider);

      // Connect to RouterOS
      final client = await service.connectWithCredentials(
        host: host,
        port: port,
        username: username,
        password: password,
      );

      // Pre-fetch system resources during login
      Map<String, dynamic>? resources;
      try {
        resources = await client.getSystemResources();

        final cache = ref.read(cacheServiceProvider);
        await cache.saveSystemResources(resources);
      } catch (e) {
        // Silently handle pre-fetch failure - dashboard will load on demand
      }

      // Log successful login
      await LogService.logLogin(username, '$host:$port');

      // Store credentials if remember me is checked
      if (rememberMe) {
        final storage = ref.read(secureStorageProvider);
        await storage.write(key: 'router_ip', value: host);
        await storage.write(key: 'port', value: port);
        await storage.write(key: 'username', value: username);
        await storage.write(key: 'password', value: password);
      }

      return AuthState(
        isAuthenticated: true,
        systemResources: resources,
      );
    });
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(routerOSServiceProvider);
      await service.disconnect();

      // Clear credentials
      await service.clearCredentials();

      // Log logout
      await LogService.logLogout('User');

      return const AuthState(isAuthenticated: false);
    });
  }

  // Clear pre-fetched resources after dashboard has consumed them
  void clearPrefetchedResources() {
    final currentState = state.value;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(systemResources: null));
    }
  }
}

// Navigation state provider for bottom navigation
final currentTabProvider = StateProvider<int>((ref) => 0);

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
        redirect: (context, state) async {
          final completed = await OnboardingService.isCompleted();
          if (!completed) return '/onboarding';
          return null;
        },
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/setup',
        name: 'setup',
        builder: (context, state) => const SetupScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/main',
            name: 'main',
            redirect: (context, state) => '/main/dashboard',
          ),
          GoRoute(
            path: '/main/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/main/users',
            name: 'users',
            builder: (context, state) => const HotspotUsersScreen(),
            routes: [
              GoRoute(
                path: 'active',
                name: 'active_users',
                builder: (context, state) => const HotspotActiveUsersScreen(),
              ),
              GoRoute(
                path: 'add',
                name: 'add_user',
                builder: (context, state) => const AddHotspotUserScreen(),
              ),
              GoRoute(
                path: 'generate',
                name: 'generate_user_vouchers',
                builder: (context, state) => const VoucherGenerationScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'user_details',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const HotspotUsersScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      )),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 250),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/main/profiles',
            name: 'profiles',
            builder: (context, state) => const UserProfilesScreen(),
          ),
          GoRoute(
            path: '/main/hosts',
            name: 'hosts',
            builder: (context, state) => const HotspotHostsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'host_details',
                pageBuilder: (context, state) {
                  final host = state.extra as HotspotHost?;
                  if (host == null) {
                    return CustomTransitionPage(
                      key: state.pageKey,
                      child: const Scaffold(
                        body: Center(child: Text('Host not found')),
                      ),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOut,
                          )),
                          child: child,
                        );
                      },
                    );
                  }
                  return CustomTransitionPage(
                    key: state.pageKey,
                    child: HotspotHostDetailsScreen(host: host),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOut,
                        )),
                        child: child,
                      );
                    },
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/main/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/main/revenue',
            name: 'revenue',
            builder: (context, state) => const RevenueScreen(),
          ),
          GoRoute(
            path: '/main/vouchers',
            name: 'vouchers',
            builder: (context, state) => const VouchersListScreen(),
            routes: [
              GoRoute(
                path: 'generate',
                name: 'generate_vouchers',
                builder: (context, state) => const VoucherGenerationScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/main/logs',
            name: 'activity_logs',
            builder: (context, state) => const ActivityLogsScreen(),
          ),
        ],
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
final hotspotUsersProvider =
    AsyncNotifierProvider<HotspotUsersNotifier, PaginatedUsers>(() {
  return HotspotUsersNotifier();
});

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

  PaginatedUsers _paginateUsers(List<Map<String, dynamic>> allUsers,
      {required int page}) {
    // Filter out system/default users like "trial"
    final systemUserNames = {'trial'};
    final filteredUsers = allUsers.where((user) {
      final userName = user['name'] as String? ?? '';
      if (systemUserNames.contains(userName.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    final startIndex = (page - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;
    final hasMore = endIndex < filteredUsers.length;
    final users = filteredUsers.skip(startIndex).take(_pageSize).toList();

    return PaginatedUsers(
      users: users,
      hasMore: hasMore,
      currentPage: page,
      pageSize: _pageSize,
    );
  }

  PaginatedUsers _emptyPaginatedUsers() {
    return PaginatedUsers(
      users: [],
      hasMore: false,
      currentPage: 1,
      pageSize: _pageSize,
    );
  }

  @override
  Future<PaginatedUsers> build() async {
    _currentPage = 1;
    // Try cache first
    final cache = ref.read(cacheServiceProvider);
    final cachedUsers = cache.getHotspotUsers();
    if (cachedUsers != null && cachedUsers.isNotEmpty) {
      return _paginateUsers(cachedUsers, page: 1);
    }
    // No cache, fetch from API
    return await _loadUsers(page: 1);
  }

  Future<PaginatedUsers> _loadUsers({required int page}) async {
    final service = ref.read(routerOSServiceProvider);
    final client = service.client;

    // Return cached data if not connected
    if (client == null) {
      final cache = ref.read(cacheServiceProvider);
      final cachedUsers = cache.getHotspotUsers();
      if (cachedUsers != null) {
        return _paginateUsers(cachedUsers, page: page);
      }
      return _emptyPaginatedUsers();
    }

    final allUsers = await client.getHotspotUsersList();

    // Cache the users
    final cache = ref.read(cacheServiceProvider);
    await cache.saveHotspotUsers(allUsers);

    return _paginateUsers(allUsers, page: page);
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

    ref.invalidate(hotspotUsersProvider);
  }

  Future<void> deleteUser(String id) async {
    final service = ref.read(routerOSServiceProvider);
    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    // Get username before deleting
    final currentState = state.value;
    String? usernameToDelete;
    if (currentState != null) {
      final userToDelete = currentState.users.firstWhere(
        (user) => user['.id'] == id,
        orElse: () => <String, dynamic>{},
      );
      usernameToDelete = userToDelete['name'] as String?;
    }

    await client.removeHotspotUser(id);

    // Delete associated voucher if exists
    if (usernameToDelete != null) {
      try {
        await ref
            .read(vouchersProvider.notifier)
            .expireVoucher(usernameToDelete);
      } catch (_) {
        // Ignore if voucher deletion fails
      }
    }

    // Immediately remove user from current state for instant UI update
    if (currentState != null) {
      final updatedUsers =
          currentState.users.where((user) => user['.id'] != id).toList();
      state = AsyncValue.data(PaginatedUsers(
        users: updatedUsers,
        hasMore: currentState.hasMore,
        currentPage: currentState.currentPage,
        pageSize: currentState.pageSize,
      ));
    }

    // Then refresh in background to ensure data is accurate
    silentRefresh();
  }

  Future<void> silentRefresh() async {
    try {
      final newData = await _loadUsers(page: 1);
      state = AsyncValue.data(newData);
    } catch (e) {
      // Silent refresh failed - will retry on next access
    }
  }

  Future<void> updateUser({
    required String id,
    required String username,
    required String profile,
    String? comment,
  }) async {
    final service = ref.read(routerOSServiceProvider);
    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    // Get current user data to preserve disabled status and password
    final allUsers = await client.getHotspotUsersList();
    final currentUser =
        allUsers.firstWhere((u) => u['.id'] == id, orElse: () => {});

    // Update user using remove and re-add approach
    await client.updateHotspotUser(
      id: id,
      username: username,
      password: currentUser['password'] ?? username,
      profile: profile,
      comment: comment,
      disabled: currentUser['disabled'] == 'true',
    );

    // Refresh the list
    ref.invalidate(hotspotUsersProvider);
  }

  Future<void> toggleUserStatus(String id) async {
    final service = ref.read(routerOSServiceProvider);
    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    // Get current user status from current state
    final currentState = state.value;
    if (currentState != null) {
      final currentUser = currentState.users
          .firstWhere((u) => u['.id'] == id, orElse: () => {});
      final isCurrentlyDisabled =
          currentUser['disabled'] == 'true' || currentUser['disabled'] == 'yes';

      // Immediately update UI by toggling the disabled status in current state
      final updatedUsers = currentState.users.map((user) {
        if (user['.id'] == id) {
          final updatedUser = Map<String, dynamic>.from(user);
          updatedUser['disabled'] = isCurrentlyDisabled ? 'false' : 'true';
          updatedUser['active'] = isCurrentlyDisabled ? 'true' : 'false';
          return updatedUser;
        }
        return user;
      }).toList();

      state = AsyncValue.data(PaginatedUsers(
        users: updatedUsers,
        hasMore: currentState.hasMore,
        currentPage: currentState.currentPage,
        pageSize: currentState.pageSize,
      ));

      // Toggle the status on RouterOS
      try {
        await client.setHotspotUserStatus(
          id: id,
          disabled: !isCurrentlyDisabled,
        );
      } catch (e) {
        // Revert UI change on error
        state = AsyncValue.data(currentState);
        rethrow;
      }

      // Refresh in background to ensure data is accurate
      silentRefresh();
    } else {
      // Fallback if no current state
      final allUsers = await client.getHotspotUsersList();
      final currentUser =
          allUsers.firstWhere((u) => u['.id'] == id, orElse: () => {});
      final isCurrentlyDisabled =
          currentUser['disabled'] == 'true' || currentUser['disabled'] == 'yes';

      await client.setHotspotUserStatus(
        id: id,
        disabled: !isCurrentlyDisabled,
      );

      ref.invalidate(hotspotUsersProvider);
    }

    ref.invalidate(hotspotActiveUsersProvider);
  }
}

// System Resources Provider
final systemResourcesProvider =
    AsyncNotifierProvider<SystemResourcesNotifier, Map<String, dynamic>>(() {
  return SystemResourcesNotifier();
});

class SystemResourcesNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    ref.keepAlive();

    final service = ref.read(routerOSServiceProvider);
    final cache = ref.read(cacheServiceProvider);

    // Try cache first
    final cachedResources = cache.getSystemResources();
    if (cachedResources != null) {
      return cachedResources;
    }

    // No cache, fetch from API
    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    final resources = await client.getSystemResources();
    await cache.saveSystemResources(resources);
    return resources;
  }

  Future<void> refresh() async {
    final cache = ref.read(cacheServiceProvider);
    await cache.clearEntry('system_resources');
    ref.invalidate(systemResourcesProvider);
  }
}

// Resource History Provider - persists across navigation for seamless charts
final resourceHistoryProvider =
    ChangeNotifierProvider<ResourceHistoryNotifier>((ref) {
  return ResourceHistoryNotifier();
});

// Hotspot Active Users Provider
final hotspotActiveUsersProvider =
    AsyncNotifierProvider<HotspotActiveUsersNotifier, PaginatedUsers>(() {
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
    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    await client.logoutHotspotUser(id);
    ref.invalidate(hotspotActiveUsersProvider);
  }
}

// User Profiles Provider
final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, List<UserProfile>>(() {
  return UserProfileNotifier();
});

// Interface Traffic Provider
final interfaceTrafficProvider =
    AsyncNotifierProvider<InterfaceTrafficNotifier, List<InterfaceTraffic>>(() {
  return InterfaceTrafficNotifier();
});

class UserProfileNotifier extends AsyncNotifier<List<UserProfile>> {
  // System profiles to filter out
  static const Set<String> _systemProfileNames = {'trial', 'default'};

  @override
  Future<List<UserProfile>> build() async {
    // Always fetch from API to ensure fresh data
    final profiles = await _fetchProfilesAndCache();

    // If API returned data, use it
    if (profiles.isNotEmpty) {
      return profiles;
    }

    // API returned empty or failed - fall back to cache
    final cache = ref.read(cacheServiceProvider);
    final cachedProfiles = cache.getUserProfiles();
    if (cachedProfiles != null && cachedProfiles.isNotEmpty) {
      return cachedProfiles
          .where((p) => !_systemProfileNames
              .contains(p['name']?.toString().toLowerCase()))
          .map((data) => UserProfile.fromJson(data))
          .toList();
    }

    return [];
  }

  Future<List<UserProfile>> _fetchProfilesAndCache() async {
    final service = ref.read(routerOSServiceProvider);
    final cache = ref.read(cacheServiceProvider);
    final client = service.client;
    if (client == null) {
      return [];
    }

    try {
      final profilesData = await client.getUserProfiles();

      // Filter out system profiles
      final profiles = profilesData
          .where((p) => !_systemProfileNames
              .contains(p['name']?.toString().toLowerCase()))
          .map((data) => UserProfile.fromJson(data))
          .toList();

      // Cache the profiles (cache original data, filtering is applied on load)
      await cache.saveUserProfiles(profilesData);

      return profiles;
    } catch (e) {
      return [];
    }
  }

  Future<void> refresh() async {
    await silentRefresh();
  }

  Future<void> silentRefresh() async {
    try {
      final newData = await _fetchProfilesAndCache();
      if (newData.isNotEmpty) {
        state = AsyncValue.data(newData);
      }
    } catch (_) {}
  }

  Future<void> addProfile(UserProfile profile) async {
    final service = ref.read(routerOSServiceProvider);
    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    // Build rate-limit string from upload/download
    final rateLimit = (profile.rateLimitUpload == null ||
                profile.rateLimitUpload == 'unlimited') &&
            (profile.rateLimitDownload == null ||
                profile.rateLimitDownload == 'unlimited')
        ? null
        : '${profile.rateLimitUpload ?? 'unlimited'}/${profile.rateLimitDownload ?? 'unlimited'}';

    await client.addUserProfile(
      name: profile.name,
      rateLimit: rateLimit,
      sessionTimeout: profile.validity,
    );

    await silentRefresh();
  }

  Future<void> updateProfile(UserProfile updatedProfile) async {
    final service = ref.read(routerOSServiceProvider);
    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    // Build rate-limit string from upload/download
    final rateLimit = (updatedProfile.rateLimitUpload == null ||
                updatedProfile.rateLimitUpload == 'unlimited') &&
            (updatedProfile.rateLimitDownload == null ||
                updatedProfile.rateLimitDownload == 'unlimited')
        ? null
        : '${updatedProfile.rateLimitUpload ?? 'unlimited'}/${updatedProfile.rateLimitDownload ?? 'unlimited'}';

    await client.updateUserProfile(
      id: updatedProfile.id,
      name: updatedProfile.name,
      rateLimit: rateLimit,
      sessionTimeout: updatedProfile.validity,
    );

    await silentRefresh();
  }

  Future<void> deleteProfile(String id) async {
    final service = ref.read(routerOSServiceProvider);
    final client = service.client;
    if (client == null) {
      throw Exception('Not connected to RouterOS');
    }

    await client.removeUserProfile(id);

    // Refresh using silent method (no loading state)
    await silentRefresh();
  }
}

// Vouchers Provider
final vouchersProvider =
    AsyncNotifierProvider<VouchersNotifier, List<Voucher>>(() {
  return VouchersNotifier();
});

class VouchersNotifier extends AsyncNotifier<List<Voucher>> {
  @override
  Future<List<Voucher>> build() async {
    final cache = ref.read(cacheServiceProvider);

    // Try to get cached vouchers first
    final cachedVouchers = cache.getVouchers();
    if (cachedVouchers != null && cachedVouchers.isNotEmpty) {
      return cachedVouchers.map((data) => Voucher.fromJson(data)).toList();
    }

    // No cache, return empty list
    return [];
  }

  /// Add new vouchers to cache and update state
  Future<void> addVouchers(List<Voucher> newVouchers) async {
    final cache = ref.read(cacheServiceProvider);
    final vouchersJson = newVouchers.map((v) => v.toJson()).toList();
    await cache.addVouchers(vouchersJson);

    // Refresh state from cache
    await refresh();
  }

  /// Delete a voucher by username
  Future<void> deleteVoucher(String username) async {
    final cache = ref.read(cacheServiceProvider);
    await cache.deleteVoucher(username);

    // Refresh state from cache
    await refresh();
  }

  /// Delete multiple vouchers by usernames (for bulk delete)
  Future<void> deleteVouchers(List<String> usernames) async {
    final cache = ref.read(cacheServiceProvider);
    for (final username in usernames) {
      await cache.deleteVoucher(username);
    }

    // Refresh state from cache
    await refresh();
  }

  /// Expire vouchers when hotspot user is deleted
  Future<void> expireVoucher(String username) async {
    // Delete the voucher when the user is deleted
    await deleteVoucher(username);
  }

  /// Expire multiple vouchers when hotspot users are deleted
  Future<void> expireVouchers(List<String> usernames) async {
    await deleteVouchers(usernames);
  }

  /// Clear all vouchers
  Future<void> clearVouchers() async {
    final cache = ref.read(cacheServiceProvider);
    await cache.clearVouchers();

    // Update state to empty list
    state = const AsyncValue.data([]);
  }

  /// Refresh vouchers from cache
  Future<void> refresh() async {
    try {
      final cache = ref.read(cacheServiceProvider);
      final cachedVouchers = cache.getVouchers();

      if (cachedVouchers != null) {
        state = AsyncValue.data(
            cachedVouchers.map((data) => Voucher.fromJson(data)).toList());
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e) {
      // Refresh failed silently
    }
  }

  /// Sort vouchers by specified criteria
  void sortVouchers(VoucherSort sort) {
    final currentVouchers = state.valueOrNull ?? [];
    if (currentVouchers.isEmpty) return;

    List<Voucher> sorted = List.from(currentVouchers);

    switch (sort) {
      case VoucherSort.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case VoucherSort.oldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case VoucherSort.az:
        sorted.sort((a, b) =>
            a.username.toLowerCase().compareTo(b.username.toLowerCase()));
        break;
    }

    state = AsyncValue.data(sorted);
  }
}

// Income/Transactions Provider
final incomeProvider = AsyncNotifierProvider<IncomeNotifier, IncomeState>(() {
  return IncomeNotifier();
});

class IncomeState {
  final List<SalesTransaction> transactions;
  final IncomeSummary summary;

  const IncomeState({
    this.transactions = const [],
    required this.summary,
  });

  IncomeState copyWith({
    List<SalesTransaction>? transactions,
    IncomeSummary? summary,
  }) {
    return IncomeState(
      transactions: transactions ?? this.transactions,
      summary: summary ?? this.summary,
    );
  }
}

class IncomeNotifier extends AsyncNotifier<IncomeState> {
  @override
  Future<IncomeState> build() async {
    final cache = ref.read(cacheServiceProvider);

    // Try to load from cache first
    final cachedTransactions = cache.getSalesTransactions();
    final cachedSummary = cache.getIncomeSummary();

    if (cachedTransactions != null && cachedSummary != null) {
      return IncomeState(
        transactions: cachedTransactions
            .map((t) => SalesTransaction.fromJson(t))
            .toList(),
        summary: IncomeSummary(
          todayIncome: (cachedSummary['todayIncome'] as num).toDouble(),
          thisMonthIncome: (cachedSummary['thisMonthIncome'] as num).toDouble(),
          transactionsToday: cachedSummary['transactionsToday'] as int,
          transactionsThisMonth: cachedSummary['transactionsThisMonth'] as int,
        ),
      );
    }

    // Return empty state if no cache
    return const IncomeState(
      transactions: [],
      summary: IncomeSummary(
        todayIncome: 0.0,
        thisMonthIncome: 0.0,
        transactionsToday: 0,
        transactionsThisMonth: 0,
      ),
    );
  }

  Future<void> recordSale({
    required String username,
    required String profile,
    required double price,
    String? comment,
  }) async {
    final cache = ref.read(cacheServiceProvider);

    final transaction = SalesTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      profile: profile,
      price: price,
      timestamp: DateTime.now(),
      comment: comment,
    );

    // Save to cache
    await cache.saveSalesTransaction(transaction.toJson());

    // Refresh state
    ref.invalidate(incomeProvider);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}

// Interface Traffic Provider
final savedConnectionsProvider =
    AsyncNotifierProvider<SavedConnectionsNotifier, List<RouterConnection>>(() {
  return SavedConnectionsNotifier();
});

class SavedConnectionsNotifier extends AsyncNotifier<List<RouterConnection>> {
  @override
  Future<List<RouterConnection>> build() async {
    final cache = ref.read(cacheServiceProvider);
    final cachedConnections = cache.getSavedConnections();

    if (cachedConnections != null) {
      return cachedConnections
          .map((c) => RouterConnection.fromJson(c))
          .toList();
    }

    return [];
  }

  Future<void> addConnection({
    required String name,
    required String host,
    required String port,
    required String username,
  }) async {
    final cache = ref.read(cacheServiceProvider);

    final connection = RouterConnection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      host: host,
      port: port,
      username: username,
    );

    await cache.addSavedConnection(connection.toJson());

    // Refresh state by rebuilding
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> updateConnection(RouterConnection connection) async {
    final cache = ref.read(cacheServiceProvider);
    await cache.updateSavedConnection(connection.id, connection.toJson());

    // Refresh state by rebuilding
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> deleteConnection(String id) async {
    final cache = ref.read(cacheServiceProvider);
    await cache.deleteSavedConnection(id);

    // Refresh state by rebuilding
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }
}

// Interface Traffic Notifier
// Traffic rate service for calculating real-time rates
final _trafficRateService = TrafficRateService();

class InterfaceTrafficNotifier extends AsyncNotifier<List<InterfaceTraffic>> {
  @override
  Future<List<InterfaceTraffic>> build() async {
    // Keep the provider alive even when no listeners are attached
    ref.keepAlive();

    final service = ref.read(routerOSServiceProvider);

    // Check cache first for instant display (seamless UX)
    final cache = ref.read(cacheServiceProvider);
    final cachedTraffic = cache.getInterfaceTraffic();

    if (cachedTraffic != null && cachedTraffic.isNotEmpty) {
      // Convert cached maps back to InterfaceTraffic objects
      return cachedTraffic
          .map((data) => InterfaceTraffic.fromJson(data))
          .toList();
    }

    // No cache, fetch from API
    final client = service.client;
    if (client == null) {
      return [];
    }

    final interfacesData = await client.getInterfaceStats();
    final interfaces = interfacesData.map((data) {
      return InterfaceTraffic.fromJson(data);
    }).toList();

    // Calculate rates using historical data
    final result = _trafficRateService.calculateRates(interfaces);

    // Save to cache
    await cache.saveInterfaceTraffic(result.map((e) => e.toJson()).toList());

    return result;
  }

  Future<void> refresh() async {
    // Don't show loading - just refresh in background
    await silentRefresh();
  }

  /// Silent refresh - updates data without showing loading state
  Future<void> silentRefresh() async {
    final service = ref.read(routerOSServiceProvider);

    try {
      final client = service.client;
      if (client == null) {
        return;
      }

      final interfacesData = await client.getInterfaceStats();
      final interfaces = interfacesData.map((data) {
        return InterfaceTraffic.fromJson(data);
      }).toList();

      // Calculate rates using historical data
      final newData = _trafficRateService.calculateRates(interfaces);

      // Save to cache
      final cache = ref.read(cacheServiceProvider);
      await cache.saveInterfaceTraffic(newData.map((e) => e.toJson()).toList());

      // Update state directly without loading
      state = AsyncValue.data(newData);
    } catch (e) {
      // Silent fail - don't show error on auto-refresh
    }
  }
}

// Hotspot Hosts Provider
final hotspotHostsProvider =
    AsyncNotifierProvider<HotspotHostsNotifier, List<HotspotHost>>(() {
  return HotspotHostsNotifier();
});

class HotspotHostsNotifier extends AsyncNotifier<List<HotspotHost>> {
  bool _timerStarted = false;

  @override
  Future<List<HotspotHost>> build() async {
    final hosts = await _fetchHosts();
    // Start auto-refresh when data becomes available
    _startAutoRefresh();
    return hosts;
  }

  Future<List<HotspotHost>> _fetchHosts() async {
    final service = ref.read(routerOSServiceProvider);

    final client = service.client;
    if (client == null) {
      return [];
    }

    try {
      final hostsData = await client.getHotspotHosts();
      return hostsData.map((data) => HotspotHost.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  void _startAutoRefresh() {
    if (_timerStarted) return;
    _timerStarted = true;
    Timer.periodic(const Duration(seconds: 5), (timer) {
      silentRefresh();
    });
  }

  Future<void> silentRefresh() async {
    try {
      final hosts = await _fetchHosts();
      state = AsyncValue.data(hosts);
    } catch (e) {
      // Silent refresh failed
    }
  }

  // Note: AsyncNotifier doesn't have dispose, timer will be cancelled when provider is disposed
}
