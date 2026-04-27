import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'mikrotik_client.dart';

class RouterOSHttpClient implements MikrotikClient {
  final String host;
  final String port;
  final String username;
  final String password;
  bool _isConnected = false;
  Dio? _dio;

  // Enable debug logging
  static const bool _debug = false;

  void _log(String message) {
    if (_debug) {
      debugPrint('[RouterOS HTTP] $message');
    }
  }

  RouterOSHttpClient({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
  });

  bool get isConnected => _isConnected;

  String get _baseUrl => 'http://$host:$port/rest';

  Future<void> connect() async {
    try {
      _log('=== Starting HTTP connection ===');
      _log('Host: $host:$port');
      _log('Username: $username');

      _dio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Basic ${base64Encode(utf8.encode('$username:$password'))}',
        },
        validateStatus: (status) => status != null && status < 500,
      ));

      // Test connection by fetching system resources
      await getSystemResources();
      _isConnected = true;
      _log('✓ HTTP Connection successful!');
    } catch (e) {
      _log('✗ HTTP Connection failed: $e');
      _isConnected = false;
      rethrow;
    }
  }

  @override
  void close() {
    _dio?.close();
    _isConnected = false;
  }

  @override
  Future<Map<String, dynamic>> getSystemResources() async {
    final response = await _dio!.get('/system/resource');
    if (response.data is List && (response.data as List).isNotEmpty) {
      return response.data[0] as Map<String, dynamic>;
    }
    if (response.data is Map) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }

  @override
  Future<List<Map<String, dynamic>>> getInterfaceStats() async {
    final response = await _dio!.get('/interface');
    return List<Map<String, dynamic>>.from(response.data);
  }

  @override
  Future<List<Map<String, dynamic>>> getHotspotUsers() async {
    final response = await _dio!.get('/ip/hotspot/user');
    return List<Map<String, dynamic>>.from(response.data);
  }

  @override
  Future<List<Map<String, dynamic>>> getHotspotActiveUsers() async {
    final response = await _dio!.get('/ip/hotspot/active');
    return List<Map<String, dynamic>>.from(response.data);
  }

  @override
  Future<List<Map<String, dynamic>>> getHotspotHosts() async {
    final response = await _dio!.get('/ip/hotspot/host');
    return List<Map<String, dynamic>>.from(response.data);
  }

  @override
  Future<List<Map<String, dynamic>>> getHotspotProfiles() async {
    final response = await _dio!.get('/ip/hotspot/user/profile');
    return List<Map<String, dynamic>>.from(response.data);
  }

  @override
  Future<void> addUser(Map<String, String> user) async {
    await _dio!.post('/ip/hotspot/user', data: user);
  }

  @override
  Future<void> updateUser(String id, Map<String, String> user) async {
    await _dio!.patch('/ip/hotspot/user/$id', data: user);
  }

  @override
  Future<void> deleteUser(String id) async {
    await _dio!.delete('/ip/hotspot/user/$id');
  }

  @override
  Future<void> toggleUserStatus(String id, bool disabled) async {
    await _dio!.patch('/ip/hotspot/user/$id', data: {'disabled': disabled});
  }

  @override
  Future<void> setHotspotUserProfile(String id, String profile) async {
    await _dio!.patch('/ip/hotspot/user/$id', data: {'profile': profile});
  }

  @override
  Future<void> logoutUser(String id) async {
    await _dio!.delete('/ip/hotspot/active/$id');
  }

  @override
  Future<void> logoutHotspotUser(String id) async => logoutUser(id);

  @override
  Future<void> setHotspotUserStatus(String id, bool disabled) async {
    await _dio!.patch('/ip/hotspot/user/$id', data: {'disabled': disabled});
  }

  @override
  Future<List<Map<String, dynamic>>> getDhcpLeases() async {
    final response = await _dio!.get('/ip/dhcp-server/lease');
    return List<Map<String, dynamic>>.from(response.data);
  }

  @override
  Future<void> addHotspotUser({
    required String username,
    required String password,
    required String profile,
    String? comment,
    String? validity,
    String? dataLimit,
  }) async {
    await addUser({
      'name': username,
      'password': password,
      'profile': profile,
      if (comment != null) 'comment': comment,
      if (validity != null) 'limit-uptime': validity,
      if (dataLimit != null) 'limit-bytes-total': dataLimit,
    });
  }

  @override
  Future<void> updateHotspotUser({
    required String id,
    required String username,
    required String profile,
    String? comment,
  }) async {
    await updateUser(id, {
      'name': username,
      'profile': profile,
      if (comment != null) 'comment': comment,
    });
  }

  @override
  Future<void> removeHotspotUser(String id) async => deleteUser(id);

  @override
  Future<void> addProfile(Map<String, String> profile) async {
    await _dio!.post('/ip/hotspot/user/profile', data: profile);
  }

  @override
  Future<void> updateProfile(String id, Map<String, String> profile) async {
    await _dio!.patch('/ip/hotspot/user/profile/$id', data: profile);
  }

  @override
  Future<void> deleteProfile(String id) async {
    await _dio!.delete('/ip/hotspot/user/profile/$id');
  }

  @override
  Future<List<Map<String, dynamic>>> getFiles() async {
    final response = await _dio!.get('/file');
    return List<Map<String, dynamic>>.from(response.data);
  }

  @override
  Future<void> deleteFile(String id) async {
    await _dio!.delete('/file/$id');
  }

  @override
  Future<void> createBackup(String name) async {
    await _dio!.post('/system/backup/save', data: {'name': name});
  }

  @override
  Future<void> exportConfig(String name) async {
    await _dio!.post('/export', data: {'file': name});
  }

  @override
  Future<String> downloadFile(String name) async {
    final response = await _dio!.get('/file/$name');
    if (response.data is Map) {
      return response.data['contents'] ?? '';
    }
    return '';
  }
}
