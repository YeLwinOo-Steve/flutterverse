import 'dart:math' as math;

import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../components/project/tier_pips.dart';
import '../../components/ui/badges.dart';
import '../../components/ui/icon.dart';
import '../../components/ui/icons.dart';
import '../../components/ui/sparkline.dart';
import '../../styles/css.dart';

/// The five headline cells under the detail header.
class KpiGrid extends StatelessComponent {
  const KpiGrid({required this.detail, required this.now, super.key});

  final ProjectDetail detail;
  final DateTime now;

  @override
  Component build(BuildContext context) {
    final r = detail.row;
    return section(classes: 'cell-grid kpis', [
      _StarsCell(r),
      _GainedCell(r),
      _MomentumCell(r),
      _PubCell(r),
      _MaintenanceCell(detail, now),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.kpis', {'grid-template-columns': 'repeat(auto-fit,minmax(240px,1fr))'}),
    rule('.kpi', {'padding': '24px', 'display': 'flex', 'flex-direction': 'column', 'gap': '16px', 'min-width': '0'}),
    rule('.kpi-row', {'display': 'flex', 'justify-content': 'space-between', 'align-items': 'center'}),
    rule('.kpi-big', {
      'font-size': '44px',
      'font-weight': '600',
      'letter-spacing': '-0.03em',
      'line-height': '1',
      'font-variant-numeric': 'tabular-nums',
    }),
    rule('.kpi-stack', {'display': 'flex', 'flex-direction': 'column', 'gap': '8px'}),
    rule('.kpi-spark', {'margin-top': 'auto'}),
    rule('.gain-row', {
      'display': 'grid',
      'grid-template-columns': '72px minmax(0,1fr) 56px',
      'gap': '12px',
      'align-items': 'center',
    }),
    rule('.gain-row > span:first-child', {'font-size': '13px', 'color': 'var(--muted)'}),
    rule('.gain-row > b', {
      'font-size': '14px',
      'font-weight': '600',
      'text-align': 'right',
      'font-variant-numeric': 'tabular-nums',
    }),
    rule('.track', {'height': '8px', 'background': 'var(--surface2)', 'border-radius': '999px', 'overflow': 'hidden'}),
    rule('.track > div', {'height': '100%', 'background': 'var(--accent)', 'border-radius': '999px'}),
    rule('.verdict', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '5px',
      'font': mono(12),
      'padding': '4px 10px 4px 8px',
      'border-radius': '999px',
      'background': 'var(--surface2)',
      'color': 'var(--ink)',
    }),
    rule('.verdict.hot', {'background': 'var(--hot-bg)', 'color': 'var(--hot-ink)'}),
    rule('.kpi-score', {'display': 'flex', 'align-items': 'baseline', 'gap': '6px'}),
    rule('.kpi-score span', {'font-size': '15px', 'color': 'var(--muted)'}),
    rule('.kpi-note', {'font-size': '13px', 'line-height': '1.5', 'color': 'var(--muted)'}),
    // Columns sized to their content so labels like "Downloads / 30d" stay on
    // one line in the narrowest cell.
    rule('.kpi-pair', {
      'display': 'grid',
      'grid-template-columns': 'repeat(2,max-content)',
      'justify-content': 'space-between',
      'gap': '16px',
    }),
    rule('.kpi-fact', {'display': 'flex', 'flex-direction': 'column', 'gap': '4px'}),
    rule('.kpi-fact > span', {'font-size': '13px', 'color': 'var(--muted)', 'white-space': 'nowrap'}),
    rule('.kpi-fact > b', {'font-size': '24px', 'font-weight': '600', 'letter-spacing': '-0.02em'}),
    rule('.kpi-line', {'display': 'flex', 'justify-content': 'space-between', 'font-size': '13px'}),
    rule('.kpi-line span', {'color': 'var(--muted)'}),
    rule('.kpi-line b', {'font-weight': '600', 'font-variant-numeric': 'tabular-nums'}),
    rule('.kpi-list', {'display': 'flex', 'flex-direction': 'column', 'border-top': '1px solid var(--line)'}),
    rule('.kpi-list > div', {
      'display': 'flex',
      'justify-content': 'space-between',
      'padding': '10px 0',
      'font-size': '13px',
    }),
    rule('.kpi-list > div + div', {'border-top': '1px solid var(--line)'}),
    rule('.kpi-list span', {'color': 'var(--muted)'}),
    rule('.kpi-list b', {'font-weight': '500'}),
  ];
}

Component _label(String text) => span(classes: 'eyebrow', [.text(text)]);

class _StarsCell extends StatelessComponent {
  const _StarsCell(this.r);
  final ProjectRow r;

  @override
  Component build(BuildContext context) => div(classes: 'kpi', [
    _label('GitHub stars'),
    div(classes: 'kpi-stack', [
      span(classes: 'kpi-big', [.text(compactNumber(r.shownStars))]),
      if (r.sharedRepo)
        span(classes: 'kpi-note', [.text(_sharedRepoNote(r.repo))])
      else
        span(classes: 'growth', styles: Styles(raw: {'padding': '3px 8px'}), [
          .text('↑ ${signedNumber(r.stars30d)} this month'),
        ]),
    ]),
    if (!r.sharedRepo) div(classes: 'kpi-spark', [Sparkline(r.spark, height: 44, area: true, fill: true)]),
  ]);
}

class _GainedCell extends StatelessComponent {
  const _GainedCell(this.r);
  final ProjectRow r;

  @override
  Component build(BuildContext context) {
    if (r.sharedRepo) {
      return div(classes: 'kpi', [
        _label('Stars gained'),
        span(classes: 'kpi-note', [
          .text('GitHub counts stars per repository, so there is no star growth to track for one package.'),
        ]),
      ]);
    }
    final values = [
      ('Today', r.stars1d),
      ('This week', r.stars7d),
      ('This month', r.stars30d),
      ('This year', r.stars365d),
    ];
    final most = math.max(1, values.map((v) => v.$2 ?? 0).reduce(math.max));
    return div(classes: 'kpi', [
      _label('Stars gained'),
      div(classes: 'kpi-stack', styles: Styles(raw: {'gap': '12px'}), [
        for (final (label, v) in values)
          div(classes: 'gain-row', [
            span([.text(label)]),
            div(classes: 'track', [
              div(
                styles: Styles(
                  raw: {'width': '${v == null ? 0 : math.max(2, math.sqrt(math.max(0, v) / most) * 100)}%'},
                ),
                [],
              ),
            ]),
            b([.text(signedNumber(v))]),
          ]),
      ]),
    ]);
  }
}

class _MomentumCell extends StatelessComponent {
  const _MomentumCell(this.r);
  final ProjectRow r;

  @override
  Component build(BuildContext context) {
    final s = r.momentum;
    if (s == null) {
      return div(classes: 'kpi', [
        _label('Momentum'),
        span(classes: 'kpi-big', [.text(notAvailable)]),
        span(classes: 'kpi-note', [.text(_noMomentumNote(r))]),
      ]);
    }
    final verdict = s >= 70 ? 'Hot' : (s >= 45 ? 'Steady' : 'Cooling');
    return div(classes: 'kpi', [
      div(classes: 'kpi-row', [
        _label('Momentum'),
        span(classes: verdict == 'Hot' ? 'verdict hot' : 'verdict', [
          if (verdict == 'Hot') const Icon(Icons.fire, size: 14, filled: true),
          .text(r.momentumEarly ? '$verdict · early' : verdict),
        ]),
      ]),
      div(classes: 'kpi-score', [
        span(classes: 'kpi-big', styles: Styles(raw: {'font-size': '44px', 'color': 'var(--ink)'}), [
          .text(momentumLabel(s, early: r.momentumEarly)),
        ]),
        span([.text('/ 100')]),
      ]),
      MomentumMeter(s, cellHeight: 20, gap: 3, radius: 2),
      span(classes: 'kpi-note', [
        if (r.momentumEarly)
          .text('Early estimate: under a week of star history so far, scaled up. It settles once a full week is in.')
        else
          .text('Recent star growth, downloads and release activity, weighted over lifetime size.'),
      ]),
    ]);
  }
}

class _PubCell extends StatelessComponent {
  const _PubCell(this.r);
  final ProjectRow r;

  @override
  Component build(BuildContext context) {
    final max = r.maxPoints ?? 160;
    return div(classes: 'kpi', [
      _label('pub.dev'),
      if (!r.isPublished)
        span(classes: 'kpi-note', styles: Styles(raw: {'font-size': '14px'}), [
          .text('Not published to pub.dev — distributed from source.'),
        ])
      else ...[
        div(classes: 'kpi-pair', [
          div(classes: 'kpi-fact', [
            span([.text('Likes')]),
            b([.text(compactNumber(r.likes))]),
          ]),
          div(classes: 'kpi-fact', [
            span([.text('Downloads / 30d')]),
            b([.text(compactNumber(r.downloads))]),
          ]),
        ]),
        div(classes: 'kpi-stack', [
          div(classes: 'kpi-line', [
            span([.text('Pub points')]),
            b([.text('${r.points ?? notAvailable} / $max')]),
          ]),
          div(classes: 'track', [
            div(styles: Styles(raw: {'width': '${(r.points ?? 0) / max * 100}%'}), []),
          ]),
        ]),
      ],
    ]);
  }
}

class _MaintenanceCell extends StatelessComponent {
  const _MaintenanceCell(this.d, this.now);
  final ProjectDetail d;
  final DateTime now;

  @override
  Component build(BuildContext context) {
    final r = d.row;
    return div(classes: 'kpi', [
      div(classes: 'kpi-row', [_label('Maintenance'), healthPill(r)]),
      div(classes: 'kpi-fact', [
        b([.text(r.version == null ? notAvailable : 'v${r.version}')]),
        span([.text('Released ${ago(r.released, now: now)}')]),
      ]),
      div(classes: 'kpi-list', [
        div([
          span([.text('Last commit')]),
          b([.text(ago(r.lastCommit, now: now))]),
        ]),
        div([
          span([.text('Releases / year')]),
          b([.text('${d.pub?.releasesLastYear ?? notAvailable}')]),
        ]),
      ]),
    ]);
  }
}

/// What the star count of a package in a shared monorepo stands for.
String _sharedRepoNote(String? repo) => 'Stars for the whole $repo repository, which it shares with other packages.';

/// Why a project has no momentum score yet, or can't have one.
String _noMomentumNote(ProjectRow r) => switch (r) {
  ProjectRow(sharedRepo: true) =>
    'Momentum is built on star growth, which a package sharing its repository doesn’t have.',
  ProjectRow(repo: null) => 'Momentum is built on star growth, and this package has no GitHub repository.',
  _ => 'Momentum is built on a week of daily star counts. It appears once that history exists.',
};
