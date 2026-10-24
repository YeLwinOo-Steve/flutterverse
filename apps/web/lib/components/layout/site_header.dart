import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../styles/css.dart';
import '../ui/icon.dart';
import '../ui/icons.dart';
import 'brand_mark.dart';
import 'lamp.dart';
import 'nav_menu.dart';
import 'site_nav.dart';

/// The repository this site is built from.
const sourceUrl = 'https://github.com/YeLwinOo-Steve/flutterverse';

/// The sticky top bar.
class SiteHeader extends StatelessComponent {
  const SiteHeader({super.key});

  @override
  Component build(BuildContext context) {
    return header(classes: 'site-header', [
      div(classes: 'bar', [
        a(
          href: '/',
          classes: 'brand',
          attributes: {'aria-label': 'Flutterverse home'},
          [
            const BrandMark(),
            span([.text('flutterverse')]),
          ],
        ),
        div(classes: 'bar-divider', []),
        const SiteNav(),
        div(classes: 'bar-tools', [
          button(
            classes: 'search-trigger',
            attributes: {'data-open-palette': '', 'type': 'button', 'aria-label': 'Search packages'},
            [
              const Icon(Icons.search, size: 15),
              span(classes: 'search-text', [.text('Search packages…')]),
              span(classes: 'search-kbd', [.text('⌘K')]),
            ],
          ),
          a(
            href: sourceUrl,
            classes: 'icon-btn',
            target: Target.blank,
            attributes: {'rel': 'noopener', 'aria-label': 'Flutterverse on GitHub', 'title': 'Star on GitHub'},
            [const Icon(Icons.github, size: 18, filled: true)],
          ),
          const Lamp(),
        ]),
        const NavMenu(),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.site-header', {
      'position': 'sticky',
      'top': '0',
      'z-index': '20',
      'background': 'var(--bg)',
      'border-bottom': '1px solid var(--line)',
    }),
    rule('.site-header .bar', {
      'max-width': '1280px',
      'margin': '0 auto',
      'padding': '0 32px',
      'height': '64px',
      'display': 'flex',
      'align-items': 'center',
      'gap': '20px',
    }),
    rule('.brand', {'display': 'flex', 'align-items': 'center', 'gap': '13px', 'flex-shrink': '0'}),
    rule('.brand span', {
      'font-size': '18px',
      'font-weight': '600',
      'letter-spacing': '-0.03em',
      'color': 'var(--ink)',
    }),
    rule('.bar-divider', {
      'width': '1px',
      'height': '24px',
      'background': 'var(--line)',
      'flex-shrink': '0',
      'margin': '0 12px',
    }),
    rule('.bar-tools', {
      'display': 'flex',
      'gap': '8px',
      'align-items': 'center',
      'flex': '0 1 auto',
      'min-width': '0',
    }),
    rule('.search-trigger', {
      'width': '40px',
      'min-width': '0',
      'height': '38px',
      'display': 'flex',
      'align-items': 'center',
      'gap': '10px',
      'padding': '0 8px 0 12px',
      'border': '1px solid var(--line)',
      'background': 'var(--surface)',
      'color': 'var(--muted)',
      'border-radius': '2px',
      'cursor': 'pointer',
      'font-size': '14px',
    }),
    rule('.search-trigger:hover, .icon-btn:hover', {'border-color': 'var(--ink)'}),
    rule('.search-text', {
      'flex': '1',
      'min-width': '0',
      'text-align': 'left',
      'white-space': 'nowrap',
      'overflow': 'hidden',
      'text-overflow': 'ellipsis',
      'display': 'none',
    }),
    rule('.search-kbd', {
      'font': mono(12),
      'border': '1px solid var(--line)',
      'padding': '1px 6px',
      'border-radius': '2px',
      'display': 'none',
    }),
    above(1120, [
      rule('.search-trigger', {'width': '180px'}),
      rule('.search-text', {'display': 'block'}),
      rule('.search-kbd', {'display': 'inline'}),
    ]),
    above(1260, [
      rule('.search-trigger', {'width': '240px'}),
    ]),
    rule('.icon-btn', {
      'width': '38px',
      'height': '38px',
      'flex-shrink': '0',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'border': '1px solid var(--line)',
      'background': 'var(--surface)',
      'color': 'var(--ink)',
      'border-radius': '2px',
    }),
    below(720, [
      rule('.site-header .bar', {'padding': '0 16px', 'gap': '12px'}),
      rule('.bar-divider', {'display': 'none'}),
      rule('.brand span', {'display': 'none'}),
    ]),
    below(navBreakpoint, [
      rule('.bar-tools', {'margin-left': 'auto'}),
      // Ahead of the search button, so its rope hangs clear of the buttons
      // and the menu.
      rule('.bar-tools .lamp', {'order': '-1', 'margin-left': '0', 'margin-right': '12px'}),
    ]),
  ];
}
