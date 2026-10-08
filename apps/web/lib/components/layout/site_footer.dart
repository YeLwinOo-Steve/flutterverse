import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../styles/css.dart';
import 'back_to_top.dart';
import 'brand_mark.dart';
import 'footer_watermark.dart';

/// A headline number in the footer's stats strip.
typedef FooterStat = ({String value, String label});

/// The dark footer with links, live stats and the watermark.
class SiteFooter extends StatelessComponent {
  const SiteFooter({required this.stats, super.key});

  final List<FooterStat> stats;

  static const _columns = [
    (
      'Discover',
      [
        ('Trending', '/rankings', null),
        ('pub.dev packages', '/pub', null),
        ('Projects', '/projects', null),
        ('Categories', '/categories', null),
      ],
    ),
    (
      'Showcase',
      [('Hall of Fame', '/hall-of-fame', null), ('About', '/about', null)],
    ),
    (
      'Contribute',
      [
        ('Propose a developer', null, 'propose-developer'),
        ('Propose a project', null, 'propose-project'),
        ('Search  ⌘K', null, 'palette'),
      ],
    ),
  ];

  @override
  Component build(BuildContext context) {
    return footer(classes: 'site-footer', [
      div(classes: 'foot-wrap', [
        div(classes: 'foot-top', [
          div(classes: 'foot-brand', [
            div(classes: 'foot-logo', [
              const BrandMark(size: 34, ink: '#E8F4FF', dark: true),
              span([.text('flutterverse')]),
            ]),
            span(classes: 'foot-tagline', [.text('Discover, explore and understand the Dart & Flutter ecosystem.')]),
          ]),
          div(classes: 'foot-cols', [
            for (final (title, links) in _columns)
              div(classes: 'foot-col', [
                span(classes: 'foot-head', [.text(title)]),
                for (final (label, href, action) in links)
                  if (href != null)
                    a(href: href, [.text(label)])
                  else
                    button(
                      type: ButtonType.button,
                      attributes: {action == 'palette' ? 'data-open-palette' : 'data-open-modal': action!},
                      [.text(label)],
                    ),
              ]),
          ]),
        ]),
        div(classes: 'foot-stats', [
          for (final s in stats)
            span(classes: 'foot-stat', [
              b([.text(s.value)]),
              span([.text(s.label)]),
            ]),
          span(classes: 'spacer', []),
          span(classes: 'foot-head', [.text('Sources · GitHub API · pub.dev API · daily snapshots')]),
        ]),
        div(classes: 'foot-legal', [
          span([.text('© 2026 Flutterverse. Not affiliated with Google or the Flutter team.')]),
          span(classes: 'spacer', []),
          const BackToTop(),
        ]),
      ]),
      div(classes: 'made-with', [
        span([.text('Proudly made with')]),
        _credit('Jaspr', 'https://jaspr.site', 'jaspr.site'),
      ]),
      const FooterWatermark(),
    ]);
  }

  Component _credit(String name, String url, String domain) => a(
    href: url,
    target: Target.blank,
    attributes: {'rel': 'noopener'},
    [
      img(src: 'https://www.google.com/s2/favicons?domain=$domain&sz=64', alt: '', width: 16, height: 16),
      .text(name),
    ],
  );

  @css
  static List<StyleRule> get styles => [
    rule('.site-footer', {
      'background': 'var(--foot-bg)',
      'color': '#E8F4FF',
      'margin-top': '40px',
      'overflow': 'hidden',
      'position': 'relative',
    }),
    rule('.foot-wrap', {
      'max-width': '1280px',
      'margin': '0 auto',
      'padding': '72px 32px 0',
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '56px',
    }),
    rule('.foot-top', {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'gap': '48px',
      'justify-content': 'space-between',
      'align-items': 'flex-start',
    }),
    rule('.foot-brand', {
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '20px',
      'max-width': '420px',
      'flex': '1 1 320px',
    }),
    rule('.foot-logo', {'display': 'flex', 'align-items': 'center', 'gap': '12px'}),
    rule('.foot-logo span', {'font-size': '22px', 'font-weight': '600', 'letter-spacing': '-0.03em'}),
    rule('.foot-tagline', {
      'font-size': '28px',
      'line-height': '1.2',
      'font-weight': '600',
      'letter-spacing': '-0.03em',
      'text-wrap': 'balance',
    }),
    rule('.foot-cols', {
      'display': 'grid',
      'grid-template-columns': 'repeat(3,minmax(140px,auto))',
      'gap': '40px 56px',
    }),
    rule('.foot-col', {'display': 'flex', 'flex-direction': 'column', 'gap': '14px'}),
    rule('.foot-head', {
      'font': mono(11),
      'letter-spacing': '0.08em',
      'text-transform': 'uppercase',
      'color': '#7F9BBE',
    }),
    rule('.foot-col a, .foot-col button', {
      'font-size': '15px',
      'color': '#E8F4FF',
      'cursor': 'pointer',
      'width': 'fit-content',
      'background': 'none',
      'border': '0',
      'padding': '0',
      'text-align': 'left',
    }),
    rule('.foot-col a:hover, .foot-col button:hover, .to-top:hover, .made-with a:hover', {'color': '#54C5F8'}),
    rule('.foot-stats', {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'gap': '12px 32px',
      'align-items': 'center',
      'padding': '20px 0',
      'border-top': '1px solid rgba(232,244,255,0.12)',
      'border-bottom': '1px solid rgba(232,244,255,0.12)',
    }),
    rule('.foot-stat', {'display': 'flex', 'align-items': 'baseline', 'gap': '8px'}),
    rule('.foot-stat b', {'font-size': '22px', 'font-weight': '600', 'letter-spacing': '-0.02em', 'color': '#E8F4FF'}),
    rule('.foot-stat span', {'font-size': '13px', 'color': '#9AB3CF'}),
    rule('.site-footer .spacer', {'flex': '1'}),
    rule('.foot-legal', {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'gap': '12px 24px',
      'align-items': 'center',
      'font-size': '13px',
      'color': '#9AB3CF',
    }),
    rule('.to-top', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '6px',
      'color': '#E8F4FF',
      'background': 'none',
      'border': '0',
      'padding': '0',
      'cursor': 'pointer',
      'font-size': '13px',
    }),
    rule('.made-with', {
      'max-width': '1280px',
      'margin': '32px auto 0',
      'padding': '0 32px',
      'display': 'flex',
      'flex-wrap': 'wrap',
      'align-items': 'center',
      'justify-content': 'center',
      'gap': '8px',
      'font-size': '13px',
      'color': '#9AB3CF',
    }),
    rule('.made-with a', {
      'display': 'inline-flex',
      'align-items': 'center',
      'gap': '6px',
      'color': '#E8F4FF',
      'text-decoration': 'underline dashed',
      'text-underline-offset': '4px',
      'text-decoration-color': 'rgba(232,244,255,0.5)',
    }),
    rule('.made-with img', {'display': 'block', 'border-radius': '3px'}),
    below(640, [
      rule('.foot-wrap', {'padding': '56px 16px 0'}),
      rule('.foot-cols', {'grid-template-columns': 'repeat(2,minmax(120px,auto))'}),
    ]),
  ];
}
