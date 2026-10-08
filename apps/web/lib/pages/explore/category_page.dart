import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../data/site_data.dart';
import '../../styles/css.dart';
import 'category_tabs.dart';

/// `/categories/<slug>`.
class CategoryPage extends StatelessComponent {
  const CategoryPage({required this.data, required this.slug, super.key});

  final SiteData data;
  final String slug;

  /// Categories that co-occur with [slug], most related first: shared
  /// projects count 1, categories of curated related projects 0.5.
  List<String> _related(List<ProjectRow> rows) {
    final score = <String, double>{};
    for (final r in rows) {
      for (final c in r.categories) {
        if (c != slug) score[c] = (score[c] ?? 0) + 1;
      }
      for (final id in data.details[r.id]?.related ?? const <String>[]) {
        for (final c in data.row(id)?.categories ?? const <String>[]) {
          if (c != slug) score[c] = (score[c] ?? 0) + 0.5;
        }
      }
    }
    return (score.entries.toList()..sort((x, y) => y.value.compareTo(x.value))).take(6).map((e) => e.key).toList();
  }

  @override
  Component build(BuildContext context) {
    final cats = data.index.categories;
    final label = cats[slug] ?? slug;
    final rows = [
      for (final r in data.index.projects)
        if (r.categories.contains(slug)) r,
    ];
    final growth = rows.any((r) => r.stars30d != null)
        ? signedNumber(rows.fold<int>(0, (sum, r) => sum + (r.stars30d ?? 0)))
        : notAvailable;

    return div(classes: 'category', [
      div(classes: 'category-head', [
        a(href: '/categories', classes: 'category-back', [.text('← All categories')]),
        div(classes: 'category-title', [
          h1(classes: 'page-title', [.text(label)]),
          a(href: '/projects?cat=$slug', classes: 'btn ink', [.text('Open in listing →')]),
        ]),
        div(classes: 'cell-grid category-stats', [
          _stat('Projects', '${rows.length}'),
          _stat('Total stars', compactNumber(rows.fold<int>(0, (sum, r) => sum + (r.stars ?? 0)))),
          _stat('Stars / 30 days', growth),
        ]),
      ]),
      if (rows.isEmpty)
        div(classes: 'empty', styles: Styles(raw: {'padding': '60px 24px'}), [
          b([.text('No projects indexed in $label yet')]),
          span([.text('This category is tracked; entries appear once they pass indexing.')]),
        ])
      else
        CategoryTabs(
          index: IndexFile(categories: cats, projects: rows),
        ),
      div(classes: 'category-related', [
        span(classes: 'eyebrow', [.text('Related categories')]),
        div([
          for (final c in _related(rows)) a(href: '/categories/$c', classes: 'pill related-cat', [.text(cats[c] ?? c)]),
        ]),
      ]),
    ]);
  }

  Component _stat(String k, String v) => div(classes: 'category-stat', [
    span(classes: 'eyebrow', [.text(k)]),
    span(classes: 'category-stat-v', [.text(v)]),
  ]);

  @css
  static List<StyleRule> get styles => [
    rule('.category', {'display': 'flex', 'flex-direction': 'column', 'gap': '32px'}),
    rule('.category-head', {
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '20px',
      'padding-bottom': '28px',
      'border-bottom': '1px solid var(--line)',
    }),
    rule('.category-back', {
      'font-size': '14px',
      'font-weight': '500',
      'color': 'var(--muted)',
      'width': 'fit-content',
    }),
    rule('.category-back:hover', {'color': 'var(--ink)'}),
    rule('.category-title', {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'gap': '24px',
      'align-items': 'flex-end',
      'justify-content': 'space-between',
    }),
    rule('.category-title .btn.ink:hover', {'color': 'var(--bg)'}),
    rule('.category-stats', {'grid-template-columns': 'repeat(auto-fit,minmax(180px,1fr))'}),
    rule('.category-stat', {'padding': '20px 24px', 'display': 'flex', 'flex-direction': 'column', 'gap': '6px'}),
    rule('.category-stat-v', {'font-size': '28px', 'font-weight': '600', 'letter-spacing': '-0.02em'}),
    rule('.category-related', {'display': 'flex', 'flex-direction': 'column', 'gap': '12px'}),
    rule('.category-related > div', {'display': 'flex', 'flex-wrap': 'wrap', 'gap': '8px'}),
    rule('.related-cat', {'font': mono(13), 'padding': '6px 12px'}),
    rule('.related-cat:hover', {'background': 'var(--accent-soft)', 'color': 'var(--accent)'}),
  ];
}
