import 'dart:async';
import 'dart:convert';
import 'dart:io';

class RouterOSClient {
  final String host;
  final String port;
  final String username;
  final String password;
  bool _isConnected = false;
  Socket? _socket;

  RouterOSClient({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
  });

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    try {
      _socket = await Socket.connect(host, int.parse(port));

      // Handle login with or without password
      if (password.isEmpty) {
        // Login without password - just send username
        _socket!.write('/login');
        _socket!.write('=name=$username');
        _socket!.write('\n');

        final loginResponse = await _readResponse();
        if (loginResponse.contains('!trap') || loginResponse.contains('!error')) {
          throw Exception('Authentication failed: Invalid credentials');
        }
      } else {
        // Login with password - use challenge-response
        _socket!.write('/login');

        final response = await _readResponse();
        if (response.contains('!trap')) {
          throw Exception('Connection failed: Invalid response');
        }

        final challenge = _extractChallenge(response);
        final hashedPassword = _hashPassword(challenge, password);

        _socket!.write('/login');
        _socket!.write('=name=$username');
        _socket!.write('=response=$hashedPassword');
        _socket!.write('\n');

        final loginResponse = await _readResponse();
        if (loginResponse.contains('!trap') || loginResponse.contains('!error')) {
          throw Exception('Authentication failed: Invalid credentials');
        }
      }

      _isConnected = true;
    } catch (e) {
      _isConnected = false;
      rethrow;
    }
  }

  Future<String> _readResponse() async {
    if (_socket == null) return '';

    final completer = Completer<String>();
    final buffer = StringBuffer();

    _socket!.listen(
      (data) {
        buffer.write(String.fromCharCodes(data));
        if (buffer.toString().endsWith('\n')) {
          completer.complete(buffer.toString());
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(buffer.toString());
        }
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => buffer.toString(),
    );
  }

  String _extractChallenge(String response) {
    final regExp = RegExp(r'=ret=([a-f0-9]+)');
    final match = regExp.firstMatch(response);
    return match?.group(1) ?? '';
  }

  String _hashPassword(String challenge, String password) {
    if (challenge.isEmpty) return '00';

    final passwordBytes = utf8.encode(password);
    final challengeBytes = _hexToBytes(challenge);

    final hashBytes = List<int>.filled(256, 0);
    for (int i = 0; i < passwordBytes.length; i++) {
      hashBytes[i] = passwordBytes[i];
    }

    var md5 = _md5Hash(hashBytes);
    for (int i = 0; i < challengeBytes.length; i++) {
      md5[i] ^= challengeBytes[i];
    }

    return _bytesToHex(md5);
  }

  List<int> _md5Hash(List<int> input) {
    // Simplified MD5 implementation - In production, use crypto package
    final bytes = List<int>.from(input);
    // This is a placeholder - use proper crypto in production
    return bytes.sublist(0, 16);
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
      _socket!.write('/ip/hotspot/user/print\n');
      final response = await _readResponse();
      return _parseResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch hotspot users: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getHotspotUsersList() async {
    try {
      _socket!.write('/ip/hotspot/user/print\n');
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
      _socket!.write('/system/resource/print\n');
      final response = await _readResponse();
      return _parseResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch system resources: $e');
    }
  }

  Future<Map<String, dynamic>> getInterfaceStats() async {
    try {
      _socket!.write('/interface/print\n');
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
      _socket!.write('/ip/hotspot/user/add');
      _socket!.write('=name=$username');
      _socket!.write('=password=$password');
      _socket!.write('=profile=$profile');
      if (comment != null) {
        _socket!.write('=comment=$comment');
      }
      _socket!.write('\n');

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
      _socket!.write('/ip/hotspot/user/remove');
      _socket!.write('=.id=$id');
      _socket!.write('\n');

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
      _socket!.write('/ip/hotspot/active/print\n');
      final response = await _readResponse();
      return _parseUserListResponse(response);
    } catch (e) {
      throw Exception('Failed to fetch active hotspot users: $e');
    }
  }

  Future<void> logoutHotspotUser(String id) async {
    try {
      _socket!.write('/ip/hotspot/active/remove');
      _socket!.write('=.id=$id');
      _socket!.write('\n');

      final response = await _readResponse();
      if (response.contains('!trap') || response.contains('!error')) {
        throw Exception('Failed to logout user: $response');
      }
    } catch (e) {
      throw Exception('Failed to logout hotspot user: $e');
    }
  }

  Future<void> disconnect() async {
    _socket?.close();
    _socket = null;
    _isConnected = false;
  }
}
