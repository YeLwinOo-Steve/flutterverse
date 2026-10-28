import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/project/verdict_legend.dart';
import '../../styles/css.dart';
import 'doctor_tool.dart';

/// `/doctor`: Pubspec Doctor. The header and legend are static; only the
/// tool is an island.
class DoctorPage extends StatelessComponent {
  const DoctorPage({required this.now, required this.tracked, super.key});

  final DateTime now;

  /// How many published packages there are to judge against.
  final int tracked;

  @override
  Component build(BuildContext context) {
    return div(classes: 'doctor', [
      header(classes: 'doctor-head', [
        span(classes: 'eyebrow accent', [.text('Pubspec Doctor')]),
        h1(classes: 'page-title', [.text('How healthy are your dependencies?')]),
        p(classes: 'lede', [
          .text(
            'Paste a pubspec.yaml, a pubspec.lock or a list of package names. Each dependency gets a verdict from '
            'daily data on ${groupedNumber(tracked)} pub.dev packages, with the reasons behind it.',
          ),
        ]),
      ]),
      DoctorTool(now: now.toIso8601String()),
      const VerdictLegend(),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.doctor', {'display': 'flex', 'flex-direction': 'column', 'gap': '32px', 'max-width': '960px'}),
    rule('.doctor-head', {'display': 'flex', 'flex-direction': 'column', 'gap': '12px', 'max-width': '720px'}),
    below(640, [
      rule('.doctor .page-title', {'font-size': '34px'}),
    ]),
  ];
}
