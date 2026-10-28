import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

import '../../components/ui/icon.dart';
import '../../components/ui/icons.dart';
import '../../styles/css.dart';

/// The paste box and its toolbar. Stateless: the island owns the text.
class DoctorInput extends StatelessComponent {
  const DoctorInput({
    required this.text,
    required this.revision,
    required this.onInput,
    required this.onLoad,
    required this.onCheck,
    required this.onExample,
    required this.onClear,
    this.hint,
    this.error,
    this.busy = false,
    super.key,
  });

  final String text;

  /// Bumped when the text is replaced from outside the box (example, file,
  /// clear), so the textarea is rebuilt with it.
  final int revision;

  /// What the text was read as, such as `pubspec.yaml · 12 dependencies`.
  final String? hint;

  /// Why the text can't be read.
  final String? error;

  /// Package data is still loading after a check was asked for.
  final bool busy;
  final void Function(String) onInput;

  /// A file was opened: its text replaces the box's.
  final void Function(String) onLoad;
  final void Function() onCheck;
  final void Function() onExample;
  final void Function() onClear;

  @override
  Component build(BuildContext context) {
    final empty = text.trim().isEmpty;
    return section(classes: 'panel doc-input', [
      textarea(
        key: ValueKey(revision),
        id: 'doctor-text',
        classes: 'doc-text mono',
        rows: 12,
        spellCheck: SpellCheck.isFalse,
        placeholder: 'Paste a pubspec.yaml, a pubspec.lock, or package names such as “http, dio, provider”',
        attributes: {'aria-label': 'Your pubspec.yaml, pubspec.lock or package names', 'aria-describedby': 'doc-hint'},
        onInput: onInput,
        events: {'keydown': _onKey},
        [.text(text)],
      ),
      div(classes: 'doc-bar', [
        div(
          id: 'doc-hint',
          classes: error != null ? 'doc-hint bad' : 'doc-hint',
          attributes: {'aria-live': 'polite'},
          [
            if (error != null)
              .text(error!)
            else if (hint != null)
              .text(hint!)
            else ...[
              const Icon(Icons.shield, size: 14),
              .text('Checked in your browser. Nothing is uploaded.'),
            ],
          ],
        ),
        div(classes: 'doc-actions', [
          if (empty)
            button(classes: 'btn small', type: ButtonType.button, onClick: onExample, [.text('Try an example')])
          else
            button(classes: 'btn small', type: ButtonType.button, onClick: onClear, [.text('Clear')]),
          label(classes: 'btn small doc-file', [
            const Icon(Icons.folderAdd, size: 15),
            .text('Open file'),
            input<String>(
              type: InputType.file,
              attributes: {'accept': '.yaml,.yml,.lock,.txt', 'aria-label': 'Open a pubspec file'},
              events: {'change': _onFile},
            ),
          ]),
          button(
            classes: 'btn small primary doc-go',
            type: ButtonType.button,
            disabled: empty || error != null || busy,
            attributes: {'title': 'Check (⌘↵)'},
            onClick: onCheck,
            [
              if (busy) span(classes: 'doc-spin', []) else const Icon(Icons.pulse, size: 15),
              .text(busy ? 'Loading package data…' : 'Check dependencies'),
            ],
          ),
        ]),
      ]),
    ]);
  }

  void _onKey(web.Event e) {
    final k = e as web.KeyboardEvent;
    if (k.key == 'Enter' && (k.metaKey || k.ctrlKey)) {
      k.preventDefault();
      onCheck();
    }
  }

  void _onFile(web.Event e) {
    final target = e.target as web.HTMLInputElement;
    final file = target.files?.item(0);
    if (file == null) return;
    file.text().toDart.then((t) => onLoad(t.toDart), onError: (Object _) {});
    target.value = ''; // Picking the same file again still fires `change`.
  }

  @css
  static List<StyleRule> get styles => [
    rule('.doc-input', {'display': 'flex', 'flex-direction': 'column'}),
    rule('.doc-text', {
      'display': 'block',
      'width': '100%',
      'min-height': '260px',
      'resize': 'vertical',
      'border': '0',
      'border-bottom': '1px solid var(--line)',
      'background': 'transparent',
      'color': 'var(--ink)',
      'padding': '18px 20px',
      'font-size': '13.5px',
      'line-height': '1.6',
      'tab-size': '2',
      'outline': 'none',
    }),
    rule('.doc-text::placeholder', {'color': 'var(--muted)', 'opacity': '.8', 'font-family': "'Geist',sans-serif"}),
    rule('.doc-input:focus-within', {'border-color': 'var(--ink)', 'box-shadow': '0 0 0 3px var(--accent-soft)'}),
    rule('.doc-bar', {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'gap': '12px',
      'align-items': 'center',
      'justify-content': 'space-between',
      'padding': '12px 14px 12px 20px',
      'background': 'var(--bg)',
    }),
    rule('.doc-hint', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '8px',
      'font-size': '13px',
      'color': 'var(--muted)',
      'min-width': '0',
    }),
    rule('.doc-hint.bad', {'color': 'var(--neg)'}),
    rule('.doc-actions', {'display': 'flex', 'flex-wrap': 'wrap', 'gap': '8px'}),
    rule('.doc-file', {'position': 'relative', 'overflow': 'hidden'}),
    rule('.doc-file input', {'position': 'absolute', 'inset': '0', 'opacity': '0', 'cursor': 'pointer'}),
    rule('.doc-file:focus-within', {'border-color': 'var(--ink)'}),
    rule('.doc-go[disabled]', {'opacity': '.5', 'cursor': 'not-allowed', 'filter': 'none'}),
    rule('.doc-spin', {
      'width': '14px',
      'height': '14px',
      'border': '2px solid currentColor',
      'border-right-color': 'transparent',
      'border-radius': '50%',
      'animation': 'fvSpin .8s linear infinite',
    }),
    below(640, [
      rule('.doc-bar', {'padding': '12px'}),
      rule('.doc-actions', {'width': '100%'}),
      rule('.doc-go', {'flex': '1', 'justify-content': 'center'}),
    ]),
  ];
}
