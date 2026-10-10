import 'package:fv_core/fv_core.dart';

import 'ranking.dart';

/// A sort option on the Projects listing, with the column it shows.
class ListSort {
  const ListSort(this.label, this.head, this.score, this.value);

  final String label;
  final String head;
  final num? Function(ProjectRow r, DateTime now) score;
  final String Function(ProjectRow r, DateTime now) value;

  /// These sorts already show their metric elsewhere in the row, so the
  /// signal column shows 30-day growth instead.
  bool get showsGrowth => const {'Momentum', 'Stars', 'Star growth', 'Downloads'}.contains(label);

  String signalHead() => showsGrowth ? 'Stars · 30 days' : head;

  String signal(ProjectRow r, DateTime now) => showsGrowth ? signedNumber(r.stars30d) : value(r, now);
}

String _pubOnly(ProjectRow r, String Function() f) => r.isPublished ? f() : notApplicable;

final listSorts = <ListSort>[
  // Until a week of history gives projects a Momentum, rank by stars rather
  // than alphabetically (a fraction, so any Momentum still comes first).
  ListSort(
    'Momentum',
    'Momentum',
    (r, _) => r.momentum ?? (r.stars == null ? null : r.stars! / 1e9),
    (r, _) => '${r.momentum ?? notAvailable}',
  ),
  ListSort('Stars', 'Stars', (r, _) => r.stars, (r, _) => compactNumber(r.stars)),
  ListSort('Star growth', '30 days', (r, _) => r.stars30d, (r, _) => signedNumber(r.stars30d)),
  ListSort(
    'Downloads',
    'DL 30d',
    (r, _) => r.isPublished ? r.downloads ?? -1 : -1,
    (r, _) => _pubOnly(r, () => compactNumber(r.downloads)),
  ),
  ListSort(
    'Likes',
    'Likes',
    (r, _) => r.isPublished ? r.likes ?? -1 : -1,
    (r, _) => _pubOnly(r, () => compactNumber(r.likes)),
  ),
  ListSort(
    'Pub points',
    'Pub points',
    (r, _) => r.isPublished ? r.points ?? -1 : -1,
    (r, _) => _pubOnly(r, () => '${r.points ?? notAvailable}/${r.maxPoints ?? 160}'),
  ),
  ListSort(
    'Recently updated',
    'Last commit',
    (r, now) => _negDays(r.lastCommit ?? r.released, now),
    (r, now) => ago(r.lastCommit ?? r.released, now: now),
  ),
  ListSort(
    'Recently released',
    'Released',
    (r, now) => _negDays(r.released, now),
    (r, now) => ago(r.released, now: now),
  ),
];

int? _negDays(DateTime? t, DateTime now) {
  final d = daysSince(t, now);
  return d == null ? null : -d;
}

/// The Projects listing's rows: [filters] applied, sorted by [sort].
List<ProjectRow> listRows(IndexFile index, ListFilters filters, ListSort sort, DateTime now) => [
  for (final r in index.projects)
    if (filters.matches(r, index.categories)) r,
]..sort((x, y) {
    final c = (sort.score(y, now) ?? -1 << 40).compareTo(sort.score(x, now) ?? -1 << 40);
    return c != 0 ? c : byName(x, y);
  });

/// Rows per page in the long listings.
const listPageSize = 50;

ListSort listSortNamed(String label) => listSorts.firstWhere((s) => s.label == label, orElse: () => listSorts.first);

/// The Projects listing filters, mirroring the design's selects.
class ListFilters {
  const ListFilters({
    this.sdk = 'Any',
    this.category = 'All',
    this.platform = 'All',
    this.minStars = 0,
    this.minPoints = 0,
    this.activeOnly = false,
    this.owner,
    this.query = '',
  });

  /// `Any`, `Dart` or `Flutter`.
  final String sdk;

  /// `All` or a category slug.
  final String category;

  /// `All` or a platform display name.
  final String platform;

  /// 0 = any; positive = at least; negative = fewer than `-minStars`.
  final int minStars;
  final int minPoints;
  final bool activeOnly;
  final String? owner;
  final String query;

  bool get isDefault =>
      sdk == 'Any' &&
      category == 'All' &&
      platform == 'All' &&
      minStars == 0 &&
      minPoints == 0 &&
      !activeOnly &&
      owner == null &&
      query.isEmpty;

  bool matches(ProjectRow r, Map<String, String> categories) {
    final stars = r.stars ?? 0;
    final q = query.trim().toLowerCase();
    return (sdk == 'Any' || r.sdk == sdk) &&
        (category == 'All' || r.categories.contains(category)) &&
        (platform == 'All' || r.platforms.contains(platform)) &&
        (minStars == 0 || (minStars < 0 ? stars < -minStars : stars >= minStars)) &&
        (minPoints == 0 || (r.isPublished && (r.points ?? 0) >= minPoints)) &&
        (!activeOnly || r.maintenance == Maintenance.active) &&
        (owner == null || r.owner == owner) &&
        (q.isEmpty ||
            [
              r.id,
              r.description ?? '',
              r.owner ?? '',
              for (final c in r.categories) categories[c] ?? c,
            ].join(' ').toLowerCase().contains(q));
  }

  ListFilters copyWith({
    String? sdk,
    String? category,
    String? platform,
    int? minStars,
    int? minPoints,
    bool? activeOnly,
    String? Function()? owner,
    String? query,
  }) => ListFilters(
    sdk: sdk ?? this.sdk,
    category: category ?? this.category,
    platform: platform ?? this.platform,
    minStars: minStars ?? this.minStars,
    minPoints: minPoints ?? this.minPoints,
    activeOnly: activeOnly ?? this.activeOnly,
    owner: owner != null ? owner() : this.owner,
    query: query ?? this.query,
  );
}
