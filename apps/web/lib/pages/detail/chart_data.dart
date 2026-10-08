import 'package:fv_core/fv_core.dart';

/// A point on a trend chart.
typedef ChartPoint = ({DateTime t, int v});

enum ChartMetric { stars, downloads }

enum ChartRange {
  day('1D'),
  week('7D'),
  month('30D'),
  quarter('3M'),
  year('1Y'),
  all('All');

  const ChartRange(this.label);
  final String label;
}

/// The series for [metric] over [range], or a reason it's empty.
({List<ChartPoint> points, String? empty}) chartSeries(ProjectDetail d, ChartMetric metric, ChartRange range) {
  if (metric == ChartMetric.downloads) {
    final w = d.pub?.weeklyDownloads;
    if (d.pub == null) return (points: const [], empty: 'Not published to pub.dev.');
    if (w == null || w.length < 2) return (points: const [], empty: 'pub.dev download history is unavailable.');
    final end = d.pub!.weeklyDownloadsEnd ?? DateTime.now().toUtc();
    final all = [
      for (final (i, v) in w.indexed) (t: end.subtract(Duration(days: 7 * (w.length - 1 - i))), v: v),
    ];
    final n = switch (range) {
      ChartRange.day || ChartRange.week => 2,
      ChartRange.month => 5,
      ChartRange.quarter => 13,
      ChartRange.year || ChartRange.all => 52,
    };
    return (points: all.sublist(all.length - (n < all.length ? n : all.length)), empty: null);
  }

  if (d.row.sharedRepo) {
    return (
      points: const [],
      empty: 'Lives in the ${d.row.repo} monorepo — per-package star history is not available.',
    );
  }
  if (d.row.repo == null) return (points: const [], empty: 'No GitHub repository.');
  final all = [
    for (final s in d.history)
      if (s.stars != null) (t: s.day, v: s.stars!),
  ];
  if (all.length < 2) {
    return (points: const [], empty: 'Star history builds up from daily snapshots — check back tomorrow.');
  }
  final days = switch (range) {
    ChartRange.day => 1,
    ChartRange.week => 7,
    ChartRange.month => 30,
    ChartRange.quarter => 91,
    ChartRange.year => 365,
    ChartRange.all => null,
  };
  if (days == null) return (points: all, empty: null);
  final cutoff = all.last.t.subtract(Duration(days: days));
  final inRange = all.where((p) => !p.t.isBefore(cutoff)).toList();
  return (points: inRange.length >= 2 ? inRange : all.sublist(all.length - 2), empty: null);
}

/// Chart geometry in an 800×200 viewBox, with the design's smoothing.
class ChartGeometry {
  ChartGeometry(this.points) {
    final vs = points.map((p) => p.v);
    var mn = vs.reduce((a, b) => a < b ? a : b).toDouble(), mx = vs.reduce((a, b) => a > b ? a : b).toDouble();
    if (mx == mn) {
      mx += 1;
      mn = mn - 1 < 0 ? 0 : mn - 1;
    }
    final pad = (mx - mn) * 0.12;
    min = mn - pad < 0 ? 0 : mn - pad;
    max = mx + pad;
  }

  final List<ChartPoint> points;
  late final double min, max;

  int get n => points.length;
  double x(int i) => n < 2 ? 800 : i * 800 / (n - 1);
  double y(num v) => 200 - (v - min) / (max - min) * 200;

  /// A smoothed line through (at most ~120) points.
  String get line {
    final step = (n / 120).ceil().clamp(1, n);
    final idx = [for (var i = 0; i < n; i += step) i];
    if (idx.last != n - 1) idx.add(n - 1);
    final p = [for (final i in idx) (x(i), y(points[i].v))];
    String f(double v) => v.toStringAsFixed(1);
    final out = StringBuffer('M${f(p[0].$1)},${f(p[0].$2)}');
    const t = 0.18;
    for (var i = 0; i < p.length - 1; i++) {
      final p0 = i > 0 ? p[i - 1] : p[i], p1 = p[i], p2 = p[i + 1], p3 = i + 2 < p.length ? p[i + 2] : p2;
      out.write(
        ' C${f(p1.$1 + (p2.$1 - p0.$1) * t)},${f(p1.$2 + (p2.$2 - p0.$2) * t)} '
        '${f(p2.$1 - (p3.$1 - p1.$1) * t)},${f(p2.$2 - (p3.$2 - p1.$2) * t)} ${f(p2.$1)},${f(p2.$2)}',
      );
    }
    return out.toString();
  }

  String get area => '${line}L800,200L0,200Z';

  /// Y-axis labels from top to bottom: (fraction from top, label).
  List<(double, String)> get gridLabels => [
    for (final g in const [1.0, 0.66, 0.33, 0.0]) (1 - g, compactNumber(min + g * (max - min))),
  ];

  static const gridPath = 'M0,0.0H800M0,66.7H800M0,133.3H800M0,200.0H800';

  List<String> get xLabels => [
    for (final g in const [0.0, 1 / 3, 2 / 3, 1.0]) fullDate(points[(g * (n - 1)).round()].t),
  ];
}

/// `1234567` → `1,234,567`.
String withCommas(int n) {
  final s = n.abs().toString();
  final out = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

/// A shortened timeline label for chart markers.
String markerLabel(String label) => label
    .replaceAll(' GitHub stars', ' ★')
    .replaceAll(' released', '')
    .replaceAll('Latest release ', '')
    .replaceAll('Repository created', 'Created')
    .replaceAll('First published', 'Published');
