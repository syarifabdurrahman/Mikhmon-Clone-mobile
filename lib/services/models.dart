class SystemResources {
  final String platform;
  final String boardName;
  final String version;
  final int cpuFrequency;
  final int cpuLoad;
  final int freeMemory;
  final int totalMemory;
  final int freeHddSpace;
  final int totalHddSpace;
  final int uptimeSeconds;

  SystemResources({
    required this.platform,
    required this.boardName,
    required this.version,
    required this.cpuFrequency,
    required this.cpuLoad,
    required this.freeMemory,
    required this.totalMemory,
    required this.freeHddSpace,
    required this.totalHddSpace,
    required this.uptimeSeconds,
  });

  factory SystemResources.fromJson(Map<String, dynamic> json) {
    return SystemResources(
      platform: json['platform'] ?? 'Unknown',
      boardName: json['board-name'] ?? 'Unknown',
      version: json['version'] ?? 'Unknown',
      cpuFrequency: int.tryParse(json['cpu-frequency'] ?? '0') ?? 0,
      cpuLoad: int.tryParse(json['cpu-load'] ?? '0') ?? 0,
      freeMemory: int.tryParse(json['free-memory'] ?? '0') ?? 0,
      totalMemory: int.tryParse(json['total-memory'] ?? '0') ?? 0,
      freeHddSpace: int.tryParse(json['free-hdd-space'] ?? '0') ?? 0,
      totalHddSpace: int.tryParse(json['total-hdd-space'] ?? '0') ?? 0,
      uptimeSeconds: int.tryParse(json['uptime'] ?? '0') ?? 0,
    );
  }

  double get memoryUsagePercent =>
      totalMemory > 0 ? ((totalMemory - freeMemory) / totalMemory * 100) : 0;

  double get hddUsagePercent =>
      totalHddSpace > 0 ? ((totalHddSpace - freeHddSpace) / totalHddSpace * 100) : 0;
}

class HotspotUser {
  final String id;
  final String name;
  final String profile;
  final bool active;
  final String? uptime;
  final int? bytesIn;
  final int? bytesOut;
  final int? limitBytesIn;
  final int? limitBytesOut;

  HotspotUser({
    required this.id,
    required this.name,
    required this.profile,
    required this.active,
    this.uptime,
    this.bytesIn,
    this.bytesOut,
    this.limitBytesIn,
    this.limitBytesOut,
  });

  factory HotspotUser.fromJson(Map<String, dynamic> json) {
    // Sync active field with disabled field
    // Active when: (disabled is not 'true') OR (active is 'true')
    final isDisabled = json['disabled'] == 'true';
    final isActive = json['active'] == 'true' || !isDisabled;

    return HotspotUser(
      id: json['.id'] ?? '',
      name: json['name'] ?? '',
      profile: json['profile'] ?? 'default',
      active: isActive,
      uptime: json['uptime'],
      bytesIn: int.tryParse(json['bytes-in'] ?? '0'),
      bytesOut: int.tryParse(json['bytes-out'] ?? '0'),
      limitBytesIn: int.tryParse(json['limit-bytes-in'] ?? '0'),
      limitBytesOut: int.tryParse(json['limit-bytes-out'] ?? '0'),
    );
  }

  String get dataUsed => '${((bytesIn ?? 0) + (bytesOut ?? 0)) / 1024 / 1024} MB';

  Map<String, dynamic> toMap() {
    // Keep disabled in sync with active
    final disabledValue = (!active).toString();
    return {
      '.id': id,
      'name': name,
      'profile': profile,
      'active': active.toString(),
      'uptime': uptime ?? '0',
      'bytes-in': (bytesIn ?? 0).toString(),
      'bytes-out': (bytesOut ?? 0).toString(),
      'limit-bytes-in': (limitBytesIn ?? 0).toString(),
      'limit-bytes-out': (limitBytesOut ?? 0).toString(),
      'disabled': disabledValue,
    };
  }
}

class InterfaceStats {
  final String name;
  final String type;
  final bool running;
  final int? mtu;
  final int? txByte;
  final int? rxByte;

  InterfaceStats({
    required this.name,
    required this.type,
    required this.running,
    this.mtu,
    this.txByte,
    this.rxByte,
  });

  factory InterfaceStats.fromJson(Map<String, dynamic> json) {
    return InterfaceStats(
      name: json['name'] ?? 'Unknown',
      type: json['type'] ?? 'Unknown',
      running: json['running'] == 'true',
      mtu: int.tryParse(json['mtu'] ?? '0'),
      txByte: int.tryParse(json['tx-byte'] ?? '0'),
      rxByte: int.tryParse(json['rx-byte'] ?? '0'),
    );
  }

  String get txData => '${(txByte ?? 0) / 1024 / 1024} MB';
  String get rxData => '${(rxByte ?? 0) / 1024 / 1024} MB';
}

class HotspotActiveUser {
  final String id;
  final String username;
  final String address;
  final String macAddress;
  final String loginTime;
  final String uptime;
  final int bytesIn;
  final int bytesOut;
  final String? server;
  final String profile;

  HotspotActiveUser({
    required this.id,
    required this.username,
    required this.address,
    required this.macAddress,
    required this.loginTime,
    required this.uptime,
    required this.bytesIn,
    required this.bytesOut,
    this.server,
    required this.profile,
  });

  factory HotspotActiveUser.fromJson(Map<String, dynamic> json) {
    return HotspotActiveUser(
      id: json['.id'] ?? '',
      username: json['user'] ?? '',
      address: json['address'] ?? '',
      macAddress: json['mac-address'] ?? '',
      loginTime: json['login-time'] ?? '0',
      uptime: json['uptime'] ?? '0',
      bytesIn: int.tryParse(json['bytes-in'] ?? '0') ?? 0,
      bytesOut: int.tryParse(json['bytes-out'] ?? '0') ?? 0,
      server: json['server'],
      profile: json['profile'] ?? 'default',
    );
  }

  String get dataUsed => _formatBytes(bytesIn + bytesOut);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }
}
