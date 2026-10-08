import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/project/mini_row.dart';
import '../../styles/css.dart';

/// A titled panel of [MiniRow]s with a "View all" link.
class SideList extends StatelessComponent {
  const SideList({required this.title, required this.items, required this.moreHref, this.emptyText, super.key});

  final String title;
  final List<(ProjectRow, String)> items;
  final String moreHref;

  /// Shown when there are no items, e.g. before enough history exists.
  final String? emptyText;

  @override
  Component build(BuildContext context) {
    return div(classes: 'side-list panel', [
      div(classes: 'side-head', [
        span([.text(title)]),
      ]),
      for (final (row, value) in items) MiniRow(row: row, value: value),
      if (items.isEmpty && emptyText != null) div(classes: 'side-empty', [.text(emptyText!)]),
      a(href: moreHref, classes: 'side-more', [.text('View all →')]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.side-head', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '8px',
      'padding': '12px 16px',
      'border-bottom': '1px solid var(--line)',
    }),
    rule('.side-head span', {'font-size': '15px', 'font-weight': '600', 'flex': '1'}),
    rule('.side-empty', {
      'padding': '14px 16px',
      'font-size': '13px',
      'color': 'var(--muted)',
      'border-bottom': '1px solid var(--line)',
    }),
    rule('.side-more', {
      'display': 'block',
      'padding': '10px 16px',
      'font-size': '13px',
      'font-weight': '500',
      'color': 'var(--muted)',
    }),
    rule('.side-more:hover', {'color': 'var(--ink)'}),
  ];
}
