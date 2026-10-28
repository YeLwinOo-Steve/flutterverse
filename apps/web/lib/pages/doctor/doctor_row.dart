import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/ui/icon.dart';
import '../../components/ui/icons.dart';
import '../../data/verdict_view.dart';
import '../../data/view.dart';
import '../../styles/css.dart';
import 'doctor_data.dart';

/// One dependency: its verdict, the reasons, and alternatives when it needs
/// attention.
class DoctorRow extends StatelessComponent {
  const DoctorRow({required this.entry, super.key});

  final DoctorEntry entry;

  @override
  Component build(BuildContext context) {
    final e = entry;
    final reasons = e.result?.reasons ?? const <String>[];
    final note = statusNote(e);
    return li(classes: 'doc-row', [
      div(classes: 'doc-row-status', [statusPill(e.status)]),
      div(classes: 'doc-row-main', [
        div(classes: 'doc-row-name', [
          _name(e),
          if (e.dependency.kind == DependencyKind.dev) span(classes: 'pill', [.text('dev')]),
          if (e.result?.rising ?? false) risingTag(),
          if (e.row?.version case final v?) span(classes: 'doc-row-ver mono', [.text('v$v')]),
        ]),
        if (note != null)
          p(classes: 'doc-row-why', [.text(note)])
        else if (reasons.isNotEmpty)
          p(classes: 'doc-row-why', [.text(_sentence(reasons))]),
        if (e.alternatives.isNotEmpty) _Alternatives(e.alternatives),
      ]),
    ]);
  }

  static Component _name(DoctorEntry e) {
    if (e.row case final r?) return a(href: r.path, classes: 'doc-row-link', [.text(e.name)]);
    if (e.dependency.source != DependencySource.hosted) return span(classes: 'doc-row-link', [.text(e.name)]);
    return a(
      href: 'https://pub.dev/packages/${e.name}',
      classes: 'doc-row-link',
      target: Target.blank,
      attributes: {'rel': 'noopener', 'title': 'Open on pub.dev'},
      [.text(e.name), const Icon(Icons.arrowUp, size: 12, classes: 'doc-ext')],
    );
  }

  /// `slowing · last release 1.1y ago` → `Slowing · last release 1.1y ago`.
  static String _sentence(List<String> reasons) {
    final s = reasons.join(' · ');
    return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.doc-row', {
      'display': 'grid',
      'grid-template-columns': '132px 1fr',
      'gap': '16px',
      'padding': '16px 20px',
      'border-top': '1px solid var(--line)',
      'align-items': 'start',
    }),
    rule('.doc-row:first-child', {'border-top': '0'}),
    rule('.doc-row-status', {'padding-top': '1px'}),
    rule('.doc-row-main', {'display': 'flex', 'flex-direction': 'column', 'gap': '6px', 'min-width': '0'}),
    rule('.doc-row-name', {'display': 'flex', 'flex-wrap': 'wrap', 'align-items': 'center', 'gap': '8px'}),
    rule('.doc-row-link', {
      'display': 'inline-flex',
      'align-items': 'center',
      'gap': '4px',
      'font': mono(15, weight: 600),
      'word-break': 'break-all',
    }),
    rule('.doc-ext', {'transform': 'rotate(45deg)', 'color': 'var(--muted)'}),
    rule('.doc-row-ver', {'font-size': '12px', 'color': 'var(--muted)', 'margin-left': 'auto'}),
    rule('.doc-row-why', {'font-size': '14px', 'color': 'var(--muted)', 'line-height': '1.5'}),
    rule('.doc-alt', {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'align-items': 'center',
      'gap': '6px 8px',
      'margin-top': '4px',
      'font-size': '13px',
    }),
    rule('.doc-alt > span:first-child', {'color': 'var(--muted)'}),
    rule('.doc-alt a', {
      'display': 'inline-flex',
      'align-items': 'center',
      'gap': '6px',
      'padding': '4px 10px 4px 8px',
      'border': '1px solid var(--line)',
      'border-radius': '999px',
      'background': 'var(--surface)',
      'font': mono(12),
    }),
    rule('.doc-alt a:hover', {'border-color': 'var(--ink)', 'color': 'var(--ink)'}),
    rule('.doc-alt-dot', {'width': '7px', 'height': '7px', 'border-radius': '50%', 'background': 'var(--line)'}),
    rule('.doc-alt-dot.healthy', {'background': 'var(--accent)'}),
    rule('.doc-alt-dot.stable', {'background': 'var(--stable-ink)'}),
    rule('.doc-alt small', {'font-size': '11px', 'color': 'var(--muted)'}),
    below(640, [
      rule('.doc-row', {'grid-template-columns': '1fr', 'gap': '8px', 'padding': '14px 16px'}),
      rule('.doc-row-ver', {'margin-left': '0'}),
    ]),
  ];
}

class _Alternatives extends StatelessComponent {
  const _Alternatives(this.alternatives);

  final List<Alternative> alternatives;

  @override
  Component build(BuildContext context) {
    return div(classes: 'doc-alt', [
      span([.text('Consider')]),
      for (final alt in alternatives)
        a(
          href: alt.row?.path ?? 'https://pub.dev/packages/${alt.name}',
          target: alt.row == null ? Target.blank : null,
          attributes: {
            if (alt.row == null) 'rel': 'noopener',
            'title': [
              if (alt.suggestedByPub) 'Suggested by pub.dev',
              if (alt.verdict?.verdict case final v?) v.label,
            ].join(' · '),
          },
          [
            span(classes: 'doc-alt-dot ${_dot(alt)}', []),
            .text(alt.name),
            if (alt.suggestedByPub) small([.text('pub.dev pick')]),
          ],
        ),
    ]);
  }

  static String _dot(Alternative alt) => switch (alt.verdict?.verdict) {
    Verdict.healthy => 'healthy',
    Verdict.stable => 'stable',
    _ => '',
  };
}
