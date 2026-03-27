class Voucher {
  final String username;
  final String password;
  final String profile;
  final String? validity;
  final String? dataLimit;
  final String? comment;
  final DateTime createdAt;
  final DateTime? expiresAt;

  Voucher({
    required this.username,
    required this.password,
    required this.profile,
    this.validity,
    this.dataLimit,
    this.comment,
    required this.createdAt,
    this.expiresAt,
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
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // Check if voucher is active
  bool get isActive => !isExpired;

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
    );
  }
}
