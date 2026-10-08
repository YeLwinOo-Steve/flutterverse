import 'dart:math' as math;

import 'package:fv_core/fv_core.dart';

import 'view.dart';

/// Sorts descending by [score]; rows without a score go last, by name.
List<ProjectRow> sortedBy(Iterable<ProjectRow> rows, num? Function(ProjectRow) score) {
  return rows.toList()..sort((a, b) {
    final sa = score(a), sb = score(b);
    if (sa == null || sb == null) {
      if (sa == null && sb == null) return a.name.compareTo(b.name);
      return sa == null ? 1 : -1;
    }
    return sb.compareTo(sa);
  });
}

int? daysSince(DateTime? t, DateTime now) => t == null ? null : now.difference(t).inDays;

/// A tab on the Rankings page.
class Rank {
  const Rank({
    required this.key,
    required this.label,
    required this.head,
    required this.description,
    required this.score,
    required this.signal,
    this.include,
    this.calculated = true,
  });

  final String key;
  final String label;

  /// Header of the signal column.
  final String head;
  final String description;
  final num? Function(ProjectRow) score;
  final String Function(ProjectRow) signal;
  final bool Function(ProjectRow)? include;

  /// Derived by Flutterverse (vs. a metric reported by the source). Calculated
  /// rankings only consider projects with GitHub data.
  final bool calculated;

  List<ProjectRow> apply(Iterable<ProjectRow> rows) => sortedBy(
    rows.where((r) => (!calculated || r.stars != null) && (include?.call(r) ?? true)),
    score,
  );
}

final ranks = <Rank>[
  Rank(
    key: 'today',
    label: 'Trending today',
    head: 'Today',
    description:
        'Stars gained in the last 24h, weighted by how unusual that is versus the project’s own 30-day daily average.',
    score: (r) {
      final d1 = r.stars1d;
      if (d1 == null) return null;
      final avg = math.max(1, (r.stars30d ?? d1 * 30) / 30);
      return d1 * math.sqrt(math.max(0, d1) / avg);
    },
    signal: (r) => '${signedNumber(r.stars1d)} today',
  ),
  Rank(
    key: 'week',
    label: 'This week',
    head: '7 days',
    description: 'Absolute stars gained over the last 7 days.',
    score: (r) => r.stars7d,
    signal: (r) => signedNumber(r.stars7d),
  ),
  Rank(
    key: 'month',
    label: 'This month',
    head: '30 days',
    description: 'Absolute stars gained over the last 30 days.',
    score: (r) => r.stars30d,
    signal: (r) => signedNumber(r.stars30d),
  ),
  Rank(
    key: 'fastest',
    label: 'Fastest growing',
    head: 'Growth 30d',
    description: '30-day growth as a share of the starting star count (minimum 30 new stars).',
    include: (r) => (r.stars30d ?? 0) >= 30,
    score: (r) => r.growth30,
    signal: (r) => '+${percent(r.growth30)}',
  ),
  Rank(
    key: 'rising',
    label: 'Rising',
    head: 'Growth 30d',
    description: 'Projects under 3k stars with the highest 30-day growth rate.',
    include: (r) => r.stars! < 3000,
    score: (r) => r.growth30,
    signal: (r) => '+${percent(r.growth30)}',
  ),
  Rank(
    key: 'gems',
    label: 'Hidden gems',
    head: 'Momentum',
    description: 'Under 2.5k stars, actively maintained, 150+ pub points where published — ranked by Momentum.',
    include: isHiddenGem,
    score: (r) => r.momentum,
    signal: (r) => r.momentumLabel,
  ),
  Rank(
    key: 'downloads',
    label: 'Most downloaded',
    head: 'DL 30d',
    description: 'Ranked by pub.dev 30-day downloads, as reported by pub.dev.',
    calculated: false,
    include: (r) => r.isPublished,
    score: (r) => r.downloads,
    signal: (r) => compactNumber(r.downloads),
  ),
  Rank(
    key: 'loved',
    label: 'Most loved',
    head: 'Likes',
    description: 'Ranked by pub.dev likes, as reported by pub.dev.',
    calculated: false,
    include: (r) => r.isPublished,
    score: (r) => r.likes,
    signal: (r) => compactNumber(r.likes),
  ),
];

bool isHiddenGem(ProjectRow r) =>
    r.stars != null &&
    r.stars! < 2500 &&
    r.maintenance == Maintenance.active &&
    (!r.isPublished || (r.points ?? 0) >= 150);
