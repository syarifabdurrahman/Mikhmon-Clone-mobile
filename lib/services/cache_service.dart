import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

/// Cache service for storing RouterOS data locally using Hive
/// Provides instant data access and offline support
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  late Box _cacheBox;
  bool _initialized = false;

  // Cache keys
  static const String _boxName = 'routeros_cache';
  static const String _systemResourcesKey = 'system_resources';
  static const String _hotspotUsersKey = 'hotspot_users';
  static const String _activeUsersKey = 'active_users';
  static const String _userProfilesKey = 'user_profiles';
  static const String _lastUpdateKey = 'last_update';

  /// Initialize Hive cache
  Future<void> init() async {
    if (_initialized) return;

    try {
      // Initialize Hive
      await Hive.initFlutter();

      // Open cache box
      _cacheBox = await Hive.openBox(_boxName);

      _initialized = true;
      debugPrint('[CacheService] Initialized successfully');
    } catch (e) {
      debugPrint('[CacheService] Initialization failed: $e');
      rethrow;
    }
  }

  /// Check if cache is initialized
  bool get isInitialized => _initialized;

  /// Get system resources from cache
  Map<String, dynamic>? getSystemResources() {
    try {
      final data = _cacheBox.get(_systemResourcesKey);
      if (data != null && data is Map) {
        debugPrint('[CacheService] System resources cache hit');
        return Map<String, dynamic>.from(data);
      }
      debugPrint('[CacheService] System resources cache miss');
      return null;
    } catch (e) {
      debugPrint('[CacheService] Error reading system resources: $e');
      return null;
    }
  }

  /// Save system resources to cache
  Future<void> saveSystemResources(Map<String, dynamic> data) async {
    try {
      await _cacheBox.put(_systemResourcesKey, data);
      await _cacheBox.put(_lastUpdateKey, DateTime.now().toIso8601String());
      debugPrint('[CacheService] System resources cached');
    } catch (e) {
      debugPrint('[CacheService] Error saving system resources: $e');
    }
  }

  /// Get hotspot users from cache
  List<Map<String, dynamic>>? getHotspotUsers() {
    try {
      final data = _cacheBox.get(_hotspotUsersKey);
      if (data != null && data is List) {
        debugPrint('[CacheService] Hotspot users cache hit (${data.length} users)');
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      debugPrint('[CacheService] Hotspot users cache miss');
      return null;
    } catch (e) {
      debugPrint('[CacheService] Error reading hotspot users: $e');
      return null;
    }
  }

  /// Save hotspot users to cache
  Future<void> saveHotspotUsers(List<Map<String, dynamic>> data) async {
    try {
      await _cacheBox.put(_hotspotUsersKey, data);
      debugPrint('[CacheService] Hotspot users cached (${data.length} users)');
    } catch (e) {
      debugPrint('[CacheService] Error saving hotspot users: $e');
    }
  }

  /// Get active users from cache
  List<Map<String, dynamic>>? getActiveUsers() {
    try {
      final data = _cacheBox.get(_activeUsersKey);
      if (data != null && data is List) {
        debugPrint('[CacheService] Active users cache hit (${data.length} users)');
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      debugPrint('[CacheService] Active users cache miss');
      return null;
    } catch (e) {
      debugPrint('[CacheService] Error reading active users: $e');
      return null;
    }
  }

  /// Save active users to cache
  Future<void> saveActiveUsers(List<Map<String, dynamic>> data) async {
    try {
      await _cacheBox.put(_activeUsersKey, data);
      debugPrint('[CacheService] Active users cached (${data.length} users)');
    } catch (e) {
      debugPrint('[CacheService] Error saving active users: $e');
    }
  }

  /// Get user profiles from cache
  List<Map<String, dynamic>>? getUserProfiles() {
    try {
      final data = _cacheBox.get(_userProfilesKey);
      if (data != null && data is List) {
        debugPrint('[CacheService] User profiles cache hit (${data.length} profiles)');
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      debugPrint('[CacheService] User profiles cache miss');
      return null;
    } catch (e) {
      debugPrint('[CacheService] Error reading user profiles: $e');
      return null;
    }
  }

  /// Save user profiles to cache
  Future<void> saveUserProfiles(List<Map<String, dynamic>> data) async {
    try {
      await _cacheBox.put(_userProfilesKey, data);
      debugPrint('[CacheService] User profiles cached (${data.length} profiles)');
    } catch (e) {
      debugPrint('[CacheService] Error saving user profiles: $e');
    }
  }

  /// Get last update timestamp
  DateTime? getLastUpdate() {
    try {
      final timestamp = _cacheBox.get(_lastUpdateKey);
      if (timestamp != null && timestamp is String) {
        return DateTime.parse(timestamp);
      }
      return null;
    } catch (e) {
      debugPrint('[CacheService] Error reading last update: $e');
      return null;
    }
  }

  /// Check if cache is stale (older than specified duration)
  bool isCacheStale({Duration maxAge = const Duration(minutes: 5)}) {
    final lastUpdate = getLastUpdate();
    if (lastUpdate == null) return true;
    return DateTime.now().difference(lastUpdate) > maxAge;
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      await _cacheBox.clear();
      debugPrint('[CacheService] Cache cleared');
    } catch (e) {
      debugPrint('[CacheService] Error clearing cache: $e');
    }
  }

  /// Clear specific cache entry
  Future<void> clearEntry(String key) async {
    try {
      await _cacheBox.delete(key);
      debugPrint('[CacheService] Cache entry cleared: $key');
    } catch (e) {
      debugPrint('[CacheService] Error clearing cache entry: $e');
    }
  }

  /// Close the cache box
  Future<void> close() async {
    try {
      await _cacheBox.close();
      _initialized = false;
      debugPrint('[CacheService] Cache closed');
    } catch (e) {
      debugPrint('[CacheService] Error closing cache: $e');
    }
  }
}
