import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/ui/project_logo.dart';
import '../../data/ranking.dart';
import '../../data/view.dart';
import '../../styles/css.dart';

/// An Explore card: category size, leading logos, growth and leader.
class CategoryCard extends StatelessComponent {
  const CategoryCard({required this.slug, required this.label, required this.rows, super.key});

  final String slug;
  final String label;

  /// Projects in this category.
  final List<ProjectRow> rows;

  @override
  Component build(BuildContext context) {
    final byStars = sortedBy(rows, (r) => r.stars);
    final growth = rows.any((r) => r.stars30d != null)
        ? compactNumber(rows.fold<int>(0, (sum, r) => sum + (r.stars30d ?? 0)))
        : notAvailable;
    return a(href: '/categories/$slug', classes: 'cat-card hover-border', [
      div(classes: 'cat-card-top', [
        div(classes: 'cat-card-title', [
          span([.text(label)]),
          span(classes: 'muted', [
            .text(rows.isEmpty ? 'No projects yet' : '${rows.length} ${rows.length == 1 ? 'project' : 'projects'}'),
          ]),
        ]),
        span(classes: 'cat-arrow', [.text('→')]),
      ]),
      if (rows.isEmpty)
        span(classes: 'cat-none', [.text('Tracked — no projects indexed yet.')])
      else ...[
        div(classes: 'cat-card-mid', [
          div(classes: 'cat-logos', [
            for (final (i, r) in byStars.take(4).indexed)
              ProjectLogo(
                initials: r.initials,
                color: r.logoColor,
                imageUrl: r.avatarUrl,
                size: 36,
                ring: 'var(--surface)',
                offset: i > 0,
              ),
          ]),
          span(classes: 'growth', styles: Styles(raw: {'padding': '3px 8px'}), [.text('↑ $growth / 30d')]),
        ]),
        div(classes: 'cat-leader', [
          span(classes: 'muted', [.text('Leader')]),
          b([.text(byStars.first.name)]),
        ]),
      ],
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.cat-card', {
      'border': '1px solid var(--line)',
      'background': 'var(--surface)',
      'border-radius': '2px',
      'padding': '24px',
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '20px',
      'color': 'var(--ink)',
    }),
    rule('.cat-card:hover', {'color': 'var(--ink)'}),
    rule('.cat-card-top', {
      'display': 'flex',
      'justify-content': 'space-between',
      'align-items': 'flex-start',
      'gap': '12px',
    }),
    rule('.cat-card-title', {'display': 'flex', 'flex-direction': 'column', 'gap': '4px'}),
    rule('.cat-card-title > span:first-child', {
      'font-size': '18px',
      'font-weight': '600',
      'letter-spacing': '-0.01em',
    }),
    rule('.cat-card-title .muted', {'font-size': '13px'}),
    rule('.cat-arrow', {'font-size': '18px', 'color': 'var(--muted)'}),
    rule('.cat-card-mid', {
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'space-between',
      'gap': '12px',
    }),
    rule('.cat-logos', {'display': 'flex'}),
    rule('.cat-leader', {
      'display': 'flex',
      'justify-content': 'space-between',
      'gap': '12px',
      'padding-top': '16px',
      'border-top': '1px solid var(--line)',
      'font-size': '13px',
    }),
    rule('.cat-leader b', {'font-weight': '600'}),
    rule('.cat-none', {
      'font-size': '13px',
      'color': 'var(--muted)',
      'padding-top': '16px',
      'border-top': '1px dashed var(--line)',
    }),
  ];
}
