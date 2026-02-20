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
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      sharedUsers: json['shared-users'] != null ? int.tryParse(json['shared-users'].toString()) : null,
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
    if (rateLimitUpload == null && rateLimitDownload == null) return 'Unlimited';
    final upload = rateLimitUpload ?? 'unlimited';
    final download = rateLimitDownload ?? 'unlimited';
    return '$upload/$download';
  }

  String get validityDisplay {
    if (validity == null || validity == 'unlimited' || validity == '0') return 'Unlimited';
    return validity!;
  }

  String get priceDisplay {
    if (price == null || price == 0) return 'Free';
    return '\$${price!.toStringAsFixed(2)}';
  }

  String get sharedUsersDisplay {
    if (sharedUsers == null || sharedUsers == 0) return 'Unlimited';
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
      platform: json['platform'] ?? json['platform-text'] ?? 'Unknown',
      boardName: json['board-name'] ?? json['board-name-text'] ?? 'Unknown',
      version: json['version'] ?? json['version-text'] ?? 'Unknown',
      cpuFrequency: _parseSizeToInt(json['cpu-frequency'] ?? json['cpu-frequency-text'] ?? '0'),
      cpuLoad: int.tryParse(json['cpu-load']?.toString().replaceAll('%', '') ?? '0') ?? 0,
      freeMemory: _parseSizeToInt(json['free-memory'] ?? json['free-memory-text'] ?? '0'),
      totalMemory: _parseSizeToInt(json['total-memory'] ?? json['total-memory-text'] ?? '0'),
      freeHddSpace: _parseSizeToInt(json['free-hdd-space'] ?? json['free-hdd-space-text'] ?? '0'),
      totalHddSpace: _parseSizeToInt(json['total-hdd-space'] ?? json['total-hdd-space-text'] ?? '0'),
      uptimeSeconds: _parseUptime(json['uptime'] ?? json['uptime-text'] ?? '0'),
    );
  }

  static int _parseSizeToInt(String value) {
    if (value.isEmpty) return 0;

    // Try parsing as integer first
    final asInt = int.tryParse(value);
    if (asInt != null) return asInt;

    // Parse format like "1048576KiB" or "1GiB" or "512MiB"
    final regex = RegExp(r'(\d+(?:\.\d+)?)\s*([KMGT]?i?B?)', caseSensitive: false);
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
          : (json['amount'] != null ? double.tryParse(json['amount'].toString()) ?? 0.0 : 0.0),
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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
      transactionsThisMonth: transactionsThisMonth ?? this.transactionsThisMonth,
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
