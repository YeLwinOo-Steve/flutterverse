import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The splash's animated logo: the orbit draws, the Flutter shards fly in and
/// the sun travels once around the orbit.
///
/// Built from real elements rather than `RawText`: hydration re-creates raw
/// markup, which would restart every animation, while real elements are
/// adopted as they are. The orbit is CSS too (not SMIL `animateMotion`, whose
/// clock starts later than CSS's), so everything runs on one timeline.
class IntroLogo extends StatelessComponent {
  const IntroLogo({super.key});

  /// The orbit's tilt, center and radii, shared with `BrandMark`.
  static const _tilt = 'rotate(-24 16 16.5)';
  static const _rx = 15.5, _ry = 5.4;

  @override
  Component build(BuildContext context) => _el(
    'svg',
    attrs: {'width': '136', 'height': '136', 'viewBox': '-2 -2 36 36', 'aria-hidden': 'true'},
    style: {'display': 'block', 'overflow': 'visible'},
    [
      _el(
        'clipPath',
        attrs: {'id': 'fv-intro-near'},
        [
          // The near half of the orbit: below its major axis, in the tilted frame.
          _el('rect', attrs: {'x': '-4', 'y': '16.5', 'width': '40', 'height': '10'}, []),
        ],
      ),
      _el(
        'ellipse',
        attrs: {'cx': '16', 'cy': '16.5', 'rx': '$_rx', 'ry': '$_ry', 'transform': _tilt, 'pathLength': '100'},
        style: {..._stroke, 'opacity': '.4', 'animation': 'fvDraw .9s cubic-bezier(.6,0,.2,1) .1s forwards'},
        [],
      ),
      // The sun is drawn twice so it passes behind the shards on the far side:
      // once under them, and once over them clipped to the near half.
      _el('g', attrs: {'transform': _tilt}, [_sun()]),
      _el(
        'g',
        attrs: {'transform': 'translate(6.3 4.5) scale(0.0646)'},
        [
          _shard('M300 171.43H185.72L85.73 271.44l57.12 57.13z', '#47C5FB', (380, -90, 35), .5),
          _shard('M57.15 242.87L0 185.72 185.72 0H300z', '#47C5FB', (-400, -310, -40), .35),
          _shard('M142.85 328.57L185.72 371.44H300L200.01 271.44z', '#00569E', (120, 400, 30), .65),
          _shard('M85.71 271.44L142.85 214.3 200 271.44 142.85 328.57z', '#00B5F8', (-360, 300, -45), .8),
        ],
      ),
      _el(
        'path',
        attrs: {'d': 'M.5 16.5A15.5 5.4 0 0 0 31.5 16.5', 'transform': _tilt, 'pathLength': '100'},
        style: {..._stroke, 'stroke-linecap': 'round', 'animation': 'fvDraw .7s cubic-bezier(.6,0,.2,1) .95s forwards'},
        [],
      ),
      _el('g', attrs: {'transform': _tilt, 'clip-path': 'url(#fv-intro-near)'}, [_sun()]),
    ],
  );

  static const _stroke = {
    'fill': 'none',
    'stroke': 'var(--ink)',
    'stroke-width': '1.3',
    'stroke-dasharray': '100',
    'stroke-dashoffset': '100',
  };

  /// A shard that flies in from `(dx, dy)` while turning by `r` degrees.
  static Component _shard(String d, String fill, (int, int, int) from, double delay) {
    final (dx, dy, r) = from;
    return _el(
      'path',
      attrs: {'d': d},
      style: {
        'fill': fill,
        'opacity': '0',
        'transform-box': 'fill-box',
        'transform-origin': 'center',
        '--dx': '${dx}px',
        '--dy': '${dy}px',
        '--r': '${r}deg',
        'animation': 'fvShard .75s cubic-bezier(.2,.9,.25,1.15) ${delay}s forwards',
      },
      [],
    );
  }

  /// The sun, orbiting in the tilted frame. The ellipse is a circle squashed
  /// by `scale(1, ry/rx)`: an arm rotates (`fvOrbit`) inside the squash, and
  /// the sun counter-rotates (`fvOrbitBack`) and un-squashes so it stays round.
  static Component _sun() {
    const motion = '1.5s cubic-bezier(.45,0,.15,1) .8s both';
    const spin = {'transform-box': 'view-box', 'transform-origin': '0 0'};
    return _el(
      'g',
      attrs: {'transform': 'translate(16 16.5) scale(1 ${_ry / _rx})'},
      [
        _el(
          'g',
          style: {...spin, 'animation': 'fvOrbit $motion'},
          [
            _el(
              'g',
              attrs: {'transform': 'translate($_rx 0)'},
              [
                _el(
                  'g',
                  style: {...spin, 'animation': 'fvOrbitBack $motion'},
                  [
                    _el(
                      'circle',
                      attrs: {'r': '2.3', 'transform': 'scale(1 ${_rx / _ry})'},
                      style: {'fill': '#FFC83D', 'opacity': '0', 'animation': 'fvFade .25s ease .8s forwards'},
                      [],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static Component _el(
    String tag,
    List<Component> children, {
    Map<String, String> attrs = const {},
    Map<String, String> style = const {},
  }) => Component.element(
    tag: tag,
    attributes: attrs,
    styles: style.isEmpty ? null : Styles(raw: style),
    children: children,
  );
}
