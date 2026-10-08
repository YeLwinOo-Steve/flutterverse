import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

import '../../data/data_repo.dart';
import '../../styles/css.dart';
import 'palette_row.dart';
import 'palette_search.dart';

/// The ⌘K search palette. Opens on ⌘K/Ctrl+K, `/`, or a click on any
/// `[data-open-palette]` element; loads `index.json` on first open.
@client
class CommandPalette extends StatefulComponent {
  const CommandPalette({super.key});

  @override
  State<CommandPalette> createState() => _CommandPaletteState();

  @css
  static List<StyleRule> get styles => [
    rule('.pal-backdrop', {
      'position': 'fixed',
      'inset': '0',
      'z-index': '50',
      'background': 'rgba(4,43,89,0.35)',
      'animation': 'fvFade .2s ease both',
      'display': 'flex',
      'justify-content': 'center',
      'align-items': 'flex-start',
      'padding-top': '12vh',
    }),
    rule('.pal', {
      'animation': 'fvPop .32s cubic-bezier(.2,.9,.3,1.15) both',
      'transform-origin': '50% 0',
      'width': 'min(640px,92vw)',
      'background': 'var(--surface)',
      'border': '1px solid var(--line)',
      'border-radius': '2px',
      'box-shadow': '0 24px 60px rgba(4,43,89,0.22)',
      'display': 'flex',
      'flex-direction': 'column',
      'max-height': '70vh',
    }),
    rule('.pal-input', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '12px',
      'padding': '0 14px',
      'border-bottom': '1px solid var(--line)',
    }),
    rule('.pal-input input', {
      'flex': '1',
      'height': '50px',
      'border': '0',
      'outline': 'none',
      'background': 'transparent',
      'color': 'var(--ink)',
      'font-size': '16px',
    }),
    rule('.pal-slash', {'font': mono(14), 'color': 'var(--muted)'}),
    rule('.pal-kbd', {
      'font': mono(12),
      'border': '1px solid var(--line)',
      'padding': '1px 6px',
      'border-radius': '2px',
      'color': 'var(--muted)',
    }),
    rule('.pal-body', {'overflow-y': 'auto', 'padding': '6px 0'}),
    rule('.pal-group', {'padding': '10px 8px'}),
    rule('.pal-group-title', {'padding': '6px 12px 8px'}),
    rule('.pal-empty', {'padding': '28px 16px', 'text-align': 'center', 'font-size': '14px', 'color': 'var(--muted)'}),
    rule('.pal-foot', {
      'display': 'flex',
      'gap': '16px',
      'align-items': 'center',
      'padding': '8px 16px',
      'border-top': '1px solid var(--line)',
      'font': mono(12, weight: 400),
      'color': 'var(--muted)',
    }),
  ];
}

class _CommandPaletteState extends State<CommandPalette> {
  bool _open = false;
  String _query = '';
  int _selected = 0;
  IndexFile? _index;
  List<PaletteItem> _flat = const [];
  JSFunction? _onKey, _onClick;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    _onKey = _handleKey.toJS;
    _onClick = _handleClick.toJS;
    web.document.addEventListener('keydown', _onKey);
    web.document.addEventListener('click', _onClick);
  }

  @override
  void dispose() {
    if (_onKey != null) web.document.removeEventListener('keydown', _onKey);
    if (_onClick != null) web.document.removeEventListener('click', _onClick);
    super.dispose();
  }

  void _show() {
    setState(() {
      _open = true;
      _query = '';
      _selected = 0;
    });
    DataRepo.index().then((loaded) => setState(() => _index = loaded), onError: (Object _) {});
    Future<void>.delayed(
      Duration.zero,
      () => (web.document.querySelector('.pal-input input') as web.HTMLElement?)?.focus(),
    );
  }

  void _close() => setState(() => _open = false);

  void _go(String href) {
    _close();
    web.window.location.href = href;
  }

  /// The event's target as an element, or null (e.g. when it's `document`).
  static web.Element? _element(web.Event e) {
    final t = e.target;
    return t != null && t.isA<web.Element>() ? t as web.Element : null;
  }

  void _handleClick(web.MouseEvent e) {
    if (_element(e)?.closest('[data-open-palette]') != null) {
      e.preventDefault();
      _show();
    }
  }

  void _handleKey(web.KeyboardEvent e) {
    final tag = _element(e)?.tagName ?? '';
    if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() == 'k') {
      e.preventDefault();
      _open ? _close() : _show();
      return;
    }
    if (!_open && e.key == '/' && !const {'INPUT', 'SELECT', 'TEXTAREA'}.contains(tag)) {
      e.preventDefault();
      _show();
      return;
    }
    if (!_open) return;
    switch (e.key) {
      case 'Escape':
        _close();
      case 'ArrowDown':
        e.preventDefault();
        setState(() => _selected = (_selected + 1).clamp(0, _flat.isEmpty ? 0 : _flat.length - 1));
      case 'ArrowUp':
        e.preventDefault();
        setState(() => _selected = (_selected - 1).clamp(0, _flat.isEmpty ? 0 : _flat.length - 1));
      case 'Enter' when _selected < _flat.length:
        e.preventDefault();
        _go(_flat[_selected].href);
    }
  }

  @override
  Component build(BuildContext context) {
    if (!_open) return const Component.empty();
    final groups = _index == null ? <PaletteGroup>[] : paletteResults(_index!, _query);
    _flat = [for (final g in groups) ...g.items];
    var k = 0;

    return div(
      classes: 'pal-backdrop',
      events: {'click': (_) => _close()},
      [
        div(
          classes: 'pal',
          attributes: {'role': 'dialog', 'aria-modal': 'true', 'aria-label': 'Search'},
          events: {'click': (e) => e.stopPropagation()},
          [
            div(classes: 'pal-input', [
              span(classes: 'pal-slash', [.text('/')]),
              input<String>(
                value: _query,
                attributes: {
                  'placeholder': 'Search packages, repos, apps, categories, authors',
                  'aria-label': 'Search',
                },
                onInput: (v) => setState(() {
                  _query = v;
                  _selected = 0;
                }),
              ),
              span(classes: 'pal-kbd', [.text('esc')]),
            ]),
            div(classes: 'pal-body', [
              if (_query.trim().isEmpty)
                PaletteSuggestions(
                  onPick: (q) => setState(() {
                    _query = q;
                    _selected = 0;
                  }),
                ),
              for (final g in groups)
                div(classes: 'pal-group', [
                  div(classes: 'pal-group-title eyebrow', [.text(g.title)]),
                  for (final item in g.items)
                    () {
                      final idx = k++;
                      return PaletteRow(
                        item: item,
                        index: idx,
                        selected: idx == _selected,
                        onHover: () {
                          if (_selected != idx) setState(() => _selected = idx);
                        },
                      );
                    }(),
                ]),
              if (_query.trim().isNotEmpty && _index != null && _flat.isEmpty)
                div(classes: 'pal-empty', [.text('No matches for “$_query”.')]),
            ]),
            div(classes: 'pal-foot', [
              span([.text('↑↓ navigate')]),
              span([.text('↵ open')]),
              span([.text('esc close')]),
            ]),
          ],
        ),
      ],
    );
  }
}
