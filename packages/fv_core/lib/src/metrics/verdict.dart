import '../format.dart';
import '../json.dart';
import '../models/output.dart';
import 'maintenance.dart';

/// Pubspec Doctor's call on one dependency, shared by Doctor, the README
/// badges and (later) the API, so the three can never disagree.
enum Verdict {
  replaceNow('Replace now'),
  healthy('Healthy'),
  stable('Stable'),
  watch('Watch'),
  atRisk('At risk');

  const Verdict(this.label);
  final String label;

  /// Healthy and Stable count toward a project's score.
  bool get good => this == healthy || this == stable;
}

/// Pub points a finished package needs to read [Verdict.stable].
const stablePoints = 140;

/// How long ago a [Verdict.stable] package may have last released.
const stableReleaseDays = 3 * 365;

/// The quarterly download change a [Verdict.stable] package may not fall below.
const stableDownloadGrowth = -0.10;

/// The momentum score a Healthy or Stable package needs for the Rising tag.
/// A starting value: tune it once live data has full weeks of star history.
const risingMomentum = 75;

/// A [Verdict] with the facts behind it.
class VerdictResult {
  const VerdictResult({this.verdict, this.reasons = const [], this.rising = false, this.replacedBy});

  /// Null when a number a rule needs is missing ("Not enough data").
  final Verdict? verdict;

  /// Short facts, such as `last release 14mo ago`, so a maintainer can see
  /// why and disagree.
  final List<String> reasons;

  /// Healthy or Stable with a high, non-early momentum score.
  final bool rising;

  /// The package pub.dev points to instead, for a discontinued one.
  final String? replacedBy;

  /// `Rising`, the verdict's label, or null without a verdict.
  String? get badgeMessage => verdict == null ? null : (rising ? 'Rising' : verdict!.label);
}

/// Judges a dependency. The first matching rule wins:
///
/// 1. [Verdict.replaceNow]: [discontinued] on pub.dev, or its GitHub repo is
///    archived.
/// 2. [Verdict.healthy]: maintenance is Active.
/// 3. [Verdict.stable]: not Active, but at least [stablePoints] pub points,
///    a release within [stableReleaseDays], and downloads not falling faster
///    than [stableDownloadGrowth] per quarter. Finished packages such as
///    `http` or `crypto` rarely change, and shouldn't read as problems.
/// 4. [Verdict.watch]: Slowing.
/// 5. [Verdict.atRisk]: Low activity.
///
/// Without a maintenance class the verdict is null: missing data gives no
/// verdict, never a guess. [row] may be null only for a discontinued package
/// that isn't tracked; otherwise the result is null ("Not tracked").
VerdictResult? verdictOf(ProjectRow? row, {required DateTime now, bool discontinued = false, String? replacedBy}) {
  if (row == null && !discontinued) return null;
  final facts = row == null ? const <String>[] : _facts(row, now);
  if (discontinued || row!.archived) {
    return VerdictResult(
      verdict: Verdict.replaceNow,
      reasons: [
        if (discontinued) 'discontinued on pub.dev',
        if (row?.archived ?? false) 'GitHub repo archived',
        if (replacedBy != null) 'pub.dev suggests $replacedBy',
        ...facts,
      ],
      replacedBy: replacedBy,
    );
  }
  final verdict = switch (row.maintenance) {
    null => null,
    Maintenance.active => Verdict.healthy,
    _ when _isStable(row, now) => Verdict.stable,
    Maintenance.slowing => Verdict.watch,
    Maintenance.low => Verdict.atRisk,
  };
  final rising = (verdict?.good ?? false) && !row.momentumEarly && (row.momentum ?? 0) >= risingMomentum;
  return VerdictResult(
    verdict: verdict,
    reasons: [
      if (verdict == null) 'no commit or release date',
      // Stable overrides Slowing or Low activity on purpose: naming them
      // would contradict the verdict.
      if (row.maintenance case final m? when verdict != Verdict.stable) m.label.toLowerCase(),
      ...facts,
    ],
    rising: rising,
  );
}

bool _isStable(ProjectRow row, DateTime now) {
  final points = row.points, released = row.released, growth = row.downloadGrowth;
  if (points == null || released == null || growth == null) return false;
  return points >= stablePoints &&
      now.difference(released).inDays <= stableReleaseDays &&
      growth >= stableDownloadGrowth;
}

List<String> _facts(ProjectRow row, DateTime now) => [
  if (row.released case final t?) 'last release ${ago(t, now: now)}',
  if (row.lastCommit case final t?) 'last commit ${ago(t, now: now)}',
  if ((row.points, row.maxPoints) case (final p?, final max?)) '$p/$max pub points',
  if (row.downloadGrowth case final g?) _growth(g),
];

String _growth(double g) {
  final pct = (g.abs() * 100).round();
  if (pct == 0) return 'downloads flat this quarter';
  return 'downloads ${g > 0 ? 'up' : 'down'} $pct% this quarter';
}

/// Shields.io colors: Healthy, Stable and Rising use colour; Watch and At
/// risk stay neutral grey, and only Replace now is red, so a badge never
/// turns alarming by surprise.
String badgeColor(VerdictResult r) {
  if (r.rising) return 'C2410C';
  return switch (r.verdict) {
    Verdict.healthy => '0468D7',
    Verdict.stable => '0B7A6E',
    Verdict.replaceNow => 'C8382B',
    _ => '6B7A90',
  };
}

/// `badge/<package>.json`, in the shape Shields.io's endpoint badge reads.
/// Null when there's no verdict, so no badge file is written.
Json? badgeJson(VerdictResult r) {
  final message = r.badgeMessage;
  if (message == null) return null;
  return {'schemaVersion': 1, 'label': 'Flutterverse', 'message': message, 'color': badgeColor(r)};
}
