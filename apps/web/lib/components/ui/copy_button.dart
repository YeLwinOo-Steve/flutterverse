import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

import '../../data/track.dart';
import '../../styles/css.dart';
import 'icon.dart';
import 'icons.dart';

/// Copies [text] to the clipboard and says so for a moment. The smallest
/// island: everything around it stays static.
@client
class CopyButton extends StatefulComponent {
  const CopyButton({required this.text, this.label = 'Copy', this.event, super.key});

  final String text;
  final String label;

  /// A PostHog event to send on copy, such as `badge_copy`.
  final String? event;

  @override
  State<CopyButton> createState() => _CopyButtonState();

  @css
  static List<StyleRule> get styles => [
    rule('.copy-btn.done', {'border-color': 'var(--pos)', 'color': 'var(--pos)'}),
  ];
}

class _CopyButtonState extends State<CopyButton> {
  bool _done = false;
  Timer? _reset;

  void _copy() {
    web.window.navigator.clipboard.writeText(component.text).toDart.then((_) {
      setState(() => _done = true);
      _reset?.cancel();
      _reset = Timer(const Duration(seconds: 2), () => setState(() => _done = false));
      if (component.event case final e?) track(e);
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return button(
      classes: _done ? 'btn small copy-btn done' : 'btn small copy-btn',
      type: ButtonType.button,
      attributes: {'aria-live': 'polite'},
      onClick: _copy,
      [
        Icon(_done ? Icons.tick : Icons.code, size: 15),
        .text(_done ? 'Copied' : component.label),
      ],
    );
  }
}
