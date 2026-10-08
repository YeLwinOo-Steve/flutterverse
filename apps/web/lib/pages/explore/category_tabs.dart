import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/ui/badges.dart';
import '../../components/ui/project_logo.dart';
import '../../components/ui/seg_control.dart';
import '../../data/ranking.dart';
import '../../data/view.dart';
import '../../styles/css.dart';

enum _Tab {
  lead('Leading', 'Most-starred projects in this category.', 'Stars'),
  fast('Fastest growing', 'Highest 30-day star growth rate.', 'Growth 30d'),
  emerging('Emerging', 'Under 3k stars, ranked by Momentum.', 'Momentum');

  const _Tab(this.label, this.description, this.head);
  final String label;
  final String description;
  final String head;
}

/// The ranked list on a category page.
@client
class CategoryTabs extends StatefulComponent {
  const CategoryTabs({required this.index, super.key});

  /// Only this category's projects.
  final IndexFile index;

  @override
  State<CategoryTabs> createState() => _CategoryTabsState();

  @css
  static List<StyleRule> get styles => [
    rule('.cat-tabs-head', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '12px',
      'flex-wrap': 'wrap',
      'padding': '16px 24px',
      'border-bottom': '1px solid var(--line)',
    }),
    rule('.cat-tabs-head > span', {'font-size': '13px', 'color': 'var(--muted)'}),
    rule('.cat-row', {
      'display': 'grid',
      'grid-template-columns': '26px 40px minmax(0,1fr) auto',
      'gap': '16px',
      'align-items': 'center',
      'padding': '20px 24px',
      'border-bottom': '1px solid var(--line)',
      'color': 'var(--ink)',
    }),
    rule('.cat-row:hover', {'color': 'var(--ink)'}),
    rule('.cat-row-main', {'display': 'flex', 'flex-direction': 'column', 'gap': '6px', 'min-width': '0'}),
    rule('.cat-row-title', {'display': 'flex', 'align-items': 'center', 'gap': '10px', 'flex-wrap': 'wrap'}),
    rule('.cat-row-title > span:first-child', {'font-size': '16px', 'font-weight': '600'}),
    rule('.cat-row-desc', {
      'font-size': '14px',
      'color': 'var(--muted)',
      'line-height': '1.5',
      'white-space': 'nowrap',
      'overflow': 'hidden',
      'text-overflow': 'ellipsis',
    }),
    rule('.cat-row-val', {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'flex-end',
      'gap': '4px',
      'min-width': '96px',
    }),
    rule('.cat-row-val > span', {'font-size': '12px', 'color': 'var(--muted)'}),
    rule('.cat-row-val > b', {
      'font-size': '20px',
      'font-weight': '600',
      'letter-spacing': '-0.02em',
      'font-variant-numeric': 'tabular-nums',
    }),
    rule('.cat-rows-none', {'padding': '32px 24px', 'font-size': '14px', 'color': 'var(--muted)'}),
  ];
}

class _CategoryTabsState extends State<CategoryTabs> {
  _Tab _tab = _Tab.lead;

  (List<ProjectRow>, String Function(ProjectRow)) _ranked() {
    final rows = component.index.projects;
    return switch (_tab) {
      _Tab.lead => (sortedBy(rows, (r) => r.stars), (r) => compactNumber(r.stars)),
      _Tab.fast => (
        sortedBy(rows.where((r) => r.growth30 != null), (r) => r.growth30),
        (r) => '+${percent(r.growth30)}',
      ),
      _Tab.emerging => (
        sortedBy(rows.where((r) => r.stars != null && r.stars! < 3000 && r.momentum != null), (r) => r.momentum),
        (r) => '${r.momentum}',
      ),
    };
  }

  @override
  Component build(BuildContext context) {
    final (rows, value) = _ranked();
    return div(classes: 'panel', [
      div(classes: 'cat-tabs-head', [
        SegControl<_Tab>(
          options: [for (final t in _Tab.values) (t, t.label)],
          selected: _tab,
          onSelect: (t) => setState(() => _tab = t),
        ),
        span([.text(_tab.description)]),
      ]),
      for (final (i, r) in rows.take(8).indexed)
        a(href: r.path, classes: 'cat-row hover-row', [
          span(classes: 'trend-rank', styles: Styles(raw: {'padding-top': '0'}), [.text('${i + 1}')]),
          ProjectLogo(initials: r.initials, color: r.logoColor, imageUrl: r.avatarUrl),
          div(classes: 'cat-row-main', [
            div(classes: 'cat-row-title', [
              span([.text(r.name)]),
              if (r.owner != null) span(classes: 'trend-owner', [.text('by ${r.owner}')]),
              healthPill(r),
            ]),
            span(classes: 'cat-row-desc', [.text(r.description ?? '')]),
          ]),
          div(classes: 'cat-row-val', [
            span([.text(_tab.head)]),
            b([.text(value(r))]),
          ]),
        ]),
      if (rows.isEmpty)
        div(classes: 'cat-rows-none', [
          .text(_tab == _Tab.lead ? 'Nothing qualifies here yet.' : 'Needs a few weeks of daily snapshots.'),
        ]),
    ]);
  }
}
