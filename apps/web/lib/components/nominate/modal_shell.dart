import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../styles/css.dart';

/// A centered dialog over a dimmed backdrop; clicking outside closes it.
class ModalShell extends StatelessComponent {
  const ModalShell({
    required this.onClose,
    required this.children,
    this.width = 540,
    this.onBackgroundClick,
    super.key,
  });

  final void Function() onClose;
  final List<Component> children;
  final int width;

  /// Called for clicks inside the dialog (e.g. to close a dropdown).
  final void Function()? onBackgroundClick;

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'modal-backdrop',
      events: {'click': (_) => onClose()},
      [
        div(
          classes: 'modal',
          styles: Styles(raw: {'width': 'min(${width}px,100%)'}),
          attributes: {'role': 'dialog', 'aria-modal': 'true'},
          events: {
            'click': (e) {
              e.stopPropagation();
              onBackgroundClick?.call();
            },
          },
          children,
        ),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    rule('.modal-backdrop', {
      'position': 'fixed',
      'inset': '0',
      'z-index': '60',
      'background': 'rgba(4,43,89,0.35)',
      'display': 'flex',
      'justify-content': 'center',
      'align-items': 'center',
      'padding': '24px',
      'animation': 'fvFade .2s ease both',
    }),
    rule('.modal', {
      'background': 'var(--surface)',
      'border': '1px solid var(--line)',
      'border-radius': '2px',
      'box-shadow': '0 24px 60px rgba(4,43,89,0.22)',
      'display': 'flex',
      'flex-direction': 'column',
      'animation': 'fvPop .3s cubic-bezier(.2,.9,.3,1.15) both',
    }),
    rule('.modal-head', {
      'display': 'flex',
      'justify-content': 'space-between',
      'align-items': 'flex-start',
      'gap': '16px',
      'padding': '24px 24px 0',
    }),
    rule('.modal-title', {'display': 'flex', 'flex-direction': 'column', 'gap': '6px'}),
    rule('.modal-title b', {'font-size': '20px', 'font-weight': '600', 'letter-spacing': '-0.02em'}),
    rule('.modal-title span', {'font-size': '14px', 'color': 'var(--muted)', 'line-height': '1.5'}),
    rule('.modal-x', {
      'width': '34px',
      'height': '34px',
      'flex-shrink': '0',
      'border': '1px solid var(--line)',
      'background': 'var(--surface)',
      'color': 'var(--ink)',
      'border-radius': '2px',
      'cursor': 'pointer',
      'font-size': '16px',
      'line-height': '1',
    }),
    rule('.modal-body', {'padding': '24px', 'display': 'flex', 'flex-direction': 'column', 'gap': '20px'}),
    rule('.modal-foot', {
      'display': 'flex',
      'justify-content': 'flex-end',
      'gap': '8px',
      'padding': '16px 24px',
      'border-top': '1px solid var(--line)',
    }),
    rule('.modal-btn', {
      'height': '42px',
      'padding': '0 18px',
      'border': '1px solid var(--line)',
      'background': 'var(--surface)',
      'color': 'var(--ink)',
      'border-radius': '2px',
      'font-size': '14px',
      'font-weight': '500',
      'cursor': 'pointer',
    }),
    rule('.modal-btn.go', {'border': '0', 'background': 'var(--accent)', 'color': 'var(--accent-ink)'}),
    rule('.modal-btn.go:disabled, .modal-btn.go.off', {
      'background': 'var(--line)',
      'color': 'var(--muted)',
      'cursor': 'not-allowed',
    }),
    rule('.field', {'display': 'flex', 'flex-direction': 'column', 'gap': '6px', 'position': 'relative'}),
    rule('.field-label', {'font-size': '13px', 'font-weight': '500'}),
    rule('.field-label i', {'font-style': 'normal', 'font-weight': '400', 'color': 'var(--muted)'}),
    rule('.field-box', {
      'display': 'flex',
      'align-items': 'center',
      'height': '44px',
      'border': '1px solid var(--line)',
      'background': 'var(--surface)',
      'border-radius': '2px',
      'overflow': 'hidden',
    }),
    rule('.field-box:focus-within', {'border-color': 'var(--ink)'}),
    rule('.field-prefix', {
      'height': '100%',
      'display': 'flex',
      'align-items': 'center',
      'padding': '0 10px 0 14px',
      'font': mono(15, weight: 400),
      'color': 'var(--muted)',
      'background': 'var(--bg)',
      'border-right': '1px solid var(--line)',
      'user-select': 'none',
    }),
    rule('.field-box input', {
      'flex': '1',
      'min-width': '0',
      'height': '100%',
      'border': '0',
      'background': 'transparent',
      'color': 'var(--ink)',
      'padding': '0 12px',
      'font': mono(15, weight: 400),
      'outline': 'none',
    }),
    rule('.field textarea', {
      'border': '1px solid var(--line)',
      'background': 'var(--surface)',
      'color': 'var(--ink)',
      'border-radius': '2px',
      'padding': '12px 14px',
      'font': "400 15px/1.5 'Geist',sans-serif",
      'outline': 'none',
      'resize': 'vertical',
      'width': '100%',
    }),
    rule('.field textarea:focus', {'border-color': 'var(--ink)', 'box-shadow': '0 0 0 3px var(--accent-soft)'}),
    rule('.field-hint', {'font-size': '12px', 'color': 'var(--muted)'}),
    rule('.field-hint.bad', {'color': 'var(--neg)'}),
    rule('.done', {
      'padding': '40px 32px',
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'center',
      'gap': '14px',
      'text-align': 'center',
    }),
    rule('.done-mark', {
      'width': '52px',
      'height': '52px',
      'border-radius': '50%',
      'background': 'var(--accent-soft)',
      'color': 'var(--accent)',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
      'font-size': '24px',
      'font-weight': '600',
    }),
    rule('.done b', {'font-size': '20px', 'font-weight': '600', 'letter-spacing': '-0.02em'}),
    rule('.done span', {'font-size': '14px', 'color': 'var(--muted)', 'line-height': '1.5', 'max-width': '380px'}),
  ];
}

/// The dialog's title row with a close button.
Component modalHead(String title, String subtitle, void Function() onClose) => div(classes: 'modal-head', [
  div(classes: 'modal-title', [
    b([.text(title)]),
    span([.text(subtitle)]),
  ]),
  button(
    classes: 'modal-x',
    type: ButtonType.button,
    attributes: {'aria-label': 'Close'},
    onClick: onClose,
    [.text('×')],
  ),
]);

/// The confirmation shown after handing off to GitHub.
Component modalDone(String title, String message, void Function() onClose) => div(classes: 'done', [
  div(classes: 'done-mark', [.text('✓')]),
  b([.text(title)]),
  span([.text(message)]),
  button(classes: 'btn ink', type: ButtonType.button, onClick: onClose, [.text('Done')]),
]);

/// A link to a prefilled nomination issue form on the site's repository;
/// there's no backend, so nominations are triaged and reviewed as GitHub
/// issues. [fields] are keyed by the form's field ids in
/// `.github/ISSUE_TEMPLATE/<template>`.
String nominationIssueUrl(
  String repoUrl, {
  required String template,
  required String title,
  required Map<String, String> fields,
}) => Uri.parse(
  '$repoUrl/issues/new',
).replace(queryParameters: {'template': template, 'title': title, ...fields}).toString();
