// Export activity log model
export 'models/activity_log.dart';

class InterfaceTraffic {
  final String name;
  final String type; // ether, bridge, wireless, etc.
  final int? txBytes; // Total transmitted bytes
  final int? rxBytes; // Total received bytes
  final int? txBytesPerSecond; // Current tx rate
  final int? rxBytesPerSecond; // Current rx rate
  final String? mtu;
  final bool running;
  final bool? enabled;

  InterfaceTraffic({
    required this.name,
    required this.type,
    this.txBytes,
    this.rxBytes,
    this.txBytesPerSecond,
    this.rxBytesPerSecond,
    this.mtu,
    required this.running,
    this.enabled,
  });

  factory InterfaceTraffic.fromJson(Map<String, dynamic> json) {
    return InterfaceTraffic(
      name: json['name'] ?? 'unknown',
      type: json['type'] ?? 'unknown',
      txBytes: json['tx-byte'] != null
          ? int.tryParse(json['tx-byte'].toString())
          : null,
      rxBytes: json['rx-byte'] != null
          ? int.tryParse(json['rx-byte'].toString())
          : null,
      txBytesPerSecond: json['tx-byte-per-second'] != null
          ? int.tryParse(json['tx-byte-per-second'].toString())
          : null,
      rxBytesPerSecond: json['rx-byte-per-second'] != null
          ? int.tryParse(json['rx-byte-per-second'].toString())
          : null,
      mtu: json['mtu']?.toString(),
      running: json['running'] == 'true' || json['running'] == true,
      enabled: json['disabled'] == 'false' || json['disabled'] == false,
    );
  }

  // Formatted getters
  String get txDisplay => _formatBytes(txBytes ?? 0);
  String get rxDisplay => _formatBytes(rxBytes ?? 0);
  String get txRateDisplay => _formatBytesPerSecond(txBytesPerSecond ?? 0);
  String get rxRateDisplay => _formatBytesPerSecond(rxBytesPerSecond ?? 0);

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes < 1024 * 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
    return '${(bytes / (1024 * 1024 * 1024 * 1024)).toStringAsFixed(2)} TB';
  }

  String _formatBytesPerSecond(int bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '$bytesPerSecond B/s';
    }
    if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    }
    if (bytesPerSecond < 1024 * 1024 * 1024) {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    if (bytesPerSecond < 1024 * 1024 * 1024 * 1024) {
      return '${(bytesPerSecond / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB/s';
    }
    return '${(bytesPerSecond / (1024 * 1024 * 1024 * 1024)).toStringAsFixed(2)} TB/s';
  }

  double get txPercent {
    if (txBytes == null || rxBytes == null) return 0;
    final total = txBytes! + rxBytes!;
    if (total == 0) return 0;
    return txBytes! / total;
  }

  double get rxPercent {
    if (txBytes == null || rxBytes == null) return 0;
    final total = txBytes! + rxBytes!;
    if (total == 0) return 0;
    return rxBytes! / total;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'tx-byte': txBytes?.toString(),
      'rx-byte': rxBytes?.toString(),
      'tx-byte-per-second': txBytesPerSecond?.toString(),
      'rx-byte-per-second': rxBytesPerSecond?.toString(),
      'mtu': mtu,
      'running': running,
      'disabled': enabled == false,
    };
  }
}

class UserProfile {
  final String id;
  final String name;
  final String? rateLimitUpload; // in kbps (e.g., "512k" or "unlimited")
  final String? rateLimitDownload; // in kbps
  final String? validity; // time duration (e.g., "1h", "1d", "unlimited")
  final double? price; // selling price
  final int? sharedUsers; // number of shared users (0 = unlimited)
  final bool? autologout; // auto logout when limit reached
  final DateTime? expiresAt; // expire date/time

  UserProfile({
    required this.id,
    required this.name,
    this.rateLimitUpload,
    this.rateLimitDownload,
    this.validity,
    this.price,
    this.sharedUsers,
    this.autologout,
    this.expiresAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['.id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'default',
      rateLimitUpload: json['rate-limit-upload'],
      rateLimitDownload: json['rate-limit-download'],
      validity: json['validity'],
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      sharedUsers: json['shared-users'] != null
          ? int.tryParse(json['shared-users'].toString())
          : null,
      autologout: json['autologout'] == 'true',
      expiresAt: json['expires-at'] != null
          ? DateTime.tryParse(json['expires-at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '.id': id,
      'name': name,
      'rate-limit-upload': rateLimitUpload,
      'rate-limit-download': rateLimitDownload,
      'validity': validity,
      'price': price?.toString(),
      'shared-users': sharedUsers?.toString(),
      'autologout': autologout?.toString() ?? 'false',
      'expires-at': expiresAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'rate-limit-upload': rateLimitUpload,
      'rate-limit-download': rateLimitDownload,
      'validity': validity,
      'price': price?.toString(),
      'shared-users': sharedUsers?.toString(),
      'autologout': autologout?.toString() ?? 'false',
    };
  }

  // Display getters
  String get rateLimitDisplay {
    if (rateLimitUpload == null && rateLimitDownload == null) {
      return 'Unlimited';
    }
    final upload = rateLimitUpload ?? 'unlimited';
    final download = rateLimitDownload ?? 'unlimited';
    return '$upload/$download';
  }

  String get validityDisplay {
    if (validity == null || validity == 'unlimited' || validity == '0') {
      return 'Unlimited';
    }
    return validity!;
  }

  String get priceDisplay {
    if (price == null || price == 0) {
      return 'Free';
    }
    return '\$${price!.toStringAsFixed(2)}';
  }

  String get sharedUsersDisplay {
    if (sharedUsers == null || sharedUsers == 0) {
      return 'Unlimited';
    }
    return '$sharedUsers user${sharedUsers! > 1 ? 's' : ''}';
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? rateLimitUpload,
    String? rateLimitDownload,
    String? validity,
    double? price,
    int? sharedUsers,
    bool? autologout,
    DateTime? expiresAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      rateLimitUpload: rateLimitUpload ?? this.rateLimitUpload,
      rateLimitDownload: rateLimitDownload ?? this.rateLimitDownload,
      validity: validity ?? this.validity,
      price: price ?? this.price,
      sharedUsers: sharedUsers ?? this.sharedUsers,
      autologout: autologout ?? this.autologout,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

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
      platform: _safeString(json['platform'] ?? json['platform-text']),
      boardName: _safeString(json['board-name'] ?? json['board-name-text']),
      version: _safeString(json['version'] ?? json['version-text']),
      cpuFrequency: _parseSizeToInt(
          json['cpu-frequency'] ?? json['cpu-frequency-text'] ?? '0'),
      cpuLoad: int.tryParse(
              json['cpu-load']?.toString().replaceAll('%', '') ?? '0') ??
          0,
      freeMemory: _parseSizeToInt(
          json['free-memory'] ?? json['free-memory-text'] ?? '0'),
      totalMemory: _parseSizeToInt(
          json['total-memory'] ?? json['total-memory-text'] ?? '0'),
      freeHddSpace: _parseSizeToInt(
          json['free-hdd-space'] ?? json['free-hdd-space-text'] ?? '0'),
      totalHddSpace: _parseSizeToInt(
          json['total-hdd-space'] ?? json['total-hdd-space-text'] ?? '0'),
      uptimeSeconds: _parseUptime(json['uptime'] ?? json['uptime-text'] ?? '0'),
    );
  }

  /// Safely extract a string value, defaulting to 'Unknown' if null or empty
  static String _safeString(dynamic value) {
    if (value == null) return 'Unknown';
    final str = value.toString().trim();
    return str.isEmpty ? 'Unknown' : str;
  }

  static int _parseSizeToInt(String value) {
    if (value.isEmpty) return 0;

    // Try parsing as integer first
    final asInt = int.tryParse(value);
    if (asInt != null) return asInt;

    // Parse format like "1048576KiB" or "1GiB" or "512MiB"
    final regex =
        RegExp(r'(\d+(?:\.\d+)?)\s*([KMGT]?i?B?)', caseSensitive: false);
    final match = regex.firstMatch(value);

    if (match != null) {
      final number = double.tryParse(match.group(1)!) ?? 0;
      final unit = (match.group(2) ?? '').toUpperCase();

      switch (unit) {
        case 'KI':
        case 'KIB':
          return (number * 1024).toInt();
        case 'K':
          return (number * 1000).toInt();
        case 'MI':
        case 'MIB':
          return (number * 1024 * 1024).toInt();
        case 'M':
          return (number * 1000 * 1000).toInt();
        case 'GI':
        case 'GIB':
          return (number * 1024 * 1024 * 1024).toInt();
        case 'G':
          return (number * 1000 * 1000 * 1000).toInt();
        case 'TI':
        case 'TIB':
          return (number * 1024 * 1024 * 1024 * 1024).toInt();
        case 'T':
          return (number * 1000 * 1000 * 1000 * 1000).toInt();
        default:
          return number.toInt();
      }
    }

    // Remove any non-numeric characters and try parsing
    final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
    return (double.tryParse(cleaned) ?? 0).toInt();
  }

  static int _parseUptime(String uptime) {
    if (uptime.isEmpty) return 0;

    // Try parsing as integer first (in case it's already in seconds)
    final asInt = int.tryParse(uptime);
    if (asInt != null) return asInt;

    // Parse format like "2d 3h 45m 30s" or "3h 45m" or "45m"
    int seconds = 0;
    final regex = RegExp(r'(\d+)([dhms])');
    final matches = regex.allMatches(uptime);

    for (final match in matches) {
      final value = int.parse(match.group(1)!);
      final unit = match.group(2);

      switch (unit) {
        case 'd':
          seconds += value * 86400;
          break;
        case 'h':
          seconds += value * 3600;
          break;
        case 'm':
          seconds += value * 60;
          break;
        case 's':
          seconds += value;
          break;
      }
    }

    return seconds;
  }

  double get memoryUsagePercent =>
      totalMemory > 0 ? ((totalMemory - freeMemory) / totalMemory * 100) : 0;

  double get hddUsagePercent => totalHddSpace > 0
      ? ((totalHddSpace - freeHddSpace) / totalHddSpace * 100)
      : 0;
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
  final String? comment;

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
    this.comment,
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
      comment: json['comment'],
    );
  }

  /// Check if this user was created via voucher generation
  /// Vouchers have comments like "mode:up" or "mode:vc"
  bool get isVoucher {
    if (comment == null) return false;
    final commentLower = comment!.toLowerCase();
    return commentLower.contains('mode:up') || commentLower.contains('mode:vc');
  }

  String get dataUsed {
    final bytes = (bytesIn ?? 0) + (bytesOut ?? 0);
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  String get simpleUptime {
    if (uptime == null || uptime == '0s' || uptime == '00:00:00') return '-';
    // Simplify: 1d 2h 3m -> 1d2h, 1h 2m -> 1h2m
    return uptime!.replaceAll(' ', '').replaceAll('s', '');
  }

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
      'comment': comment,
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
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }
}

// Sales transaction model for income tracking
class SalesTransaction {
  final String id;
  final String username;
  final String profile;
  final double price;
  final DateTime timestamp;
  final String? comment;

  SalesTransaction({
    required this.id,
    required this.username,
    required this.profile,
    required this.price,
    required this.timestamp,
    this.comment,
  });

  factory SalesTransaction.fromJson(Map<String, dynamic> json) {
    return SalesTransaction(
      id: json['id'] ?? json['.id'] ?? '',
      username: json['username'] ?? json['name'] ?? '',
      profile: json['profile'] ?? 'default',
      price: (json['price'] != null)
          ? (double.tryParse(json['price'].toString()) ?? 0.0)
          : (json['amount'] != null
              ? double.tryParse(json['amount'].toString()) ?? 0.0
              : 0.0),
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] is int
              ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
              : DateTime.tryParse(json['timestamp']) ?? DateTime.now())
          : DateTime.now(),
      comment: json['comment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'profile': profile,
      'price': price,
      'timestamp': timestamp.millisecondsSinceEpoch,
      if (comment != null) 'comment': comment,
    };
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  // Format date as "MMM dd, yyyy"
  String get formattedDate {
    return '${_monthName(timestamp.month)} ${timestamp.day}, ${timestamp.year}';
  }

  // Format time as "HH:mm"
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  SalesTransaction copyWith({
    String? id,
    String? username,
    String? profile,
    double? price,
    DateTime? timestamp,
    String? comment,
  }) {
    return SalesTransaction(
      id: id ?? this.id,
      username: username ?? this.username,
      profile: profile ?? this.profile,
      price: price ?? this.price,
      timestamp: timestamp ?? this.timestamp,
      comment: comment ?? this.comment,
    );
  }
}

// Income summary model
class IncomeSummary {
  final double todayIncome;
  final double thisMonthIncome;
  final int transactionsToday;
  final int transactionsThisMonth;

  const IncomeSummary({
    required this.todayIncome,
    required this.thisMonthIncome,
    required this.transactionsToday,
    required this.transactionsThisMonth,
  });

  IncomeSummary copyWith({
    double? todayIncome,
    double? thisMonthIncome,
    int? transactionsToday,
    int? transactionsThisMonth,
  }) {
    return IncomeSummary(
      todayIncome: todayIncome ?? this.todayIncome,
      thisMonthIncome: thisMonthIncome ?? this.thisMonthIncome,
      transactionsToday: transactionsToday ?? this.transactionsToday,
      transactionsThisMonth:
          transactionsThisMonth ?? this.transactionsThisMonth,
    );
  }
}

// Saved Router Connection model
class RouterConnection {
  final String id;
  final String name;
  final String host;
  final String port;
  final String username;
  final DateTime createdAt;

  RouterConnection({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory RouterConnection.fromJson(Map<String, dynamic> json) {
    return RouterConnection(
      id: json['id'] as String,
      name: json['name'] as String,
      host: json['host'] as String,
      port: json['port'] as String,
      username: json['username'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get displayName => name;
  String get address => '$host:$port';

  RouterConnection copyWith({
    String? id,
    String? name,
    String? host,
    String? port,
    String? username,
    DateTime? createdAt,
  }) {
    return RouterConnection(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Hotspot Host Model - Represents a DHCP host/lease in RouterOS hotspot
class HotspotHost {
  final String id;
  final String? macAddress;
  final String? address; // IP address
  final String? toAddress; // Target IP (for static entries)
  final String? server; // Hotspot server name
  final String? user; // Associated username (if logged in)
  final String? hostname; // Device hostname from DHCP
  final String? uptime; // Connection duration
  final String? idleTime; // Time since last activity
  final bool authorized; // Authorization status
  final bool bypassed; // Bypassed status (can access without login)
  final String? comment; // Comment/description
  final int? bytesIn; // Bytes received by host
  final int? bytesOut; // Bytes sent by host
  final int? packetsIn; // Packets received
  final int? packetsOut; // Packets sent

  HotspotHost({
    required this.id,
    this.macAddress,
    this.address,
    this.toAddress,
    this.server,
    this.user,
    this.hostname,
    this.uptime,
    this.idleTime,
    required this.authorized,
    required this.bypassed,
    this.comment,
    this.bytesIn,
    this.bytesOut,
    this.packetsIn,
    this.packetsOut,
  });

  factory HotspotHost.fromJson(Map<String, dynamic> json) {
    return HotspotHost(
      id: json['.id'] as String? ?? json['id'] as String? ?? '',
      macAddress: json['mac-address'] as String?,
      address: json['address'] as String?,
      toAddress: json['to-address'] as String?,
      server: json['server'] as String?,
      user: json['user'] as String?,
      hostname: json['host-name'] as String? ?? json['hostname'] as String?,
      uptime: json['uptime'] as String?,
      idleTime: json['idle-time'] as String?,
      authorized: json['authorized'] == 'true' || json['authorized'] == true,
      bypassed: json['bypassed'] == 'true' || json['bypassed'] == true,
      comment: json['comment'] as String?,
      bytesIn: _parseInt(json['bytes-in']),
      bytesOut: _parseInt(json['bytes-out']),
      packetsIn: _parseInt(json['packets-in']),
      packetsOut: _parseInt(json['packets-out']),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      '.id': id,
      'mac-address': macAddress,
      'address': address,
      'to-address': toAddress,
      'server': server,
      'user': user,
      'host-name': hostname,
      'uptime': uptime,
      'idle-time': idleTime,
      'authorized': authorized.toString(),
      'bypassed': bypassed.toString(),
      'comment': comment,
      'bytes-in': bytesIn,
      'bytes-out': bytesOut,
      'packets-in': packetsIn,
      'packets-out': packetsOut,
    };
  }

  /// Display name for the host (username or hostname)
  String get displayName {
    if (user != null && user!.isNotEmpty) return user!;
    if (hostname != null && hostname!.isNotEmpty) return hostname!;
    if (macAddress != null && macAddress!.isNotEmpty) return macAddress!;
    if (address != null && address!.isNotEmpty) return address!;
    return 'Unknown';
  }

  /// Device name for display (hostname or MAC)
  String get deviceName {
    if (hostname != null && hostname!.isNotEmpty) return hostname!;
    if (user != null && user!.isNotEmpty) return user!;
    return 'Unknown Device';
  }

  /// Status badge text
  String get statusText {
    if (bypassed) return 'Bypassed';
    if (authorized) return 'Authorized';
    return 'Unauthorized';
  }

  /// Check if host is active (has IP and is authorized or bypassed)
  bool get isActive =>
      address != null && address!.isNotEmpty && (authorized || bypassed);

  HotspotHost copyWith({
    String? id,
    String? macAddress,
    String? address,
    String? toAddress,
    String? server,
    String? user,
    String? hostname,
    String? uptime,
    String? idleTime,
    bool? authorized,
    bool? bypassed,
    String? comment,
    int? bytesIn,
    int? bytesOut,
    int? packetsIn,
    int? packetsOut,
  }) {
    return HotspotHost(
      id: id ?? this.id,
      macAddress: macAddress ?? this.macAddress,
      address: address ?? this.address,
      toAddress: toAddress ?? this.toAddress,
      server: server ?? this.server,
      user: user ?? this.user,
      hostname: hostname ?? this.hostname,
      uptime: uptime ?? this.uptime,
      idleTime: idleTime ?? this.idleTime,
      authorized: authorized ?? this.authorized,
      bypassed: bypassed ?? this.bypassed,
      comment: comment ?? this.comment,
      bytesIn: bytesIn ?? this.bytesIn,
      bytesOut: bytesOut ?? this.bytesOut,
      packetsIn: packetsIn ?? this.packetsIn,
      packetsOut: packetsOut ?? this.packetsOut,
    );
  }

  @override
  String toString() {
    return 'HotspotHost(id: $id, macAddress: $macAddress, address: $address, user: $user, authorized: $authorized, bypassed: $bypassed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HotspotHost && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
