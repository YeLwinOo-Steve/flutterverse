import 'dart:math' as math;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../styles/css.dart';
import 'intro_controller.dart';
import 'intro_logo.dart';

/// The once-per-session loading splash: the logo assembles, the wordmark
/// rises, then the screen irises out. Click to skip. Hidden before paint on
/// later page loads by `themeBootScript`.
///
/// Deliberately not an island: hydration re-inserts nodes it can't line up
/// with the pretty-printed server markup, and re-inserting an element
/// restarts its CSS animations, so the splash would play twice. The markup
/// stays static and [IntroController] drives it.
class IntroSplash extends StatelessComponent {
  const IntroSplash({super.key});

  @css
  static List<StyleRule> get styles => [
    rule('html[data-intro-seen] .intro', {'display': 'none'}),
    rule('.intro', {
      'position': 'fixed',
      'inset': '0',
      'z-index': '200',
      'background': 'var(--bg)',
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'center',
      'justify-content': 'center',
      'gap': '26px',
      'cursor': 'pointer',
      'overflow': 'hidden',
      'clip-path': 'circle(150vmax at 50% 44%)',
    }),
    rule('.intro.out', {'animation': 'fvOut .7s cubic-bezier(.7,0,.25,1) forwards'}),
    rule('.intro-stars', {'position': 'absolute', 'inset': '0', 'pointer-events': 'none'}),
    rule('.intro-stars span', {
      'position': 'absolute',
      'border-radius': '50%',
      'background': 'var(--ink)',
      'opacity': '.12',
    }),
    rule('.intro-body', {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'center',
      'gap': '26px',
      'position': 'relative',
    }),
    rule('.intro.out .intro-body', {'animation': 'fvShrink .5s ease-in forwards'}),
    rule('.intro-float', {'animation': 'fvFloat 3.2s ease-in-out 2s infinite'}),
    rule('.intro-word', {
      'font-size': '36px',
      'font-weight': '600',
      'letter-spacing': '-0.03em',
      'color': 'var(--ink)',
      'line-height': '1',
      'overflow': 'hidden',
      'padding': '2px 0 4px',
    }),
    rule('.intro-word span', {'display': 'inline-block', 'opacity': '0'}),
    rule('.intro-status', {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'center',
      'gap': '12px',
      'opacity': '0',
      'animation': 'fvFade .4s ease .6s forwards',
    }),
    rule('.intro-ticker', {
      'height': '1.6em',
      'overflow': 'hidden',
      'font': mono(11),
      'letter-spacing': '0.08em',
      'text-transform': 'uppercase',
      'color': 'var(--muted)',
      'line-height': '1.6em',
    }),
    rule('.intro-ticker > div', {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'center',
      'animation': 'fvTick 2.2s ease-in-out .6s forwards',
    }),
    rule('.intro-track', {
      'width': '168px',
      'height': '2px',
      'background': 'var(--line)',
      'border-radius': '999px',
      'overflow': 'hidden',
    }),
    rule('.intro-track > div', {
      'width': '100%',
      'height': '100%',
      'background': 'var(--accent)',
      'transform-origin': 'left',
      'transform': 'scaleX(0)',
      'animation': 'fvBar 2.2s cubic-bezier(.4,0,.2,1) .3s forwards',
    }),
    rule('.intro-skip', {
      'position': 'absolute',
      'bottom': '28px',
      'font': mono(12, weight: 400),
      'color': 'var(--muted)',
      'opacity': '0',
      'animation': 'fvFade .4s ease 1.6s forwards',
    }),
  ];

  /// The design's deterministic star field.
  static final _stars = List.generate(54, (n) {
    double f(double x) {
      final v = math.sin(x) * 43758.5453;
      return v - v.floorToDouble();
    }

    return (
      x: f(n * 1.7 + 1) * 100,
      y: f(n * 3.1 + 7) * 100,
      size: 1 + (f(n * 5.3) * 2).round(),
      delay: f(n * 9.7) * 2.4,
    );
  });

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'intro',
      attributes: {'role': 'status', 'aria-label': 'Loading Flutterverse'},
      [
        div(
          classes: 'intro-stars',
          attributes: {'aria-hidden': 'true'},
          [
            for (final s in _stars)
              span(
                styles: Styles(
                  raw: {
                    'left': '${s.x}%',
                    'top': '${s.y}%',
                    'width': '${s.size}px',
                    'height': '${s.size}px',
                    'animation': 'fvTwinkle ${2.2 + s.delay}s ease-in-out ${s.delay}s infinite',
                  },
                ),
                [],
              ),
          ],
        ),
        div(classes: 'intro-body', [
          div(classes: 'intro-float', [const IntroLogo()]),
          div(classes: 'intro-word', [
            for (final (n, c) in 'flutterverse'.split('').indexed)
              span(
                styles: Styles(raw: {'animation': 'fvRise .5s cubic-bezier(.2,.8,.2,1) ${1.15 + n * 0.04}s forwards'}),
                [.text(c)],
              ),
          ]),
          div(classes: 'intro-status', [
            div(classes: 'intro-ticker', [
              div([
                for (final line in ['Fetching pub.dev scores', 'Counting GitHub stars', 'Plotting momentum'])
                  span([.text(line)]),
              ]),
            ]),
            div(classes: 'intro-track', [div([])]),
          ]),
        ]),
        span(classes: 'intro-skip', [.text('Click to skip')]),
        const IntroController(),
      ],
    );
  }
}
