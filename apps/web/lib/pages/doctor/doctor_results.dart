import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../styles/css.dart';
import 'doctor_data.dart';
import 'doctor_row.dart';
import 'doctor_summary.dart';

/// The whole report: summary, then direct dependencies by urgency, then the
/// transitive ones folded away.
class DoctorResults extends StatelessComponent {
  const DoctorResults({required this.report, required this.dataDate, required this.onShare, super.key});

  final DoctorReport report;
  final String dataDate;
  final void Function() onShare;

  @override
  Component build(BuildContext context) {
    final transitive = report.transitive;
    return div(
      id: 'doctor-report',
      classes: 'doc-results',
      attributes: {'tabindex': '-1'},
      [
        DoctorSummary(report: report, dataDate: dataDate, onShare: onShare),
        for (final g in reportGroups(report))
          section(classes: 'doc-group', [
            div(classes: 'doc-group-head', [
              h2([
                .text(g.title),
                span(classes: 'tabular', [.text(' ${g.entries.length}')]),
              ]),
              if (g.note != null) span(classes: 'muted', [.text(g.note!)]),
            ]),
            ul(classes: 'panel doc-list', [for (final e in g.entries) DoctorRow(entry: e)]),
          ]),
        if (transitive.isNotEmpty)
          details(classes: 'doc-trans', [
            summary([
              span([.text('Transitive dependencies')]),
              span(classes: 'tabular muted', [.text(' ${transitive.length}')]),
              span(classes: 'doc-trans-note muted', [
                .text(
                  'Pulled in by your packages, not scored. '
                  '${transitive.where((e) => e.status.needsAttention).length} need attention.',
                ),
              ]),
            ]),
            ul(classes: 'panel doc-list', [for (final e in transitive) DoctorRow(entry: e)]),
          ]),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    rule('.doc-results', {
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '28px',
      'outline': 'none',
      // Clears the sticky header when the report scrolls into view.
      'scroll-margin-top': '88px',
    }),
    rule('.doc-group', {'display': 'flex', 'flex-direction': 'column', 'gap': '12px'}),
    rule('.doc-group-head', {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'align-items': 'baseline',
      'gap': '6px 14px',
      'font-size': '13px',
    }),
    rule('.doc-group-head h2', {'font-size': '20px', 'font-weight': '600', 'letter-spacing': '-0.01em'}),
    rule('.doc-group-head h2 span', {'color': 'var(--muted)', 'font-weight': '500'}),
    rule('.doc-list', {'list-style': 'none', 'margin': '0', 'padding': '0'}),
    rule('.doc-trans', {'display': 'flex', 'flex-direction': 'column', 'gap': '12px'}),
    rule('.doc-trans summary', {
      'cursor': 'pointer',
      'font-size': '20px',
      'font-weight': '600',
      'letter-spacing': '-0.01em',
      'padding': '4px 0',
      'list-style-position': 'inside',
    }),
    rule('.doc-trans[open] summary', {'margin-bottom': '12px'}),
    rule('.doc-trans-note', {'font-size': '13px', 'font-weight': '400', 'margin-left': '14px', 'letter-spacing': '0'}),
  ];
}
