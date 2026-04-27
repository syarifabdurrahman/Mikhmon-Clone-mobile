/// Generates an on-login script for MikroTik Hotspot user profiles
/// that automatically schedules user removal when their session timeout expires
class OnLoginScriptGenerator {
  static String generate(String validity) {
    return ''':local user \$user
:local comment [/ip hotspot user get [find name=\$user] comment]

:if (\$comment = "" || \$comment = "Aktif") do={
    :if ([:len [/system scheduler find name=\$user]] = 0) do={
        /system scheduler add name=\$user interval=''' +
        validity +
        ''' on-event="/ip hotspot user remove [find name=\$user]; /ip hotspot active remove [find user=\$user]; /system scheduler remove [find name=\$user]"
    }
    :local date [/system clock get date]
    :local time [/system clock get time]
    /ip hotspot user set [find name=\$user] comment="Aktif \$date \$time"
}''';
  }

  static bool isValidSessionTimeout(String? sessionTimeout) {
    if (sessionTimeout == null ||
        sessionTimeout.isEmpty ||
        sessionTimeout.toLowerCase() == 'unlimited') {
      return false;
    }
    return true;
  }

  static String? parseSessionTimeout(String validity) {
    final v = validity.toLowerCase().trim();

    if (v == 'unlimited' || v.isEmpty) {
      return null;
    }

    // Handle format: "DD d HH:mm:ss" (e.g., "1d 00:00:00", "2d 03:30:00")
    final fullFormatRegex = RegExp(r'^(\d+)d\s+(\d+):(\d+):(\d+)$');
    final fullMatch = fullFormatRegex.firstMatch(v);

    if (fullMatch != null) {
      final days = int.tryParse(fullMatch.group(1) ?? '0') ?? 0;
      final hours = int.tryParse(fullMatch.group(2) ?? '0') ?? 0;
      final minutes = int.tryParse(fullMatch.group(3) ?? '0') ?? 0;
      final seconds = int.tryParse(fullMatch.group(4) ?? '0') ?? 0;

      int totalSeconds =
          (days * 24 * 3600) + (hours * 3600) + (minutes * 60) + seconds;

      if (totalSeconds <= 0) return null;

      return _formatDuration(totalSeconds);
    }

    // Handle simple format: "1d", "12h", "30m", "1s"
    final simpleRegex = RegExp(r'^(\d+)([smhd])$');
    final simpleMatch = simpleRegex.firstMatch(v);

    if (simpleMatch == null) {
      return null;
    }

    final value = int.tryParse(simpleMatch.group(1) ?? '');
    final unit = simpleMatch.group(2) ?? 'd';

    if (value == null || value <= 0) {
      return null;
    }

    int seconds;
    switch (unit) {
      case 's':
        seconds = value;
        break;
      case 'm':
        seconds = value * 60;
        break;
      case 'h':
        seconds = value * 60 * 60;
        break;
      case 'd':
      default:
        seconds = value * 24 * 60 * 60;
        break;
    }

    return _formatDuration(seconds);
  }

  static String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h${minutes > 0 ? "${minutes}m" : ""}';
    } else if (minutes > 0) {
      return '${minutes}m${secs > 0 ? "${secs}s" : ""}';
    } else {
      return '${secs}s';
    }
  }
}
