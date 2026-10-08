import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../styles/css.dart';

/// The "you are here" helicopter, tinted with the current line's color.
/// [flying] lifts it and spins the rotor while it moves between stops.
class Helicopter extends StatelessComponent {
  const Helicopter({
    required this.x,
    required this.y,
    required this.heading,
    required this.color,
    required this.flying,
    required this.vertical,
    required this.title,
    super.key,
  });

  final double x, y, heading;
  final String color;
  final bool flying, vertical;
  final String title;

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'heli',
      attributes: {'title': title},
      styles: Styles(
        raw: {
          'left': '${x}px',
          'top': '${y}px',
          'transform': 'translate(-38px,-24px) rotate(${heading.toStringAsFixed(1)}deg)${vertical ? ' scale(.8)' : ''}',
        },
      ),
      [
        span(
          classes: 'heli-shadow',
          styles: Styles(
            raw: {
              'opacity': flying ? '0.08' : '0.18',
              'transform':
                  'translate(-50%,-50%) translate(${flying ? 14 : 3}px,${flying ? 18 : 4}px) scale(${flying ? 1.15 : 0.9})',
            },
          ),
          [],
        ),
        RawText(
          '<svg width="64" height="48" viewBox="0 0 64 48" class="heli-body" '
          'style="transform:scale(${flying ? 1.4 : 1})">'
          '<path d="M6 24H30" style="fill:none;stroke:var(--ink);stroke-width:3;stroke-linecap:round"/>'
          '<path d="M10 24H24" style="fill:none;stroke:$color;stroke-width:3;stroke-linecap:round"/>'
          '<path d="M7.5 17.5V30.5" style="fill:none;stroke:var(--ink);stroke-width:1.6;stroke-linecap:round"/>'
          '<path d="M2 21.5 6 24 2 26.5" style="fill:none;stroke:var(--ink);stroke-width:1.6;stroke-linecap:round;stroke-linejoin:round"/>'
          '<path d="M26 18.5H44C52 18.5 57 21 57 24S52 29.5 44 29.5H26C24 29.5 23 27 23 24S24 18.5 26 18.5Z" '
          'style="fill:$color;stroke:var(--ink);stroke-width:1.4"/>'
          '<path d="M44 19.5C50 19.5 55.5 21.5 55.5 24S50 28.5 44 28.5C46 26.5 46 21.5 44 19.5Z" style="fill:var(--ink);opacity:0.85"/>'
          '<path d="M30 18.5V15.5M30 29.5V32.5M44 18.8V15.5M44 29.2V32.5M27 15.5H48M27 32.5H48" '
          'style="fill:none;stroke:var(--ink);stroke-width:1.3;stroke-linecap:round"/>'
          '<g style="transform-origin:38px 24px;animation:fvSpin ${flying ? '.18s' : '1.4s'} linear infinite">'
          '<circle cx="38" cy="24" r="23" style="fill:var(--ink);opacity:0.07"/>'
          '<path d="M15 24H61M38 1V47" style="fill:none;stroke:var(--ink);stroke-width:2.2;stroke-linecap:round;opacity:0.75"/>'
          '</g><circle cx="38" cy="24" r="2.6" style="fill:var(--surface);stroke:var(--ink);stroke-width:1.4"/></svg>',
        ),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    rule('.heli', {
      'position': 'absolute',
      'width': '64px',
      'height': '48px',
      'z-index': '4',
      'pointer-events': 'none',
      'transform-origin': '38px 24px',
      'transition':
          'left 1.6s cubic-bezier(.45,0,.25,1), top 1.6s cubic-bezier(.45,0,.25,1), transform .7s cubic-bezier(.45,0,.25,1)',
    }),
    rule('.heli-shadow', {
      'position': 'absolute',
      'left': '38px',
      'top': '24px',
      'width': '44px',
      'height': '20px',
      'border-radius': '50%',
      'background': 'var(--ink)',
      'filter': 'blur(3px)',
      'transition': 'all .7s cubic-bezier(.3,0,.2,1)',
    }),
    rule('.heli-body', {
      'display': 'block',
      'overflow': 'visible',
      'transform-origin': '38px 24px',
      'transition': 'transform .7s cubic-bezier(.3,0,.2,1)',
    }),
    rule('.mono-11', {'font': mono(11)}),
  ];
}
