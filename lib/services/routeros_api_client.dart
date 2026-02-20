import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class RouterOSClient {
  final String host;
  final String port;
  final String username;
  final String password;
  bool _isConnected = false;
  Socket? _socket;
  Completer<List<Map<String, dynamic>>>? _responseCompleter;
  final List<int> _readBuffer = [];
  final List<Map<String, dynamic>> _currentResponse = [];
  Map<String, dynamic>? _currentItem;
  bool _awaitingDone = false;

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

      _setupSocketListener();

      // RouterOS v6.43+ login - send in one sentence
      _writeWord('/login');
      _writeWord('=name=$username');
      _writeWord('=password=$password');
      _writeWord(''); // Empty word to terminate sentence

      final response = await _readResponse();
      _log('Login response received: ${response.length} items');

      // Check for error
      for (final item in response) {
        if (item.containsKey('message')) {
          throw Exception('Authentication failed: ${item['message']}');
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
        _readBuffer.addAll(data);
        _log('Received ${data.length} bytes, buffer size: ${_readBuffer.length}');
        _processBuffer();
      },
      onError: (error) {
        _log('Socket error: $error');
        if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
          _responseCompleter!.completeError(error);
        }
        _isConnected = false;
        _awaitingDone = false;
      },
      onDone: () {
        _log('Socket closed by server');
        if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
          _responseCompleter!.complete(List.from(_currentResponse));
        }
        _isConnected = false;
        _awaitingDone = false;
      },
    );
  }

  void _processBuffer() {
    while (_readBuffer.isNotEmpty) {
      final length = _readLength();
      if (length == null) {
        _log('Need more data to read length');
        return;
      }

      // Check if we have the full word
      if (_readBuffer.length < _encodedLength(length) + length) {
        _log('Need more data: have ${_readBuffer.length}, need ${_encodedLength(length) + length}');
        return;
      }

      // Remove the length bytes
      final lengthBytes = _encodedLength(length);
      _readBuffer.removeRange(0, lengthBytes);

      // Extract the word
      final wordBytes = _readBuffer.sublist(0, length);
      final word = utf8.decode(wordBytes);
      _readBuffer.removeRange(0, length);

      _log('Read word: "$word" (${word.length} chars)');

      // Empty word - end of sentence
      if (word.isEmpty) {
        _log('Received empty word (end of sentence)');
        continue;
      }

      // Process the word
      _processWord(word);
    }
  }

  int? _readLength() {
    if (_readBuffer.isEmpty) return null;

    final firstByte = _readBuffer[0];

    if (firstByte < 0x80) {
      // 1 byte length
      return firstByte;
    } else if (firstByte < 0xC0) {
      // 2 byte length
      if (_readBuffer.length < 2) return null;
      return ((_readBuffer[0] & 0x3F) << 8) | _readBuffer[1];
    } else if (firstByte < 0xE0) {
      // 3 byte length
      if (_readBuffer.length < 3) return null;
      return ((_readBuffer[0] & 0x1F) << 16) | (_readBuffer[1] << 8) | _readBuffer[2];
    } else if (firstByte < 0xF0) {
      // 4 byte length
      if (_readBuffer.length < 4) return null;
      return ((_readBuffer[0] & 0x0F) << 24) | (_readBuffer[1] << 16) | (_readBuffer[2] << 8) | _readBuffer[3];
    } else if (firstByte == 0xF0) {
      // 5 byte length
      if (_readBuffer.length < 5) return null;
      return (_readBuffer[1] << 24) | (_readBuffer[2] << 16) | (_readBuffer[3] << 8) | _readBuffer[4];
    }

    // Control byte - not supported
    _log('Unknown control byte: $firstByte');
    return null;
  }

  int _encodedLength(int length) {
    if (length < 0x80) return 1;
    if (length < 0x4000) return 2;
    if (length < 0x200000) return 3;
    if (length < 0x10000000) return 4;
    return 5;
  }

  void _encodeLength(int length, List<int> buffer) {
    if (length < 0x80) {
      buffer.add(length);
    } else if (length < 0x4000) {
      buffer.add(0x80 | (length >> 8));
      buffer.add(length & 0xFF);
    } else if (length < 0x200000) {
      buffer.add(0xC0 | (length >> 16));
      buffer.add((length >> 8) & 0xFF);
      buffer.add(length & 0xFF);
    } else if (length < 0x10000000) {
      buffer.add(0xE0 | (length >> 24));
      buffer.add((length >> 16) & 0xFF);
      buffer.add((length >> 8) & 0xFF);
      buffer.add(length & 0xFF);
    } else {
      buffer.add(0xF0);
      buffer.add((length >> 24) & 0xFF);
      buffer.add((length >> 16) & 0xFF);
      buffer.add((length >> 8) & 0xFF);
      buffer.add(length & 0xFF);
    }
  }

  void _processWord(String word) {
    if (word.startsWith('!re')) {
      // New record starting
      _currentItem = {};
      _log('Starting new record');
    } else if (word.startsWith('!done')) {
      // End of response
      _log('Received !done');
      if (_currentItem != null) {
        _currentResponse.add(_currentItem!);
        _currentItem = null;
      }
      if (_awaitingDone && _responseCompleter != null && !_responseCompleter!.isCompleted) {
        _log('Completing response with ${_currentResponse.length} items');
        _responseCompleter!.complete(List.from(_currentResponse));
        _currentResponse.clear();
        _awaitingDone = false;
        _responseCompleter = null;
      }
    } else if (word.startsWith('!trap')) {
      // Error response
      _log('Received !trap (error)');
      if (_currentItem != null) {
        _currentResponse.add(_currentItem!);
        _currentItem = null;
      }
      if (_awaitingDone && _responseCompleter != null && !_responseCompleter!.isCompleted) {
        _responseCompleter!.complete(List.from(_currentResponse));
        _currentResponse.clear();
        _awaitingDone = false;
        _responseCompleter = null;
      }
    } else if (word.startsWith('!fatal')) {
      // Fatal error
      _log('Received !fatal (fatal error)');
      if (_currentItem != null) {
        _currentResponse.add(_currentItem!);
        _currentItem = null;
      }
      if (_awaitingDone && _responseCompleter != null && !_responseCompleter!.isCompleted) {
        _responseCompleter!.complete(List.from(_currentResponse));
        _currentResponse.clear();
        _awaitingDone = false;
        _responseCompleter = null;
      }
    } else if (word.startsWith('=')) {
      // Attribute
      if (_currentItem != null) {
        final equalIndex = word.indexOf('=', 1);
        if (equalIndex > 1) {
          final key = word.substring(1, equalIndex);
          final value = word.substring(equalIndex + 1);
          _currentItem![key] = value;
          _log('  $key = $value');
        } else {
          final key = word.substring(1);
          _currentItem![key] = '';
          _log('  $key = (empty)');
        }
      }
    } else if (word.startsWith('.tag=')) {
      // Tag attribute (for queries)
      if (_currentItem != null) {
        final value = word.substring(5);
        _currentItem!['.tag'] = value;
      }
    }
  }

  void _writeWord(String word) {
    if (_socket == null) {
      throw Exception('Not connected to RouterOS');
    }

    final bytes = utf8.encode(word);
    final length = bytes.length;

    final data = <int>[];
    _encodeLength(length, data);
    data.addAll(bytes);

    _socket!.add(data);
    _log('Wrote word: "$word" ($length bytes)');
  }

  Future<List<Map<String, dynamic>>> _readResponse() async {
    _currentResponse.clear();
    _currentItem = null;
    _awaitingDone = true;
    _responseCompleter = Completer<List<Map<String, dynamic>>>();

    return _responseCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _log('Response timeout after 10 seconds');
        _awaitingDone = false;
        if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
          _responseCompleter!.complete(List.from(_currentResponse));
        }
        return List.from(_currentResponse);
      },
    );
  }

  Future<Map<String, dynamic>> getSystemResources() async {
    try {
      _ensureConnected();
      _writeWord('/system/resource/print');
      _writeWord(''); // Empty word to terminate sentence
      final response = await _readResponse();
      _log('System resources response: ${response.length} items');
      if (response.isNotEmpty) {
        return response.first;
      }
      return {};
    } catch (e) {
      _log('Failed to fetch system resources: $e');
      throw Exception('Failed to fetch system resources: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHotspotUsersList() async {
    try {
      _ensureConnected();
      _writeWord('/ip/hotspot/user/print');
      _writeWord(''); // Empty word to terminate sentence
      final response = await _readResponse();
      _log('Got ${response.length} hotspot users');
      return response;
    } catch (e) {
      throw Exception('Failed to fetch hotspot users list: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHotspotActiveUsers() async {
    try {
      _ensureConnected();
      _writeWord('/ip/hotspot/active/print');
      _writeWord(''); // Empty word to terminate sentence
      final response = await _readResponse();
      _log('Got ${response.length} active users');
      return response;
    } catch (e) {
      throw Exception('Failed to fetch active hotspot users: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserProfiles() async {
    try {
      _ensureConnected();
      _writeWord('/ip/hotspot/user/profile/print');
      _writeWord(''); // Empty word to terminate sentence
      final response = await _readResponse();
      _log('Got ${response.length} user profiles');
      return response;
    } catch (e) {
      throw Exception('Failed to fetch user profiles: $e');
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
      _writeWord('/ip/hotspot/user/add');
      _writeWord('=name=$username');
      _writeWord('=password=$password');
      _writeWord('=profile=$profile');
      if (comment != null) {
        _writeWord('=comment=$comment');
      }
      _writeWord(''); // Empty word to terminate sentence

      final response = await _readResponse();
      if (_hasError(response)) {
        throw Exception('Failed to add user: ${response.first}');
      }
    } catch (e) {
      throw Exception('Failed to add hotspot user: $e');
    }
  }

  Future<void> removeHotspotUser(String id) async {
    try {
      _ensureConnected();
      _writeWord('/ip/hotspot/user/remove');
      _writeWord('=.id=$id');
      _writeWord(''); // Empty word to terminate sentence

      final response = await _readResponse();
      if (_hasError(response)) {
        throw Exception('Failed to remove user: ${response.first}');
      }
    } catch (e) {
      throw Exception('Failed to remove hotspot user: $e');
    }
  }

  Future<void> logoutHotspotUser(String id) async {
    try {
      _ensureConnected();
      _writeWord('/ip/hotspot/active/remove');
      _writeWord('=.id=$id');
      _writeWord(''); // Empty word to terminate sentence

      final response = await _readResponse();
      if (_hasError(response)) {
        throw Exception('Failed to logout user: ${response.first}');
      }
    } catch (e) {
      throw Exception('Failed to logout hotspot user: $e');
    }
  }

  Future<void> setHotspotUserStatus({
    required String id,
    required bool disabled,
  }) async {
    try {
      _ensureConnected();
      _writeWord('/ip/hotspot/user/set');
      _writeWord('=.id=$id');
      _writeWord('=disabled=${disabled ? "yes" : "no"}');
      _writeWord(''); // Empty word to terminate sentence

      final response = await _readResponse();
      if (_hasError(response)) {
        throw Exception('Failed to set user status: ${response.first}');
      }
    } catch (e) {
      throw Exception('Failed to set hotspot user status: $e');
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
      // First remove the existing user
      await removeHotspotUser(id);

      // Then add the updated user
      _writeWord('/ip/hotspot/user/add');
      _writeWord('=name=$username');
      _writeWord('=password=$password');
      _writeWord('=profile=$profile');
      _writeWord('=disabled=${disabled ? "yes" : "no"}');
      if (comment != null) {
        _writeWord('=comment=$comment');
      }
      _writeWord(''); // Empty word to terminate sentence

      final response = await _readResponse();
      if (_hasError(response)) {
        throw Exception('Failed to update user: ${response.first}');
      }
    } catch (e) {
      throw Exception('Failed to update hotspot user: $e');
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
      _writeWord('/ip/hotspot/user/profile/add');
      _writeWord('=name=$name');
      if (rateLimit != null) {
        _writeWord('=rate-limit=$rateLimit');
      }
      if (uptimeLimit != null) {
        _writeWord('=on-logout=$uptimeLimit');
      }
      if (dataLimit != null) {
        _writeWord('=on-login=$dataLimit');
      }
      _writeWord(''); // Empty word to terminate sentence

      final response = await _readResponse();
      if (_hasError(response)) {
        throw Exception('Failed to add user profile: ${response.first}');
      }
    } catch (e) {
      throw Exception('Failed to add user profile: $e');
    }
  }

  Future<void> updateUserProfile({
    required String id,
    String? name,
    String? rateLimit,
  }) async {
    try {
      _ensureConnected();
      _writeWord('/ip/hotspot/user/profile/set');
      _writeWord('=.id=$id');
      if (name != null) {
        _writeWord('=name=$name');
      }
      if (rateLimit != null) {
        _writeWord('=rate-limit=$rateLimit');
      }
      _writeWord(''); // Empty word to terminate sentence

      final response = await _readResponse();
      if (_hasError(response)) {
        throw Exception('Failed to update user profile: ${response.first}');
      }
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  Future<void> removeUserProfile(String id) async {
    try {
      _ensureConnected();
      _writeWord('/ip/hotspot/user/profile/remove');
      _writeWord('=.id=$id');
      _writeWord(''); // Empty word to terminate sentence

      final response = await _readResponse();
      if (_hasError(response)) {
        throw Exception('Failed to remove user profile: ${response.first}');
      }
    } catch (e) {
      throw Exception('Failed to remove user profile: $e');
    }
  }

  bool _hasError(List<Map<String, dynamic>> response) {
    for (final item in response) {
      if (item.containsKey('message') || item.containsKey('detail')) {
        return true;
      }
    }
    return false;
  }

  Future<void> disconnect() async {
    _awaitingDone = false;
    if (_responseCompleter != null && !_responseCompleter!.isCompleted) {
      _responseCompleter!.complete([]);
    }
    _responseCompleter = null;
    _socket?.close();
    _socket = null;
    _isConnected = false;
    _readBuffer.clear();
    _currentResponse.clear();
    _currentItem = null;
    _log('Disconnected');
  }
}
