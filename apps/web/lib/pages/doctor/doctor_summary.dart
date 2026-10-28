import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/ui/icon.dart';
import '../../components/ui/icons.dart';
import '../../data/verdict_view.dart';
import '../../styles/css.dart';
import 'doctor_data.dart';

/// The project score, a bar of verdict counts and the share action.
class DoctorSummary extends StatelessComponent {
  const DoctorSummary({required this.report, required this.dataDate, required this.onShare, super.key});

  final DoctorReport report;

  /// When the data was collected, e.g. `Oct 10, 2026`.
  final String dataDate;
  final void Function() onShare;

  @override
  Component build(BuildContext context) {
    final score = report.score;
    final counts = statusCounts(report);
    final total = report.direct.length;
    final good = report.direct.where((e) => e.status.good).length;
    return section(
      classes: 'panel doc-sum',
      attributes: {'aria-label': 'Summary'},
      [
        div(classes: 'doc-score', [
          span(classes: 'eyebrow', [.text(report.project ?? 'Your project')]),
          div(classes: 'doc-score-n tabular', [
            .text(score == null ? notAvailable : '$score'),
            if (score != null) span([.text('%')]),
          ]),
          span(classes: 'doc-score-l', [
            .text(
              score == null
                  ? 'None of these packages are tracked, so there’s no score.'
                  : '$good of ${report.judged} judged direct dependencies are Healthy or Stable.',
            ),
          ]),
        ]),
        div(classes: 'doc-break', [
          div(
            classes: 'doc-bar-track',
            attributes: {
              'role': 'img',
              'aria-label': [for (final (s, n) in counts) '$n ${s.label}'].join(', '),
            },
            [
              for (final (s, n) in counts)
                span(
                  classes: 'doc-seg ${statusClass(s)}',
                  styles: Styles(raw: {'flex-grow': '$n'}),
                  attributes: {'title': '$n ${s.label}'},
                  [],
                ),
            ],
          ),
          ul(classes: 'doc-counts', [
            for (final (s, n) in counts)
              li([
                statusPill(s),
                b(classes: 'tabular', [.text('$n')]),
              ]),
          ]),
          div(classes: 'doc-sum-foot', [
            span(classes: 'muted', [
              .text(
                '${groupedNumber(total)} direct'
                '${report.transitive.isEmpty ? '' : ', ${groupedNumber(report.transitive.length)} transitive'}'
                ' · data from $dataDate',
              ),
            ]),
            if (score != null)
              button(classes: 'btn small', type: ButtonType.button, onClick: onShare, [
                const Icon(Icons.download, size: 15),
                .text('Download share card'),
              ]),
          ]),
        ]),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    rule('.doc-sum', {'display': 'grid', 'grid-template-columns': 'minmax(220px,300px) 1fr'}),
    rule('.doc-score', {
      'padding': '24px',
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '6px',
      'border-right': '1px solid var(--line)',
    }),
    rule('.doc-score .eyebrow', {'overflow': 'hidden', 'text-overflow': 'ellipsis', 'white-space': 'nowrap'}),
    rule('.doc-score-n', {
      'font-size': '72px',
      'line-height': '1',
      'font-weight': '600',
      'letter-spacing': '-0.04em',
    }),
    rule('.doc-score-n span', {'font-size': '32px', 'color': 'var(--muted)', 'margin-left': '2px'}),
    rule('.doc-score-l', {'font-size': '14px', 'color': 'var(--muted)', 'line-height': '1.45'}),
    rule('.doc-break', {
      'padding': '24px',
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '16px',
      'min-width': '0',
    }),
    rule('.doc-bar-track', {
      'display': 'flex',
      'gap': '3px',
      'height': '12px',
      'border-radius': '2px',
      'overflow': 'hidden',
    }),
    rule('.doc-seg', {'flex-basis': '0', 'min-width': '6px', 'background': 'var(--line)'}),
    rule('.doc-seg.replace', {'background': 'var(--neg)'}),
    rule('.doc-seg.risk', {'background': 'var(--slow-ink)'}),
    rule('.doc-seg.watch', {'background': 'var(--muted)'}),
    rule('.doc-seg.healthy', {'background': 'var(--accent)'}),
    rule('.doc-seg.stable', {'background': 'var(--stable-ink)'}),
    rule('.doc-counts', {
      'list-style': 'none',
      'margin': '0',
      'padding': '0',
      'display': 'flex',
      'flex-wrap': 'wrap',
      'gap': '8px 18px',
    }),
    rule('.doc-counts li', {'display': 'flex', 'align-items': 'center', 'gap': '8px', 'font-size': '15px'}),
    rule('.doc-sum-foot', {
      'margin-top': 'auto',
      'display': 'flex',
      'flex-wrap': 'wrap',
      'gap': '12px',
      'align-items': 'center',
      'justify-content': 'space-between',
      'font-size': '13px',
    }),
    below(760, [
      rule('.doc-sum', {'grid-template-columns': '1fr'}),
      rule('.doc-score', {'border-right': '0', 'border-bottom': '1px solid var(--line)'}),
    ]),
  ];
}
