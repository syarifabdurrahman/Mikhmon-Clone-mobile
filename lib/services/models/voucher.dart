class Voucher {
  final String username;
  final String password;
  final String profile;
  final String? validity;
  final String? dataLimit;
  final String? comment;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int? remainingSeconds; // remaining session time in seconds
  final DateTime? sessionStartedAt; // when current session started

  Voucher({
    required this.username,
    required this.password,
    required this.profile,
    this.validity,
    this.dataLimit,
    this.comment,
    required this.createdAt,
    this.expiresAt,
    this.remainingSeconds,
    this.sessionStartedAt,
  });

  // Get display text for voucher
  String get displayText {
    if (username == password) {
      // Voucher mode - same username and password
      return 'Voucher: $username';
    } else {
      // User/Password mode
      return 'User: $username\nPass: $password';
    }
  }

  // Get QR code data
  String get qrData {
    if (username == password) {
      return 'WIFI:S:$username;;';
    } else {
      return 'WIFI:S:$username;P:$password;;';
    }
  }

  // Check if voucher is expired
  bool get isExpired {
    // Use remainingSeconds if tracked, otherwise fall back to expiresAt
    if (remainingSeconds != null && remainingSeconds! <= 0) return true;
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // Check if voucher is active
  bool get isActive => !isExpired;

  // Get total validity in seconds from the validity string
  static int? validityToSeconds(String? validity) {
    if (validity == null || validity.isEmpty || validity == 'unlimited') {
      return null;
    }
    final match = RegExp(r'^(\d+)\s*([a-z]+)$', caseSensitive: false)
        .firstMatch(validity);
    if (match == null) return null;
    final value = int.tryParse(match.group(1) ?? '');
    final unit = match.group(2)?.toLowerCase() ?? '';
    if (value == null) return null;
    switch (unit) {
      case 's':
      case 'sec':
        return value;
      case 'm':
      case 'min':
        return value * 60;
      case 'h':
      case 'hr':
        return value * 3600;
      case 'd':
      case 'day':
        return value * 86400;
      case 'w':
      case 'week':
        return value * 604800;
      default:
        return null;
    }
  }

  // Format remaining time as human-readable string
  String get remainingTimeDisplay {
    final secs = remainingSeconds;
    if (secs == null || secs <= 0) return 'Expired';
    if (secs >= 86400) {
      final d = secs ~/ 86400;
      final h = (secs % 86400) ~/ 3600;
      return '${d}d${h}h';
    }
    if (secs >= 3600) {
      final h = secs ~/ 3600;
      final m = (secs % 3600) ~/ 60;
      return '${h}h${m}m';
    }
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m}m${s}s';
  }

  // Check if currently in an active session (connected)
  bool get isInSession =>
      sessionStartedAt != null &&
      remainingSeconds != null &&
      remainingSeconds! > 0;

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'profile': profile,
      'validity': validity,
      'dataLimit': dataLimit,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'remainingSeconds': remainingSeconds,
      'sessionStartedAt': sessionStartedAt?.toIso8601String(),
    };
  }

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      username: json['username'] as String,
      password: json['password'] as String,
      profile: json['profile'] as String,
      validity: json['validity'] as String?,
      dataLimit: json['dataLimit'] as String?,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      remainingSeconds: json['remainingSeconds'] as int?,
      sessionStartedAt: json['sessionStartedAt'] != null
          ? DateTime.parse(json['sessionStartedAt'] as String)
          : null,
    );
  }

  Voucher copyWith({
    String? username,
    String? password,
    String? profile,
    String? validity,
    String? dataLimit,
    String? comment,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? remainingSeconds,
    DateTime? sessionStartedAt,
  }) {
    return Voucher(
      username: username ?? this.username,
      password: password ?? this.password,
      profile: profile ?? this.profile,
      validity: validity ?? this.validity,
      dataLimit: dataLimit ?? this.dataLimit,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      sessionStartedAt: sessionStartedAt ?? this.sessionStartedAt,
    );
  }
}
