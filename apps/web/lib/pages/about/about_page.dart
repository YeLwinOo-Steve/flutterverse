import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/ui/icon.dart';
import '../../components/ui/icons.dart';
import '../../styles/css.dart';

/// `/about`.
class AboutPage extends StatelessComponent {
  const AboutPage({super.key});

  static const _problems = [
    (
      '01',
      'Signals are scattered',
      'Stars live on GitHub, likes and points on pub.dev, apps in two stores. Nobody puts them side by side.',
    ),
    (
      '02',
      'Totals hide momentum',
      'A package with 10k stars can be fading while a 600-star newcomer takes off. Lifetime totals can’t tell you which.',
    ),
    (
      '03',
      'Great builders go unnoticed',
      'The people behind the packages everyone depends on rarely get the credit they deserve.',
    ),
  ];

  static const _pillars = [
    (
      Icons.trending,
      'Track momentum',
      'Daily snapshots turn raw counts into growth, trends and a single Momentum score.',
      'See trending →',
      '/rankings',
    ),
    (
      Icons.layers,
      'Map the ecosystem',
      'Every package and project, grouped by category and filterable by platform and health.',
      'Explore →',
      '/projects',
    ),
    (
      Icons.trophy,
      'Honor the builders',
      'A yearly Hall of Fame for the people and projects that shaped Flutter.',
      'Hall of Fame →',
      '/hall-of-fame',
    ),
  ];

  static const _principles = [
    (Icons.shield, 'No pay-to-rank', 'Rankings come from data. Nobody can buy a spot.'),
    (Icons.code, 'Open by default', 'Methods are documented and every number links back to its source.'),
    (Icons.people, 'Built with the community', 'Developers and projects are proposed by people like you.'),
  ];

  @override
  Component build(BuildContext context) {
    return div(classes: 'about', [
      section(classes: 'about-hero', [
        span(classes: 'eyebrow wide accent', [.text('Why Flutterverse exists')]),
        h1([.text("pub.dev tells you what a package is. We show you how it's doing.")]),
        p([
          .text(
            'Flutter has grown into an ecosystem of thousands of packages, apps and people. Flutterverse is the map: '
            "one place to see what's rising, what's healthy and who's building it.",
          ),
        ]),
      ]),
      section(classes: 'about-block', [
        span(classes: 'eyebrow wide', [.text('The problem')]),
        div(classes: 'cell-grid about-problems', [
          for (final (n, title, body) in _problems)
            div(classes: 'about-problem', [
              span(classes: 'about-num', [.text(n)]),
              span(classes: 'about-h', [.text(title)]),
              span(classes: 'about-p', [.text(body)]),
            ]),
        ]),
      ]),
      section(classes: 'about-block', [
        span(classes: 'eyebrow wide', [.text('What we do')]),
        div(classes: 'about-pillars', [
          for (final (icon, title, body, cta, href) in _pillars)
            a(href: href, classes: 'about-pillar hover-border', [
              div(classes: 'about-icon', [Icon(icon, size: 20, strokeWidth: 1.4)]),
              div(classes: 'about-pillar-text', [
                span(classes: 'about-pillar-title', [.text(title)]),
                span(classes: 'about-pillar-body', [.text(body)]),
              ]),
              span(classes: 'about-cta', [.text(cta)]),
            ]),
        ]),
      ]),
      section(classes: 'about-split', [
        div(classes: 'about-sources', [
          span(classes: 'eyebrow wide', [.text('Where the data comes from')]),
          span(classes: 'about-big', [.text('Public sources, snapshotted daily.')]),
          div(classes: 'about-chips', [
            for (final s in const ['GitHub API', 'pub.dev API', 'pub.dev scores', 'Community submissions'])
              span(classes: 'pill', [.text(s)]),
          ]),
          span(classes: 'about-p', [
            .text(
              'Momentum blends recent star growth, download trend, release cadence and commit activity, so new '
              'projects can outrank old giants.',
            ),
          ]),
        ]),
        div(classes: 'about-principles panel', [
          span(classes: 'eyebrow wide', [.text('Our principles')]),
          for (final (icon, title, body) in _principles)
            div(classes: 'about-principle', [
              div(classes: 'about-principle-icon', [Icon(icon, size: 20, strokeWidth: 1.4)]),
              div([
                span(classes: 'about-principle-title', [.text(title)]),
                span(classes: 'about-principle-body', [.text(body)]),
              ]),
            ]),
        ]),
      ]),
      section(classes: 'about-cta-band', [
        div([
          span(classes: 'about-big', styles: Styles(raw: {'line-height': '1.15'}), [
            .text("Know something we're missing?"),
          ]),
          span(classes: 'muted', [.text('Help us map the Flutter universe.')]),
        ]),
        div(classes: 'about-cta-buttons', [
          button(
            classes: 'btn',
            type: ButtonType.button,
            attributes: {'data-open-modal': 'propose-developer'},
            [.text('Propose a developer')],
          ),
          button(
            classes: 'btn',
            type: ButtonType.button,
            attributes: {'data-open-modal': 'propose-project'},
            [.text('Propose a project')],
          ),
        ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.about', {'display': 'flex', 'flex-direction': 'column', 'gap': '88px', 'padding-top': '24px'}),
    rule('.about-hero', {'display': 'flex', 'flex-direction': 'column', 'gap': '24px', 'max-width': '880px'}),
    rule('.about-hero h1', {
      'font-size': 'clamp(40px,6vw,72px)',
      'line-height': '1.02',
      'letter-spacing': '-0.04em',
      'font-weight': '600',
      'text-wrap': 'balance',
    }),
    rule('.about-hero p', {
      'font-size': '19px',
      'line-height': '1.55',
      'color': 'var(--muted)',
      'max-width': '640px',
      'text-wrap': 'pretty',
    }),
    rule('.about-block', {'display': 'flex', 'flex-direction': 'column', 'gap': '24px'}),
    rule('.about-problems', {'grid-template-columns': 'repeat(auto-fit,minmax(260px,1fr))'}),
    rule('.about-problem', {'display': 'flex', 'flex-direction': 'column', 'gap': '12px', 'padding': '28px'}),
    rule('.about-num', {'font': mono(13, weight: 600), 'color': 'var(--accent)'}),
    rule('.about-h', {'font-size': '20px', 'font-weight': '600', 'letter-spacing': '-0.02em'}),
    rule('.about-p', {'font-size': '15px', 'line-height': '1.55', 'color': 'var(--muted)'}),
    rule('.about-pillars', {'display': 'grid', 'grid-template-columns': '1fr', 'gap': '16px'}),
    above(760, [
      rule('.about-pillars', {'grid-template-columns': 'repeat(3,minmax(0,1fr))'}),
    ]),
    rule('.about-pillar', {
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '16px',
      'padding': '28px',
      'border': '1px solid var(--line)',
      'background': 'var(--surface)',
      'border-radius': '2px',
      'color': 'var(--ink)',
    }),
    rule('.about-pillar:hover', {'color': 'var(--ink)'}),
    rule('.about-icon', {
      'width': '44px',
      'height': '44px',
      'border-radius': '2px',
      'background': 'var(--accent-soft)',
      'color': 'var(--accent)',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
    }),
    rule('.about-pillar-text', {'display': 'flex', 'flex-direction': 'column', 'gap': '6px'}),
    rule('.about-pillar-title', {'font-size': '18px', 'font-weight': '600', 'letter-spacing': '-0.01em'}),
    rule('.about-pillar-body', {'font-size': '14px', 'line-height': '1.55', 'color': 'var(--muted)'}),
    rule('.about-cta', {'font-size': '14px', 'font-weight': '500', 'margin-top': 'auto'}),
    rule('.about-split', {
      'display': 'grid',
      'grid-template-columns': 'repeat(auto-fit,minmax(320px,1fr))',
      'gap': '48px',
      'align-items': 'start',
    }),
    rule('.about-sources', {'display': 'flex', 'flex-direction': 'column', 'gap': '20px'}),
    rule('.about-big', {'font-size': '28px', 'line-height': '1.2', 'font-weight': '600', 'letter-spacing': '-0.03em'}),
    rule('.about-chips', {'display': 'flex', 'flex-wrap': 'wrap', 'gap': '8px'}),
    rule('.about-chips .pill', {'font': mono(13), 'padding': '6px 12px'}),
    rule('.about-principles', {'display': 'flex', 'flex-direction': 'column', 'gap': '24px', 'padding': '32px'}),
    rule('.about-principle', {'display': 'flex', 'gap': '14px', 'align-items': 'flex-start'}),
    rule('.about-principle > div:last-child', {'display': 'flex', 'flex-direction': 'column', 'gap': '4px'}),
    rule('.about-principle-icon', {'color': 'var(--accent)', 'padding-top': '2px'}),
    rule('.about-principle-title', {'font-size': '16px', 'font-weight': '600'}),
    rule('.about-principle-body', {'font-size': '14px', 'line-height': '1.5', 'color': 'var(--muted)'}),
    rule('.about-cta-band', {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'gap': '24px',
      'align-items': 'center',
      'justify-content': 'space-between',
      'padding': '40px',
      'border-radius': '2px',
      'background': 'var(--accent-soft)',
    }),
    rule('.about-cta-band > div:first-child', {
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '8px',
      'max-width': '520px',
    }),
    rule('.about-cta-band .muted', {'font-size': '15px'}),
    rule('.about-cta-buttons', {'display': 'flex', 'flex-wrap': 'wrap', 'gap': '8px'}),
    rule('.about-cta-buttons .btn', {'padding': '0 18px'}),
  ];
}
