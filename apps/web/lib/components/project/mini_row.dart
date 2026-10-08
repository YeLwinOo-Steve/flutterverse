import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../data/view.dart';
import '../../styles/css.dart';
import '../ui/project_logo.dart';

/// A compact project row for side lists: logo, name, description, value.
class MiniRow extends StatelessComponent {
  const MiniRow({required this.row, required this.value, super.key});

  final ProjectRow row;
  final String value;

  @override
  Component build(BuildContext context) {
    final r = row;
    return a(href: r.path, classes: 'mini-row hover-row', [
      ProjectLogo(initials: r.initials, color: r.logoColor, imageUrl: r.avatarUrl, size: 32),
      div(classes: 'mini-main', [
        span(classes: 'mini-name', [.text(r.name)]),
        span(classes: 'mini-sub', [.text(r.description ?? '')]),
      ]),
      span(classes: 'mini-val', [.text(value)]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.mini-row', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '12px',
      'padding': '10px 16px',
      'border-bottom': '1px solid var(--line)',
      'color': 'var(--ink)',
    }),
    rule('.mini-row:hover', {'color': 'var(--ink)'}),
    rule('.mini-main', {'flex': '1', 'min-width': '0', 'display': 'flex', 'flex-direction': 'column'}),
    rule('.mini-name', {'font-size': '14px', 'font-weight': '600'}),
    rule('.mini-sub', {
      'font-size': '13px',
      'color': 'var(--muted)',
      'white-space': 'nowrap',
      'overflow': 'hidden',
      'text-overflow': 'ellipsis',
    }),
    rule('.mini-val', {'font': mono(13), 'color': 'var(--pos)', 'white-space': 'nowrap'}),
  ];
}
