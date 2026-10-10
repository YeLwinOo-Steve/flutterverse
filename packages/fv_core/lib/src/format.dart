/// Shared display formatting, so every surface prints numbers the same way.
library;

/// The metric is unknown (source failed, or not enough history).
const notAvailable = 'N/A';

/// The metric doesn't apply (e.g. pub.dev numbers for an unpublished project).
const notApplicable = '—';

/// `999` → `999`, `1234` → `1.2k`, `123456` → `123k`, `4698698` → `4.7M`,
/// `12000000` → `12M`; null → `N/A`.
String compactNumber(num? n) {
  if (n == null) return notAvailable;
  final sign = n < 0 ? '-' : '';
  final abs = n.abs();
  String fmt(double v, bool whole, String suffix) {
    final s = v.toStringAsFixed(whole ? 0 : 1);
    return '$sign${s.endsWith('.0') ? s.substring(0, s.length - 2) : s}$suffix';
  }

  if (abs >= 1e6) return fmt(abs / 1e6, abs >= 1e7, 'M');
  if (abs >= 1e3) return fmt(abs / 1e3, abs >= 1e5, 'k');
  return '$sign${abs.round()}';
}

/// A momentum score, `~42` while it's an early estimate.
String momentumLabel(int? score, {bool early = false}) => score == null ? notAvailable : '${early ? '~' : ''}$score';

/// `3002` → `3,002`: an exact count, for totals and page ranges.
String groupedNumber(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ',');

/// `+12`, `-3`, `+0`; null → `N/A`.
String signedNumber(int? n) {
  if (n == null) return notAvailable;
  return n < 0 ? compactNumber(n) : '+${compactNumber(n)}';
}

/// `0.123` → `12.3%`; null → `N/A`.
String percent(double? x) => x == null ? notAvailable : '${(x * 100).toStringAsFixed(1)}%';

/// `today`, `3d ago`, `2mo ago`, `1.5y ago`; null → `N/A`.
String ago(DateTime? t, {required DateTime now}) {
  if (t == null) return notAvailable;
  final d = now.difference(t).inDays;
  if (d <= 0) return 'today';
  if (d < 30) return '${d}d ago';
  if (d < 365) return '${(d / 30).round()}mo ago';
  final y = (d / 365).toStringAsFixed(1);
  return '${y.endsWith('.0') ? y.substring(0, y.length - 2) : y}y ago';
}

/// A duration in the same style without "ago": `3d`, `2mo`, `6.4y`.
String age(DateTime? t, {required DateTime now}) => ago(t, now: now).replaceFirst(' ago', '');

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// `Oct 6, 2026`.
String fullDate(DateTime t) {
  final u = t.toUtc();
  return '${_months[u.month - 1]} ${u.day}, ${u.year}';
}

/// `Oct 2026`.
String monthYear(DateTime t) {
  final u = t.toUtc();
  return '${_months[u.month - 1]} ${u.year}';
}
