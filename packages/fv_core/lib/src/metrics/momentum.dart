import 'dart:math' as math;

import '../models/snapshot.dart';

/// Stars gained over the last [days] days, or null when [history] doesn't
/// reach back that far (or has no star counts).
///
/// [history] must be sorted oldest first. The baseline is the latest snapshot
/// taken on or before `latest.day - days`.
int? starGrowth(List<Snapshot> history, int days) {
  final latest = _lastWithStars(history);
  if (latest == null) return null;
  final cutoff = latest.day.subtract(Duration(days: days));
  Snapshot? base;
  for (final s in history) {
    if (s.stars == null) continue;
    if (s.day.isAfter(cutoff)) break;
    base = s;
  }
  if (base == null) return null;
  return latest.stars! - base.stars!;
}

/// [starGrowth] over [days] days, or while [history] is shorter than that,
/// an estimate scaled up from the gain over the span it covers (at least a
/// day); `early` marks the estimate. Null with under two days of stars.
({int gain, bool early})? starGrowthEstimate(List<Snapshot> history, int days) {
  final measured = starGrowth(history, days);
  if (measured != null) return (gain: measured, early: false);
  final starred = [
    for (final s in history)
      if (s.stars != null) s,
  ];
  if (starred.length < 2) return null;
  final span = starred.last.day.difference(starred.first.day).inDays;
  if (span < 1) return null;
  return (gain: ((starred.last.stars! - starred.first.stars!) * days / span).round(), early: true);
}

/// Stars gained per day over the last [days] days, oldest first, for
/// sparklines. Days without a snapshot count as 0. Null with less than two
/// days of star history.
List<int>? dailyStarGains(List<Snapshot> history, {int days = 30}) {
  final starred = [
    for (final s in history)
      if (s.stars != null) s,
  ];
  if (starred.length < 2) return null;
  final end = starred.last.day;
  final gains = List.filled(days, 0);
  for (var i = 1; i < starred.length; i++) {
    final offset = end.difference(starred[i].day).inDays;
    if (offset < days) gains[days - 1 - offset] = math.max(0, starred[i].stars! - starred[i - 1].stars!);
  }
  return gains;
}

/// The inputs [momentumScores] needs for one project.
class MomentumInput {
  const MomentumInput({
    required this.stars,
    required this.stars7d,
    required this.stars30d,
    this.daysSinceCommit,
    this.daysSinceRelease,
    this.downloadGrowth,
  });

  final int? stars;
  final int? stars7d;
  final int? stars30d;
  final int? daysSinceCommit;
  final int? daysSinceRelease;

  /// Relative change in weekly downloads over the last quarter.
  final double? downloadGrowth;
}

/// A 0–100 score for how much a project is taking off right now, relative
/// to the other tracked projects. Null when the 7-day star growth is unknown.
///
/// Weighted sum of six signals, each scaled to 0–1:
///
/// | Weight | Signal |
/// |---|---|
/// | 26% | 7-day stars, log-scaled against the fastest project |
/// | 24% | 30-day growth as a share of stars, capped at 12% |
/// | 16% | Acceleration: last week's pace vs the month's (0.7× → 0, 1.3× → 1) |
/// | 12% | Download growth over the quarter, capped at 25% (unknown → 0.4) |
/// | 12% | Last commit: ≤7 days 1, ≤30 0.7, ≤90 0.35, else 0.1 |
/// | 10% | Last release: ≤30 days 1, ≤90 0.6, else 0.2 |
///
/// Until 30 days of history exist, the 30-day gain is extrapolated from the
/// 7-day one.
Map<K, int?> momentumScores<K>(Map<K, MomentumInput> inputs) {
  final maxD7 = inputs.values.map((i) => i.stars7d ?? 0).fold(0, math.max);
  double clamp01(double v) => v.clamp(0.0, 1.0).toDouble();

  return inputs.map((key, i) {
    final d7 = i.stars7d;
    if (d7 == null) return MapEntry(key, null);
    final d7c = math.max(0, d7);
    final d30 = math.max(0, i.stars30d ?? (d7c * 30 / 7).round());
    final stars = i.stars ?? 0;

    final velocity = maxD7 <= 0 ? 0.0 : math.log(1 + d7c) / math.log(1 + maxD7);
    final base = stars - d30;
    final growth = base <= 0 ? (d30 > 0 ? 1.0 : 0.0) : clamp01(d30 / base / 0.12);
    final acceleration = clamp01(((d7c * 30 / 7) / math.max(1, d30) - 0.7) / 0.6);
    final downloads = i.downloadGrowth == null ? 0.4 : clamp01(i.downloadGrowth! / 0.25);
    final commit = switch (i.daysSinceCommit) {
      final d? when d <= 7 => 1.0,
      final d? when d <= 30 => 0.7,
      final d? when d <= 90 => 0.35,
      _ => 0.1,
    };
    final release = switch (i.daysSinceRelease) {
      final d? when d <= 30 => 1.0,
      final d? when d <= 90 => 0.6,
      _ => 0.2,
    };
    final score =
        0.26 * velocity + 0.24 * growth + 0.16 * acceleration + 0.12 * downloads + 0.12 * commit + 0.10 * release;
    return MapEntry(key, (100 * score).round());
  });
}

Snapshot? _lastWithStars(List<Snapshot> history) {
  for (final s in history.reversed) {
    if (s.stars != null) return s;
  }
  return null;
}
