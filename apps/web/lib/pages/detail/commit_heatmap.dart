import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../styles/css.dart';

/// A year of commits as a grid of days, one column per week, darker on
/// busier days, like GitHub's contribution graph.
class CommitHeatmap extends StatelessComponent {
  const CommitHeatmap({required this.activity, required this.repo, super.key});

  final CommitActivity activity;

  /// `owner/name`, which the counts are for: the whole repo, even when it
  /// holds several packages.
  final String repo;

  @override
  Component build(BuildContext context) {
    final act = activity;
    final weeks = act.days.length ~/ 7;
    final levels = heatLevels(act.days);
    final total = act.total;
    return section(classes: 'detail-section', [
      h2([.text('Commit activity')]),
      span(classes: 'detail-section-note', [
        .text('${commitCount(total)} in the past year to '),
        a(href: 'https://github.com/$repo', [.text(repo)]),
        .text(' · as of ${fullDate(act.fetchedDay)}'),
      ]),
      div(classes: 'heat', styles: Styles(raw: {'--weeks': '$weeks'}), [
        div(
          classes: 'heat-months',
          attributes: {'aria-hidden': 'true'},
          [
            for (final (w, label) in monthStarts(act))
              span(styles: Styles(raw: {'grid-column': '${w + 1} / span 4'}), [.text(label)]),
          ],
        ),
        div(
          classes: 'heat-grid',
          attributes: {'role': 'img', 'aria-label': '$total commits in the past year, by day'},
          [
            for (final (i, n) in act.days.indexed)
              if (act.dayAt(i).isAfter(act.fetchedDay))
                span(classes: 'heat-day later', [])
              else
                span(
                  classes: ['heat-day l${levels(n)}', ?_tipSide(i ~/ 7, weeks)].join(' '),
                  attributes: {'data-tip': commitCount(n), 'data-date': fullDate(act.dayAt(i))},
                  [],
                ),
          ],
        ),
      ]),
      div(
        classes: 'heat-legend',
        attributes: {'aria-hidden': 'true'},
        [
          span([.text('Less')]),
          for (var l = 0; l <= 4; l++) span(classes: 'heat-day l$l', []),
          span([.text('More')]),
        ],
      ),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.heat', {'max-width': '760px', 'display': 'flex', 'flex-direction': 'column', 'gap': '6px'}),
    rule('.heat-months, .heat-grid', {
      'display': 'grid',
      'grid-template-columns': 'repeat(var(--weeks),minmax(0,1fr))',
      'column-gap': '3px',
    }),
    rule('.heat-months', {'font': mono(11, weight: 400), 'color': 'var(--muted)', 'white-space': 'nowrap'}),
    rule('.heat-grid', {'grid-template-rows': 'repeat(7,auto)', 'grid-auto-flow': 'column', 'row-gap': '3px'}),
    rule('.heat-day', {'aspect-ratio': '1', 'border-radius': '2px', 'background': 'var(--line)'}),
    rule('.heat-day.l1', {'background': 'color-mix(in srgb,var(--accent) 30%,var(--surface))'}),
    rule('.heat-day.l2', {'background': 'color-mix(in srgb,var(--accent) 55%,var(--surface))'}),
    rule('.heat-day.l3', {'background': 'color-mix(in srgb,var(--accent) 78%,var(--surface))'}),
    rule('.heat-day.l4', {'background': 'var(--accent)'}),
    rule('.heat-day.later', {'visibility': 'hidden'}),
    // The hover tooltip, in the trend chart's style. Near the edges it
    // hangs inwards so it stays on screen.
    rule('.heat-grid .heat-day', {'position': 'relative'}),
    rule('.heat-grid .heat-day:hover', {'outline': '1px solid var(--ink)'}),
    rule('.heat-grid .heat-day:hover::after', {
      'content': "attr(data-tip) '\\A' attr(data-date)",
      'white-space': 'pre',
      'position': 'absolute',
      'bottom': 'calc(100% + 6px)',
      'left': '50%',
      'transform': 'translateX(-50%)',
      'z-index': '5',
      'padding': '6px 10px',
      'background': 'var(--surface)',
      'border': '1px solid var(--line)',
      'box-shadow': '0 8px 24px rgba(4,43,89,0.12)',
      'font': sans(12),
      'line-height': '1.5',
      'color': 'var(--ink)',
      'pointer-events': 'none',
    }),
    rule('.heat-grid .heat-day.tip-start:hover::after', {'left': '0', 'transform': 'none'}),
    rule('.heat-grid .heat-day.tip-end:hover::after', {'left': 'auto', 'right': '0', 'transform': 'none'}),
    rule('.heat-legend', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '3px',
      'font': mono(11, weight: 400),
      'color': 'var(--muted)',
    }),
    rule('.heat-legend .heat-day', {'width': '11px'}),
    rule('.heat-legend span:first-child', {'margin-right': '4px'}),
    rule('.heat-legend span:last-child', {'margin-left': '4px'}),
    below(600, [
      rule('.heat-months, .heat-grid', {'column-gap': '2px'}),
      rule('.heat-grid', {'row-gap': '2px'}),
      rule('.heat-day', {'border-radius': '1px'}),
      rule('.heat-months', {'font-size': '10px'}),
    ]),
  ];
}

/// `No commits`, `1 commit`, `1,711 commits`.
String commitCount(int n) => switch (n) {
  0 => 'No commits',
  1 => '1 commit',
  _ => '${groupedNumber(n)} commits',
};

/// Which way week [w]'s tooltips hang: inwards for the outer weeks.
String? _tipSide(int w, int weeks) => w < 6 ? 'tip-start' : (w >= weeks - 6 ? 'tip-end' : null);

/// How dark a day is, 0–4: 0 for no commits, then by the quartile of the
/// busy days it falls in, so one huge day doesn't wash out the rest.
int Function(int) heatLevels(List<int> days) {
  final busy = [
    for (final n in days)
      if (n > 0) n,
  ]..sort();
  if (busy.isEmpty) return (_) => 0;
  int q(double f) => busy[((busy.length - 1) * f).round()];
  final (q1, q2, q3) = (q(.25), q(.5), q(.75));
  return (n) => n <= 0
      ? 0
      : n <= q1
      ? 1
      : n <= q2
      ? 2
      : n <= q3
      ? 3
      : 4;
}

/// `(week column, month)` for each week that starts a new month, skipping
/// a first label that would be cut short.
List<(int, String)> monthStarts(CommitActivity a) {
  final out = <(int, String)>[];
  final weeks = a.days.length ~/ 7;
  for (var w = 0; w < weeks; w++) {
    final day = a.dayAt(w * 7);
    final prev = w == 0 ? null : a.dayAt(w * 7 - 7);
    if (prev != null && prev.month == day.month) continue;
    if (w == 0 && day.day > 14) continue;
    if (weeks - w < 3) continue;
    out.add((w, monthYear(day).split(' ').first));
  }
  return out;
}
