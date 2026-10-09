import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

/// Drives the static `IntroSplash` markup: ends it once its animation has
/// played (or on click), irises it out and removes it. Renders nothing.
@client
class IntroController extends StatefulComponent {
  const IntroController({super.key});

  @override
  State<IntroController> createState() => _IntroControllerState();
}

class _IntroControllerState extends State<IntroController> {
  web.Element? _intro;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    final intro = web.document.querySelector('.intro');
    if (intro == null || web.document.documentElement?.getAttribute('data-intro-seen') != null) {
      intro?.remove();
      return;
    }
    _intro = intro;
    try {
      web.window.sessionStorage.setItem('fv-intro', '1');
    } catch (_) {}
    intro.addEventListener('click', ((web.Event _) => _end()).toJS);
    // The animation started with the page, not with this script, so only
    // wait out what's left of it.
    final reduced = web.window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    final left = (reduced ? 500 : 2600) - web.window.performance.now();
    _timer = Timer(Duration(milliseconds: left.clamp(0, 2600).round()), _end);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _end() {
    final intro = _intro;
    if (intro == null || intro.classList.contains('out')) return;
    _timer?.cancel();
    intro.classList.add('out');
    _timer = Timer(const Duration(milliseconds: 700), () => intro.remove());
  }

  @override
  Component build(BuildContext context) => const Component.empty();
}
