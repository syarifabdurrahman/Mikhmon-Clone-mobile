import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'routeros_api_client.dart';

class RouterOSService {
  static final RouterOSService _instance = RouterOSService._internal();
  factory RouterOSService() => _instance;
  RouterOSService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  RouterOSClient? _client;

  // Store connection parameters for reconnect
  String? _lastHost;
  String? _lastPort;
  String? _lastUsername;
  String? _lastPassword;

  // Session State Management for persistence across network loss
  final _sessionMetadataKey = 'session_metadata';

  Future<void> saveSessionMetadata(Map<String, dynamic> metadata) async {
    await _storage.write(key: _sessionMetadataKey, value: jsonEncode(metadata));
  }

  Future<Map<String, dynamic>?> loadSessionMetadata() async {
    final data = await _storage.read(key: _sessionMetadataKey);
    return data != null ? jsonDecode(data) as Map<String, dynamic> : null;
  }

  RouterOSClient? get client => _client;
  bool get isConnected => _client?.isConnected ?? false;

  // Direct connection with provided credentials (for initial login)
  Future<RouterOSClient> connectWithCredentials({
    required String host,
    required String port,
    required String username,
    required String password,
  }) async {
    // Store connection parameters for potential reconnect
    _lastHost = host;
    _lastPort = port;
    _lastUsername = username;
    _lastPassword = password;

    // For RouterOS API, default to port 8728
    final apiPort = port.isEmpty ? '8728' : port;

    _client = RouterOSClient(
      host: host,
      port: apiPort,
      username: username,
      password: password,
    );

    await _client!.connect();
    return _client!;
  }

  // Reconnect using last credentials or storage
  Future<RouterOSClient> connect() async {
    if (_client != null) {
      return _client!;
    }

    String? host = _lastHost;
    String? port = _lastPort;
    String? username = _lastUsername;
    String? password = _lastPassword;

    // If not available, try to read from storage
    if (host == null || username == null || password == null) {
      host = await _storage.read(key: 'router_ip');
      port = await _storage.read(key: 'port') ?? '8728';
      username = await _storage.read(key: 'username');
      password = await _storage.read(key: 'password');
    }

    if (host == null || username == null || password == null) {
      throw Exception('No saved credentials found. Please login again.');
    }

    return await connectWithCredentials(
      host: host,
      port: port ?? '8728',
      username: username,
      password: password,
    );
  }

  Future<void> disconnect() async {
    // 1. Save current session state before disconnecting to ensure time usage is recorded up to this point
    final metadataToSave = {
      'lastActiveTime': DateTime.now().toIso8601String(),
      'sessionEndTime': null
    }; // Needs dynamic calculation of remaining time from app context if possible
    await saveSessionMetadata(metadataToSave);

    await _client?.disconnect();
    _client = null;
  }

  Future<void> reconnect() async {
    _client = null;
    await connect();
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: 'router_ip');
    await _storage.delete(key: 'port');
    await _storage.delete(key: 'username');
    await _storage.delete(key: 'password');

    // Also clear session metadata on full credential clear
    await saveSessionMetadata({});

    // Clear cached credentials pointers
    _lastHost = null;
    _lastPort = null;
    _lastUsername = null;
    _lastPassword = null;
  }
}
