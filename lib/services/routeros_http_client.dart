import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class RouterOSHttpClient {
  final String host;
  final String port;
  final String username;
  final String password;
  bool _isConnected = false;
  Dio? _dio;
  String? _sessionId;

  // Enable debug logging
  static const bool _debug = true;

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
      _log('Password: ${password.isNotEmpty ? "***" : "(empty)"}');

      _dio = Dio(BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ));

      // Login to get session
      if (password.isNotEmpty) {
        _log('Logging in with password...');
        await _login();
      } else {
        _log('Logging in without password...');
        await _loginWithoutPassword();
      }

      _isConnected = true;
      _log('✓ Connection successful!');
    } catch (e) {
      _log('✗ Connection failed: $e');
      _isConnected = false;
      _sessionId = null;
      rethrow;
    }
  }

  Future<void> _login() async {
    try {
      final response = await _dio!.post(
        '/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      _log('Login response status: ${response.statusCode}');

      // Check for session cookie
      final cookies = response.headers['set-cookie'];
      if (cookies != null && cookies.isNotEmpty) {
        for (final cookie in cookies) {
          if (cookie.contains('MIKROTIK_JWT') || cookie.contains('PHPSESSID')) {
            _sessionId = cookie.split(';')[0];
            _log('Session ID: $_sessionId');
            break;
          }
        }
      }

      // Some RouterOS versions return the session directly
      if (response.data is Map && response.data['token'] != null) {
        _sessionId = response.data['token'];
        _log('Token: $_sessionId');
      }

      if (response.statusCode != 200 && response.statusCode != 401) {
        throw Exception('Login failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _log('Login error: $e');
      rethrow;
    }
  }

  Future<void> _loginWithoutPassword() async {
    // For login without password, just send username
    try {
      final response = await _dio!.post(
        '/login',
        data: {
          'username': username,
        },
      );

      _log('Login response status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 401) {
        throw Exception('Login failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _log('Login error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSystemResources() async {
    try {
      _ensureConnected();
      _log('Fetching system resources...');

      final response = await _dio!.get(
        '/system/resource/print',
        options: _buildOptions(),
      );

      _log('Response status: ${response.statusCode}');
      _log('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List && data.isNotEmpty) {
          return Map<String, dynamic>.from(data[0]);
        }
        return Map<String, dynamic>.from(data);
      }

      throw Exception('Failed with status: ${response.statusCode}');
    } catch (e) {
      _log('Error fetching system resources: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getHotspotUsersList() async {
    try {
      _ensureConnected();
      _log('Fetching hotspot users...');

      final response = await _dio!.get(
        '/ip/hotspot/user/print',
        options: _buildOptions(),
      );

      _log('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return List<Map<String, dynamic>>.from(
            data.map((e) => Map<String, dynamic>.from(e)),
          );
        }
        return [Map<String, dynamic>.from(data)];
      }

      throw Exception('Failed with status: ${response.statusCode}');
    } catch (e) {
      _log('Error fetching hotspot users: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getHotspotActiveUsers() async {
    try {
      _ensureConnected();
      _log('Fetching active hotspot users...');

      final response = await _dio!.get(
        '/ip/hotspot/active/print',
        options: _buildOptions(),
      );

      _log('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return List<Map<String, dynamic>>.from(
            data.map((e) => Map<String, dynamic>.from(e)),
          );
        }
        return [Map<String, dynamic>.from(data)];
      }

      throw Exception('Failed with status: ${response.statusCode}');
    } catch (e) {
      _log('Error fetching active users: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserProfiles() async {
    try {
      _ensureConnected();
      _log('Fetching user profiles...');

      final response = await _dio!.get(
        '/ip/hotspot/user/profile/print',
        options: _buildOptions(),
      );

      _log('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return List<Map<String, dynamic>>.from(
            data.map((e) => Map<String, dynamic>.from(e)),
          );
        }
        return [Map<String, dynamic>.from(data)];
      }

      throw Exception('Failed with status: ${response.statusCode}');
    } catch (e) {
      _log('Error fetching user profiles: $e');
      rethrow;
    }
  }

  Future<void> addHotspotUser({
    required String username,
    required String password,
    required String profile,
    String? comment,
  }) async {
    try {
      _ensureConnected();
      _log('Adding hotspot user: $username');

      final data = {
        'name': username,
        'password': password,
        'profile': profile,
      };
      if (comment != null) {
        data['comment'] = comment;
      }

      final response = await _dio!.put(
        '/ip/hotspot/user/add',
        data: data,
        options: _buildOptions(),
      );

      _log('Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _log('Error adding hotspot user: $e');
      rethrow;
    }
  }

  Future<void> removeHotspotUser(String id) async {
    try {
      _ensureConnected();
      _log('Removing hotspot user: $id');

      final response = await _dio!.post(
        '/ip/hotspot/user/remove',
        data: {'.id': id},
        options: _buildOptions(),
      );

      _log('Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _log('Error removing hotspot user: $e');
      rethrow;
    }
  }

  Future<void> logoutHotspotUser(String id) async {
    try {
      _ensureConnected();
      _log('Logging out hotspot user: $id');

      final response = await _dio!.post(
        '/ip/hotspot/active/remove',
        data: {'.id': id},
        options: _buildOptions(),
      );

      _log('Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _log('Error logging out user: $e');
      rethrow;
    }
  }

  Future<void> setHotspotUserStatus({
    required String id,
    required bool disabled,
  }) async {
    try {
      _ensureConnected();
      _log('Setting user status: $id -> disabled=$disabled');

      final response = await _dio!.post(
        '/ip/hotspot/user/set',
        data: {
          '.id': id,
          'disabled': disabled ? 'true' : 'false',
        },
        options: _buildOptions(),
      );

      _log('Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _log('Error setting user status: $e');
      rethrow;
    }
  }

  Future<void> updateHotspotUser({
    required String id,
    required String username,
    required String password,
    required String profile,
    String? comment,
    bool disabled = false,
  }) async {
    try {
      _ensureConnected();
      _log('Updating hotspot user: $username');

      final data = {
        '.id': id,
        'name': username,
        'password': password,
        'profile': profile,
        'disabled': disabled ? 'yes' : 'no',
      };
      if (comment != null) {
        data['comment'] = comment;
      }

      final response = await _dio!.post(
        '/ip/hotspot/user/set',
        data: data,
        options: _buildOptions(),
      );

      _log('Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _log('Error updating hotspot user: $e');
      rethrow;
    }
  }

  Future<void> addUserProfile({
    required String name,
    String? rateLimit,
    String? uptimeLimit,
    String? dataLimit,
  }) async {
    try {
      _ensureConnected();
      _log('Adding user profile: $name');

      final data = <String, dynamic>{'name': name};
      if (rateLimit != null) {
        data['rate-limit'] = rateLimit;
      }
      if (uptimeLimit != null) {
        data['on-logout'] = uptimeLimit;
      }
      if (dataLimit != null) {
        data['on-login'] = dataLimit;
      }

      final response = await _dio!.put(
        '/ip/hotspot/user/profile/add',
        data: data,
        options: _buildOptions(),
      );

      _log('Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _log('Error adding user profile: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfile({
    required String id,
    String? name,
    String? rateLimit,
  }) async {
    try {
      _ensureConnected();
      _log('Updating user profile: $id');

      final data = <String, dynamic>{'.id': id};
      if (name != null) {
        data['name'] = name;
      }
      if (rateLimit != null) {
        data['rate-limit'] = rateLimit;
      }

      final response = await _dio!.post(
        '/ip/hotspot/user/profile/set',
        data: data,
        options: _buildOptions(),
      );

      _log('Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _log('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<void> removeUserProfile(String id) async {
    try {
      _ensureConnected();
      _log('Removing user profile: $id');

      final response = await _dio!.post(
        '/ip/hotspot/user/profile/remove',
        data: {'.id': id},
        options: _buildOptions(),
      );

      _log('Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Failed with status: ${response.statusCode}');
      }
    } catch (e) {
      _log('Error removing user profile: $e');
      rethrow;
    }
  }

  Future<void> _ensureConnected() async {
    if (!_isConnected || _dio == null) {
      _log('Auto-reconnecting...');
      await connect();
    }
  }

  Options _buildOptions() {
    final options = Options();

    if (_sessionId != null) {
      options.headers = {'Cookie': _sessionId};
    }

    return options;
  }

  Future<void> disconnect() async {
    _sessionId = null;
    _dio?.close();
    _dio = null;
    _isConnected = false;
    _log('Disconnected');
  }
}
