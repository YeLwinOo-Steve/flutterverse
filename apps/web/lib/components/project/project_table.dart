import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../data/view.dart';
import '../../styles/css.dart';
import '../ui/badges.dart';
import '../ui/icon.dart';
import '../ui/icons.dart';
import '../ui/project_logo.dart';
import '../ui/sparkline.dart';
import 'project_card.dart';
import 'tier_pips.dart';

/// A ranked row and the value for its signal column.
typedef RankedRow = ({ProjectRow row, String signal});

/// The shared Rankings/Listing table: a wide grid on desktop, cards on
/// narrow screens (both rendered; CSS picks one).
class ProjectTable extends StatelessComponent {
  const ProjectTable({
    required this.rows,
    required this.categories,
    required this.signalHead,
    this.rankFrom = 1,
    super.key,
  });

  final List<RankedRow> rows;
  final Map<String, String> categories;
  final String signalHead;

  /// The first row's rank, for later pages.
  final int rankFrom;

  @override
  Component build(BuildContext context) {
    return Component.fragment([
      div(classes: 'ptable panel', [
        div(classes: 'ptable-inner', [
          div(classes: 'ptable-head', [
            span([.text('Rank')]),
            span([.text('Project')]),
            span([.text(signalHead)]),
            span(classes: 'r', [.text('Stars')]),
            span(classes: 'r', [.text('Downloads')]),
            span([.text('Momentum')]),
            span(classes: 'r', [.text('30-day trend')]),
          ]),
          for (final (i, ranked) in rows.indexed) _WideRow(ranked, rankFrom + i, categories),
        ]),
      ]),
      div(classes: 'pcards', [
        for (final (i, ranked) in rows.indexed) ProjectCard(ranked: ranked, rank: rankFrom + i),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.ptable', {'overflow-x': 'auto'}),
    rule('.ptable-inner', {'min-width': '960px'}),
    rule('.ptable-head, .ptable-row', {
      'display': 'grid',
      'grid-template-columns':
          '56px minmax(280px,2.4fr) minmax(120px,1fr) minmax(90px,0.8fr) minmax(90px,0.8fr) minmax(120px,1fr) 120px',
      'gap': '0 24px',
      'align-items': 'center',
      'padding': '12px 24px',
    }),
    rule('.ptable-head', {
      'background': 'var(--bg)',
      'border-bottom': '1px solid var(--line)',
      'font': mono(11),
      'letter-spacing': '0.06em',
      'text-transform': 'uppercase',
      'color': 'var(--muted)',
    }),
    rule('.ptable-head .r', {'text-align': 'right'}),
    rule('.ptable-row', {
      'padding': '18px 24px',
      'border-bottom': '1px solid var(--line)',
      'font-size': '14px',
      'color': 'var(--ink)',
    }),
    rule('.ptable-row:hover', {'color': 'var(--ink)'}),
    rule('.pt-rank', {'font': mono(14), 'color': 'var(--muted)'}),
    rule('.pt-project', {'display': 'flex', 'gap': '14px', 'align-items': 'center', 'min-width': '0'}),
    rule('.pt-text', {'display': 'flex', 'flex-direction': 'column', 'min-width': '0', 'gap': '6px'}),
    rule('.pt-title', {'display': 'flex', 'gap': '8px', 'align-items': 'center', 'flex-wrap': 'wrap'}),
    rule('.pt-name', {'font-size': '15px', 'font-weight': '600'}),
    rule('.pt-owner', {'font-size': '13px', 'color': 'var(--muted)'}),
    rule('.pt-tags', {'display': 'flex', 'gap': '6px', 'flex-wrap': 'wrap'}),
    rule('.pt-signal', {
      'font': mono(13),
      'padding': '4px 9px',
      'border-radius': '999px',
      'background': 'var(--accent-soft)',
      'color': 'var(--pos)',
      'white-space': 'nowrap',
    }),
    rule('.pt-metric', {'display': 'flex', 'flex-direction': 'column', 'align-items': 'flex-end', 'gap': '6px'}),
    rule('.pt-value', {
      'display': 'flex',
      'align-items': 'center',
      'gap': '6px',
      'font-size': '15px',
      'font-weight': '600',
      'font-variant-numeric': 'tabular-nums',
      'color': 'var(--ink)',
    }),
    rule('.pt-value .icon', {'color': 'var(--muted)'}),
    rule('.pt-repo', {'font-size': '11px', 'color': 'var(--muted)'}),
    rule('.pt-mom', {'display': 'flex', 'align-items': 'center', 'gap': '10px'}),
    rule('.pt-mom b', {
      'font-size': '15px',
      'font-weight': '600',
      'font-variant-numeric': 'tabular-nums',
      'width': '28px',
    }),
    rule('.pt-trend', {'display': 'flex', 'justify-content': 'flex-end'}),
    rule('.pcards', {'display': 'none', 'flex-direction': 'column', 'gap': '8px'}),
    below(820, [
      rule('.ptable', {'display': 'none'}),
      rule('.pcards', {'display': 'flex'}),
    ]),
  ];
}

class _WideRow extends StatelessComponent {
  const _WideRow(this.ranked, this.rank, this.categories);

  final RankedRow ranked;
  final int rank;
  final Map<String, String> categories;

  @override
  Component build(BuildContext context) {
    final r = ranked.row;
    return a(href: r.path, classes: 'ptable-row hover-row', [
      span(classes: 'pt-rank', [.text('$rank')]),
      div(classes: 'pt-project', [
        ProjectLogo(initials: r.initials, color: r.logoColor, imageUrl: r.avatarUrl),
        div(classes: 'pt-text', [
          span(classes: 'pt-title', [
            span(classes: 'pt-name', [.text(r.name)]),
            if (r.owner != null) span(classes: 'pt-owner', [.text('by ${r.owner}')]),
          ]),
          div(classes: 'pt-tags', [
            for (final c in r.categories.take(1)) categoryPill(categoryLabel(categories, c), padding: '3px 8px'),
            healthPill(r),
          ]),
        ]),
      ]),
      span([
        span(classes: 'pt-signal', [.text(ranked.signal)]),
      ]),
      div(classes: 'pt-metric', [
        span(
          classes: 'pt-value',
          attributes: {if (r.repoWideStars) 'title': 'Stars for the whole ${r.repo} repo'},
          [
            .text(compactNumber(r.shownStars)),
            if (r.repoWideStars) span(classes: 'pt-repo', [.text('repo')]),
          ],
        ),
        StarPips(r.stars),
      ]),
      div(classes: 'pt-metric', [
        span(classes: 'pt-value', [
          const Icon(Icons.downloadTable, size: 14, strokeWidth: 1.6),
          .text(r.isPublished ? compactNumber(r.downloads) : notApplicable),
        ]),
        DownloadPips(r.downloads, published: r.isPublished),
      ]),
      div(classes: 'pt-mom', [
        b(
          attributes: {if (r.momentumEarly) 'title': 'Early estimate: under a week of star history'},
          [.text(momentumLabel(r.momentum, early: r.momentumEarly))],
        ),
        MomentumMeter(r.momentum),
      ]),
      div(classes: 'pt-trend', [Sparkline(r.spark, width: 104, height: 32)]),
    ]);
  }
}
