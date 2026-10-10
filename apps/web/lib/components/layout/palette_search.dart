import 'package:fv_core/fv_core.dart';

import '../../data/ranking.dart';
import '../../data/view.dart';

/// One selectable palette result.
class PaletteItem {
  const PaletteItem({required this.label, required this.meta, required this.href, this.project});

  final String label;
  final String meta;
  final String href;

  /// Set for project results, to show its logo.
  final ProjectRow? project;
}

typedef PaletteGroup = ({String title, List<PaletteItem> items});

const paletteSuggestions = [
  'state management',
  'flutter animation',
  'riverpod',
  'database',
  'felangel',
  'trending packages',
];

/// The design's palette search: pages, packages, projects, categories and
/// authors matching every word of [query]; trending projects when empty.
List<PaletteGroup> paletteResults(IndexFile index, String query) {
  final q = query.trim().toLowerCase();
  final rows = index.projects;
  PaletteItem project(ProjectRow r, String meta) => PaletteItem(label: r.name, meta: meta, href: r.path, project: r);

  if (q.isEmpty) {
    final trending = sortedBy(rows.where((r) => r.stars != null), (r) => r.stars7d ?? -1).take(5);
    return [
      (
        title: 'Trending now',
        items: [
          for (final r in trending)
            project(r, r.stars7d == null ? '${compactNumber(r.stars)} ★' : '${signedNumber(r.stars7d)} this week'),
        ],
      ),
    ];
  }

  bool matches(String s) {
    final lower = s.toLowerCase();
    return lower.contains(q) || q.split(' ').every(lower.contains);
  }

  bool hit(ProjectRow r) =>
      matches(
        [
          r.id,
          r.description ?? '',
          for (final c in r.categories) categoryLabel(index.categories, c),
          r.owner ?? '',
        ].join(' '),
      ) ||
      (q.contains('animation') && r.categories.contains('animation'));

  final owners = {for (final r in rows) ?r.owner};
  final groups = <PaletteGroup>[
    (
      title: 'Go to',
      items: [
        if (q.contains('trend')) const PaletteItem(label: 'Trending rankings', meta: 'page', href: '/rankings'),
      ],
    ),
    (
      title: 'Packages',
      items: [
        for (final r in rows.where((r) => r.kind == ProjectKind.package && hit(r)).take(6))
          project(r, '${compactNumber(r.shownStars)} ★${r.repoWideStars ? ' repo' : ''}'),
      ],
    ),
    (
      title: 'Projects & repositories',
      items: [
        for (final r in rows.where((r) => r.kind == ProjectKind.project && hit(r)).take(4))
          project(r, '${compactNumber(r.shownStars)} ★${r.repoWideStars ? ' repo' : ''}'),
      ],
    ),
    (
      title: 'Categories',
      items: [
        for (final MapEntry(key: slug, value: label) in index.categories.entries.where((e) => matches(e.value)).take(4))
          PaletteItem(label: label, meta: 'category', href: '/categories/$slug'),
      ],
    ),
    (
      title: 'Authors & organizations',
      items: [
        for (final o in owners.where(matches).take(4))
          PaletteItem(label: o, meta: 'author', href: '/projects?owner=${Uri.encodeQueryComponent(o)}'),
      ],
    ),
  ];
  return [
    for (final g in groups)
      if (g.items.isNotEmpty) g,
  ];
}
