import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/layout/seo.dart';
import '../../components/ui/copy_button.dart';
import '../../components/ui/icon.dart';
import '../../components/ui/icons.dart';
import '../../data/verdict_view.dart';
import '../../styles/css.dart';

/// The README badge snippet for [package]. The address is permanent:
/// READMEs will link to it for years.
String badgeMarkdown(String package) {
  final endpoint = Uri.encodeComponent('$siteUrl/badge/$package.json');
  return '[![Flutterverse](https://img.shields.io/endpoint?url=$endpoint)]($siteUrl/p/$package)';
}

/// The package's Doctor verdict, its README badge and a way into Doctor.
class DoctorPanel extends StatelessComponent {
  const DoctorPanel({required this.package, required this.result, super.key});

  /// The pub.dev name.
  final String package;
  final VerdictResult result;

  @override
  Component build(BuildContext context) {
    final message = result.badgeMessage;
    return section(classes: 'panel dp', [
      div(classes: 'dp-head', [
        span([.text('Doctor verdict')]),
        verdictPill(result),
        if (result.rising) risingTag(),
      ]),
      if (result.reasons.isNotEmpty) p(classes: 'dp-why', [.text(result.reasons.join(' · '))]),
      if (message != null) ...[
        div(classes: 'dp-badge', [
          span(classes: 'dp-label', [.text('README badge')]),
          // Drawn here rather than loaded from Shields, so the preview never
          // depends on a third party or a deploy that hasn't happened yet.
          span(
            classes: 'dp-shield',
            attributes: {'aria-label': 'Badge preview: Flutterverse $message'},
            [
              span([.text('Flutterverse')]),
              span(styles: Styles(raw: {'background': '#${badgeColor(result)}'}), [.text(message)]),
            ],
          ),
        ]),
        div(classes: 'dp-snippet', [
          code(classes: 'mono', [.text(badgeMarkdown(package))]),
          CopyButton(text: badgeMarkdown(package), label: 'Copy Markdown', event: 'badge_copy'),
        ]),
      ],
      a(href: '/doctor', classes: 'dp-cta', [
        const Icon(Icons.pulse, size: 15),
        .text('Check your whole pubspec'),
        const Icon(Icons.chevronRight, size: 14),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.dp', {'display': 'flex', 'flex-direction': 'column'}),
    rule('.dp-head', {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'align-items': 'center',
      'gap': '8px',
      'padding': '16px 20px',
      'border-bottom': '1px solid var(--line)',
    }),
    rule('.dp-head > span:first-child', {'font-size': '15px', 'font-weight': '600', 'margin-right': 'auto'}),
    rule('.dp-why', {
      'padding': '14px 20px 0',
      'font-size': '13px',
      'line-height': '1.5',
      'color': 'var(--muted)',
    }),
    rule('.dp-why::first-letter', {'text-transform': 'uppercase'}),
    rule('.dp-badge', {'display': 'flex', 'align-items': 'center', 'gap': '12px', 'padding': '16px 20px 10px'}),
    rule('.dp-label', {'font-size': '13px', 'font-weight': '500', 'margin-right': 'auto'}),
    rule('.dp-shield', {
      'display': 'inline-flex',
      'font': "11px Verdana,Geneva,'DejaVu Sans',sans-serif",
      'color': '#fff',
      'border-radius': '3px',
      'overflow': 'hidden',
      'line-height': '20px',
    }),
    rule('.dp-shield > span', {'padding': '0 6px', 'text-shadow': '0 1px 0 rgba(1,1,1,.3)'}),
    rule('.dp-shield > span:first-child', {'background': '#555'}),
    rule('.dp-snippet', {
      'margin': '0 20px 16px',
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '8px',
    }),
    rule('.dp-snippet code', {
      'display': 'block',
      'padding': '10px 12px',
      'font-size': '11.5px',
      'line-height': '1.5',
      'background': 'var(--bg)',
      'border': '1px solid var(--line)',
      'border-radius': '2px',
      'word-break': 'break-all',
      'user-select': 'all',
    }),
    rule('.dp-snippet .copy-btn', {'justify-content': 'center'}),
    rule('.dp-cta', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '8px',
      'padding': '14px 20px',
      'border-top': '1px solid var(--line)',
      'font-size': '14px',
      'font-weight': '500',
      'color': 'var(--accent)',
    }),
    rule('.dp-cta .icon:last-child', {'margin-left': 'auto'}),
  ];
}
