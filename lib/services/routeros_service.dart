import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'routeros_api_client.dart';

class RouterOSService {
  static final RouterOSService _instance = RouterOSService._internal();
  factory RouterOSService() => _instance;
  RouterOSService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  RouterOSClient? _client;
  bool _demoMode = false;

  RouterOSClient? get client => _client;
  bool get isConnected => _client?.isConnected ?? false;
  bool get isDemoMode => _demoMode;

  void setDemoMode(bool enabled) {
    _demoMode = enabled;
  }

  Future<RouterOSClient> connect() async {
    final host = await _storage.read(key: 'router_ip');
    final port = await _storage.read(key: 'port') ?? '8728';
    final username = await _storage.read(key: 'username');
    final password = await _storage.read(key: 'password');

    if (host == null || username == null || password == null) {
      throw Exception('No saved credentials found');
    }

    _client = RouterOSClient(
      host: host,
      port: port,
      username: username,
      password: password,
    );

    await _client!.connect();
    return _client!;
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
  }
}
