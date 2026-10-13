import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../styles/css.dart';
import '../ui/icon.dart';
import '../ui/icons.dart';
import 'site_nav.dart';

/// Inline in `<head>`, so it works before hydration: Escape closes the menu,
/// and a page restored from the back/forward cache comes back with it closed.
const navBootScript = '''
(function(){function c(){var m=document.getElementById('nav-open');if(m)m.checked=false;}
addEventListener('keydown',function(e){if(e.key==='Escape')c();});
addEventListener('pageshow',function(e){if(e.persisted)c();});})();''';

/// The menu button and drop-down drawer that stand in for [SiteNav] below
/// [navBreakpoint].
///
/// Pure HTML and CSS: a hidden checkbox holds the open state and the button
/// and backdrop are its labels, so the menu works the moment the page paints,
/// before (or without) the client script. The open drawer locks page scroll.
class NavMenu extends StatelessComponent {
  const NavMenu({super.key});

  @override
  Component build(BuildContext context) {
    final current = navSection(context.url);
    return .fragment([
      input(
        type: InputType.checkbox,
        id: 'nav-open',
        classes: 'nav-check',
        attributes: {'aria-label': 'Menu', 'aria-controls': 'nav-drawer', 'autocomplete': 'off'},
      ),
      label(
        htmlFor: 'nav-open',
        classes: 'icon-btn nav-toggle',
        attributes: {'aria-hidden': 'true'},
        [
          Icon(Icons.menu, size: 18, classes: 'nav-icon-open'),
          Icon(Icons.close, size: 18, classes: 'nav-icon-close'),
        ],
      ),
      label(htmlFor: 'nav-open', classes: 'nav-backdrop', attributes: {'aria-hidden': 'true'}, []),
      nav(
        id: 'nav-drawer',
        classes: 'nav-drawer',
        attributes: {'aria-label': 'Primary'},
        [
          for (final item in navItems)
            a(
              href: item.path,
              classes: item.key == current ? 'on' : null,
              attributes: {if (item.key == current) 'aria-current': 'page'},
              [Icon(item.icon, size: 18), .text(item.label)],
            ),
        ],
      ),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    // Visually hidden but still focusable, so keyboards can toggle the menu.
    rule('.nav-check', {
      'position': 'absolute',
      'width': '1px',
      'height': '1px',
      'opacity': '0',
      'pointer-events': 'none',
    }),
    rule('.icon-btn.nav-toggle', {'display': 'none', 'cursor': 'pointer'}),
    rule('.nav-check:focus-visible + .nav-toggle', {'outline': '2px solid var(--accent)', 'outline-offset': '2px'}),
    rule('.nav-toggle .nav-icon-close, .nav-check:checked + .nav-toggle .nav-icon-open', {'display': 'none'}),
    rule('.nav-check:checked + .nav-toggle .nav-icon-close', {'display': 'block'}),
    rule('.nav-drawer, .nav-backdrop', {'display': 'none'}),
    below(navBreakpoint, [
      rule('.icon-btn.nav-toggle', {'display': 'flex'}),
      rule('html:has(.nav-check:checked)', {'overflow': 'hidden'}),
      rule('.nav-check:checked ~ .nav-backdrop', {
        'display': 'block',
        'position': 'fixed',
        'inset': '64px 0 0',
        'z-index': '19',
        'background': 'rgba(4,43,89,0.35)',
        'animation': 'fvFade .2s ease both',
      }),
      rule('.nav-check:checked ~ .nav-drawer', {
        'display': 'flex',
        'flex-direction': 'column',
        'position': 'fixed',
        'top': '64px',
        'left': '0',
        'right': '0',
        'z-index': '20',
        'max-height': 'calc(100dvh - 64px)',
        'overflow-y': 'auto',
        'padding': '8px 16px 16px',
        'background': 'var(--bg)',
        'border-bottom': '1px solid var(--line)',
        'box-shadow': '0 18px 40px rgba(4,43,89,0.18)',
        'animation': 'fvFade .2s ease both',
      }),
      rule('.nav-drawer a', {
        'display': 'flex',
        'align-items': 'center',
        'gap': '12px',
        'min-height': '48px',
        'padding': '0 12px',
        'font': sans(16, weight: 500),
        'color': 'var(--muted)',
        'border-radius': '2px',
      }),
      rule('.nav-drawer a + a', {'border-top': '1px solid var(--line)'}),
      rule('.nav-drawer a.on', {'color': 'var(--ink)', 'background': 'var(--surface2)'}),
      // The lamp and its pull cord hang over the open drawer.
      rule('.lamp', {'z-index': '21'}),
    ]),
  ];
}
