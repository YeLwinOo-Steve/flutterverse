import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import '../../styles/css.dart';

/// The giant outlined wordmark; a spotlight follows the pointer and fills it.
@client
class FooterWatermark extends StatelessComponent {
  const FooterWatermark({super.key});

  static void _track(web.Event event, {String? radius}) {
    final e = event as web.MouseEvent;
    final el = e.currentTarget as web.HTMLElement;
    final r = el.getBoundingClientRect();
    el.style
      ..setProperty('--mx', '${e.x - r.left}px')
      ..setProperty('--my', '${e.y - r.top}px');
    if (radius != null) el.style.setProperty('--r', radius);
  }

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'watermark',
      attributes: {'aria-hidden': 'true'},
      [
        div(
          classes: 'watermark-inner',
          events: {
            'mousemove': _track,
            'mouseenter': (e) => _track(e, radius: '110px'),
            'mouseleave': (e) => (e.currentTarget as web.HTMLElement).style.setProperty('--r', '0px'),
          },
          [
            span(classes: 'wm-outline', [.text('flutterverse')]),
            span(classes: 'wm-fill', [.text('flutterverse')]),
          ],
        ),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    rule('.watermark', {
      'max-width': '1280px',
      'margin': '24px auto 0',
      'padding': '0 24px',
      'line-height': '0.78',
      'height': 'clamp(64px,13vw,170px)',
      'overflow': 'hidden',
    }),
    rule('.watermark-inner', {
      'position': 'relative',
      'width': 'fit-content',
      '--r': '0px',
      '--mx': '50%',
      '--my': '50%',
    }),
    rule('.wm-outline, .wm-fill', {
      'display': 'block',
      'font-size': 'clamp(80px,16.2vw,214px)',
      'font-weight': '700',
      'letter-spacing': '-0.06em',
      'white-space': 'nowrap',
      'user-select': 'none',
    }),
    rule('.wm-outline', {'color': 'transparent', '-webkit-text-stroke': '1px rgba(232,244,255,0.28)'}),
    rule('.wm-fill', {
      'position': 'absolute',
      'left': '0',
      'top': '0',
      'color': '#54C5F8',
      '-webkit-text-stroke': '1px #54C5F8',
      'clip-path': 'circle(var(--r) at var(--mx) var(--my))',
      'transition': 'clip-path .35s cubic-bezier(.2,.8,.2,1)',
      'pointer-events': 'none',
    }),
  ];
}
