/// Text formatting helpers (no external package needed).
abstract final class Formatters {
  /// 1234 -> 1.2K, 128400 -> 128K, 2300000 -> 2.3M
  static String compactCount(int n) {
    if (n >= 1000000) return '${_trim(n / 1000000)}M';
    if (n >= 1000) return '${_trim(n / 1000)}K';
    return '$n';
  }

  static String _trim(double v) {
    final s = v.toStringAsFixed(v >= 10 ? 0 : 1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  /// 754 -> 12:34, 3725 -> 1:02:05
  static String duration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(h > 0 ? 2 : 1, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  /// Relative time such as "5 hours ago" or "2 days ago".
  static String timeAgo(DateTime time, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return _plural(diff.inMinutes, 'minute');
    if (diff.inHours < 24) return _plural(diff.inHours, 'hour');
    if (diff.inDays < 7) return _plural(diff.inDays, 'day');
    if (diff.inDays < 30) return _plural(diff.inDays ~/ 7, 'week');
    if (diff.inDays < 365) return _plural(diff.inDays ~/ 30, 'month');
    return _plural(diff.inDays ~/ 365, 'year');
  }

  static String _plural(int n, String unit) => '$n $unit${n == 1 ? '' : 's'} ago';
}
