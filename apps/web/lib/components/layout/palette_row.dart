import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../data/view.dart';
import '../../styles/css.dart';
import '../ui/project_logo.dart';
import 'palette_search.dart';

/// One palette result: logo (or initial), label and meta.
class PaletteRow extends StatelessComponent {
  const PaletteRow({required this.item, required this.index, required this.selected, required this.onHover, super.key});

  final PaletteItem item;

  /// Position in the flattened result list, for the staggered entrance.
  final int index;
  final bool selected;
  final void Function() onHover;

  @override
  Component build(BuildContext context) {
    final p = item.project;
    return a(
      href: item.href,
      classes: selected ? 'pal-item on' : 'pal-item',
      styles: Styles(
        raw: {'animation': 'fvItem .3s cubic-bezier(.2,.8,.2,1) ${80 + (index < 12 ? index : 12) * 30}ms both'},
      ),
      events: {'mouseenter': (_) => onHover()},
      [
        if (p != null)
          ProjectLogo(initials: p.initials, color: p.logoColor, imageUrl: p.avatarUrl, size: 28)
        else
          div(classes: 'pal-tile', [.text(item.label.isEmpty ? '' : item.label[0].toUpperCase())]),
        span(classes: 'pal-label', [.text(item.label)]),
        span(classes: 'pal-meta', [.text(item.meta)]),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    rule('.pal-item', {
      'transition': 'background .15s',
      'display': 'flex',
      'align-items': 'center',
      'gap': '14px',
      'padding': '10px 12px',
      'border-radius': '2px',
      'cursor': 'pointer',
      'color': 'var(--ink)',
    }),
    rule('.pal-item.on', {'background': 'var(--surface2)'}),
    rule('.pal-item:hover', {'color': 'var(--ink)'}),
    rule('.pal-tile', {
      'width': '28px',
      'height': '28px',
      'border-radius': '2px',
      'background': 'var(--surface2)',
      'color': 'var(--muted)',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'font': mono(11, weight: 600),
      'flex-shrink': '0',
    }),
    rule('.pal-label', {
      'flex': '1',
      'min-width': '0',
      'font-size': '15px',
      'font-weight': '500',
      'white-space': 'nowrap',
      'overflow': 'hidden',
      'text-overflow': 'ellipsis',
    }),
    rule('.pal-meta', {'font': mono(12), 'color': 'var(--muted)', 'white-space': 'nowrap'}),
  ];
}

/// Example queries shown before the user types.
class PaletteSuggestions extends StatelessComponent {
  const PaletteSuggestions({required this.onPick, super.key});

  final void Function(String) onPick;

  @override
  Component build(BuildContext context) {
    return div(classes: 'pal-try', [
      span(classes: 'eyebrow', [.text('Try')]),
      div(classes: 'pal-try-list', [
        for (final (n, q) in paletteSuggestions.indexed)
          button(
            type: ButtonType.button,
            styles: Styles(raw: {'animation': 'fvItem .3s cubic-bezier(.2,.8,.2,1) ${60 + n * 30}ms both'}),
            onClick: () => onPick(q),
            [.text(q)],
          ),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.pal-try', {'padding': '8px 16px', 'display': 'flex', 'flex-direction': 'column', 'gap': '8px'}),
    rule('.pal-try-list', {'display': 'flex', 'flex-wrap': 'wrap', 'gap': '8px'}),
    rule('.pal-try-list button', {
      'font-size': '14px',
      'padding': '4px 10px',
      'border': '1px solid var(--line)',
      'border-radius': '2px',
      'cursor': 'pointer',
      'background': 'transparent',
      'color': 'var(--ink)',
    }),
    rule('.pal-try-list button:hover', {'border-color': 'var(--ink)'}),
  ];
}
