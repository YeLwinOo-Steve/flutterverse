import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import '../../styles/css.dart';
import '../ui/icon.dart';

/// Pick an existing award category or create a new one; keyboard friendly.
class CategoryCombo extends StatelessComponent {
  const CategoryCombo({
    required this.categories,
    required this.query,
    required this.selected,
    required this.menuOpen,
    required this.highlight,
    required this.onQuery,
    required this.onPick,
    required this.onMenu,
    required this.onHighlight,
    super.key,
  });

  final List<String> categories;
  final String query;
  final String selected;
  final bool menuOpen;
  final int highlight;
  final void Function(String) onQuery;
  final void Function(String) onPick;
  final void Function(bool) onMenu;
  final void Function(int) onHighlight;

  List<String> get _options {
    final q = query.trim().toLowerCase();
    return [
      for (final c in categories)
        if (q.isEmpty || c.toLowerCase().contains(q)) c,
    ];
  }

  bool get _canCreate {
    final q = query.trim().toLowerCase();
    return q.isNotEmpty && !categories.any((c) => c.toLowerCase() == q);
  }

  void _key(web.KeyboardEvent e) {
    final opts = _options, total = opts.length + (_canCreate ? 1 : 0);
    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        onMenu(true);
        onHighlight((highlight + 1).clamp(0, total == 0 ? 0 : total - 1));
      case 'ArrowUp':
        e.preventDefault();
        onHighlight((highlight - 1).clamp(0, total == 0 ? 0 : total - 1));
      case 'Enter':
        e.preventDefault();
        if (highlight < opts.length) {
          onPick(opts[highlight]);
        } else if (_canCreate) {
          onPick(query.trim());
        }
    }
  }

  @override
  Component build(BuildContext context) {
    final opts = _options;
    final isNew = selected.isNotEmpty && !categories.contains(selected);
    return div(classes: 'field', [
      span(classes: 'field-label', [.text('Award category')]),
      div(
        classes: menuOpen ? 'combo open' : 'combo',
        events: {'click': (e) => e.stopPropagation()},
        [
          input<String>(
            value: query,
            attributes: {
              'placeholder': 'Search or create a category',
              'role': 'combobox',
              'aria-expanded': '$menuOpen',
            },
            onInput: onQuery,
            events: {
              'focus': (_) => onMenu(true),
              'keydown': (e) => _key(e as web.KeyboardEvent),
            },
          ),
          button(
            classes: 'combo-toggle',
            type: ButtonType.button,
            attributes: {'aria-label': 'Show categories'},
            onClick: () => onMenu(!menuOpen),
            [const Icon('M2.5 4.5 6 8l3.5-3.5', size: 12)],
          ),
        ],
      ),
      if (menuOpen)
        div(classes: 'combo-menu', attributes: {'role': 'listbox'}, events: {'click': (e) => e.stopPropagation()}, [
          for (final (i, c) in opts.indexed)
            div(
              classes: i == highlight ? 'combo-opt on' : 'combo-opt',
              attributes: {'role': 'option', 'aria-selected': '${c == selected}'},
              events: {'click': (_) => onPick(c), 'mouseenter': (_) => onHighlight(i)},
              [
                span([.text(c)]),
                span(classes: 'combo-meta', [.text(c == selected ? 'Selected' : '')]),
              ],
            ),
          if (_canCreate)
            div(
              classes: [
                'combo-opt create',
                if (highlight == opts.length) 'on',
                if (opts.isNotEmpty) 'sep',
              ].join(' '),
              events: {'click': (_) => onPick(query.trim()), 'mouseenter': (_) => onHighlight(opts.length)},
              [
                span(classes: 'combo-plus', [.text('+')]),
                span([
                  .text('Create “'),
                  b([.text(query.trim())]),
                  .text('”'),
                ]),
              ],
            ),
          if (opts.isEmpty && !_canCreate) div(classes: 'combo-none', [.text('Type to create a new category.')]),
        ]),
      if (selected.isNotEmpty)
        div(classes: 'combo-picked', [
          span(classes: 'pill soft', [.text(selected)]),
          .text(isNew ? 'New category — the editors will review it.' : 'Existing category'),
        ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.combo', {
      'display': 'flex',
      'align-items': 'center',
      'height': '44px',
      'border': '1px solid var(--line)',
      'background': 'var(--surface)',
      'border-radius': '2px',
    }),
    rule('.combo.open', {'border-color': 'var(--ink)'}),
    rule('.combo input', {
      'flex': '1',
      'min-width': '0',
      'height': '100%',
      'border': '0',
      'background': 'transparent',
      'color': 'var(--ink)',
      'padding': '0 12px 0 14px',
      'font-size': '15px',
      'outline': 'none',
    }),
    rule('.combo-toggle', {
      'width': '40px',
      'height': '100%',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'color': 'var(--muted)',
      'cursor': 'pointer',
      'background': 'none',
      'border': '0',
    }),
    rule('.combo-menu', {
      'position': 'absolute',
      'top': '72px',
      'left': '0',
      'right': '0',
      'z-index': '5',
      'background': 'var(--surface)',
      'border': '1px solid var(--line)',
      'border-radius': '2px',
      'box-shadow': '0 12px 32px rgba(4,43,89,0.14)',
      'max-height': '240px',
      'overflow-y': 'auto',
      'padding': '4px 0',
    }),
    rule('.combo-opt', {
      'display': 'flex',
      'justify-content': 'space-between',
      'align-items': 'center',
      'gap': '10px',
      'padding': '10px 14px',
      'font-size': '14px',
      'cursor': 'pointer',
    }),
    rule('.combo-opt.on', {'background': 'var(--surface2)'}),
    rule('.combo-opt.create', {'justify-content': 'flex-start'}),
    rule('.combo-opt.sep', {'border-top': '1px solid var(--line)'}),
    rule('.combo-opt b', {'font-weight': '600'}),
    rule('.combo-meta', {'font-size': '12px', 'color': 'var(--muted)'}),
    rule('.combo-plus', {'font-size': '16px', 'line-height': '1', 'color': 'var(--accent)'}),
    rule('.combo-none', {'padding': '10px 14px', 'font-size': '13px', 'color': 'var(--muted)'}),
    rule('.combo-picked', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '8px',
      'font-size': '12px',
      'color': 'var(--muted)',
    }),
    rule('.combo-picked .pill', {'padding': '3px 9px', 'font': mono(12)}),
  ];
}
