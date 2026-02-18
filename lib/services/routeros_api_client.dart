import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class RouterOSClient {
  final String host;
  final String port;
  final String username;
  final String password;
  bool _isConnected = false;
  Socket? _socket;
  Completer<String>? _responseCompleter;
  final StringBuffer _responseBuffer = StringBuffer();

  // Enable debug logging
  static const bool _debug = true;

  void _log(String message) {
    if (_debug) {
      debugPrint('[RouterOS] $message');
    }
  }

  RouterOSClient({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
  });

  bool get isConnected => _isConnected;

  Future<void> _ensureConnected() async {
    if (_socket == null || !_isConnected) {
      _log('Auto-reconnecting...');
      await connect();
    }
  }

  Future<void> connect() async {
    try {
      _log('=== Starting connection ===');
      _log('Host: $host:$port');
      _log('Username: $username');
      _log('Password: ${password.isNotEmpty ? "***" : "(empty)"}');

      _socket = await Socket.connect(host, int.parse(port))
          .timeout(const Duration(seconds: 10));

      _log('✓ Socket connected successfully');

      // Set up socket listener
      _setupSocketListener();

      // Flush any initial data
      _responseBuffer.clear();

      // Handle login with or without password
      if (password.isEmpty) {
        _log('Attempting login without password...');
        // Login without password - just send username
        _writeCommand('/login', {'name': username});

        final loginResponse = await _readResponse();
        _log('Login response: $loginResponse');
        if (loginResponse.contains('!trap') || loginResponse.contains('!error')) {
          throw Exception('Authentication failed: Invalid credentials');
        }
      } else {
        _log('Attempting login with password (challenge-response)...');
        // Login with password - use challenge-response
        _writeCommand('/login');

        final response = await _readResponse();
        _log('Challenge response: $response');
        if (response.contains('!trap')) {
          throw Exception('Connection failed: Invalid response');
        }

        final challenge = _extractChallenge(response);
        _log('Extracted challenge: $challenge');

        final hashedPassword = _hashPassword(challenge, password);
        _log('Hashed password: $hashedPassword');

        _writeCommand('/login', {
          'name': username,
          'response': hashedPassword,
        });

        final loginResponse = await _readResponse();
        _log('Final login response: $loginResponse');
        if (loginResponse.contains('!trap') || loginResponse.contains('!error')) {
          throw Exception('Authentication failed: Invalid credentials');
        }
      }

      _isConnected = true;
      _log('✓ Connection successful!');
    } catch (e) {
      _log('✗ Connection failed: $e');
      _isConnected = false;
      await disconnect();
      rethrow;
    }
  }

  void _setupSocketListener() {
    _socket?.listen(
      (data) {
        final response = String.fromCharCodes(data);
        _log('Received raw data: ${response.length} bytes');
        _log('Raw data (hex): ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
        _responseBuffer.write(response);
        _log('Buffer so far: ${_responseBuffer.toString()}');

        // Check if response is complete (ends with !done or empty line after data)
        final bufferStr = _responseBuffer.toString();
        if (bufferStr.contains('!done') ||
            (bufferStr.contains('!re') && bufferStr.endsWith('\n'))) {
          _log('Response complete, completing future');
          _responseCompleter?.complete(_responseBuffer.toString());
        }
      },
      onError: (error) {
        _log('Socket error: $error');
        _responseCompleter?.completeError(error);
      },
      onDone: () {
        _log('Socket closed by server');
        if (!_responseCompleter!.isCompleted) {
          _responseCompleter?.complete(_responseBuffer.toString());
        }
        _isConnected = false;
      },
    );
  }

  void _writeCommand(String command, [Map<String, String>? params]) {
    if (_socket == null) {
      _log('Socket is null, cannot write command');
      throw Exception('Not connected to RouterOS');
    }

    final cmdBuffer = StringBuffer();
    cmdBuffer.write(command);
    if (params != null) {
      params.forEach((key, value) {
        cmdBuffer.write('=$key=$value');
      });
    }
    cmdBuffer.write('\n');

    final cmdString = cmdBuffer.toString();
    _log('Sending command: $cmdString');
    _socket!.write(cmdString);
  }

  Future<String> _readResponse() async {
    if (_socket == null) return '';

    _responseBuffer.clear();
    _responseCompleter = Completer<String>();

    return _responseCompleter!.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        if (!_responseCompleter!.isCompleted) {
          _responseCompleter!.complete(_responseBuffer.toString());
        }
        return _responseBuffer.toString();
      },
    );
  }

  String _extractChallenge(String response) {
    final regExp = RegExp(r'=ret=([a-f0-9]+)');
    final match = regExp.firstMatch(response);
    return match?.group(1) ?? '';
  }

  String _hashPassword(String challenge, String password) {
    if (challenge.isEmpty) return '00';

    // RouterOS uses a specific challenge-response mechanism
    // 1. Create a 256-byte buffer with password at the beginning
    // 2. MD5 hash the buffer
    // 3. XOR the hash with the challenge
    // 4. Return as hex string

    final passwordBytes = utf8.encode(password);
    final challengeBytes = _hexToBytes(challenge);

    // Create 256-byte buffer and put password at beginning
    final buffer = List<int>.filled(256, 0);
    for (int i = 0; i < passwordBytes.length && i < 256; i++) {
      buffer[i] = passwordBytes[i];
    }

    // MD5 hash the buffer
    final digest = md5.convert(buffer);
    final hashBytes = digest.bytes.toList();

    // XOR with challenge
    for (int i = 0; i < challengeBytes.length && i < hashBytes.length; i++) {
      hashBytes[i] ^= challengeBytes[i];
    }

    return _bytesToHex(hashBytes);
  }

  List<int> _hexToBytes(String hex) {
    final result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  Future<Map<String, dynamic>> getHotspotUsers() async {
    try {
      _writeCommand('/ip/hotspot/user/print');
      final response = await _readResponse();
      return _parseResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch hotspot users: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHotspotUsersList() async {
    try {
      _writeCommand('/ip/hotspot/user/print');
      final response = await _readResponse();
      return _parseUserListResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch hotspot users list: $e');
    }
  }

  List<Map<String, dynamic>> _parseUserListResponse(String response) {
    final lines = response.split('\n');
    final users = <Map<String, dynamic>>[];
    Map<String, dynamic>? currentUser;

    for (final line in lines) {
      if (line.startsWith('!re')) {
        // Start of a new record
        if (currentUser != null) {
          users.add(currentUser);
        }
        currentUser = {};
      } else if (line.startsWith('=') && currentUser != null) {
        final parts = line.substring(1).split('=');
        if (parts.length >= 2) {
          currentUser[parts[0]] = parts.sublist(1).join('=');
        }
      }
    }

    if (currentUser != null) {
      users.add(currentUser);
    }

    return users;
  }

  Future<Map<String, dynamic>> getSystemResources() async {
    try {
      _ensureConnected();
      _writeCommand('/system/resource/print');
      final response = await _readResponse();
      return _parseResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch system resources: $e');
    }
  }

  Future<Map<String, dynamic>> getInterfaceStats() async {
    try {
      _writeCommand('/interface/print');
      final response = await _readResponse();
      return _parseResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch interface stats: $e');
    }
  }

  Map<String, dynamic> _parseResponse(String response) {
    final lines = response.split('\n');
    final data = <String, dynamic>{};

    for (final line in lines) {
      if (line.startsWith('=')) {
        final parts = line.substring(1).split('=');
        if (parts.length >= 2) {
          data[parts[0]] = parts.sublist(1).join('=');
        }
      }
    }

    return data;
  }

  Future<void> addHotspotUser({
    required String username,
    required String password,
    required String profile,
    String? comment,
  }) async {
    try {
      final params = {
        'name': username,
        'password': password,
        'profile': profile,
      };
      if (comment != null) {
        params['comment'] = comment;
      }
      _writeCommand('/ip/hotspot/user/add', params);

      final response = await _readResponse();
      if (response.contains('!trap') || response.contains('!error')) {
        throw Exception('Failed to add user: $response');
      }
    } catch (e) {
      throw Exception('Failed to add hotspot user: $e');
    }
  }

  Future<void> removeHotspotUser(String id) async {
    try {
      _writeCommand('/ip/hotspot/user/remove', {'.id': id});

      final response = await _readResponse();
      if (response.contains('!trap') || response.contains('!error')) {
        throw Exception('Failed to remove user: $response');
      }
    } catch (e) {
      throw Exception('Failed to remove hotspot user: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHotspotActiveUsers() async {
    try {
      _writeCommand('/ip/hotspot/active/print');
      final response = await _readResponse();
      return _parseUserListResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch active hotspot users: $e');
    }
  }

  Future<void> logoutHotspotUser(String id) async {
    try {
      _writeCommand('/ip/hotspot/active/remove', {'.id': id});

      final response = await _readResponse();
      if (response.contains('!trap') || response.contains('!error')) {
        throw Exception('Failed to logout user: $response');
      }
    } catch (e) {
      throw Exception('Failed to logout hotspot user: $e');
    }
  }

  Future<void> disconnect() async {
    _responseCompleter?.complete('');
    _socket?.close();
    _socket = null;
    _isConnected = false;
    _responseBuffer.clear();
  }

  // Update hotspot user - RouterOS doesn't have direct update, so we remove and re-add
  Future<void> updateHotspotUser({
    required String id,
    required String username,
    required String password,
    required String profile,
    String? comment,
    bool disabled = false,
  }) async {
    try {
      // First remove the existing user
      await removeHotspotUser(id);

      // Then add the updated user
      final params = {
        'name': username,
        'password': password,
        'profile': profile,
        'disabled': disabled ? 'yes' : 'no',
      };
      if (comment != null) {
        params['comment'] = comment;
      }
      _writeCommand('/ip/hotspot/user/add', params);

      final response = await _readResponse();
      if (response.contains('!trap') || response.contains('!error')) {
        throw Exception('Failed to update user: $response');
      }
    } catch (e) {
      throw Exception('Failed to update hotspot user: $e');
    }
  }

  // Set hotspot user disabled status (enable/disable)
  Future<void> setHotspotUserStatus({
    required String id,
    required bool disabled,
  }) async {
    try {
      _writeCommand('/ip/hotspot/user/set', {
        '.id': id,
        'disabled': disabled ? 'yes' : 'no',
      });

      final response = await _readResponse();
      if (response.contains('!trap') || response.contains('!error')) {
        throw Exception('Failed to set user status: $response');
      }
    } catch (e) {
      throw Exception('Failed to set hotspot user status: $e');
    }
  }

  // Get user profiles
  Future<List<Map<String, dynamic>>> getUserProfiles() async {
    try {
      _writeCommand('/ip/hotspot/user/profile/print');
      final response = await _readResponse();
      return _parseUserListResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch user profiles: $e');
    }
  }

  // Add user profile
  Future<void> addUserProfile({
    required String name,
    String? rateLimit,
    String? uptimeLimit,
    String? dataLimit,
  }) async {
    try {
      final params = <String, String>{'name': name};
      if (rateLimit != null) {
        params['rate-limit'] = rateLimit;
      }
      if (uptimeLimit != null) {
        params['on-logout'] = uptimeLimit;
      }
      if (dataLimit != null) {
        params['on-login'] = dataLimit;
      }
      _writeCommand('/ip/hotspot/user/profile/add', params);

      final response = await _readResponse();
      if (response.contains('!trap') || response.contains('!error')) {
        throw Exception('Failed to add user profile: $response');
      }
    } catch (e) {
      throw Exception('Failed to add user profile: $e');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String id,
    String? name,
    String? rateLimit,
  }) async {
    try {
      final params = <String, String>{'.id': id};
      if (name != null) {
        params['name'] = name;
      }
      if (rateLimit != null) {
        params['rate-limit'] = rateLimit;
      }
      _writeCommand('/ip/hotspot/user/profile/set', params);

      final response = await _readResponse();
      if (response.contains('!trap') || response.contains('!error')) {
        throw Exception('Failed to update user profile: $response');
      }
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Remove user profile
  Future<void> removeUserProfile(String id) async {
    try {
      _writeCommand('/ip/hotspot/user/profile/remove', {'.id': id});

      final response = await _readResponse();
      if (response.contains('!trap') || response.contains('!error')) {
        throw Exception('Failed to remove user profile: $response');
      }
    } catch (e) {
      throw Exception('Failed to remove user profile: $e');
    }
  }
}
