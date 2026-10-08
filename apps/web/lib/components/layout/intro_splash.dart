import 'dart:async';
import 'dart:math' as math;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import '../../styles/css.dart';

/// The once-per-session loading splash: the logo assembles, the wordmark
/// rises, then the screen irises out. Click to skip. Hidden before paint on
/// later page loads by `themeBootScript`.
@client
class IntroSplash extends StatefulComponent {
  const IntroSplash({super.key});

  @override
  State<IntroSplash> createState() => _IntroSplashState();

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
}

class _IntroSplashState extends State<IntroSplash> {
  bool _visible = true;
  bool _out = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    if (web.document.documentElement?.getAttribute('data-intro-seen') != null) {
      _visible = false;
      return;
    }
    try {
      web.window.sessionStorage.setItem('fv-intro', '1');
    } catch (_) {}
    final reduced = web.window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    _timer = Timer(Duration(milliseconds: reduced ? 500 : 2600), _end);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _end() {
    if (_out) return;
    _timer?.cancel();
    setState(() => _out = true);
    _timer = Timer(const Duration(milliseconds: 700), () => setState(() => _visible = false));
  }

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
    if (!_visible) return const Component.empty();
    return div(
      classes: _out ? 'intro out' : 'intro',
      attributes: {'role': 'status', 'aria-label': 'Loading Flutterverse'},
      events: {'click': (_) => _end()},
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
          div(classes: 'intro-float', [const RawText(_logo)]),
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
      ],
    );
  }

  /// The animated logo: the orbit draws, the Flutter shards fly in and the
  /// sun travels around the orbit.
  static const _logo =
      '<svg width="136" height="136" viewBox="-2 -2 36 36" style="display:block;overflow:visible" aria-hidden="true">'
      '<ellipse cx="16" cy="16.5" rx="15.5" ry="5.4" transform="rotate(-24 16 16.5)" pathLength="100" '
      'style="fill:none;stroke:var(--ink);stroke-width:1.3;opacity:.4;stroke-dasharray:100;stroke-dashoffset:100;'
      'animation:fvDraw .9s cubic-bezier(.6,0,.2,1) .1s forwards"/>'
      '<g transform="translate(6.3 4.5) scale(0.0646)">'
      '<path d="M300 171.43H185.72L85.73 271.44l57.12 57.13z" style="$_shardBase;fill:#47C5FB;--dx:380px;--dy:-90px;--r:35deg;animation:fvShard .75s cubic-bezier(.2,.9,.25,1.15) .5s forwards"/>'
      '<path d="M57.15 242.87L0 185.72 185.72 0H300z" style="$_shardBase;fill:#47C5FB;--dx:-400px;--dy:-310px;--r:-40deg;animation:fvShard .75s cubic-bezier(.2,.9,.25,1.15) .35s forwards"/>'
      '<path d="M142.85 328.57L185.72 371.44H300L200.01 271.44z" style="$_shardBase;fill:#00569E;--dx:120px;--dy:400px;--r:30deg;animation:fvShard .75s cubic-bezier(.2,.9,.25,1.15) .65s forwards"/>'
      '<path d="M85.71 271.44L142.85 214.3 200 271.44 142.85 328.57z" style="$_shardBase;fill:#00B5F8;--dx:-360px;--dy:300px;--r:-45deg;animation:fvShard .75s cubic-bezier(.2,.9,.25,1.15) .8s forwards"/>'
      '</g>'
      '<path d="M.5 16.5A15.5 5.4 0 0 0 31.5 16.5" transform="rotate(-24 16 16.5)" pathLength="100" '
      'style="fill:none;stroke:var(--ink);stroke-width:1.3;stroke-linecap:round;stroke-dasharray:100;'
      'stroke-dashoffset:100;animation:fvDraw .7s cubic-bezier(.6,0,.2,1) .95s forwards"/>'
      '<g transform="rotate(-24 16 16.5)"><circle r="2.3" cx="0" cy="0" style="fill:#FFC83D;opacity:0;'
      'animation:fvFade .25s ease .8s forwards">'
      '<animateMotion path="M30.42 14.6A15.5 5.4 0 1 1 1.58 18.4A15.5 5.4 0 1 1 30.42 14.6" dur="1.5s" '
      'begin="0.8s" fill="freeze" calcMode="spline" keyTimes="0;1" keyPoints="0;1" keySplines=".45 0 .15 1"/>'
      '</circle></g></svg>';

  static const _shardBase = 'opacity:0;transform-box:fill-box;transform-origin:center';
}
