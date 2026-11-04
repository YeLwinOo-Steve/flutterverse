import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/layout/site_header.dart';
import '../../styles/css.dart';
import 'jobs_view.dart';

/// `/jobs`: open Flutter roles from companies' own hiring pages. A feed, not
/// a job board: every row links out, and nothing is applied for here.
class JobsPage extends StatelessComponent {
  const JobsPage({required this.jobs, required this.now, super.key});

  final JobsFile jobs;
  final DateTime now;

  @override
  Component build(BuildContext context) {
    final updated = jobs.generatedAt;
    return div(classes: 'jobs', [
      header(classes: 'jobs-head', [
        span(classes: 'eyebrow accent', [.text('Jobs')]),
        h1(classes: 'page-title', [.text('Open Flutter roles')]),
        p(classes: 'lede', [
          .text("Open Flutter roles from companies' own hiring pages. You apply on their site."),
        ]),
        if (updated != null)
          span(classes: 'jobs-stamp', [
            .text(
              '${groupedNumber(jobs.jobs.length)} roles from ${jobs.companies} companies · updated ${fullDate(updated)}',
            ),
          ]),
      ]),
      if (jobs.jobs.isEmpty)
        div(classes: 'empty', [
          b([.text('No open roles listed right now')]),
          span([.text('The list refreshes every day.')]),
        ])
      else
        JobsView(jobs: jobs, now: now.toIso8601String()),
      p(classes: 'jobs-foot', [
        .text('Hiring Flutter developers? '),
        a(
          href: _addCompanyUrl,
          target: Target.blank,
          attributes: {'rel': 'noopener'},
          [
            .text('List your company'),
          ],
        ),
        .text('. Want your roles removed? '),
        a(
          href: _removalUrl,
          target: Target.blank,
          attributes: {'rel': 'noopener'},
          [.text('Ask here')],
        ),
        .text(' and they go within a week.'),
      ]),
    ]);
  }

  /// The issue forms in `.github/ISSUE_TEMPLATE/`, opened already filled in.
  static const _addCompanyUrl = '$sourceUrl/issues/new?template=jobs-add-company.yml';

  static const _removalUrl = '$sourceUrl/issues/new?template=jobs-remove.yml';

  @css
  static List<StyleRule> get styles => [
    rule('.jobs', {'display': 'flex', 'flex-direction': 'column', 'gap': '28px', 'max-width': '1040px'}),
    rule('.jobs-head', {'display': 'flex', 'flex-direction': 'column', 'gap': '12px', 'max-width': '720px'}),
    rule('.jobs-stamp', {'font': mono(12, weight: 400), 'color': 'var(--muted)'}),
    rule('.jobs-body', {'display': 'flex', 'flex-direction': 'column', 'gap': '16px'}),
    rule('.jobs-foot', {'margin': '0', 'font-size': '14px', 'color': 'var(--muted)'}),
    rule('.jobs-foot a', {'color': 'var(--accent)'}),
    below(640, [
      rule('.jobs .page-title', {'font-size': '34px'}),
    ]),
  ];
}
