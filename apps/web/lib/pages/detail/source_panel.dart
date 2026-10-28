import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/ui/copy_button.dart';
import '../../components/ui/icon.dart';
import '../../styles/css.dart';

/// One label/value fact with an icon.
typedef Fact = ({String icon, String label, String value});

/// A pub.dev or GitHub summary card in the detail sidebar.
class SourcePanel extends StatelessComponent {
  const SourcePanel({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.cta,
    required this.href,
    required this.ctaIcon,
    this.note,
    this.install,
    this.tiles = const [],
    this.rows = const [],
    this.topics = const [],
    super.key,
  });

  final String title;
  final String subtitle;

  /// The square mark left of the title.
  final Component badge;
  final String cta;
  final String href;
  final Component ctaIcon;
  final String? note;

  /// A shell command to add the package, shown with a copy button.
  final String? install;
  final List<Fact> tiles;
  final List<Fact> rows;
  final List<String> topics;

  @override
  Component build(BuildContext context) {
    return section(classes: 'src panel', [
      div(classes: 'src-head', [
        badge,
        div(classes: 'src-title', [
          span([.text(title)]),
          span(classes: 'src-sub', [.text(subtitle)]),
        ]),
      ]),
      if (note != null) div(classes: 'src-note', [.text(note!)]),
      if (install != null)
        div(classes: 'src-install', [
          code(classes: 'mono', [.text(install!)]),
          CopyButton(text: install!, event: 'install_copy', compact: true),
        ]),
      if (tiles.isNotEmpty)
        div(classes: 'src-tiles', [
          for (final t in tiles)
            div(classes: 'src-tile', [
              div(classes: 'src-tile-k', [
                Icon(t.icon, size: 14, strokeWidth: 1.4),
                span([.text(t.label)]),
              ]),
              span(classes: 'src-tile-v', [.text(t.value)]),
            ]),
        ]),
      div(classes: 'src-rows', [
        for (final r in rows)
          div(classes: 'src-row', [
            span(classes: 'src-row-icon', [Icon(r.icon, size: 14, strokeWidth: 1.4)]),
            span(classes: 'src-row-k', [.text(r.label)]),
            span(classes: 'src-row-v', [.text(r.value)]),
          ]),
      ]),
      if (topics.isNotEmpty)
        div(classes: 'src-topics', [
          span(classes: 'eyebrow', [.text('Topics')]),
          div(classes: 'src-topic-list', [
            for (final t in topics) span(classes: 'pill soft', [.text(t)]),
          ]),
        ]),
      div(classes: 'src-cta', [
        a(href: href, target: Target.blank, attributes: {'rel': 'noopener'}, [ctaIcon, .text(cta)]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.src', {'display': 'flex', 'flex-direction': 'column'}),
    rule('.src-head', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '10px',
      'padding': '16px 20px',
      'border-bottom': '1px solid var(--line)',
    }),
    rule('.src-title', {'display': 'flex', 'flex-direction': 'column', 'flex': '1', 'min-width': '0'}),
    rule('.src-title > span:first-child', {'font-size': '15px', 'font-weight': '600'}),
    rule('.src-sub', {
      'font-size': '12px',
      'color': 'var(--muted)',
      'white-space': 'nowrap',
      'overflow': 'hidden',
      'text-overflow': 'ellipsis',
    }),
    rule('.src-mark', {
      'width': '32px',
      'height': '32px',
      'border-radius': '2px',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'flex-shrink': '0',
    }),
    rule('.src-mark.gh', {'background': 'var(--ink)', 'color': 'var(--bg)'}),
    rule('.src-mark.pub', {
      'border': '1px solid var(--line)',
      'background': '#fff url(https://pub.dev/favicon.ico) center/20px no-repeat',
    }),
    rule('.src-note', {
      'padding': '14px 20px',
      'font-size': '13px',
      'color': 'var(--muted)',
      'border-bottom': '1px solid var(--line)',
      'line-height': '1.5',
    }),
    // The code and its copy button share one bordered box, on one line.
    rule('.src-install', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '4px',
      'margin': '14px 20px',
      'padding': '3px 3px 3px 12px',
      'background': 'var(--bg)',
      'border': '1px solid var(--line)',
      'border-radius': '2px',
    }),
    rule('.src-install code', {
      'flex': '1',
      'min-width': '0',
      'font-size': '12.5px',
      'white-space': 'nowrap',
      'overflow-x': 'auto',
      'user-select': 'all',
      'scrollbar-width': 'none',
    }),
    rule('.src-tiles', {
      'display': 'grid',
      'grid-template-columns': '1fr 1fr',
      'border-bottom': '1px solid var(--line)',
    }),
    rule('.src-tile', {'padding': '16px 20px', 'display': 'flex', 'flex-direction': 'column', 'gap': '6px'}),
    rule('.src-tile:nth-child(odd)', {'border-right': '1px solid var(--line)'}),
    rule('.src-tile:nth-child(-n+2)', {'border-bottom': '1px solid var(--line)'}),
    rule('.src-tile-k', {'display': 'flex', 'align-items': 'center', 'gap': '6px', 'color': 'var(--muted)'}),
    rule('.src-tile-k span', {'font-size': '12px'}),
    rule('.src-tile-v', {
      'font-size': '22px',
      'font-weight': '600',
      'letter-spacing': '-0.02em',
      'font-variant-numeric': 'tabular-nums',
    }),
    rule('.src-rows', {'display': 'flex', 'flex-direction': 'column', 'padding': '6px 0'}),
    rule('.src-row', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '10px',
      'padding': '9px 20px',
      'font-size': '14px',
    }),
    rule('.src-row-icon', {'color': 'var(--muted)', 'display': 'flex'}),
    rule('.src-row-k', {'color': 'var(--muted)', 'flex': '1'}),
    rule('.src-row-v', {'font-weight': '500', 'text-align': 'right'}),
    rule('.src-topics', {
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '8px',
      'padding': '14px 20px',
      'border-top': '1px solid var(--line)',
    }),
    rule('.src-topic-list', {'display': 'flex', 'flex-wrap': 'wrap', 'gap': '6px'}),
    rule('.src-cta', {'padding': '16px 20px', 'border-top': '1px solid var(--line)'}),
    rule('.src-cta a', {
      'height': '40px',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'gap': '8px',
      'border': '1px solid var(--line)',
      'border-radius': '2px',
      'font-size': '14px',
      'font-weight': '500',
    }),
    rule('.src-cta a:hover', {'border-color': 'var(--ink)', 'color': 'var(--ink)'}),
  ];
}
