import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/project/trend_row.dart';
import '../../components/ui/seg_control.dart';
import '../../data/ranking.dart';
import '../../styles/css.dart';

enum _Window {
  day('Today', 'today'),
  week('This week', 'this week'),
  month('This month', 'this month');

  const _Window(this.label, this.suffix);
  final String label;
  final String suffix;

  int? of(ProjectRow r) => switch (this) {
    day => r.stars1d,
    week => r.stars7d,
    month => r.stars30d,
  };
}

const _sorts = ['Trending', 'Stars', 'Star growth', 'Downloads', 'Likes', 'Recently updated', 'Recently released'];

/// The home page's Trending panel: a time window and a sort.
@client
class TrendingCard extends StatefulComponent {
  const TrendingCard({required this.index, required this.now, super.key});

  /// Only the rows some window and sort can show (see [previewRows]).
  final IndexFile index;

  /// ISO timestamp of the data snapshot.
  final String now;

  @override
  State<TrendingCard> createState() => _TrendingCardState();

  /// Every row any window and sort shows: their top 8s, which keeps the
  /// card's props small however many projects there are.
  static List<ProjectRow> previewRows(IndexFile index, DateTime now) => {
    for (final w in _Window.values)
      for (final s in _sorts) ..._top(index.projects, w, s, now),
  }.toList();

  @css
  static List<StyleRule> get styles => [
    rule('.trending', {'flex': '1 1 640px', 'min-width': '0'}),
    rule('.trending h2', {'font-size': '16px', 'font-weight': '600'}),
    rule('.trending .spacer', {'flex': '1'}),
    rule('.sort-label', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '8px',
      'font': mono(12),
      'color': 'var(--muted)',
      'text-transform': 'uppercase',
      'letter-spacing': '0.05em',
    }),
    rule('.sort-label select', {'height': '32px', 'font': sans(14), 'text-transform': 'none', 'letter-spacing': '0'}),
    rule('.trending-more', {
      'display': 'block',
      'padding': '12px 16px',
      'font-size': '14px',
      'font-weight': '500',
      'color': 'var(--ink)',
    }),
    rule('.trending-more:hover', {'background': 'var(--surface2)', 'color': 'var(--ink)'}),
  ];
}

List<ProjectRow> _top(List<ProjectRow> all, _Window window, String sort, DateTime now) {
  final withStars = all.where((r) => r.stars != null);
  final sorted = switch (sort) {
    'Stars' => sortedBy(withStars, (r) => r.stars),
    'Star growth' => sortedBy(withStars, (r) => r.growth30),
    'Downloads' => sortedBy(all, (r) => r.downloads),
    'Likes' => sortedBy(all, (r) => r.likes),
    'Recently updated' => sortedBy(all, (r) => -(daysSince(r.lastCommit ?? r.released, now) ?? 1 << 30)),
    'Recently released' => sortedBy(all, (r) => -(daysSince(r.released, now) ?? 1 << 30)),
    // Until growth history exists, fall back to total stars so the list
    // isn't alphabetical.
    _ => sortedBy(withStars, (r) => window.of(r) ?? (r.stars! / 1e9)),
  };
  return sorted.take(8).toList();
}

class _TrendingCardState extends State<TrendingCard> {
  _Window _window = _Window.day;
  String _sort = 'Trending';

  List<ProjectRow> _rows() => _top(component.index.projects, _window, _sort, DateTime.parse(component.now));

  @override
  Component build(BuildContext context) {
    final cats = component.index.categories;
    return div(classes: 'trending panel', [
      div(classes: 'panel-head', [
        h2([.text('Trending')]),
        SegControl<_Window>(
          label: 'Time window',
          options: [for (final w in _Window.values) (w, w.label)],
          selected: _window,
          onSelect: (w) => setState(() => _window = w),
        ),
        span(classes: 'spacer', []),
        label(classes: 'sort-label', [
          .text('Sort'),
          select(
            classes: 'select',
            value: _sort,
            onChange: (v) => setState(() => _sort = v.first),
            [
              for (final s in _sorts) option(value: s, selected: s == _sort, [.text(s)]),
            ],
          ),
        ]),
      ]),
      for (final (i, r) in _rows().indexed)
        TrendRow(row: r, rank: i + 1, categories: cats, growth: _window.of(r), growthLabel: _window.suffix),
      a(href: '/rankings', classes: 'trending-more', [.text('All rankings →')]),
    ]);
  }
}
