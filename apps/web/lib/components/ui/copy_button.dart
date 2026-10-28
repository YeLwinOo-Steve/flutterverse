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
  const CopyButton({required this.text, this.label = 'Copy', this.event, this.compact = false, super.key});

  final String text;
  final String label;

  /// A PostHog event to send on copy, such as `badge_copy`.
  final String? event;

  /// A small, borderless button for inside a code block.
  final bool compact;

  @override
  State<CopyButton> createState() => _CopyButtonState();

  @css
  static List<StyleRule> get styles => [
    rule('.copy-btn.copied', {'border-color': 'var(--pos)', 'color': 'var(--pos)'}),
    rule('.copy-btn.compact', {
      'height': '28px',
      'padding': '0 8px',
      'gap': '6px',
      'font-size': '12.5px',
      'white-space': 'nowrap',
      'flex-shrink': '0',
      // Wide enough for "Copied", so the label change never shifts anything.
      'min-width': '80px',
      'justify-content': 'center',
      // Filled, so it reads as a button against the code block's background.
      'border-color': 'var(--line)',
      'background': 'var(--surface2)',
      'color': 'var(--ink)',
    }),
    rule('.copy-btn.compact:hover', {'border-color': 'var(--muted)', 'color': 'var(--ink)'}),
    rule('.copy-btn.compact.copied', {'border-color': 'var(--pos)', 'color': 'var(--pos)'}),
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
      classes: ['btn small copy-btn', if (component.compact) 'compact', if (_done) 'copied'].join(' '),
      type: ButtonType.button,
      attributes: {'aria-live': 'polite'},
      onClick: _copy,
      [
        Icon(_done ? Icons.tick : Icons.copy, size: component.compact ? 14 : 15),
        .text(_done ? 'Copied' : component.label),
      ],
    );
  }
}
