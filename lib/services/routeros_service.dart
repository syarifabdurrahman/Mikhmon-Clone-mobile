import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'routeros_http_client.dart';

class RouterOSService {
  static final RouterOSService _instance = RouterOSService._internal();
  factory RouterOSService() => _instance;
  RouterOSService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  RouterOSHttpClient? _client;
  bool _demoMode = false;

  // Store connection parameters for reconnect
  String? _lastHost;
  String? _lastPort;
  String? _lastUsername;
  String? _lastPassword;

  RouterOSHttpClient? get client => _client;
  bool get isConnected => _client?.isConnected ?? false;
  bool get isDemoMode => _demoMode;

  void setDemoMode(bool enabled) {
    _demoMode = enabled;
  }

  // Direct connection with provided credentials (for initial login)
  Future<RouterOSHttpClient> connectWithCredentials({
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

    // For HTTP, always use port 80 unless specified otherwise
    final httpPort = port.isEmpty || port == '8728' ? '80' : port;

    _client = RouterOSHttpClient(
      host: host,
      port: httpPort,
      username: username,
      password: password,
    );

    await _client!.connect();
    return _client!;
  }

  // Reconnect using last credentials or storage
  Future<RouterOSHttpClient> connect() async {
    // If we have a client (even if disconnected), try to use it
    if (_client != null) {
      debugPrint('[RouterOSService] Reusing existing client');
      return _client!;
    }

    // Try to use stored connection parameters from last login
    String? host = _lastHost;
    String? port = _lastPort;
    String? username = _lastUsername;
    String? password = _lastPassword;

    debugPrint('[RouterOSService] Cached credentials: host=$host, user=$username, password=${password != null ? "***" : "null"}');

    // If not available, try to read from storage
    if (host == null || username == null || password == null) {
      host = await _storage.read(key: 'router_ip');
      port = await _storage.read(key: 'port') ?? '80';
      username = await _storage.read(key: 'username');
      password = await _storage.read(key: 'password');
      debugPrint('[RouterOSService] Storage credentials: host=$host, user=$username, password=${password != null ? "***" : "null"}');
    }

    if (host == null || username == null || password == null) {
      throw Exception('No saved credentials found. Please login again.');
    }

    debugPrint('[RouterOSService] Creating new connection...');
    return await connectWithCredentials(
      host: host,
      port: port ?? '80',
      username: username,
      password: password,
    );
  }

  Future<void> disconnect() async {
    await _client?.disconnect();
    _client = null;
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: 'router_ip');
    await _storage.delete(key: 'port');
    await _storage.delete(key: 'username');
    await _storage.delete(key: 'password');
    // Also clear cached credentials
    _lastHost = null;
    _lastPort = null;
    _lastUsername = null;
    _lastPassword = null;
  }
}
