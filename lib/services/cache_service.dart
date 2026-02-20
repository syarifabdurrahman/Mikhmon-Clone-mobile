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
  static const String _salesTransactionsKey = 'sales_transactions';
  static const String _incomeSummaryKey = 'income_summary';
  static const String _savedConnectionsKey = 'saved_connections';
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

  /// Get sales transactions from cache
  List<Map<String, dynamic>>? getSalesTransactions() {
    try {
      final data = _cacheBox.get(_salesTransactionsKey);
      if (data != null && data is List) {
        debugPrint('[CacheService] Sales transactions cache hit (${data.length} transactions)');
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      debugPrint('[CacheService] Sales transactions cache miss');
      return null;
    } catch (e) {
      debugPrint('[CacheService] Error reading sales transactions: $e');
      return null;
    }
  }

  /// Save a single sales transaction to cache
  Future<void> saveSalesTransaction(Map<String, dynamic> transaction) async {
    try {
      final transactions = getSalesTransactions() ?? [];
      transactions.add(transaction);
      await _cacheBox.put(_salesTransactionsKey, transactions);
      debugPrint('[CacheService] Sales transaction cached');
    } catch (e) {
      debugPrint('[CacheService] Error saving sales transaction: $e');
    }
  }

  /// Save multiple sales transactions to cache
  Future<void> saveSalesTransactions(List<Map<String, dynamic>> transactions) async {
    try {
      await _cacheBox.put(_salesTransactionsKey, transactions);
      debugPrint('[CacheService] Sales transactions cached (${transactions.length} transactions)');
    } catch (e) {
      debugPrint('[CacheService] Error saving sales transactions: $e');
    }
  }

  /// Get income summary from cache
  Map<String, dynamic>? getIncomeSummary() {
    try {
      final data = _cacheBox.get(_incomeSummaryKey);
      if (data != null && data is Map) {
        debugPrint('[CacheService] Income summary cache hit');
        return Map<String, dynamic>.from(data);
      }
      debugPrint('[CacheService] Income summary cache miss');
      return null;
    } catch (e) {
      debugPrint('[CacheService] Error reading income summary: $e');
      return null;
    }
  }

  /// Save income summary to cache
  Future<void> saveIncomeSummary(Map<String, dynamic> summary) async {
    try {
      await _cacheBox.put(_incomeSummaryKey, summary);
      debugPrint('[CacheService] Income summary cached');
    } catch (e) {
      debugPrint('[CacheService] Error saving income summary: $e');
    }
  }

  /// Get saved router connections from cache
  List<Map<String, dynamic>>? getSavedConnections() {
    try {
      final data = _cacheBox.get(_savedConnectionsKey);
      if (data != null && data is List) {
        debugPrint('[CacheService] Saved connections cache hit (${data.length} connections)');
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      debugPrint('[CacheService] Saved connections cache miss');
      return null;
    } catch (e) {
      debugPrint('[CacheService] Error reading saved connections: $e');
      return null;
    }
  }

  /// Save router connections to cache
  Future<void> saveSavedConnections(List<Map<String, dynamic>> connections) async {
    try {
      await _cacheBox.put(_savedConnectionsKey, connections);
      debugPrint('[CacheService] Saved connections cached (${connections.length} connections)');
    } catch (e) {
      debugPrint('[CacheService] Error saving saved connections: $e');
    }
  }

  /// Add a single router connection to cache
  Future<void> addSavedConnection(Map<String, dynamic> connection) async {
    try {
      final connections = getSavedConnections() ?? [];
      connections.add(connection);
      await _cacheBox.put(_savedConnectionsKey, connections);
      debugPrint('[CacheService] Saved connection added');
    } catch (e) {
      debugPrint('[CacheService] Error adding saved connection: $e');
    }
  }

  /// Update a router connection in cache
  Future<void> updateSavedConnection(String id, Map<String, dynamic> updatedConnection) async {
    try {
      final connections = getSavedConnections();
      if (connections == null) return;

      final index = connections.indexWhere((c) => c['id'] == id);
      if (index != -1) {
        connections[index] = updatedConnection;
        await _cacheBox.put(_savedConnectionsKey, connections);
        debugPrint('[CacheService] Saved connection updated');
      }
    } catch (e) {
      debugPrint('[CacheService] Error updating saved connection: $e');
    }
  }

  /// Delete a router connection from cache
  Future<void> deleteSavedConnection(String id) async {
    try {
      final connections = getSavedConnections();
      if (connections == null) return;

      connections.removeWhere((c) => c['id'] == id);
      await _cacheBox.put(_savedConnectionsKey, connections);
      debugPrint('[CacheService] Saved connection deleted');
    } catch (e) {
      debugPrint('[CacheService] Error deleting saved connection: $e');
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
