import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../styles/css.dart';

/// The first few Hall of Fame inductees on the home page.
class HofPreview extends StatelessComponent {
  const HofPreview({required this.edition, required this.names, super.key});

  final HallOfFameEdition edition;

  /// Project id → display name.
  final Map<String, String> names;

  @override
  Component build(BuildContext context) {
    return section(classes: 'hof-preview', [
      div(classes: 'hof-preview-head', [
        h2(classes: 'section-title', [.text('Hall of Fame · ${edition.year}')]),
        a(href: '/hall-of-fame', classes: 'link-more', [.text('All inductees →')]),
      ]),
      div(classes: 'cell-grid hof-preview-grid', [
        for (final p in edition.projects.take(4))
          a(href: '/p/${p.id}', classes: 'hof-cell hover-row', [
            span(classes: 'eyebrow warn', styles: Styles(raw: {'font-size': '12px'}), [.text(p.category)]),
            span(classes: 'hof-cell-name', [.text(names[p.id] ?? p.id)]),
            span(classes: 'hof-cell-reason', [.text(p.reason)]),
          ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.hof-preview', {'display': 'flex', 'flex-direction': 'column', 'gap': '16px'}),
    rule('.hof-preview-head', {'display': 'flex', 'align-items': 'baseline', 'gap': '12px'}),
    rule('.hof-preview-head h2', {'flex': '1'}),
    rule('.hof-preview-grid', {'grid-template-columns': 'repeat(auto-fill,minmax(312px,1fr))'}),
    rule('.hof-cell', {
      'padding': '24px',
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '12px',
      'color': 'var(--ink)',
    }),
    rule('.hof-cell:hover', {'color': 'var(--ink)'}),
    rule('.hof-cell-name', {'font-size': '18px', 'font-weight': '600', 'letter-spacing': '-0.01em'}),
    rule('.hof-cell-reason', {
      'font-size': '14px',
      'line-height': '1.5',
      'color': 'var(--muted)',
      'text-wrap': 'pretty',
      'font': sans(14),
    }),
  ];
}
