import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../styles/css.dart';

/// The home page's headline and search box.
class HomeHero extends StatelessComponent {
  const HomeHero({super.key});

  @override
  Component build(BuildContext context) {
    return section(classes: 'home-hero', [
      div(classes: 'home-hero-text', [
        h1([.text('Explore the Dart & Flutter ecosystem.')]),
        p(classes: 'lede', [
          .text("Discover what's trending, what's growing, and what people are building with Flutter."),
        ]),
      ]),
      button(
        classes: 'hero-search',
        type: ButtonType.button,
        attributes: {'data-open-palette': ''},
        [
          span(classes: 'hero-slash', [.text('/')]),
          span(classes: 'hero-placeholder', [.text('Search packages, repos, apps, authors…')]),
          span(classes: 'hero-kbd', [.text('⌘K')]),
        ],
      ),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.home-hero', {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'gap': '20px',
      'align-items': 'flex-end',
      'justify-content': 'space-between',
      'padding-bottom': '42px',
      'border-bottom': '1px solid var(--line)',
    }),
    rule('.home-hero-text', {'display': 'flex', 'flex-direction': 'column', 'gap': '12px', 'max-width': '640px'}),
    rule('.home-hero h1', {
      'font-size': '44px',
      'line-height': '1.08',
      'letter-spacing': '-0.03em',
      'font-weight': '600',
      'text-wrap': 'balance',
    }),
    rule('.hero-search', {
      'flex': '1 1 320px',
      'max-width': '460px',
      'height': '44px',
      'border': '1px solid var(--line)',
      'background': 'var(--surface)',
      'border-radius': '2px',
      'display': 'flex',
      'align-items': 'center',
      'gap': '12px',
      'padding': '0 12px',
      'cursor': 'text',
      'color': 'var(--muted)',
      'font-size': '15px',
      'text-align': 'left',
    }),
    rule('.hero-search:hover', {'border-color': 'var(--ink)'}),
    rule('.hero-slash', {'font': mono(14)}),
    rule('.hero-placeholder', {'flex': '1'}),
    rule('.hero-kbd', {
      'font': mono(12),
      'border': '1px solid var(--line)',
      'padding': '2px 6px',
      'border-radius': '2px',
    }),
    below(640, [
      rule('.home-hero h1', {'font-size': '34px'}),
    ]),
  ];
}
