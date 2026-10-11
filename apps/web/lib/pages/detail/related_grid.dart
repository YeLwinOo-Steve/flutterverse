import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/ui/project_logo.dart';
import '../../data/view.dart';
import '../../styles/css.dart';

/// A titled grid of project cards: the projects commonly used alongside
/// this one, or more by its author.
class RelatedGrid extends StatelessComponent {
  const RelatedGrid({required this.title, required this.rows, super.key});

  final String title;
  final List<ProjectRow> rows;

  @override
  Component build(BuildContext context) {
    return section(classes: 'detail-section', [
      h2([.text(title)]),
      div(classes: 'related', [
        for (final r in rows)
          a(href: r.path, classes: 'related-card hover-border', [
            ProjectLogo(initials: r.initials, color: r.logoColor, imageUrl: r.avatarUrl, size: 32),
            div(classes: 'related-text', [
              span(classes: 'related-name', [.text(r.name)]),
              span(classes: 'related-sub', [.text(r.owner == null ? '' : 'by ${r.owner}')]),
            ]),
          ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.related', {'display': 'grid', 'grid-template-columns': 'repeat(auto-fill,minmax(240px,1fr))', 'gap': '8px'}),
    rule('.related-card', {
      'border': '1px solid var(--line)',
      'background': 'var(--surface)',
      'border-radius': '2px',
      'padding': '12px',
      'display': 'flex',
      'gap': '12px',
      'align-items': 'center',
      'color': 'var(--ink)',
    }),
    rule('.related-card:hover', {'color': 'var(--ink)'}),
    rule('.related-text', {'flex': '1', 'min-width': '0', 'display': 'flex', 'flex-direction': 'column'}),
    rule('.related-name', {'font-size': '14px', 'font-weight': '600'}),
    rule('.related-sub', {'font-size': '13px', 'color': 'var(--muted)'}),
  ];
}
