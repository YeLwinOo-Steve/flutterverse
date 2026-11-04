import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../styles/css.dart';
import '../ui/icon.dart';
import '../ui/icons.dart';
import 'site_nav.dart';

/// The bar's "More" dropdown, holding [navMore].
///
/// A native `<details>` disclosure, not an ARIA menu, so it works before
/// hydration: Enter or Space toggles it and Tab walks the links. Closing on
/// Escape, outside clicks and back/forward restores is in `navBootScript`.
/// The summary takes the `on` style when the current page is inside.
class NavMore extends StatelessComponent {
  const NavMore({required this.current, super.key});

  /// The current page's [navSection] key.
  final String? current;

  @override
  Component build(BuildContext context) {
    final inside = navMore.any((item) => item.key == current);
    return details(classes: 'nav-more', [
      summary(classes: inside ? 'on' : null, [
        const Icon(Icons.grid),
        .text('More'),
        const Icon(Icons.chevronDown, size: 14, classes: 'nav-more-chev'),
      ]),
      div(classes: 'nav-more-panel', [
        for (final item in navMore)
          a(
            href: item.path,
            classes: item.key == current ? 'on' : null,
            attributes: {if (item.key == current) 'aria-current': 'page'},
            [Icon(item.icon), .text(item.label)],
          ),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.nav-more', {'position': 'relative'}),
    rule('.nav-more > summary', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '6px',
      'font': sans(14, weight: 500),
      'padding': '6px 10px',
      'border-radius': '2px',
      'white-space': 'nowrap',
      'color': 'var(--muted)',
      'cursor': 'pointer',
      'list-style': 'none',
      'user-select': 'none',
    }),
    rule('.nav-more > summary::-webkit-details-marker', {'display': 'none'}),
    rule('.nav-more > summary:hover, .nav-more[open] > summary', {'color': 'var(--ink)'}),
    rule('.nav-more > summary.on', {'color': 'var(--ink)', 'background': 'var(--surface2)'}),
    rule('.nav-more > summary:focus-visible', {'outline': '2px solid var(--accent)', 'outline-offset': '2px'}),
    rule('.nav-more .icon', {'flex-shrink': '0'}),
    rule('.nav-more-chev', {'transition': 'transform .15s ease'}),
    rule('.nav-more[open] .nav-more-chev', {'transform': 'rotate(180deg)'}),
    rule('.nav-more-panel', {
      'position': 'absolute',
      'top': 'calc(100% + 8px)',
      'left': '0',
      'z-index': '30',
      'min-width': '180px',
      'display': 'flex',
      'flex-direction': 'column',
      'padding': '6px',
      'background': 'var(--bg)',
      'border': '1px solid var(--line)',
      'border-radius': '2px',
      'box-shadow': '0 18px 40px rgba(4,43,89,0.18)',
      'animation': 'fvFade .15s ease both',
    }),
    rule('.nav-more-panel a', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '10px',
      'min-height': '38px',
      'padding': '0 10px',
      'font': sans(14, weight: 500),
      'color': 'var(--muted)',
      'border-radius': '2px',
      'white-space': 'nowrap',
    }),
    rule('.nav-more-panel a:hover', {'color': 'var(--ink)', 'background': 'var(--surface2)'}),
    rule('.nav-more-panel a.on', {'color': 'var(--ink)', 'background': 'var(--surface2)'}),
  ];
}
