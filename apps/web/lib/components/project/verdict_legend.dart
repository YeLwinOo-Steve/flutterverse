import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../data/verdict_view.dart';
import '../../styles/css.dart';

/// What each Pubspec Doctor verdict means: under the tool and on the About
/// page, so the rules are published where people look for them.
class VerdictLegend extends StatelessComponent {
  const VerdictLegend({super.key});

  @override
  Component build(BuildContext context) {
    return section(
      classes: 'doc-legend',
      attributes: {'id': 'verdicts'},
      [
        h2([.text('How verdicts work')]),
        p(classes: 'muted', [
          .text(
            'The first rule that matches wins. The score is the share of judged direct dependencies that are Healthy '
            'or Stable; the grey states are left out of it. Verdicts never guess: missing data means no verdict.',
          ),
        ]),
        dl(classes: 'panel', [
          for (final s in DoctorStatus.values)
            div([
              dt([statusPill(s)]),
              dd([.text(statusMeaning(s))]),
            ]),
        ]),
        p(classes: 'muted', [
          risingTag(),
          .text(' marks Healthy or Stable packages with a momentum score of $risingMomentum or more.'),
        ]),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    rule('.doc-legend', {'display': 'flex', 'flex-direction': 'column', 'gap': '12px', 'scroll-margin-top': '88px'}),
    rule('.doc-legend h2', {'font-size': '20px', 'font-weight': '600', 'letter-spacing': '-0.01em'}),
    rule('.doc-legend > p', {'font-size': '14px', 'line-height': '1.5', 'max-width': '720px'}),
    rule('.doc-legend dl', {'margin': '0'}),
    rule('.doc-legend dl > div', {
      'display': 'grid',
      'grid-template-columns': '148px 1fr',
      'gap': '16px',
      'align-items': 'center',
      'padding': '12px 20px',
      'border-top': '1px solid var(--line)',
    }),
    rule('.doc-legend dl > div:first-child', {'border-top': '0'}),
    rule('.doc-legend dt, .doc-legend dd', {'margin': '0'}),
    rule('.doc-legend dd', {'font-size': '14px', 'line-height': '1.5'}),
    below(640, [
      rule('.doc-legend dl > div', {'grid-template-columns': '1fr', 'gap': '6px'}),
    ]),
  ];
}
