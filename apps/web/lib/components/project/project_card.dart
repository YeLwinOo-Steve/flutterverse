import 'package:fv_core/fv_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../data/view.dart';
import '../../styles/css.dart';
import '../ui/badges.dart';
import '../ui/project_logo.dart';
import 'project_table.dart';

/// A project as a card, used instead of the table on narrow screens.
class ProjectCard extends StatelessComponent {
  const ProjectCard({required this.ranked, required this.rank, super.key});

  final RankedRow ranked;
  final int rank;

  @override
  Component build(BuildContext context) {
    final r = ranked.row;
    return a(href: r.path, classes: 'pcard', [
      div(classes: 'pcard-top', [
        span(classes: 'pt-rank', styles: Styles(raw: {'font-size': '13px'}), [.text('$rank')]),
        ProjectLogo(initials: r.initials, color: r.logoColor, imageUrl: r.avatarUrl),
        div(classes: 'pcard-id', [
          b([.text(r.name)]),
          span([.text(r.owner ?? '')]),
        ]),
        span(classes: 'pcard-signal', [.text(ranked.signal)]),
      ]),
      if (r.description != null) span(classes: 'pcard-desc', [.text(r.description!)]),
      div(classes: 'pcard-facts', [
        span([
          b([.text(compactNumber(r.shownStars))]),
          .text(r.repoWideStars ? ' repo stars' : ' stars'),
        ]),
        span([.text('${signedNumber(r.stars30d)} / 30d')]),
        span([
          .text('MOM '),
          b([.text(momentumLabel(r.momentum, early: r.momentumEarly))]),
        ]),
        span([.text('${r.isPublished ? compactNumber(r.likes) : notApplicable} likes')]),
        span([.text('${r.isPublished ? compactNumber(r.downloads) : notApplicable} dl')]),
        healthPill(r),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    rule('.pcard', {
      'border': '1px solid var(--line)',
      'background': 'var(--surface)',
      'border-radius': '2px',
      'padding': '16px',
      'display': 'flex',
      'flex-direction': 'column',
      'gap': '12px',
      'color': 'var(--ink)',
    }),
    rule('.pcard:hover', {'color': 'var(--ink)'}),
    rule('.pcard-top', {'display': 'flex', 'gap': '12px', 'align-items': 'center'}),
    rule('.pcard-id', {'flex': '1', 'min-width': '0', 'display': 'flex', 'flex-direction': 'column'}),
    rule('.pcard-id b', {'font-size': '15px', 'font-weight': '600'}),
    rule('.pcard-id span', {'font-size': '13px', 'color': 'var(--muted)'}),
    rule('.pcard-signal', {'font': mono(13, weight: 600), 'color': 'var(--pos)'}),
    rule('.pcard-desc', {'font-size': '14px', 'color': 'var(--muted)', 'line-height': '1.45'}),
    rule('.pcard-facts', {
      'display': 'grid',
      'grid-template-columns': 'repeat(3,minmax(0,1fr))',
      'gap': '8px',
      'font': mono(13, weight: 400),
      'color': 'var(--muted)',
    }),
    rule('.pcard-facts b', {'color': 'var(--ink)'}),
  ];
}
