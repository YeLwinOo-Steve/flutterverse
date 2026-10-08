import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/ui/badges.dart';
import '../../components/ui/icon.dart';
import '../../components/ui/icons.dart';
import '../../components/ui/project_logo.dart';
import '../../data/view.dart';
import '../../styles/css.dart';

/// Breadcrumb, identity, description, categories and outbound links.
class DetailHeader extends StatelessComponent {
  const DetailHeader({required this.row, required this.categories, super.key});

  final ProjectRow row;
  final Map<String, String> categories;

  @override
  Component build(BuildContext context) {
    final r = row;
    return Component.fragment([
      div(classes: 'crumbs', [
        a(href: '/projects', [.text(r.kindPlural)]),
        span([.text('/')]),
        span(classes: 'crumb-here', [.text(r.id)]),
      ]),
      section(classes: 'detail-head', [
        div(classes: 'detail-id', [
          ProjectLogo(initials: r.initials, color: r.logoColor, imageUrl: r.avatarUrl, size: 56),
          div(classes: 'detail-id-text', [
            div(classes: 'detail-title', [
              h1(classes: 'page-title', [.text(r.name)]),
              if (r.version != null) span(classes: 'detail-version', [.text('v${r.version}')]),
              healthPill(r),
              if (r.flutterFavorite) favoriteBadge(),
            ]),
            if (r.description != null) p(classes: 'detail-desc', [.text(r.description!)]),
            div(classes: 'detail-cats', [
              for (final c in r.categories)
                a(href: '/categories/$c', classes: 'detail-cat', [.text(categoryLabel(categories, c))]),
            ]),
          ]),
        ]),
        div(classes: 'detail-links', [
          if (r.repo != null) _link('https://github.com/${r.repo}', 'GitHub', const Icon(Icons.github, filled: true)),
          if (r.pub != null) ...[
            _link('https://pub.dev/packages/${r.pub}', 'pub.dev', span(classes: 'pub-favicon', [])),
            _link('https://pub.dev/documentation/${r.pub}/latest/', 'Docs', const Icon(Icons.book, strokeWidth: 1.4)),
          ],
        ]),
      ]),
    ]);
  }

  Component _link(String href, String label, Component icon) => a(
    href: href,
    classes: 'detail-link hover-border',
    target: Target.blank,
    attributes: {'rel': 'noopener'},
    [icon, .text(label)],
  );

  @css
  static List<StyleRule> get styles => [
    rule('.crumbs', {'font': mono(13, weight: 400), 'color': 'var(--muted)', 'display': 'flex', 'gap': '8px'}),
    rule('.crumbs a:hover', {'color': 'var(--ink)'}),
    rule('.crumb-here', {'color': 'var(--ink)'}),
    rule('.detail-head', {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'gap': '20px',
      'align-items': 'flex-start',
      'justify-content': 'space-between',
      'padding-bottom': '28px',
      'border-bottom': '1px solid var(--line)',
    }),
    rule('.detail-id', {
      'display': 'flex',
      'gap': '16px',
      'align-items': 'flex-start',
      'min-width': '0',
      'flex': '1 1 480px',
    }),
    rule('.detail-id-text', {'display': 'flex', 'flex-direction': 'column', 'gap': '8px', 'min-width': '0'}),
    rule('.detail-title', {'display': 'flex', 'align-items': 'baseline', 'gap': '12px', 'flex-wrap': 'wrap'}),
    rule('.detail-version', {'font': mono(14), 'color': 'var(--muted)'}),
    rule('.detail-desc', {'font-size': '16px', 'color': 'var(--muted)', 'line-height': '1.5', 'max-width': '640px'}),
    rule('.detail-cats', {'display': 'flex', 'flex-wrap': 'wrap', 'gap': '8px', 'margin-top': '2px'}),
    rule('.detail-cat', {
      'font-size': '13px',
      'padding': '4px 8px',
      'border': '1px solid var(--line)',
      'border-radius': '2px',
    }),
    rule('.detail-cat:hover', {'border-color': 'var(--ink)', 'color': 'var(--ink)'}),
    rule('.detail-links', {'display': 'flex', 'flex-wrap': 'wrap', 'gap': '8px'}),
    rule('.detail-link', {
      'height': '38px',
      'display': 'flex',
      'align-items': 'center',
      'gap': '8px',
      'padding': '0 14px 0 12px',
      'border': '1px solid var(--line)',
      'background': 'var(--surface)',
      'border-radius': '2px',
      'font-size': '14px',
      'font-weight': '500',
    }),
    rule('.pub-favicon', {
      'width': '16px',
      'height': '16px',
      'flex-shrink': '0',
      'display': 'block',
      'background': 'url(https://pub.dev/favicon.ico) center/contain no-repeat',
    }),
  ];
}
