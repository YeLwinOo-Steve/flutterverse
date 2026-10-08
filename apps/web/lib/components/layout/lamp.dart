import 'dart:async';
import 'dart:math' as math;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

import '../../styles/css.dart';
import 'lamp_rope.dart';

/// The pull-cord lamp that toggles dark mode. Click it, tug the bead, or
/// drag the bead down; Enter/Space work on the bead for keyboard users.
@client
class Lamp extends StatefulComponent {
  const Lamp({super.key});

  @override
  State<Lamp> createState() => _LampState();

  @css
  static List<StyleRule> get styles => [
    rule('.lamp', {
      'cursor': 'pointer',
      'position': 'relative',
      'width': '56px',
      'height': '64px',
      'flex-shrink': '0',
      'margin-left': '4px',
      'z-index': '1',
      'isolation': 'isolate',
      'user-select': 'none',
      '-webkit-user-select': 'none',
    }),
    rule('.lamp-cord', {
      'position': 'absolute',
      'left': '27px',
      'top': '-1px',
      'width': '2px',
      'height': '12px',
      'background': 'var(--ink)',
    }),
    rule('.lamp-shade', {
      'position': 'absolute',
      'left': '8px',
      'top': '10px',
      'display': 'block',
      'fill': 'var(--ink)',
    }),
    rule('.lamp-bulb', {
      'position': 'absolute',
      'left': '20px',
      'top': '32px',
      'width': '16px',
      'height': '9px',
      'border-radius': '0 0 16px 16px',
      'background': 'var(--line)',
      'transition': 'background .25s, box-shadow .35s',
    }),
    rule(':root[data-theme="dark"] .lamp-bulb', {
      'background': '#FFD966',
      'box-shadow':
          '0 0 6px 2px rgba(255,236,170,0.95), 0 0 18px 8px rgba(255,217,102,0.7), 0 8px 60px 26px rgba(255,200,80,0.35)',
    }),
    rule('.lamp-cone', {
      'position': 'absolute',
      'left': '-102px',
      'top': '26px',
      'filter': 'blur(6px)',
      'width': '260px',
      'height': '360px',
      'pointer-events': 'none',
      'z-index': '-1',
      'clip-path': 'polygon(44% 0, 56% 0, 100% 100%, 0 100%)',
      'background':
          'radial-gradient(ellipse 50% 70% at 50% 0%, rgba(255,214,110,0.28), rgba(255,214,110,0.08) 55%, rgba(255,214,110,0) 80%)',
      'opacity': '0',
      'transition': 'opacity .4s ease',
    }),
    rule(':root[data-theme="dark"] .lamp-cone', {'opacity': '1'}),
    rule('.lamp-rope', {
      'position': 'absolute',
      'left': '0',
      'top': '0',
      'overflow': 'visible',
      'pointer-events': 'none',
    }),
    rule('.lamp-rope path', {'fill': 'none', 'stroke': 'var(--muted)', 'stroke-width': '2', 'stroke-linecap': 'round'}),
    rule('.lamp-rope path.lamp-rope-hit', {
      'stroke': 'transparent',
      'stroke-width': '14',
      'pointer-events': 'stroke',
      'cursor': 'grab',
      'touch-action': 'none',
    }),
    rule('.lamp-bead', {
      'position': 'absolute',
      'width': '12px',
      'height': '12px',
      'border-radius': '50%',
      'background': 'var(--ink)',
      'cursor': 'grab',
      'touch-action': 'none',
      'outline': 'none',
    }),
    rule('.lamp-bead:focus-visible', {'box-shadow': '0 0 0 3px var(--accent-soft)'}),
  ];
}

class _LampState extends State<Lamp> {
  final _rope = LampRope();
  bool _dark = false;
  bool _dragging = false;
  (double, double)? _target;
  int? _frame;

  /// When the last drag or tap on the cord ended. The browser follows it
  /// with a `click` on the lamp, which must not count as a second tug.
  DateTime? _cordReleasedAt;
  JSFunction? _onMove, _onUp;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) _dark = web.document.documentElement?.getAttribute('data-theme') == 'dark';
  }

  @override
  void dispose() {
    if (_frame != null) web.window.cancelAnimationFrame(_frame!);
    _removeDragListeners();
    super.dispose();
  }

  void _animate() {
    if (_frame != null) return;
    void step(num _) {
      final settled = _rope.step(target: _target, dragging: _dragging);
      setState(() {});
      _frame = settled ? null : web.window.requestAnimationFrame(step.toJS);
    }

    _frame = web.window.requestAnimationFrame(step.toJS);
  }

  void _tug() {
    _rope.tug(math.Random());
    _animate();
    Timer(const Duration(milliseconds: 110), _flip);
  }

  void _flip() {
    final dark = !_dark;
    void apply() {
      _dark = dark;
      web.document.documentElement?.setAttribute('data-theme', dark ? 'dark' : 'light');
      try {
        web.window.localStorage.setItem('fv-theme', dark ? 'dark' : 'light');
      } catch (_) {}
    }

    final reduced = web.window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    final el = web.document.querySelector('.lamp');
    if (reduced || el == null) {
      setState(apply);
      return;
    }
    final rect = el.getBoundingClientRect();
    final x = rect.left + 28, y = rect.top + 36;
    final w = web.window.innerWidth, h = web.window.innerHeight;
    final radius = math.sqrt(math.pow(math.max(x, w - x), 2) + math.pow(math.max(y, h - y), 2));
    final web.ViewTransition transition;
    try {
      transition = web.document.startViewTransition((() => setState(apply)).toJS);
    } catch (_) {
      // View transitions are unsupported (e.g. Firefox before 2025).
      setState(apply);
      return;
    }
    transition.ready.toDart.then((_) {
      web.document.documentElement!.animate(
        {
              'clipPath': ['circle(0px at ${x}px ${y}px)', 'circle(${radius}px at ${x}px ${y}px)'],
            }.jsify()
            as JSObject?,
        {
              'duration': 500,
              'easing': 'cubic-bezier(.65,.05,.36,1)',
              'pseudoElement': '::view-transition-new(root)',
            }.jsify()
            as JSAny,
      );
    }, onError: (Object _) {});
  }

  void _onPointerDown(web.Event event) {
    final e = event as web.PointerEvent;
    e.preventDefault();
    e.stopPropagation();
    // `x`/`y`, not `clientX`/`clientY`: package:web types those as int, but
    // browsers report fractional pixels, which throws in debug builds.
    final x0 = e.x, y0 = e.y;
    var dx = 0.0, dy = 0.0;
    _dragging = true;
    _target = (LampRope.restX, LampRope.restY);
    _animate();
    _onMove = ((web.PointerEvent ev) {
      dx = (ev.x - x0).clamp(-30, 30).toDouble();
      dy = (ev.y - y0).clamp(-10, 50).toDouble();
      _target = (LampRope.restX + dx, LampRope.restY + dy);
    }).toJS;
    _onUp = ((web.PointerEvent _) {
      _removeDragListeners();
      _cordReleasedAt = DateTime.now();
      _dragging = false;
      _target = null;
      _animate();
      if (dx.abs() < 4 && dy.abs() < 4) {
        _tug();
      } else if (dx * dx + dy * dy > 12 * 12) {
        // Any real pull toggles on release, like a physical cord.
        _flip();
      }
    }).toJS;
    web.window.addEventListener('pointermove', _onMove);
    web.window.addEventListener('pointerup', _onUp);
  }

  void _removeDragListeners() {
    if (_onMove != null) web.window.removeEventListener('pointermove', _onMove);
    if (_onUp != null) web.window.removeEventListener('pointerup', _onUp);
    _onMove = _onUp = null;
  }

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'lamp',
      attributes: {'title': 'Click or pull the cord'},
      events: {
        'click': (_) {
          final released = _cordReleasedAt;
          if (released != null && DateTime.now().difference(released).inMilliseconds < 400) return;
          _tug();
        },
      },
      [
        span(classes: 'lamp-cord', []),
        svg(classes: 'lamp-shade', width: 40.px, height: 22.px, viewBox: '0 0 40 22', [
          path(d: 'M12 0h16l12 22H0z', []),
        ]),
        span(classes: 'lamp-cone', []),
        span(classes: 'lamp-bulb', []),
        svg(classes: 'lamp-rope', width: 56.px, height: 140.px, viewBox: '0 0 56 140', [
          path(d: _rope.path(), []),
          // A wide invisible stroke so the cord itself can be grabbed.
          path(d: _rope.path(), classes: 'lamp-rope-hit', events: {'pointerdown': _onPointerDown}, []),
        ]),
        span(
          classes: 'lamp-bead',
          styles: Styles(
            raw: {
              'left': '${(_rope.x - 6).toStringAsFixed(2)}px',
              'top': '${(_rope.y - 6).toStringAsFixed(2)}px',
              if (_dragging) 'cursor': 'grabbing',
            },
          ),
          attributes: {
            'role': 'switch',
            'tabindex': '0',
            'aria-checked': '$_dark',
            'aria-label': 'Pull to toggle dark mode',
            'title': 'Pull the cord',
          },
          events: {
            'pointerdown': _onPointerDown,
            'keydown': (e) {
              final key = (e as web.KeyboardEvent).key;
              if (key == 'Enter' || key == ' ') {
                e.preventDefault();
                _tug();
              }
            },
          },
          [],
        ),
      ],
    );
  }
}
