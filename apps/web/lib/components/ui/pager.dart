import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import '../../styles/css.dart';
import 'icon.dart';
import 'icons.dart';

/// Page numbers under a long table: `‹ 1 … 4 5 6 … 120 ›`. [page] is
/// zero-based. Renders nothing for a single page.
class Pager extends StatelessComponent {
  const Pager({required this.page, required this.pages, required this.onPage, this.anchor, super.key});

  final int page;
  final int pages;
  final void Function(int page) onPage;

  /// A selector for where a new page starts, when not the top of the page.
  final String? anchor;

  @override
  Component build(BuildContext context) {
    if (pages <= 1) return const Component.empty();
    Component step(int to, String icon, String label) => button(
      classes: 'pager-step',
      type: ButtonType.button,
      disabled: to < 0 || to >= pages,
      attributes: {'aria-label': label},
      onClick: () => _go(to),
      [Icon(icon, size: 14, strokeWidth: 1.6)],
    );
    return nav(
      classes: 'pager',
      attributes: {'aria-label': 'Pages'},
      [
        step(page - 1, Icons.chevronLeft, 'Previous page'),
        for (final n in pagerItems(page, pages))
          if (n == null)
            span(classes: 'pager-gap', [.text('…')])
          else
            button(
              classes: n == page ? 'on' : null,
              type: ButtonType.button,
              attributes: {if (n == page) 'aria-current': 'page'},
              onClick: () => _go(n),
              [.text('${n + 1}')],
            ),
        step(page + 1, Icons.chevronRight, 'Next page'),
      ],
    );
  }

  /// Shows page [to] from its top: the pager sits under the table.
  void _go(int to) {
    onPage(to);
    if (!kIsWeb) return;
    final start = anchor == null ? null : web.document.querySelector(anchor!);
    if (start != null) {
      start.scrollIntoView(web.ScrollIntoViewOptions(block: 'start'));
    } else {
      web.window.scrollTo(web.ScrollToOptions(top: 0));
    }
  }

  @css
  static List<StyleRule> get styles => [
    rule('.pager', {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'justify-content': 'center',
      'align-items': 'center',
      'gap': '4px',
      'padding': '8px 0 4px',
    }),
    rule('.pager button', {
      'min-width': '36px',
      'height': '36px',
      'padding': '0 10px',
      'display': 'inline-flex',
      'align-items': 'center',
      'justify-content': 'center',
      'border': '1px solid var(--line)',
      'border-radius': '2px',
      'background': 'var(--surface)',
      'color': 'var(--ink)',
      'font': mono(13),
      'cursor': 'pointer',
    }),
    rule('.pager button:hover:not(:disabled)', {'border-color': 'var(--ink)'}),
    rule('.pager button.on', {'background': 'var(--ink)', 'border-color': 'var(--ink)', 'color': 'var(--bg)'}),
    rule('.pager button:disabled', {'opacity': '.4', 'cursor': 'default'}),
    rule('.pager-gap', {'min-width': '24px', 'text-align': 'center', 'color': 'var(--muted)'}),
  ];
}

/// The page numbers to show: the first, the last and the current one with a
/// neighbour each side; `null` marks a gap.
List<int?> pagerItems(int page, int pages) {
  final shown = {0, pages - 1, page - 1, page, page + 1}.where((n) => n >= 0 && n < pages).toList()..sort();
  return [
    for (final (i, n) in shown.indexed) ...[
      // A gap of one page shows that page rather than an ellipsis.
      if (i > 0 && n - shown[i - 1] == 2) n - 1 else if (i > 0 && n - shown[i - 1] > 2) null,
      n,
    ],
  ];
}
