import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../styles/css.dart';
import '../ui/icon.dart';
import '../ui/icons.dart';
import 'nav_more.dart';

/// The bar's top-level destinations, in order.
const navPrimary = [
  (key: 'trending', label: 'Trending', path: '/rankings', icon: Icons.trending),
  (key: 'pub', label: 'pub.dev', path: '/pub', icon: Icons.box),
  (key: 'explore', label: 'Projects', path: '/projects', icon: Icons.layers),
  (key: 'jobs', label: 'Jobs', path: '/jobs', icon: Icons.briefcase),
  (key: 'doctor', label: 'Doctor', path: '/doctor', icon: Icons.pulse),
];

/// The destinations inside the bar's "More" dropdown.
const navMore = [
  (key: 'hof', label: 'Hall of Fame', path: '/hall-of-fame', icon: Icons.trophy),
  (key: 'roadmap', label: 'Roadmap', path: '/roadmap', icon: Icons.roadmap),
  (key: 'about', label: 'About', path: '/about', icon: Icons.info),
];

/// Every destination, for the mobile menu, which stays one flat list.
const navItems = [...navPrimary, ...navMore];

/// Below this width the bar's links collapse into the menu button.
const navBreakpoint = 960;

/// Which nav item a URL path belongs to.
String? navSection(String path) {
  if (path.startsWith('/rankings')) return 'trending';
  if (path.startsWith('/pub')) return 'pub';
  if (path.startsWith('/projects') || path.startsWith('/p/') || path.startsWith('/categories')) return 'explore';
  if (path.startsWith('/doctor')) return 'doctor';
  if (path.startsWith('/jobs')) return 'jobs';
  if (path.startsWith('/hall-of-fame')) return 'hof';
  if (path.startsWith('/roadmap')) return 'roadmap';
  if (path.startsWith('/about')) return 'about';
  return null;
}

/// The primary navigation: the [navPrimary] links, then [NavMore].
/// Below [navBreakpoint] the [NavMenu] drawer replaces it.
class SiteNav extends StatelessComponent {
  const SiteNav({super.key});

  @override
  Component build(BuildContext context) {
    final current = navSection(context.url);
    return nav(
      classes: 'site-nav',
      attributes: {'aria-label': 'Primary'},
      [
        for (final item in navPrimary)
          a(
            href: item.path,
            classes: item.key == current ? 'on' : null,
            attributes: {if (item.key == current) 'aria-current': 'page'},
            [Icon(item.icon), .text(item.label)],
          ),
        NavMore(current: current),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    rule('.site-nav', {
      'display': 'flex',
      'gap': '2px',
      'flex': '1',
      'min-width': '0',
      'align-items': 'center',
    }),
    // No overflow scroll or edge fade: they would clip the open More panel,
    // and six entries fit from the breakpoint up.
    rule('.site-nav a', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '7px',
      'font': sans(14, weight: 500),
      'padding': '6px 10px',
      'border-radius': '2px',
      'white-space': 'nowrap',
      'color': 'var(--muted)',
    }),
    rule('.site-nav .icon', {'flex-shrink': '0'}),
    rule('.site-nav a:hover', {'color': 'var(--ink)'}),
    rule('.site-nav a.on', {'color': 'var(--ink)', 'background': 'var(--surface2)'}),
    below(navBreakpoint, [
      rule('.site-nav', {'display': 'none'}),
    ]),
  ];
}
